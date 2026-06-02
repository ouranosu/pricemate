import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../core/formatters.dart';
import '../../models/purchase_record.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import '../receipt/receipt_flow.dart';
import 'purchase_sheet.dart';

class PurchaseHistoryView extends StatefulWidget {
  const PurchaseHistoryView({super.key, required this.store});

  final AppStore store;

  @override
  State<PurchaseHistoryView> createState() => _PurchaseHistoryViewState();
}

class _PurchaseHistoryViewState extends State<PurchaseHistoryView> {
  final _searchController = TextEditingController();
  String _query = '';

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

  List<PurchaseRecord> get _filtered {
    if (_query.isEmpty) return widget.store.purchaseRecords;
    return widget.store.purchaseRecords.where((r) {
      return r.productName.toLowerCase().contains(_query) ||
          r.storeName.toLowerCase().contains(_query);
    }).toList();
  }

  List<Object> _buildFlatList(List<PurchaseRecord> records) {
    final map = <String, List<PurchaseRecord>>{};
    for (final r in records) {
      final key = '${r.purchasedAt.year}年${r.purchasedAt.month}月';
      (map[key] ??= []).add(r);
    }
    final flat = <Object>[];
    for (final entry in map.entries) {
      flat.add(entry.key);
      flat.addAll(entry.value);
    }
    return flat;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final flatList = _buildFlatList(filtered);

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.store.activeSpaceId == null) return;
        widget.store.stopListening();
        widget.store.startListening();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: ViewTitle(
              title: '購入履歴',
              subtitle: 'スワイプで削除、タップで編集できます。',
              action: IconButton.filledTonal(
                tooltip: '購入履歴を追加',
                icon: const Icon(Icons.add),
                onPressed: () =>
                    _showAddPurchaseSheet(context, widget.store),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '商品名・店舗名で検索',
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
          ),
          const BannerAdWidget(),
          Expanded(
            child: widget.store.purchaseRecords.isEmpty
                ? const EmptyMessage(message: '購入履歴はまだありません。')
                : filtered.isEmpty
                ? const EmptyMessage(message: '検索結果がありません。')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: flatList.length,
                    itemBuilder: (context, index) {
                      final item = flatList[index];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final record = item as PurchaseRecord;
                      return Dismissible(
                        key: ValueKey(record.id),
                        direction: DismissDirection.endToStart,
                        background: const DeleteBackground(),
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          debugLog(
                            'Dismiss purchase record id=${record.id}',
                          );
                          widget.store.deletePurchaseRecord(record);
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(
                              record.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${record.storeName}  '
                              '${record.purchasedAt.year}/${record.purchasedAt.month.toString().padLeft(2, '0')}/'
                              '${record.purchasedAt.day.toString().padLeft(2, '0')}',
                            ),
                            trailing: Text(
                              formatYen(record.price),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            onTap: () => showPurchaseSheet(
                              context,
                              widget.store,
                              record: record,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddPurchaseSheet(
  BuildContext context,
  AppStore store,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('手動で登録'),
            onTap: () {
              Navigator.pop(ctx);
              showPurchaseSheet(context, store);
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('レシートを読み取る'),
            onTap: () {
              Navigator.pop(ctx);
              showReceiptFlow(context, store);
            },
          ),
        ],
      ),
    ),
  );
}
