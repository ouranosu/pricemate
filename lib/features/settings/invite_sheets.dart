import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/debug.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';

Future<void> showInviteSheet(BuildContext context, AppStore store) async {
  String? inviteCode;
  String? errorMessage;
  var loading = false;
  debugLog('showInviteSheet open');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetTitle(title: 'パートナーを招待'),
                  const Text('招待コードを作成して、家族に共有します。有効期限は7日間です。'),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (inviteCode != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      inviteCode!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: inviteCode!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('招待コードをコピーしました')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('招待コードをコピー'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () async {
                            setSheetState(() {
                              loading = true;
                              errorMessage = null;
                            });
                            try {
                              debugLog('showInviteSheet create invite start');
                              final code = await store.createInviteCode();
                              debugLog(
                                'showInviteSheet create invite success code=$code',
                              );
                              setSheetState(() => inviteCode = code);
                            } catch (_) {
                              debugLog(
                                'showInviteSheet create invite failed',
                              );
                              setSheetState(
                                () => errorMessage = '招待コードを作成できませんでした。',
                              );
                            } finally {
                              setSheetState(() => loading = false);
                            }
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.vpn_key_outlined),
                    label: Text(inviteCode == null ? '招待コードを作成' : '作り直す'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  debugLog('showInviteSheet closed');
}

Future<void> showAcceptInviteSheet(
  BuildContext context,
  AppStore store,
) async {
  final codeController = TextEditingController();
  String? errorMessage;
  var loading = false;
  Animation<double>? sheetAnimation;

  debugLog('showAcceptInviteSheet open');
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetTitle(title: '招待コードを入力'),
                  const Text('共有された8文字の招待コードを入力してください。'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: '招待コード',
                      hintText: '例: ABCD2345',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: const ButtonStyle(animationDuration: Duration.zero),
                    onPressed: loading
                        ? null
                        : () async {
                            setSheetState(() {
                              loading = true;
                              errorMessage = null;
                            });
                            try {
                              debugLog(
                                'showAcceptInviteSheet accept start',
                              );
                              await store.acceptInviteCode(
                                codeController.text,
                              );
                              debugLog(
                                'showAcceptInviteSheet accept success; pop',
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                              return;
                            } catch (error) {
                              debugLog(
                                'showAcceptInviteSheet accept failed $error',
                              );
                              if (!context.mounted) return;
                              setSheetState(() {
                                errorMessage = inviteErrorMessage(error);
                              });
                            }
                            if (context.mounted) {
                              setSheetState(() => loading = false);
                            }
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('参加する'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  debugLog(
    'showAcceptInviteSheet future resolved accepted=$accepted '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  void finalizeAcceptSheet() {
    debugLog(
      'showAcceptInviteSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    codeController.dispose();
    if (accepted == true) {
      store.stopListening();
      store.startListening();
      debugLog('showAcceptInviteSheet startListening done');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('共有スペースに参加しました。')),
        );
      }
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizeAcceptSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizeAcceptSheet();
      }
    }

    anim.addStatusListener(onStatus);
  }
}

String inviteErrorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => '招待コードを確認できませんでした。コードが正しいか、招待が有効か確認してください。',
      'invalid-argument' => '招待コードの形式を確認してください。',
      _ => '招待コードを確認できませんでした。${error.code}',
    };
  }
  return '招待コードを確認できませんでした。';
}
