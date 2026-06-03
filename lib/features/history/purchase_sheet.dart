import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/debug.dart';
import '../../l10n/app_localizations.dart';
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
          final l10n = AppLocalizations.of(context)!;
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
                SheetTitle(
                  title: record == null
                      ? l10n.addPurchaseSheet
                      : l10n.editPurchaseSheet,
                ),
                TextField(
                  controller: productName,
                  decoration: InputDecoration(labelText: l10n.productName),
                ),
                TextField(
                  controller: storeName,
                  decoration: InputDecoration(labelText: l10n.storeName),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.purchasePrice),
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
                              SnackBar(
                                content: Text(l10n.enterProductName),
                              ),
                            );
                            return;
                          }
                          if (priceVal == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.enterPurchasePrice),
                              ),
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
                  child: Text(l10n.save),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              record == null ? l10n.purchaseAdded : l10n.purchaseUpdated,
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
