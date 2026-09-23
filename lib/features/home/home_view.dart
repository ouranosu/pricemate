import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../ad_banner.dart';
import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import '../products/product_sheet.dart';
import '../history/purchase_sheet.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.store, this.onNavigateTab});
  final AppStore store;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final sales = store.products
        .where((p) => p.saleDays.contains(now.weekday))
        .toList();
    final done = store.shoppingItems.where((i) => i.checked).length;
    final recent = [...store.purchaseRecords]
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    final greeting = now.hour >= 5 && now.hour < 11
        ? l10n.greetingMorning
        : now.hour >= 11 && now.hour < 18
        ? l10n.greetingAfternoon
        : l10n.greetingEvening;
    return RefreshIndicator(
      onRefresh: () async {
        if (store.activeSpaceId != null) {
          store.stopListening();
          store.startListening();
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            DateFormat.MMMEd(locale).format(now),
            style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(greeting, style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(
            l10n.marketEyebrow,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: colors.onPrimary,
                        size: 30,
                      ),
                    ),
                    const Spacer(),
                    if (sales.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDF83),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          l10n.countItems(sales.length),
                          style: const TextStyle(
                            color: Color(0xFF40330A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  sales.isEmpty ? l10n.homeStartTitle : l10n.saleDayHeadline,
                  style: text.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sales.isEmpty ? l10n.homeStartBody : l10n.saleDayNote,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onPrimary,
                    foregroundColor: colors.primary,
                  ),
                  onPressed: store.products.isEmpty
                      ? () => showProductSheet(context, store)
                      : onNavigateTab == null
                      ? null
                      : () => onNavigateTab!(3),
                  icon: Icon(
                    store.products.isEmpty
                        ? Icons.add
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    store.products.isEmpty
                        ? l10n.addFirstProduct
                        : l10n.productListTitle,
                  ),
                ),
              ],
            ),
          ),
          SectionHeading(
            title: l10n.shoppingListTitle,
            action: TextButton(
              onPressed: onNavigateTab == null ? null : () => onNavigateTab!(1),
              child: Text(l10n.seeAll),
            ),
          ),
          ShoppingProgressCard(
            done: done,
            total: store.shoppingItems.length,
            onTap: onNavigateTab == null ? null : () => onNavigateTab!(1),
          ),
          if (sales.isNotEmpty) ...[
            SectionHeading(title: l10n.todaysSale),
            ...sales
                .take(2)
                .map(
                  (product) => Card(
                    child: InkWell(
                      onTap: () =>
                          showProductSheet(context, store, product: product),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ProductAvatar(category: product.category),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: text.titleMedium),
                                  Text(
                                    product.storeName,
                                    style: text.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.priceGuide,
                                    style: text.labelMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    formatYen(product.acceptablePrice),
                                    style: text.headlineSmall?.copyWith(
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
          SectionHeading(
            title: l10n.recentPurchases,
            action: TextButton(
              onPressed: onNavigateTab == null ? null : () => onNavigateTab!(2),
              child: Text(l10n.seeAll),
            ),
          ),
          if (recent.isEmpty)
            EmptyMessage(
              message: l10n.emptyHistoryHint,
              icon: Icons.receipt_long_outlined,
              action: OutlinedButton.icon(
                onPressed: onNavigateTab == null
                    ? null
                    : () => onNavigateTab!(2),
                icon: const Icon(Icons.add),
                label: Text(l10n.recordPurchaseAction),
              ),
            )
          else
            ...recent
                .take(3)
                .map(
                  (record) => Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.receipt_long_outlined,
                        color: colors.primary,
                      ),
                      title: Text(record.productName, style: text.titleMedium),
                      subtitle: Text(
                        [
                          record.storeName,
                          DateFormat.Md(locale).format(record.purchasedAt),
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      trailing: Text(
                        formatYen(record.price),
                        style: text.titleMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                      onTap: () =>
                          showPurchaseSheet(context, store, record: record),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
