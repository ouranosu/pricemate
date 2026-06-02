import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../core/formatters.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import '../history/purchase_sheet.dart';
import 'product_sheet.dart';

class ProductListView extends StatefulWidget {
  const ProductListView({super.key, required this.store});

  final AppStore store;

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  ProductSort _sort = ProductSort.recentFirst;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final list = widget.store.products.where((p) {
      final matchesQuery =
          _query.isEmpty ||
          p.name.toLowerCase().contains(_query) ||
          p.storeName.toLowerCase().contains(_query) ||
          categoryLabel(p.category).toLowerCase().contains(_query);
      final matchesCategory =
          _categoryFilter == null || p.category == _categoryFilter;
      return matchesQuery && matchesCategory;
    }).toList();
    switch (_sort) {
      case ProductSort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case ProductSort.bestPriceAsc:
        list.sort((a, b) => a.bestPrice.compareTo(b.bestPrice));
      case ProductSort.bestPriceDesc:
        list.sort((a, b) => b.bestPrice.compareTo(a.bestPrice));
      case ProductSort.recentFirst:
        break;
    }
    return list;
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: SheetTitle(title: '並び替え'),
                ),
                for (final (value, label) in [
                  (ProductSort.recentFirst, '最近追加順'),
                  (ProductSort.nameAsc, '名前順（A→Z）'),
                  (ProductSort.bestPriceAsc, 'ベスト価格が安い順'),
                  (ProductSort.bestPriceDesc, 'ベスト価格が高い順'),
                ])
                  ListTile(
                    title: Text(label),
                    trailing: _sort == value ? const Icon(Icons.check) : null,
                    selected: _sort == value,
                    onTap: () {
                      setState(() => _sort = value);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<String> get _usedCategoryIds =>
      widget.store.products.map((p) => p.category ?? '').toSet();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final usedIds = _usedCategoryIds;
    final visibleCategories = productCategories
        .where((c) => usedIds.contains(c.id))
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.store.activeSpaceId == null) return;
        widget.store.stopListening();
        widget.store.startListening();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ViewTitle(
            title: '商品リスト',
            subtitle: '家庭内の価格基準を一覧できます。',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '並び替え',
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortSheet(context),
                ),
                IconButton.filledTonal(
                  tooltip: '商品を追加',
                  icon: const Icon(Icons.add),
                  onPressed: () => showProductSheet(context, widget.store),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '商品名・店舗・カテゴリーで検索',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const BannerAdWidget(),
          if (visibleCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('すべて'),
                    selected: _categoryFilter == null,
                    onSelected: (_) =>
                        setState(() => _categoryFilter = null),
                  ),
                  ...visibleCategories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(cat.label),
                        selected: _categoryFilter == cat.id,
                        onSelected: (selected) => setState(() {
                          _categoryFilter = selected ? cat.id : null;
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.store.products.isEmpty)
            const EmptyMessage(message: '商品はまだ登録されていません。')
          else if (filtered.isEmpty)
            const EmptyMessage(message: '検索結果がありません。')
          else
            ...filtered.map((product) {
              final catLabel = categoryLabel(product.category);
              final sizeText = product.size == null || product.size!.isEmpty
                  ? ''
                  : ' / ${product.size}';
              return Dismissible(
                key: ValueKey(product.id),
                direction: DismissDirection.endToStart,
                background: const DeleteBackground(),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  debugLog('Dismiss product id=${product.id}');
                  widget.store.deleteProduct(product);
                },
                child: Card(
                  child: ListTile(
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${catLabel.isNotEmpty ? '[$catLabel] ' : ''}${product.storeName}$sizeText\n'
                      'ベスト ${formatYen(product.bestPrice)} / 許容 ${formatYen(product.acceptablePrice)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showProductSheet(
                      context,
                      widget.store,
                      product: product,
                    ),
                    onLongPress: () => showPurchaseSheet(
                      context,
                      widget.store,
                      product: product,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
