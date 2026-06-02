import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../models/enums.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'shopping_item_sheet.dart';

class ShoppingListView extends StatelessWidget {
  const ShoppingListView({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final sorted = [...store.shoppingItems]
      ..sort((a, b) {
        if (a.checked != b.checked) return a.checked ? 1 : -1;
        return a.urgency == Urgency.now ? -1 : 1;
      });

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (store.activeSpaceId == null) return;
              store.stopListening();
              store.startListening();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ViewTitle(
                  title: '買うものリスト',
                  subtitle: 'スワイプで削除、タップで編集できます。',
                  action: IconButton.filledTonal(
                    tooltip: '買うものを追加',
                    icon: const Icon(Icons.add),
                    onPressed: () => showShoppingItemSheet(context, store),
                  ),
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  const EmptyMessage(message: '買うものはまだありません。')
                else
                  ...sorted.map((item) {
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: const DeleteBackground(),
                      onDismissed: (_) {
                        HapticFeedback.mediumImpact();
                        debugLog('Dismiss shopping item id=${item.id}');
                        store.deleteShoppingItem(item);
                      },
                      child: Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: item.checked,
                            onChanged: (_) {
                              HapticFeedback.lightImpact();
                              store.toggleShoppingItem(item);
                            },
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            item.urgency == Urgency.now ? 'すぐ必要' : 'そのうち',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              showShoppingItemSheet(context, store, item: item),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}
