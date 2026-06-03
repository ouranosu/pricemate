import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/debug.dart';
import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart'
    show Product, productCategories, localizedCategoryLabel, localizedWeekdayLabels;
import '../../models/receipt.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

const _kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

Future<void> showReceiptFlow(BuildContext context, AppStore store) async {
  final l10n = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.capturePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
  if (source == null || !context.mounted) return;

  final xFile = await ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1920,
  );
  if (xFile == null || !context.mounted) return;

  _showLoadingDialog(context, l10n.processingReceipt);

  ReceiptParseResult? parsed;
  try {
    final bytes = await xFile.readAsBytes();
    final mime = xFile.mimeType ?? 'image/jpeg';
    parsed = await _parseReceiptWithGemini(bytes, mime);
  } catch (e) {
    debugLog('receiptOcr error: $e');
  }
  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (parsed == null || parsed.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.receiptReadFailed)),
    );
    return;
  }

  if (!context.mounted) return;
  final confirmed = await _showReceiptConfirmSheet(context, parsed);
  if (confirmed == null || !context.mounted) return;

  store.addPurchaseRecordsFromReceipt(confirmed);

  final wantsRegister = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.registerRegularTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.registerRegularDesc),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.selectAndRegister),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.later),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (wantsRegister != true || !context.mounted) return;

  final selectedItems = await _showProductSelectionSheet(
    context,
    confirmed,
    store,
  );
  if (selectedItems == null || selectedItems.isEmpty || !context.mounted) {
    return;
  }

  await _showSequentialProductRegistration(
    context,
    selectedItems,
    confirmed.storeName,
    store,
  );
}

Future<ReceiptParseResult?> _showReceiptConfirmSheet(
  BuildContext context,
  ReceiptParseResult initial,
) {
  final storeCtrl = TextEditingController(text: initial.storeName);
  final items = initial.items
      .map(
        (e) => ReceiptItem(name: e.name, price: e.price, quantity: e.quantity),
      )
      .toList();

  return showModalBottomSheet<ReceiptParseResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
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
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return SheetTitle(
                          title: l10n.confirmReceiptTitle,
                          subtitle: l10n.confirmReceiptSubtitle,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return TextField(
                          controller: storeCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.storeName,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.purchaseDateLabel(
                            initial.purchasedAt
                                .toLocal()
                                .toIso8601String()
                                .substring(0, 10),
                          ),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Dismissible(
                          key: ValueKey(Object.hash(item.name, index)),
                          direction: DismissDirection.endToStart,
                          background: const DeleteBackground(),
                          onDismissed: (_) =>
                              setSheetState(() => items.removeAt(index)),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${formatYen(item.price)} × ${item.quantity}',
                            ),
                            trailing: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                            ),
                            onTap: () async {
                              final edited = await _showReceiptItemEditDialog(
                                context,
                                item,
                              );
                              if (edited != null) {
                                setSheetState(() => items[index] = edited);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: FilledButton(
                      style: const ButtonStyle(
                        animationDuration: Duration.zero,
                      ),
                      onPressed: items.isEmpty
                          ? null
                          : () => Navigator.pop(
                              ctx,
                              ReceiptParseResult(
                                storeName:
                                    storeCtrl.text.trim().isNotEmpty
                                    ? storeCtrl.text.trim()
                                    : initial.storeName,
                                purchasedAt: initial.purchasedAt,
                                items: List.from(items),
                              ),
                            ),
                      child: Builder(
                        builder: (context) => Text(
                          AppLocalizations.of(context)!
                              .saveAsPurchases(items.length),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  ).then((result) {
    storeCtrl.dispose();
    return result;
  });
}

Future<ReceiptItem?> _showReceiptItemEditDialog(
  BuildContext context,
  ReceiptItem item,
) async {
  final nameCtrl = TextEditingController(text: item.name);
  final priceCtrl = TextEditingController(text: item.price.toString());
  final result = await showDialog<ReceiptItem>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Builder(
        builder: (context) =>
            Text(AppLocalizations.of(context)!.editItemTitle),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.productName,
              ),
            ),
          ),
          Builder(
            builder: (context) => TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.priceYen,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            ReceiptItem(
              name: nameCtrl.text.trim().isNotEmpty
                  ? nameCtrl.text.trim()
                  : item.name,
              price: int.tryParse(priceCtrl.text) ?? item.price,
              quantity: item.quantity,
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  nameCtrl.dispose();
  priceCtrl.dispose();
  return result;
}

Future<List<ReceiptItem>?> _showProductSelectionSheet(
  BuildContext context,
  ReceiptParseResult result,
  AppStore store,
) {
  final existingNames =
      store.products.map((p) => p.name.toLowerCase()).toSet();
  final selectables = result.items.map((item) {
    final exists = existingNames.contains(item.name.toLowerCase());
    return _SelectableReceiptItem(
      item: item,
      selected: !exists,
      alreadyExists: exists,
    );
  }).toList();

  return showModalBottomSheet<List<ReceiptItem>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final count =
              selectables.where((s) => s.selected && !s.alreadyExists).length;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 1.0,
            builder: (ctx2, scrollController) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Builder(
                      builder: (context) => SheetTitle(
                        title: AppLocalizations.of(
                          context,
                        )!.selectProductsTitle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: selectables.length,
                      itemBuilder: (context, index) {
                        final s = selectables[index];
                        final disabledColor =
                            Theme.of(context).colorScheme.onSurfaceVariant;
                        return CheckboxListTile(
                          value: s.selected,
                          onChanged: s.alreadyExists
                              ? null
                              : (val) => setSheetState(
                                  () => s.selected = val ?? false,
                                ),
                          title: Text(
                            s.item.name,
                            style: TextStyle(
                              color: s.alreadyExists ? disabledColor : null,
                            ),
                          ),
                          subtitle: Text(
                            s.alreadyExists
                                ? AppLocalizations.of(
                                    context,
                                  )!.alreadyRegistered
                                : formatYen(s.item.price),
                            style: TextStyle(
                              color: s.alreadyExists ? disabledColor : null,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: FilledButton(
                      style: const ButtonStyle(
                        animationDuration: Duration.zero,
                      ),
                      onPressed: count == 0
                          ? null
                          : () => Navigator.pop(
                              ctx,
                              selectables
                                  .where((s) => s.selected && !s.alreadyExists)
                                  .map((s) => s.item)
                                  .toList(),
                            ),
                      child: Builder(
                        builder: (context) => Text(
                          AppLocalizations.of(context)!.registerCount(count),
                        ),
                      ),
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
}

Future<void> _showSequentialProductRegistration(
  BuildContext context,
  List<ReceiptItem> items,
  String storeName,
  AppStore store,
) async {
  for (int i = 0; i < items.length; i++) {
    if (!context.mounted) return;

    _showLoadingDialog(
      context,
      AppLocalizations.of(context)!.organizing,
    );

    ProductSuggestion suggestion;
    try {
      suggestion = await _suggestProductWithGemini(items[i], storeName);
    } catch (e) {
      debugLog('productSuggest error: $e');
      suggestion = ProductSuggestion(
        name: items[i].name,
        storeName: storeName,
        bestPrice: items[i].price,
        acceptablePrice: (items[i].price * 1.15).round(),
      );
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final action = await _showProductSuggestionSheet(
      context,
      store,
      suggestion,
      current: i + 1,
      total: items.length,
    );
    if (!context.mounted) return;
    if (action == null) return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.registrationComplete),
      ),
    );
  }
}

Future<bool?> _showProductSuggestionSheet(
  BuildContext context,
  AppStore store,
  ProductSuggestion suggestion, {
  required int current,
  required int total,
}) async {
  final nameCtrl = TextEditingController(text: suggestion.name);
  final storeCtrl = TextEditingController(text: suggestion.storeName);
  final sizeCtrl = TextEditingController(text: suggestion.size ?? '');
  final bestCtrl = TextEditingController(
    text: suggestion.bestPrice.toString(),
  );
  final acceptableCtrl = TextEditingController(
    text: suggestion.acceptablePrice.toString(),
  );
  final memoCtrl = TextEditingController(text: suggestion.memo ?? '');
  var saleDays = <int>{};
  String? selectedCategory;
  var isProcessing = false;
  Animation<double>? sheetAnimation;

  final result = await showModalBottomSheet<(bool, Product?)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.progressOf(current, total),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: current / total),
                  ),
                  const SizedBox(height: 16),
                  SheetTitle(title: l10n.addProductSheet),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: l10n.productName),
                  ),
                  TextField(
                    controller: storeCtrl,
                    decoration: InputDecoration(labelText: l10n.storeName),
                  ),
                  TextField(
                    controller: sizeCtrl,
                    decoration: const InputDecoration(labelText: 'サイズ（任意）'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.reviewHere,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextField(
                    controller: bestCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.bestPrice,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: acceptableCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.acceptablePrice,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  TextField(
                    controller: memoCtrl,
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
                        label: Text(localizedCategoryLabel(cat.id, l10n)),
                        selected: selectedCategory == cat.id,
                        onSelected: (sel) => setSheetState(() {
                          selectedCategory = sel ? cat.id : null;
                        }),
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
                      final wdLabels = localizedWeekdayLabels(l10n);
                      return FilterChip(
                        label: Text(wdLabels[index]),
                        selected: saleDays.contains(weekday),
                        onSelected: (sel) => setSheetState(() {
                          sel
                              ? saleDays.add(weekday)
                              : saleDays.remove(weekday);
                        }),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: const ButtonStyle(animationDuration: Duration.zero),
                    onPressed: isProcessing
                        ? null
                        : () {
                            final nameVal = nameCtrl.text.trim();
                            final storeVal = storeCtrl.text.trim();
                            final best = int.tryParse(bestCtrl.text) ?? 0;
                            final acceptable =
                                int.tryParse(acceptableCtrl.text) ?? 0;
                            String? err;
                            if (nameVal.isEmpty) {
                              err = l10n.enterProductName;
                            } else if (storeVal.isEmpty) {
                              err = l10n.enterStoreName;
                            } else if (best == 0) {
                              err = l10n.enterBestPrice;
                            } else if (acceptable < best) {
                              err = l10n.acceptablePriceConstraint;
                            }
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                              return;
                            }
                            final saved = Product(
                              id: 'new',
                              name: nameVal,
                              storeName: storeVal,
                              size: sizeCtrl.text.trim().isEmpty
                                  ? null
                                  : sizeCtrl.text.trim(),
                              bestPrice: best,
                              acceptablePrice: acceptable,
                              saleDays: saleDays,
                              memo: memoCtrl.text.trim().isEmpty
                                  ? null
                                  : memoCtrl.text.trim(),
                              category: selectedCategory,
                            );
                            setSheetState(() => isProcessing = true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                Navigator.pop(ctx, (true, saved));
                              }
                            });
                          },
                    child: Text(l10n.saveAndNext),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    style: const ButtonStyle(animationDuration: Duration.zero),
                    onPressed: isProcessing
                        ? null
                        : () {
                            setSheetState(() => isProcessing = true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                Navigator.pop(ctx, (false, null));
                              }
                            });
                          },
                    child: Text(l10n.skipThisProduct),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  void finalize() {
    nameCtrl.dispose();
    storeCtrl.dispose();
    sizeCtrl.dispose();
    bestCtrl.dispose();
    acceptableCtrl.dispose();
    memoCtrl.dispose();
    if (result != null) {
      final (save, product) = result;
      if (save && product != null) store.upsertProduct(null, product);
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalize();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalize();
      }
    }

    anim.addStatusListener(onStatus);
  }

  return result?.$1;
}

// ─── Gemini helpers ───────────────────────────────────────────────────────────

String _cleanJson(String text) => text
    .replaceAll(RegExp(r'```json\s*'), '')
    .replaceAll(RegExp(r'```\s*'), '')
    .trim();

Future<ReceiptParseResult> _parseReceiptWithGemini(
  Uint8List bytes,
  String mimeType,
) async {
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _kGeminiApiKey,
  );
  const prompt =
      'このレシート画像を解析し、以下のJSON形式のみで返してください。\n'
      '{\n'
      '  "storeName": "店舗名",\n'
      '  "purchasedAt": "YYYY-MM-DD",\n'
      '  "items": [\n'
      '    {"name": "商品名", "price": 単価(整数), "quantity": 個数(整数)}\n'
      '  ]\n'
      '}\n'
      'マークダウンのコードブロックは使わないでください。';
  final content = Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]);
  final response = await model.generateContent([content]);
  final json =
      jsonDecode(_cleanJson(response.text ?? '{}')) as Map<String, dynamic>;
  return ReceiptParseResult(
    storeName: json['storeName'] as String? ?? '',
    purchasedAt:
        DateTime.tryParse(json['purchasedAt'] as String? ?? '') ??
        DateTime.now(),
    items: ((json['items'] as List?) ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return ReceiptItem(
        name: m['name'] as String? ?? '',
        price: (m['price'] as num?)?.toInt() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList(),
  );
}

Future<ProductSuggestion> _suggestProductWithGemini(
  ReceiptItem item,
  String storeName,
) async {
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _kGeminiApiKey,
  );
  final prompt =
      '以下の商品について家族の価格管理アプリ向けの登録データをJSONのみで返してください。\n'
      '商品名: ${item.name}\n'
      '購入価格: ${item.price}円\n'
      '店舗: $storeName\n'
      '{\n'
      '  "name": "登録用商品名(シンプルに)",\n'
      '  "storeName": "$storeName",\n'
      '  "size": "サイズ・規格(不明ならnull)",\n'
      '  "bestPrice": ベスト価格(整数・今回の購入価格以下),\n'
      '  "acceptablePrice": 許容価格(整数・ベスト価格の約115%),\n'
      '  "memo": "メモ(なければnull)"\n'
      '}\n'
      'マークダウンのコードブロックは使わないでください。';
  final response = await model.generateContent([Content.text(prompt)]);
  final json =
      jsonDecode(_cleanJson(response.text ?? '{}')) as Map<String, dynamic>;
  return ProductSuggestion(
    name: json['name'] as String? ?? item.name,
    storeName: json['storeName'] as String? ?? storeName,
    size: json['size'] as String?,
    bestPrice: (json['bestPrice'] as num?)?.toInt() ?? item.price,
    acceptablePrice:
        (json['acceptablePrice'] as num?)?.toInt() ??
        (item.price * 1.15).round(),
    memo: json['memo'] as String?,
  );
}

void _showLoadingDialog(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _SelectableReceiptItem {
  _SelectableReceiptItem({
    required this.item,
    required this.selected,
    required this.alreadyExists,
  });
  final ReceiptItem item;
  bool selected;
  final bool alreadyExists;
}
