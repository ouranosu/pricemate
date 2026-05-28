// Google Play 審査用のローカル動作モード。
// Firebase への接続は一切行わず、SQLite をデータストアとして使用する。
// main.dart の既存クラス・ロジックは変更せず、このファイルに完全に分離する。

import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart';

// ─── SQLite ヘルパー ──────────────────────────────────────────────────────────

class ReviewLocalDb {
  static Database? _instance;

  Future<Database> get _db async {
    _instance ??= await _open();
    return _instance!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'review_local.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE products(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            store_name TEXT NOT NULL,
            size TEXT,
            best_price INTEGER NOT NULL,
            acceptable_price INTEGER NOT NULL,
            sale_days TEXT NOT NULL,
            memo TEXT,
            category TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_items(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            urgency TEXT NOT NULL,
            checked INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE purchase_records(
            id TEXT PRIMARY KEY,
            product_name TEXT NOT NULL,
            store_name TEXT NOT NULL,
            price INTEGER NOT NULL,
            purchased_at INTEGER NOT NULL,
            source TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── products ──────────────────────────────────────────────────────────────

  Future<List<Product>> loadProducts() async {
    final rows = await (await _db).query('products');
    return rows.map((r) {
      return Product(
        id: r['id'] as String,
        name: r['name'] as String,
        storeName: r['store_name'] as String,
        size: r['size'] as String?,
        bestPrice: r['best_price'] as int,
        acceptablePrice: r['acceptable_price'] as int,
        saleDays: Set<int>.from(
          (jsonDecode(r['sale_days'] as String) as List).cast<int>(),
        ),
        memo: r['memo'] as String?,
        category: r['category'] as String?,
      );
    }).toList();
  }

  Future<void> saveProduct(Product product) async {
    await (await _db).insert(
      'products',
      {
        'id': product.id,
        'name': product.name,
        'store_name': product.storeName,
        'size': product.size,
        'best_price': product.bestPrice,
        'acceptable_price': product.acceptablePrice,
        'sale_days': jsonEncode(product.saleDays.toList()..sort()),
        'memo': product.memo,
        'category': product.category,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeProduct(String id) async {
    await (await _db).delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ── shopping_items ────────────────────────────────────────────────────────

  Future<List<ShoppingItem>> loadShoppingItems() async {
    final rows = await (await _db).query('shopping_items');
    return rows.map((r) {
      return ShoppingItem(
        id: r['id'] as String,
        name: r['name'] as String,
        urgency: r['urgency'] == Urgency.later.name ? Urgency.later : Urgency.now,
        checked: (r['checked'] as int) == 1,
      );
    }).toList();
  }

  Future<void> saveShoppingItem(ShoppingItem item) async {
    await (await _db).insert(
      'shopping_items',
      {
        'id': item.id,
        'name': item.name,
        'urgency': item.urgency.name,
        'checked': item.checked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeShoppingItem(String id) async {
    await (await _db).delete(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── purchase_records ──────────────────────────────────────────────────────

  Future<List<PurchaseRecord>> loadPurchaseRecords() async {
    final rows = await (await _db).query(
      'purchase_records',
      orderBy: 'purchased_at DESC',
    );
    return rows.map((r) {
      return PurchaseRecord(
        id: r['id'] as String,
        productName: r['product_name'] as String,
        storeName: r['store_name'] as String,
        price: r['price'] as int,
        purchasedAt: DateTime.fromMillisecondsSinceEpoch(
          r['purchased_at'] as int,
        ),
        source: r['source'] as String,
      );
    }).toList();
  }

  Future<void> savePurchaseRecord(PurchaseRecord record) async {
    await (await _db).insert(
      'purchase_records',
      {
        'id': record.id,
        'product_name': record.productName,
        'store_name': record.storeName,
        'price': record.price,
        'purchased_at': record.purchasedAt.millisecondsSinceEpoch,
        'source': record.source,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removePurchaseRecord(String id) async {
    await (await _db).delete(
      'purchase_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ─── 審査用ストア ─────────────────────────────────────────────────────────────

/// AppStore を継承し、Firestore への書き込みをすべて SQLite に置き換える。
/// activeSpaceId / activeUserId は null のまま運用することで、
/// 親クラス側の Firestore ガード（if (activeSpaceId != null)）が自然に機能する。
class ReviewModeStore extends AppStore {
  final _localDb = ReviewLocalDb();

  /// 審査セッション開始：SQLite からデータを読み込んでメモリリストを初期化する。
  Future<void> initReviewSession() async {
    final ps = await _localDb.loadProducts();
    final ss = await _localDb.loadShoppingItems();
    final rs = await _localDb.loadPurchaseRecords();
    products
      ..clear()
      ..addAll(ps);
    shoppingItems
      ..clear()
      ..addAll(ss);
    purchaseRecords
      ..clear()
      ..addAll(rs);
    notifyStoreListeners('reviewMode:init');
  }

  // Firestore への接続をすべて無効化 ──────────────────────────────────────────

  @override
  Future<void> connectUser(User user) async {}

  @override
  void startListening() {}

  @override
  void stopListening() {}

  // データ変更：親クラスのメモリ更新を利用し、SQLite に非同期で永続化 ────────

  @override
  void upsertProduct(Product? current, Product product) {
    // 親クラスがメモリリストの更新と notifyListeners を担う（Firestore はスキップ）
    super.upsertProduct(current, product);
    final id = current?.id;
    final saved = id != null
        ? products.firstWhere((p) => p.id == id, orElse: () => products.first)
        : products.first;
    _localDb.saveProduct(saved);
  }

  @override
  void deleteProduct(Product product) {
    super.deleteProduct(product);
    _localDb.removeProduct(product.id);
  }

  @override
  void upsertShoppingItem(ShoppingItem? current, ShoppingItem item) {
    super.upsertShoppingItem(current, item);
    final id = current?.id;
    final saved = id != null
        ? shoppingItems.firstWhere(
            (s) => s.id == id,
            orElse: () => shoppingItems.first,
          )
        : shoppingItems.first;
    _localDb.saveShoppingItem(saved);
  }

  @override
  void toggleShoppingItem(ShoppingItem item) {
    super.toggleShoppingItem(item);
    final updated = shoppingItems.firstWhere(
      (s) => s.id == item.id,
      orElse: () => item.copyWith(checked: !item.checked),
    );
    _localDb.saveShoppingItem(updated);
  }

  @override
  void deleteShoppingItem(ShoppingItem item) {
    super.deleteShoppingItem(item);
    _localDb.removeShoppingItem(item.id);
  }

  @override
  void addPurchaseRecord(PurchaseRecord record) {
    // 親クラスは record.id を新規採番して purchaseRecords[0] に挿入する
    super.addPurchaseRecord(record);
    _localDb.savePurchaseRecord(purchaseRecords.first);
  }

  @override
  void deletePurchaseRecord(PurchaseRecord record) {
    super.deletePurchaseRecord(record);
    _localDb.removePurchaseRecord(record.id);
  }

  @override
  void updatePurchaseRecord(PurchaseRecord record) {
    super.updatePurchaseRecord(record);
    _localDb.savePurchaseRecord(record);
  }

  // 招待コード：ローカルで完結させる ──────────────────────────────────────────

  /// ランダムな 8 文字コードを生成し SharedPreferences に保存して返す。
  /// 実際の Firestore 登録は行わないが、UI フローは完全に動作する。
  @override
  Future<String> createInviteCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final code = List.generate(
      8,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_invite_code', code);
    return code;
  }

  /// 形式が正しければ（8 文字英数字）受け付ける。
  /// 実際のスペース結合は行わないが、UI のフローを審査担当者が体験できる。
  @override
  Future<void> acceptInviteCode(String code) async {
    final normalized = normalizeInviteCode(code);
    if (normalized == null) {
      throw StateError('8文字の招待コードを入力してください。');
    }
  }

  /// 審査モードではスペース離脱の概念がないため何もしない。
  @override
  Future<void> leaveSharedSpace(String userId) async {
    notifyStoreListeners('leaveSharedSpace:reviewMode');
  }
}
