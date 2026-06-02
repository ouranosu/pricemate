import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/debug.dart';
import '../../models/product.dart';
import '../../models/purchase_record.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

Future<void> showPurchaseSheet(
  BuildContext context,
  AppStore store, {
  Product? product,
  PurchaseRecord? record,
}) async {
  final productName = TextEditingController(
    text: product?.name ?? record?.productName ?? '',
  );
  final storeName = TextEditingController(
    text: product?.storeName ?? record?.storeName ?? '',
  );
  final price = TextEditingController(text: record?.price.toString() ?? '');
  var isProcessing = false;
  Animation<double>? sheetAnimation;

  debugLog(
    'showPurchaseSheet open product=${product?.id} record=${record?.id}',
  );
  final result = await showModalBottomSheet<PurchaseRecord>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetTitle(title: record == null ? '購入履歴を登録' : '購入履歴を編集'),
                TextField(
                  controller: productName,
                  decoration: const InputDecoration(labelText: '商品名'),
                ),
                TextField(
                  controller: storeName,
                  decoration: const InputDecoration(labelText: '店舗名'),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '購入価格'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: const ButtonStyle(animationDuration: Duration.zero),
                  onPressed: isProcessing
                      ? null
                      : () {
                          final productNameVal = productName.text.trim();
                          final priceVal = int.tryParse(price.text) ?? 0;
                          if (productNameVal.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('商品名を入力してください')),
                            );
                            return;
                          }
                          if (priceVal == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('購入価格を入力してください')),
                            );
                            return;
                          }
                          debugLog(
                            'showPurchaseSheet safeClose '
                            'phase=${SchedulerBinding.instance.schedulerPhase}',
                          );
                          final saved = PurchaseRecord(
                            id: record?.id ?? 'new',
                            productName: productName.text.trim(),
                            storeName: storeName.text.trim(),
                            price: int.tryParse(price.text) ?? 0,
                            purchasedAt: record?.purchasedAt ?? DateTime.now(),
                            source: record?.source ?? 'manual',
                          );
                          setSheetState(() {
                            debugLog(
                              'showPurchaseSheet setSheetState isProcessing=true',
                            );
                            isProcessing = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            debugLog(
                              'showPurchaseSheet popCallback mounted=${context.mounted} '
                              'phase=${SchedulerBinding.instance.schedulerPhase}',
                            );
                            if (context.mounted) Navigator.pop(context, saved);
                          });
                        },
                  child: const Text('保存'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  debugLog(
    'showPurchaseSheet future resolved product=${product?.id} '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  void finalizePurchaseSheet() {
    debugLog(
      'showPurchaseSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    productName.dispose();
    storeName.dispose();
    price.dispose();
    if (result != null) {
      if (record != null) {
        store.updatePurchaseRecord(result);
      } else {
        store.addPurchaseRecord(result);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              record == null ? '購入履歴を登録しました' : '購入履歴を更新しました',
            ),
          ),
        );
      }
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizePurchaseSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizePurchaseSheet();
      }
    }

    anim.addStatusListener(onStatus);
  }
}
