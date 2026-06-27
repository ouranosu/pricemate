import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart'
    show
        Product,
        productCategories,
        localizedCategoryLabel,
        localizedWeekdayLabels;
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

Future<void> showProductSheet(
  BuildContext context,
  AppStore store, {
  Product? product,
}) async {
  final name = TextEditingController(text: product?.name ?? '');
  final storeName = TextEditingController(text: product?.storeName ?? '');
  final size = TextEditingController(text: product?.size ?? '');
  final bestPrice = TextEditingController(
    text: product?.bestPrice.toString() ?? '',
  );
  final acceptablePrice = TextEditingController(
    text: product?.acceptablePrice.toString() ?? '',
  );
  final memo = TextEditingController(text: product?.memo ?? '');
  final saleDays = {...?product?.saleDays};
  var selectedCategory = product?.category;
  var isProcessing = false;
  Animation<double>? sheetAnimation;

  // ゲストモードかつ新規登録時は広告をプリロード（シート表示中にロード完了を狙う）
  final adHelper = (store.isGuestMode && product == null)
      ? (InterstitialAdHelper()..load())
      : null;

  debugLog('showProductSheet open product=${product?.id}');
  final result = await showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context)!;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            builder: (ctx2, scrollController) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        MediaQuery.viewInsetsOf(context).bottom + 20,
                      ),
                      children: [
                        SheetTitle(
                          title: product == null
                              ? l10n.addProductSheet
                              : l10n.editProductSheet,
                        ),
                        TextField(
                          controller: name,
                          decoration: InputDecoration(
                            labelText: l10n.productName,
                          ),
                        ),
                        TextField(
                          controller: storeName,
                          decoration: InputDecoration(
                            labelText: l10n.storeName,
                          ),
                        ),
                        TextField(
                          controller: size,
                          decoration: InputDecoration(
                            labelText: l10n.sizeOptional,
                          ),
                        ),
                        TextField(
                          controller: bestPrice,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.bestPrice,
                          ),
                        ),
                        TextField(
                          controller: acceptablePrice,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.acceptablePrice,
                          ),
                        ),
                        TextField(
                          controller: memo,
                          decoration: InputDecoration(
                            labelText: l10n.memoOptional,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.categoryHeading,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: productCategories.map((cat) {
                            return FilterChip(
                              label: Text(
                                localizedCategoryLabel(cat.id, l10n),
                              ),
                              selected: selectedCategory == cat.id,
                              onSelected: (selected) {
                                setSheetState(() {
                                  selectedCategory = selected ? cat.id : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.saleDaysHeading,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(7, (index) {
                            final weekday = index + 1;
                            final wdLabels =
                                localizedWeekdayLabels(l10n);
                            return FilterChip(
                              label: Text(wdLabels[index]),
                              selected: saleDays.contains(weekday),
                              onSelected: (selected) {
                                setSheetState(() {
                                  selected
                                      ? saleDays.add(weekday)
                                      : saleDays.remove(weekday);
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          style: const ButtonStyle(
                            animationDuration: Duration.zero,
                          ),
                          onPressed: isProcessing
                              ? null
                              : () {
                                  final nameVal = name.text.trim();
                                  final storeNameVal = storeName.text.trim();
                                  final bestPriceVal =
                                      int.tryParse(bestPrice.text) ?? 0;
                                  final acceptablePriceVal =
                                      int.tryParse(acceptablePrice.text) ?? 0;
                                  String? validationError;
                                  if (nameVal.isEmpty) {
                                    validationError = l10n.enterProductName;
                                  } else if (storeNameVal.isEmpty) {
                                    validationError = l10n.enterStoreName;
                                  } else if (bestPriceVal == 0) {
                                    validationError = l10n.enterBestPrice;
                                  } else if (acceptablePriceVal <
                                      bestPriceVal) {
                                    validationError =
                                        l10n.acceptablePriceConstraint;
                                  }
                                  if (validationError != null) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(validationError),
                                      ),
                                    );
                                    return;
                                  }
                                  debugLog(
                                    'showProductSheet safeClose '
                                    'phase=${SchedulerBinding.instance.schedulerPhase}',
                                  );
                                  final saved = Product(
                                    id: product?.id ?? 'new',
                                    name: name.text.trim(),
                                    storeName: storeName.text.trim(),
                                    size: size.text.trim().isEmpty
                                        ? null
                                        : size.text.trim(),
                                    bestPrice:
                                        int.tryParse(bestPrice.text) ?? 0,
                                    acceptablePrice:
                                        int.tryParse(acceptablePrice.text) ??
                                        0,
                                    saleDays: saleDays,
                                    memo: memo.text.trim().isEmpty
                                        ? null
                                        : memo.text.trim(),
                                    category: selectedCategory,
                                  );
                                  setSheetState(() {
                                    debugLog(
                                      'showProductSheet setSheetState isProcessing=true',
                                    );
                                    isProcessing = true;
                                  });
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    debugLog(
                                      'showProductSheet popCallback mounted=${context.mounted} '
                                      'phase=${SchedulerBinding.instance.schedulerPhase}',
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context, saved);
                                    }
                                  });
                                },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
  debugLog(
    'showProductSheet future resolved product=${product?.id} '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  Future<void> finalizeProductSheet() async {
    debugLog(
      'showProductSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    name.dispose();
    storeName.dispose();
    size.dispose();
    bestPrice.dispose();
    acceptablePrice.dispose();
    memo.dispose();
    if (result != null) {
      store.upsertProduct(product, result);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product == null ? l10n.productAdded : l10n.productUpdated,
            ),
          ),
        );
        await adHelper?.show();
      }
    }
    adHelper?.dispose();
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    unawaited(finalizeProductSheet());
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        unawaited(finalizeProductSheet());
      }
    }

    anim.addStatusListener(onStatus);
  }
}
