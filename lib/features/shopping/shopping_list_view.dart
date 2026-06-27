import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
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
  final _addKey = GlobalKey();
  final _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  Future<void> _maybeStartTour() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tourDoneShopping') ?? false) return;
    await prefs.setBool('tourDoneShopping', true);
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([_addKey, _listKey]);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.store.shoppingItems]
      ..sort((a, b) {
        if (a.checked != b.checked) return a.checked ? 1 : -1;
        return a.urgency == Urgency.now ? -1 : 1;
      });

    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (widget.store.activeSpaceId == null) return;
              widget.store.stopListening();
              widget.store.startListening();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ViewTitle(
                  title: l10n.shoppingListTitle,
                  subtitle: l10n.shoppingListSubtitle,
                  action: Showcase(
                    key: _addKey,
                    title: l10n.tourShoppingAddTitle,
                    description: l10n.tourShoppingAddDesc,
                    child: IconButton.filledTonal(
                      tooltip: l10n.addShoppingItemTooltip,
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          showShoppingItemSheet(context, widget.store),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  EmptyMessage(message: l10n.emptyShoppingList)
                else
                  Showcase(
                    key: _listKey,
                    title: l10n.tourShoppingListTitle,
                    description: l10n.tourShoppingListDesc,
                    child: Column(
                      children: sorted.map((item) {
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: const DeleteBackground(),
                          onDismissed: (_) {
                            HapticFeedback.mediumImpact();
                            debugLog('Dismiss shopping item id=${item.id}');
                            widget.store.deleteShoppingItem(item);
                          },
                          child: Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: item.checked,
                                onChanged: (_) {
                                  HapticFeedback.lightImpact();
                                  widget.store.toggleShoppingItem(item);
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
                                item.urgency == Urgency.now
                                    ? l10n.urgencyNow
                                    : l10n.urgencyLater,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => showShoppingItemSheet(
                                context,
                                widget.store,
                                item: item,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}
