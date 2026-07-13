import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  const HomeView({super.key, required this.store, this.onNavigateTab});

  final AppStore store;

  /// ボトムタブの切り替え（「すべて見る」から各タブへ遷移するため）。
  final ValueChanged<int>? onNavigateTab;

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

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return l10n.greetingMorning;
    if (hour >= 11 && hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  /// タブ切り替え直後の入場アニメーション（フェード＋スライド）。
  Widget _entrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 90),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final urgentItems = widget.store.shoppingItems
        .where((item) => item.urgency == Urgency.now && !item.checked)
        .toList();
    final todayProducts = widget.store.products
        .where((product) => product.saleDays.contains(now.weekday))
        .toList();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();

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
            DateFormat.MMMEd(locale).format(now),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _greeting(l10n),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          _entrance(
            0,
            Showcase(
              key: _saleKey,
              title: l10n.tourSaleTitle,
              description: l10n.tourSaleDesc,
              child: _HomeCard(
                color: colorScheme.tertiaryContainer,
                onColor: colorScheme.onTertiaryContainer,
                icon: Icons.local_offer_outlined,
                title: l10n.todaysSale,
                badge: todayProducts.isEmpty
                    ? null
                    : l10n.countItems(todayProducts.length),
                seeAllLabel: l10n.seeAll,
                onSeeAll: widget.onNavigateTab == null
                    ? null
                    : () => widget.onNavigateTab!(3),
                child: todayProducts.isEmpty
                    ? _CardEmpty(
                        icon: Icons.storefront_outlined,
                        message: l10n.noSaleToday,
                        onColor: colorScheme.onTertiaryContainer,
                      )
                    : Column(
                        children: [
                          ...todayProducts.take(4).map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      _EmojiAvatar(
                                        emoji: _categoryEmoji(product.category),
                                        onColor:
                                            colorScheme.onTertiaryContainer,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme
                                                    .onTertiaryContainer,
                                                fontSize: 13.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              product.storeName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme
                                                    .onTertiaryContainer
                                                    .withValues(alpha: 0.65),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _PricePill(
                                        text:
                                            '${l10n.acceptableLabel} ${formatYen(product.acceptablePrice)}',
                                        onColor:
                                            colorScheme.onTertiaryContainer,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          if (todayProducts.length > 4)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                l10n.moreCount(todayProducts.length - 4),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onTertiaryContainer
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _entrance(
            1,
            Showcase(
              key: _urgentKey,
              title: l10n.tourUrgentTitle,
              description: l10n.tourUrgentDesc,
              child: _HomeCard(
                color: colorScheme.primaryContainer,
                onColor: colorScheme.onPrimaryContainer,
                icon: Icons.priority_high_rounded,
                title: l10n.urgentNeeded,
                badge: urgentItems.isEmpty
                    ? null
                    : l10n.countItems(urgentItems.length),
                seeAllLabel: l10n.seeAll,
                onSeeAll: widget.onNavigateTab == null
                    ? null
                    : () => widget.onNavigateTab!(1),
                child: urgentItems.isEmpty
                    ? _CardEmpty(
                        icon: Icons.task_alt,
                        message: l10n.nothingUrgent,
                        onColor: colorScheme.onPrimaryContainer,
                      )
                    : Column(
                        children: urgentItems.take(5).map((item) {
                          final onColor = colorScheme.onPrimaryContainer;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.store.toggleShoppingItem(item);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    size: 20,
                                    color: onColor.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: onColor,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _entrance(
            2,
            Showcase(
              key: _recentKey,
              title: l10n.tourRecentTitle,
              description: l10n.tourRecentDesc,
              child: _HomeCard(
                color: colorScheme.surfaceContainerHighest,
                onColor: colorScheme.onSurface,
                icon: Icons.receipt_long_outlined,
                title: l10n.recentPurchases,
                seeAllLabel: l10n.seeAll,
                onSeeAll: widget.onNavigateTab == null
                    ? null
                    : () => widget.onNavigateTab!(2),
                child: widget.store.purchaseRecords.isEmpty
                    ? _CardEmpty(
                        icon: Icons.shopping_bag_outlined,
                        message: l10n.noHistory,
                        onColor: colorScheme.onSurfaceVariant,
                      )
                    : Column(
                        children:
                            widget.store.purchaseRecords.take(3).map((record) {
                          final initial = record.productName.isEmpty
                              ? '?'
                              : record.productName.characters.first;
                          final subtitle = [
                            if (record.storeName.trim().isNotEmpty)
                              record.storeName,
                            DateFormat.Md(locale).format(record.purchasedAt),
                          ].join(' ・ ');
                          return Dismissible(
                            key: ValueKey(record.id),
                            direction: DismissDirection.endToStart,
                            background: const DeleteBackground(),
                            onDismissed: (_) {
                              HapticFeedback.mediumImpact();
                              widget.store.deletePurchaseRecord(record);
                            },
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => showPurchaseSheet(
                                context,
                                widget.store,
                                record: record,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatYen(record.price),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

String _categoryEmoji(String? id) => switch (id) {
      'meat' => '🥩',
      'fish' => '🐟',
      'egg' => '🥚',
      'vegetable' => '🥦',
      'fruit' => '🍎',
      'dairy' => '🥛',
      'drink' => '🥤',
      'snack' => '🍪',
      'daily' => '🧴',
      _ => '🛒',
    };

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.color,
    required this.onColor,
    required this.icon,
    required this.title,
    this.badge,
    this.seeAllLabel,
    this.onSeeAll,
    required this.child,
  });

  final Color color;
  final Color onColor;
  final IconData icon;
  final String title;
  final String? badge;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, surface, 0.22)!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: onColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: onColor,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: onColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: onColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (onSeeAll != null && seeAllLabel != null)
                InkWell(
                  onTap: onSeeAll,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          seeAllLabel!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: onColor.withValues(alpha: 0.75),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: onColor.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({required this.emoji, required this.onColor});

  final String emoji;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 17)),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.text, required this.onColor});

  final String text;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: onColor,
        ),
      ),
    );
  }
}

class _CardEmpty extends StatelessWidget {
  const _CardEmpty({
    required this.icon,
    required this.message,
    required this.onColor,
  });

  final IconData icon;
  final String message;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 24, color: onColor.withValues(alpha: 0.35)),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: onColor.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
