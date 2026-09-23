import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ad_banner.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/shopping_item.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'shopping_item_sheet.dart';

class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key, required this.store});
  final AppStore store;
  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  bool _showCompleted = false;

  Widget _item(ShoppingItem item) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: const DeleteBackground(),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        widget.store.deleteShoppingItem(item);
      },
      child: Card(
        color: item.checked ? colors.surfaceContainerLow : null,
        child: ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: Checkbox(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              value: item.checked,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                widget.store.toggleShoppingItem(item);
              },
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: item.checked ? TextDecoration.lineThrough : null,
              color: item.checked ? colors.onSurfaceVariant : colors.onSurface,
            ),
          ),
          subtitle: Text(
            item.urgency == Urgency.now ? l10n.urgencyNow : l10n.urgencyLater,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showShoppingItemSheet(context, widget.store, item: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = widget.store.shoppingItems;
    final pending = items.where((i) => !i.checked).toList();
    final completed = items.where((i) => i.checked).toList();
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (widget.store.activeSpaceId != null) {
                widget.store.stopListening();
                widget.store.startListening();
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ViewTitle(
                  title: l10n.shoppingListTitle,
                  subtitle: l10n.shoppingReady,
                ),
                const SizedBox(height: 20),
                ShoppingProgressCard(
                  done: completed.length,
                  total: items.length,
                ),
                if (items.isEmpty)
                  EmptyMessage(message: l10n.emptyShoppingHint)
                else ...[
                  if (pending.any((i) => i.urgency == Urgency.now)) ...[
                    SectionHeading(title: l10n.urgencyNow),
                    ...pending
                        .where((i) => i.urgency == Urgency.now)
                        .map(_item),
                  ],
                  if (pending.any((i) => i.urgency == Urgency.later)) ...[
                    SectionHeading(title: l10n.urgencyLater),
                    ...pending
                        .where((i) => i.urgency == Urgency.later)
                        .map(_item),
                  ],
                  if (completed.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showCompleted = !_showCompleted),
                      icon: Icon(
                        _showCompleted ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(
                        '${l10n.completedItems} (${completed.length})',
                      ),
                    ),
                    if (_showCompleted) ...completed.map(_item),
                  ],
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showShoppingItemSheet(context, widget.store),
              icon: const Icon(Icons.add),
              label: Text(l10n.addToList),
            ),
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}
