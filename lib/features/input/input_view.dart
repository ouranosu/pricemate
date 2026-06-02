import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import '../history/purchase_sheet.dart';
import '../products/product_sheet.dart';
import '../receipt/receipt_flow.dart';
import '../shopping/shopping_item_sheet.dart';

class InputView extends StatefulWidget {
  const InputView({super.key, required this.store});

  final AppStore store;

  @override
  State<InputView> createState() => _InputViewState();
}

class _InputViewState extends State<InputView> {
  EntryMode mode = EntryMode.product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const ViewTitle(
          title: '入力',
          subtitle: '価格基準、買うもの、購入履歴をここから追加します。',
        ),
        const SizedBox(height: 16),
        SegmentedButton<EntryMode>(
          segments: const [
            ButtonSegment(
              value: EntryMode.product,
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('商品'),
            ),
            ButtonSegment(
              value: EntryMode.shoppingItem,
              icon: Icon(Icons.checklist),
              label: Text('買うもの'),
            ),
            ButtonSegment(
              value: EntryMode.purchase,
              icon: Icon(Icons.receipt_long_outlined),
              label: Text('購入'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => setState(() => mode = value.first),
        ),
        const SizedBox(height: 20),
        if (mode == EntryMode.product)
          FilledButton.icon(
            onPressed: () => showProductSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: const Text('商品を登録'),
          )
        else if (mode == EntryMode.shoppingItem)
          FilledButton.icon(
            onPressed: () => showShoppingItemSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: const Text('買うものを登録'),
          )
        else ...[
          FilledButton.icon(
            onPressed: () => showPurchaseSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: const Text('購入履歴を登録'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showReceiptFlow(context, widget.store),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('レシートを読み取る'),
          ),
        ],
      ],
    );
  }
}
