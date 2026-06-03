import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/debug.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/receipt.dart';
import '../models/shopping_item.dart';

class AppStore extends ChangeNotifier {
  final ValueNotifier<AppThemePreset> themeNotifier = ValueNotifier(
    themePresets.first,
  );
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);
  String? activeUserId;
  String? activeSpaceId;
  bool _connecting = false;
  bool _notifyScheduled = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _productsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _shoppingSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _purchasesSubscription;

  final List<Product> products = [];
  final List<ShoppingItem> shoppingItems = [];
  final List<PurchaseRecord> purchaseRecords = [];

  int _nextId = 10;

  AppThemePreset get selectedTheme => themeNotifier.value;

  String get _id => '${DateTime.now().millisecondsSinceEpoch}-${_nextId++}';

  @override
  void dispose() {
    debugLog('AppStore dispose');
    stopListening();
    themeNotifier.dispose();
    localeNotifier.dispose();
    super.dispose();
  }

  void notifyStoreListeners(String reason) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    debugLog(
      'AppStore scheduleNotify[$reason] phase=$phase '
      'user=$activeUserId space=$activeSpaceId '
      'products=${products.length} shopping=${shoppingItems.length} '
      'records=${purchaseRecords.length}',
    );

    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) {
        debugLog('AppStore notifyDirect[$reason]');
        notifyListeners();
      }
      return;
    }

    if (_notifyScheduled) {
      debugLog('AppStore notifySkipped[$reason] already queued');
      return;
    }
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      final nowPhase = SchedulerBinding.instance.schedulerPhase;
      debugLog('AppStore notifyDeferred[$reason] nowPhase=$nowPhase');
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance
          .collection('sharedSpaces')
          .doc(activeSpaceId)
          .collection('products');

  CollectionReference<Map<String, dynamic>> get _shoppingItemsRef =>
      FirebaseFirestore.instance
          .collection('sharedSpaces')
          .doc(activeSpaceId)
          .collection('shoppingItems');

  CollectionReference<Map<String, dynamic>> get _purchaseRecordsRef =>
      FirebaseFirestore.instance
          .collection('sharedSpaces')
          .doc(activeSpaceId)
          .collection('purchaseRecords');

  Future<void> connectUser(User user) async {
    debugLog(
      'connectUser start uid=${user.uid} currentUser=$activeUserId '
      'currentSpace=$activeSpaceId connecting=$_connecting',
    );
    if (_connecting || (activeUserId == user.uid && activeSpaceId != null)) {
      debugLog('connectUser skipped');
      return;
    }
    _connecting = true;

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();
      final savedSpaceId = userSnapshot.data()?['activeSpaceId'] as String?;
      var spaceId = savedSpaceId ?? user.uid;
      debugLog(
        'connectUser savedSpaceId=$savedSpaceId resolvedSpaceId=$spaceId',
      );

      final userData = <String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'activeSpaceId': spaceId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!userSnapshot.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }
      await userRef.set(userData, SetOptions(merge: true));

      if (spaceId == user.uid) {
        await _ensurePersonalSpace(firestore, user);
      } else {
        final memberRef = firestore
            .collection('sharedSpaces')
            .doc(spaceId)
            .collection('members')
            .doc(user.uid);
        var isMember = false;
        try {
          isMember = (await memberRef.get()).exists;
        } on FirebaseException catch (error) {
          if (error.code != 'permission-denied') rethrow;
        }
        if (!isMember) {
          debugLog(
            'connectUser user is not a member of saved space $spaceId; '
            'falling back to personal space',
          );
          spaceId = user.uid;
          await userRef.set({
            'activeSpaceId': spaceId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await _ensurePersonalSpace(firestore, user);
        }
      }

      activeUserId = user.uid;
      activeSpaceId = spaceId;
      debugLog('connectUser connected uid=$activeUserId space=$activeSpaceId');
      startListening();
    } finally {
      _connecting = false;
      debugLog('connectUser finish connecting=$_connecting');
    }
  }

  Future<void> _ensurePersonalSpace(
    FirebaseFirestore firestore,
    User user,
  ) async {
    final spaceRef = firestore.collection('sharedSpaces').doc(user.uid);
    await spaceRef.set({
      'name': 'マイスペース',
      'ownerId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await spaceRef.collection('members').doc(user.uid).set({
      'role': 'owner',
      'displayName': user.displayName ?? user.email ?? '自分',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> createInviteCode() async {
    if (activeUserId == null || activeSpaceId == null) {
      throw StateError('ログインが必要です。');
    }

    final code = _newInviteCode();
    debugLog('createInviteCode space=$activeSpaceId code=$code');
    await FirebaseFirestore.instance.collection('invites').doc(code).set({
      'spaceId': activeSpaceId,
      'role': 'member',
      'status': 'active',
      'invitedBy': activeUserId,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<void> acceptInviteCode(String code) async {
    debugLog(
      'acceptInviteCode start input="$code" currentSpace=$activeSpaceId',
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('ログインが必要です。');
    }

    final normalizedCode = normalizeInviteCode(code);
    if (normalizedCode == null) {
      throw StateError('8文字の招待コードを入力してください。');
    }
    final firestore = FirebaseFirestore.instance;
    final inviteRef = firestore.collection('invites').doc(normalizedCode);
    String? acceptedSpaceId;
    debugLog('acceptInviteCode normalized=$normalizedCode');

    await firestore.runTransaction((transaction) async {
      final inviteSnapshot = await transaction.get(inviteRef);
      if (!inviteSnapshot.exists) {
        throw StateError('招待コードが見つかりません。');
      }

      final invite = inviteSnapshot.data()!;
      debugLog('acceptInviteCode invite=${invite.toString()}');
      final expiresAt = invite['expiresAt'];
      if (invite['status'] != 'active' ||
          (expiresAt is Timestamp &&
              expiresAt.toDate().isBefore(DateTime.now()))) {
        throw StateError('この招待コードは期限切れです。');
      }

      final spaceId = invite['spaceId'];
      if (spaceId is! String || spaceId.isEmpty) {
        throw StateError('招待コードの共有先が壊れています。');
      }

      final memberRef = firestore
          .collection('sharedSpaces')
          .doc(spaceId)
          .collection('members')
          .doc(user.uid);
      final userRef = firestore.collection('users').doc(user.uid);

      transaction.set(memberRef, {
        'role': 'member',
        'displayName': user.displayName ?? user.email ?? 'メンバー',
        'inviteId': normalizedCode,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(userRef, {
        'activeSpaceId': spaceId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      acceptedSpaceId = spaceId;
    });

    activeUserId = user.uid;
    activeSpaceId = acceptedSpaceId;
    if (activeSpaceId == null) {
      throw StateError('共有スペースに参加できませんでした。');
    }
    debugLog(
      'acceptInviteCode accepted user=$activeUserId space=$activeSpaceId',
    );
  }

  String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String? normalizeInviteCode(String input) {
    final trimmed = input.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return normalized.length == 8 ? normalized : null;
  }

  void clearCloudSession() {
    stopListening();
    activeUserId = null;
    activeSpaceId = null;
  }

  Future<void> leaveSharedSpace(String userId) async {
    debugLog(
      'leaveSharedSpace start userId=$userId currentSpace=$activeSpaceId',
    );
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(userId);

    await userRef.set({
      'activeSpaceId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final user = FirebaseAuth.instance.currentUser!;
    await _ensurePersonalSpace(firestore, user);

    activeSpaceId = userId;
    stopListening();
    startListening();
    notifyStoreListeners('leaveSharedSpace');
    debugLog('leaveSharedSpace done space=$activeSpaceId');
  }

  void startListening() {
    debugLog('startListening start space=$activeSpaceId');
    if (activeSpaceId == null) {
      debugLog('startListening skipped: no activeSpaceId');
      return;
    }
    _productsSubscription = _productsRef.snapshots().listen((snapshot) {
      products
        ..clear()
        ..addAll(snapshot.docs.map(productFromDoc));
      notifyStoreListeners('products:snapshot');
    }, onError: (Object e) => debugLog('snapshot error: $e'));
    _shoppingSubscription = _shoppingItemsRef.snapshots().listen((snapshot) {
      shoppingItems
        ..clear()
        ..addAll(snapshot.docs.map(shoppingItemFromDoc));
      notifyStoreListeners('shopping:snapshot');
    }, onError: (Object e) => debugLog('snapshot error: $e'));
    _purchasesSubscription = _purchaseRecordsRef
        .orderBy('purchasedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          purchaseRecords
            ..clear()
            ..addAll(snapshot.docs.map(purchaseRecordFromDoc));
          notifyStoreListeners('purchases:snapshot');
        }, onError: (Object e) => debugLog('snapshot error: $e'));
  }

  void stopListening() {
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _shoppingSubscription?.cancel();
    _shoppingSubscription = null;
    _purchasesSubscription?.cancel();
    _purchasesSubscription = null;
  }

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('selectedThemeId');
    if (savedId == null) return;
    final theme = themePresets.firstWhere(
      (t) => t.id == savedId,
      orElse: () => themePresets.first,
    );
    themeNotifier.value = theme;
  }

  void selectTheme(AppThemePreset theme) {
    themeNotifier.value = theme;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('selectedThemeId', theme.id),
    );
    notifyStoreListeners('selectTheme:${theme.id}');
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('selectedLocale');
    if (code == null) return;
    localeNotifier.value = Locale(code);
  }

  void selectLocale(Locale? locale) {
    localeNotifier.value = locale;
    SharedPreferences.getInstance().then((prefs) {
      if (locale == null) {
        prefs.remove('selectedLocale');
      } else {
        prefs.setString('selectedLocale', locale.languageCode);
      }
    });
    notifyStoreListeners('selectLocale:${locale?.languageCode}');
  }

  void upsertProduct(Product? current, Product product) {
    final savedProduct = Product(
      id: current?.id ?? _id,
      name: product.name,
      storeName: product.storeName,
      size: product.size,
      bestPrice: product.bestPrice,
      acceptablePrice: product.acceptablePrice,
      saleDays: product.saleDays,
      memo: product.memo,
      category: product.category,
    );

    if (current == null) {
      products.insert(0, savedProduct);
    } else {
      final index = products.indexWhere((item) => item.id == current.id);
      if (index == -1) {
        debugLog('upsertProduct missing existing id=${current.id}; inserting');
        products.insert(0, savedProduct);
      } else {
        products[index] = savedProduct;
      }
    }
    if (activeSpaceId != null) {
      _productsRef.doc(savedProduct.id).set(productToMap(savedProduct));
    }
    notifyStoreListeners('upsertProduct:${savedProduct.id}');
  }

  void addPurchaseRecordsFromReceipt(ReceiptParseResult result) {
    for (final item in result.items) {
      addPurchaseRecord(
        PurchaseRecord(
          id: _id,
          productName: item.name,
          storeName: result.storeName,
          price: item.price,
          purchasedAt: result.purchasedAt,
          source: 'receipt_ocr',
        ),
      );
    }
  }

  void deleteProduct(Product product) {
    debugLog('deleteProduct id=${product.id}');
    products.removeWhere((item) => item.id == product.id);
    if (activeSpaceId != null) {
      _productsRef.doc(product.id).delete();
    }
    notifyStoreListeners('deleteProduct:${product.id}');
  }

  void upsertShoppingItem(ShoppingItem? current, ShoppingItem item) {
    final savedItem = ShoppingItem(
      id: current?.id ?? _id,
      name: item.name,
      urgency: item.urgency,
      checked: item.checked,
    );

    if (current == null) {
      shoppingItems.insert(0, savedItem);
    } else {
      final index = shoppingItems.indexWhere((entry) => entry.id == current.id);
      if (index == -1) {
        debugLog(
          'upsertShoppingItem missing existing id=${current.id}; inserting',
        );
        shoppingItems.insert(0, savedItem);
      } else {
        shoppingItems[index] = savedItem;
      }
    }
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(savedItem.id).set(shoppingItemToMap(savedItem));
    }
    notifyStoreListeners('upsertShoppingItem:${savedItem.id}');
  }

  void toggleShoppingItem(ShoppingItem item) {
    final index = shoppingItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      debugLog('toggleShoppingItem missing id=${item.id}');
      return;
    }
    final updatedItem = item.copyWith(checked: !item.checked);
    shoppingItems[index] = updatedItem;
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(updatedItem.id).set(shoppingItemToMap(updatedItem));
    }
    notifyStoreListeners('toggleShoppingItem:${updatedItem.id}');
  }

  void deleteShoppingItem(ShoppingItem item) {
    debugLog('deleteShoppingItem id=${item.id}');
    shoppingItems.removeWhere((entry) => entry.id == item.id);
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(item.id).delete();
    }
    notifyStoreListeners('deleteShoppingItem:${item.id}');
  }

  void addPurchaseRecord(PurchaseRecord record) {
    final savedRecord = PurchaseRecord(
      id: _id,
      productName: record.productName,
      storeName: record.storeName,
      price: record.price,
      purchasedAt: record.purchasedAt,
      source: record.source,
    );
    purchaseRecords.insert(0, savedRecord);
    if (activeSpaceId != null) {
      _purchaseRecordsRef
          .doc(savedRecord.id)
          .set(purchaseRecordToMap(savedRecord));
    }
    notifyStoreListeners('addPurchaseRecord:${savedRecord.id}');
  }

  void deletePurchaseRecord(PurchaseRecord record) {
    purchaseRecords.removeWhere((r) => r.id == record.id);
    if (activeSpaceId != null) {
      _purchaseRecordsRef.doc(record.id).delete();
    }
    notifyStoreListeners('deletePurchaseRecord:${record.id}');
  }

  void updatePurchaseRecord(PurchaseRecord record) {
    final index = purchaseRecords.indexWhere((r) => r.id == record.id);
    if (index == -1) {
      debugLog('updatePurchaseRecord missing id=${record.id}; inserting');
      purchaseRecords.insert(0, record);
    } else {
      purchaseRecords[index] = record;
    }
    if (activeSpaceId != null) {
      _purchaseRecordsRef.doc(record.id).set(purchaseRecordToMap(record));
    }
    notifyStoreListeners('updatePurchaseRecord:${record.id}');
  }

  Map<String, dynamic> productToMap(Product product) {
    return {
      'name': product.name,
      'storeName': product.storeName,
      'size': product.size,
      'bestPrice': product.bestPrice,
      'acceptablePrice': product.acceptablePrice,
      'saleDays': product.saleDays.toList()..sort(),
      'memo': product.memo,
      'category': product.category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Product productFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      size: data['size'] as String?,
      bestPrice: data['bestPrice'] as int? ?? 0,
      acceptablePrice: data['acceptablePrice'] as int? ?? 0,
      saleDays: Set<int>.from(data['saleDays'] as List? ?? const []),
      memo: data['memo'] as String?,
      category: data['category'] as String?,
    );
  }

  Map<String, dynamic> shoppingItemToMap(ShoppingItem item) {
    return {
      'name': item.name,
      'urgency': item.urgency.name,
      'checked': item.checked,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ShoppingItem shoppingItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ShoppingItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      urgency: data['urgency'] == Urgency.later.name
          ? Urgency.later
          : Urgency.now,
      checked: data['checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> purchaseRecordToMap(PurchaseRecord record) {
    return {
      'productName': record.productName,
      'storeName': record.storeName,
      'price': record.price,
      'purchasedAt': Timestamp.fromDate(record.purchasedAt),
      'source': record.source,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PurchaseRecord purchaseRecordFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final purchasedAt = data['purchasedAt'];
    return PurchaseRecord(
      id: doc.id,
      productName: data['productName'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      price: data['price'] as int? ?? 0,
      purchasedAt: purchasedAt is Timestamp
          ? purchasedAt.toDate()
          : DateTime.now(),
      source: data['source'] as String? ?? 'manual',
    );
  }
}
