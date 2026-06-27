import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/shopping_item.dart';
import '../review_mode.dart';
import 'app_store.dart';

/// ゲストモード用ストア。ローカルSQLite（guest_local.db）に永続化し、
/// Firestore への接続は一切行わない。
class GuestModeStore extends AppStore {
  final _localDb = ReviewLocalDb(dbName: 'guest_local.db');

  @override
  bool get isGuestMode => true;

  Future<void> initGuestSession() async {
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
    notifyStoreListeners('guestMode:init');
  }

  @override
  Future<void> connectUser(User user) async {}

  @override
  void startListening() {}

  @override
  void stopListening() {}

  @override
  void upsertProduct(Product? current, Product product) {
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

  @override
  Future<String> createInviteCode() async =>
      throw StateError('ログインが必要です。');

  @override
  Future<void> acceptInviteCode(String code) async =>
      throw StateError('ログインが必要です。');

  @override
  Future<void> leaveSharedSpace(String userId) async {}
}
