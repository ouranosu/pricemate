import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ViewTitle(
          title: l10n.inputTitle,
          subtitle: l10n.inputSubtitle,
        ),
        const SizedBox(height: 16),
        SegmentedButton<EntryMode>(
          segments: [
            ButtonSegment(
              value: EntryMode.product,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(l10n.segProduct),
            ),
            ButtonSegment(
              value: EntryMode.shoppingItem,
              icon: const Icon(Icons.checklist),
              label: Text(l10n.segShopping),
            ),
            ButtonSegment(
              value: EntryMode.purchase,
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.segPurchase),
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
            label: Text(l10n.addProductBtn),
          )
        else if (mode == EntryMode.shoppingItem)
          FilledButton.icon(
            onPressed: () => showShoppingItemSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: Text(l10n.addShoppingBtn),
          )
        else ...[
          FilledButton.icon(
            onPressed: () => showPurchaseSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: Text(l10n.addPurchaseBtn),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showReceiptFlow(context, widget.store),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(l10n.scanReceiptBtn),
          ),
        ],
      ],
    );
  }
}
