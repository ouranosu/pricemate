import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../ad_banner.dart';
import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import '../history/purchase_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _saleKey = GlobalKey();
  final _urgentKey = GlobalKey();
  final _recentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  Future<void> _maybeStartTour() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tourDoneHome') ?? false) return;
    await prefs.setBool('tourDoneHome', true);
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([_saleKey, _urgentKey, _recentKey]);
  }

  @override
  Widget build(BuildContext context) {
    final urgentItems = widget.store.shoppingItems
        .where((item) => item.urgency == Urgency.now && !item.checked)
        .toList();
    final urgentCount = urgentItems.length;
    final todayProducts = widget.store.products
        .where((product) => product.saleDays.contains(DateTime.now().weekday))
        .toList();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.store.activeSpaceId == null) return;
        widget.store.stopListening();
        widget.store.startListening();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            l10n.home,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          Showcase(
            key: _saleKey,
            title: l10n.tourSaleTitle,
            description: l10n.tourSaleDesc,
            child: _BentoCard(
              color: colorScheme.tertiaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        color: colorScheme.onTertiaryContainer,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.todaysSale,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onTertiaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (todayProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          l10n.noSaleToday,
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer.withValues(
                              alpha: 0.55,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    ...todayProducts.take(4).map((product) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onTertiaryContainer,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatYen(product.acceptablePrice),
                              style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Showcase(
            key: _urgentKey,
            title: l10n.tourUrgentTitle,
            description: l10n.tourUrgentDesc,
            child: _BentoCard(
              color: colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.urgentNeeded,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (urgentCount > 0)
                        Text(
                          l10n.countItems(urgentCount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (urgentItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          l10n.nothingUrgent,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.55,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    ...urgentItems.take(5).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Showcase(
            key: _recentKey,
            title: l10n.tourRecentTitle,
            description: l10n.tourRecentDesc,
            child: _BentoCard(
              color: colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.recentPurchases,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.store.purchaseRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.noHistory,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ...widget.store.purchaseRecords.take(3).map((record) {
                      return Dismissible(
                        key: ValueKey(record.id),
                        direction: DismissDirection.endToStart,
                        background: const DeleteBackground(),
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          widget.store.deletePurchaseRecord(record);
                        },
                        child: InkWell(
                          onTap: () =>
                              showPurchaseSheet(context, widget.store, record: record),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    record.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formatYen(record.price),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
