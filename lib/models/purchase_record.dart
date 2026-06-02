class PurchaseRecord {
  PurchaseRecord({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.purchasedAt,
    required this.source,
  });

  final String id;
  final String productName;
  final String storeName;
  final int price;
  final DateTime purchasedAt;
  final String source;
}
