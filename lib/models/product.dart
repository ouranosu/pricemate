import '../l10n/app_localizations.dart';

class ProductCategory {
  const ProductCategory({required this.id, required this.label});
  final String id;
  final String label;
}

const productCategories = [
  ProductCategory(id: 'meat', label: '肉'),
  ProductCategory(id: 'fish', label: '魚'),
  ProductCategory(id: 'egg', label: '卵'),
  ProductCategory(id: 'vegetable', label: '野菜'),
  ProductCategory(id: 'fruit', label: '果物'),
  ProductCategory(id: 'dairy', label: '乳製品'),
  ProductCategory(id: 'drink', label: '飲料'),
  ProductCategory(id: 'snack', label: 'お菓子'),
  ProductCategory(id: 'daily', label: '日用品'),
  ProductCategory(id: 'other', label: 'その他'),
];

String categoryLabel(String? id) {
  if (id == null) return '';
  return productCategories
      .firstWhere(
        (c) => c.id == id,
        orElse: () => const ProductCategory(id: '', label: ''),
      )
      .label;
}

String localizedCategoryLabel(String? id, AppLocalizations l10n) {
  return switch (id) {
    'meat' => l10n.catMeat,
    'fish' => l10n.catFish,
    'egg' => l10n.catEgg,
    'vegetable' => l10n.catVegetable,
    'fruit' => l10n.catFruit,
    'dairy' => l10n.catDairy,
    'drink' => l10n.catDrink,
    'snack' => l10n.catSnack,
    'daily' => l10n.catDaily,
    'other' => l10n.catOther,
    _ => '',
  };
}

List<String> localizedWeekdayLabels(AppLocalizations l10n) => [
  l10n.wdMon,
  l10n.wdTue,
  l10n.wdWed,
  l10n.wdThu,
  l10n.wdFri,
  l10n.wdSat,
  l10n.wdSun,
];

class Product {
  Product({
    required this.id,
    required this.name,
    required this.storeName,
    this.size,
    required this.bestPrice,
    required this.acceptablePrice,
    required this.saleDays,
    this.memo,
    this.category,
  });

  final String id;
  final String name;
  final String storeName;
  final String? size;
  final int bestPrice;
  final int acceptablePrice;
  final Set<int> saleDays;
  final String? memo;
  final String? category;

  Product copyWith({
    String? name,
    String? storeName,
    String? size,
    int? bestPrice,
    int? acceptablePrice,
    Set<int>? saleDays,
    String? memo,
    String? category,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      size: size ?? this.size,
      bestPrice: bestPrice ?? this.bestPrice,
      acceptablePrice: acceptablePrice ?? this.acceptablePrice,
      saleDays: saleDays ?? this.saleDays,
      memo: memo ?? this.memo,
      category: category ?? this.category,
    );
  }
}
