import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/debug.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/shopping_item.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

Future<void> showShoppingItemSheet(
  BuildContext context,
  AppStore store, {
  ShoppingItem? item,
}) async {
  final name = TextEditingController(text: item?.name ?? '');
  var urgency = item?.urgency ?? Urgency.now;
  var isProcessing = false;
  Animation<double>? sheetAnimation;

  debugLog('showShoppingItemSheet open item=${item?.id}');
  final savedItem = await showModalBottomSheet<ShoppingItem>(
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
                  title: item == null
                      ? l10n.addShoppingItemSheet
                      : l10n.editShoppingItemSheet,
                ),
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.productName),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Urgency>(
                  segments: [
                    ButtonSegment(
                      value: Urgency.now,
                      label: Text(l10n.urgencyNow),
                    ),
                    ButtonSegment(
                      value: Urgency.later,
                      label: Text(l10n.urgencyLater),
                    ),
                  ],
                  selected: {urgency},
                  onSelectionChanged: (value) =>
                      setSheetState(() => urgency = value.first),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: const ButtonStyle(animationDuration: Duration.zero),
                  onPressed: isProcessing
                      ? null
                      : () {
                          if (name.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.enterProductName),
                              ),
                            );
                            return;
                          }
                          debugLog(
                            'showShoppingItemSheet safeClose '
                            'phase=${SchedulerBinding.instance.schedulerPhase}',
                          );
                          final result = ShoppingItem(
                            id: item?.id ?? 'new',
                            name: name.text.trim(),
                            urgency: urgency,
                            checked: item?.checked ?? false,
                          );
                          setSheetState(() {
                            debugLog(
                              'showShoppingItemSheet setSheetState isProcessing=true',
                            );
                            isProcessing = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            debugLog(
                              'showShoppingItemSheet popCallback mounted=${context.mounted} '
                              'phase=${SchedulerBinding.instance.schedulerPhase}',
                            );
                            if (context.mounted) Navigator.pop(context, result);
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
    'showShoppingItemSheet future resolved item=${item?.id} '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  void finalizeShoppingSheet() {
    debugLog(
      'showShoppingItemSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    name.dispose();
    if (savedItem != null) {
      store.upsertShoppingItem(item, savedItem);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item == null ? l10n.shoppingItemAdded : l10n.shoppingItemUpdated,
            ),
          ),
        );
      }
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizeShoppingSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizeShoppingSheet();
      }
    }

    anim.addStatusListener(onStatus);
  }
}
