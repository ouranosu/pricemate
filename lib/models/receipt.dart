class ReceiptItem {
  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.selected = true,
  });
  String name;
  int price;
  int quantity;
  bool selected;
}

class ReceiptParseResult {
  ReceiptParseResult({
    required this.storeName,
    required this.purchasedAt,
    required this.items,
  });
  String storeName;
  DateTime purchasedAt;
  List<ReceiptItem> items;
}

class ProductSuggestion {
  ProductSuggestion({
    required this.name,
    required this.storeName,
    this.size,
    required this.bestPrice,
    required this.acceptablePrice,
    this.memo,
  });
  final String name;
  final String storeName;
  final String? size;
  final int bestPrice;
  final int acceptablePrice;
  final String? memo;
}
