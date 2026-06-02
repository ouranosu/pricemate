import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/debug.dart';
import '../../core/formatters.dart';
import '../../models/product.dart';
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

  debugLog('showProductSheet open product=${product?.id}');
  final result = await showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
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
                          title: product == null ? '商品を登録' : '商品を編集',
                        ),
                        TextField(
                          controller: name,
                          decoration: const InputDecoration(labelText: '商品名'),
                        ),
                        TextField(
                          controller: storeName,
                          decoration: const InputDecoration(labelText: '店舗名'),
                        ),
                        TextField(
                          controller: size,
                          decoration:
                              const InputDecoration(labelText: 'サイズ（任意）'),
                        ),
                        TextField(
                          controller: bestPrice,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'ベスト価格'),
                        ),
                        TextField(
                          controller: acceptablePrice,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: '許容価格'),
                        ),
                        TextField(
                          controller: memo,
                          decoration:
                              const InputDecoration(labelText: 'メモ（任意）'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'カテゴリー',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: productCategories.map((cat) {
                            return FilterChip(
                              label: Text(cat.label),
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
                        const Text(
                          '特売日',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(7, (index) {
                            final weekday = index + 1;
                            return FilterChip(
                              label: Text(weekdayLabels[index]),
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
                                    validationError = '商品名を入力してください';
                                  } else if (storeNameVal.isEmpty) {
                                    validationError = '店舗名を入力してください';
                                  } else if (bestPriceVal == 0) {
                                    validationError = 'ベスト価格を入力してください';
                                  } else if (acceptablePriceVal <
                                      bestPriceVal) {
                                    validationError = '許容価格はベスト価格以上にしてください';
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
                          child: const Text('保存'),
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

  void finalizeProductSheet() {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product == null ? '商品を登録しました' : '商品を更新しました'),
          ),
        );
      }
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizeProductSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizeProductSheet();
      }
    }

    anim.addStatusListener(onStatus);
  }
}
