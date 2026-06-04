import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

class ReviewService {
  ReviewService._();

  static const _keyDone = 'review_done';
  static const _keyCount = 'shopping_add_count';
  static const _triggerAt = 3;

  // TODO: iOS App Store 公開後に実際の App Store ID を設定してください
  // 例: '1234567890'
  static const _iosAppId = '';
  static const _androidPackage = 'com.okstore.pricemate';

  /// 買い物メモを新規追加するたびに呼ぶ。3回目に達したらレビューダイアログを表示。
  static Future<void> recordAddAndCheck(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyDone) == true) return;

    final count = (prefs.getInt(_keyCount) ?? 0) + 1;
    await prefs.setInt(_keyCount, count);

    if (count == _triggerAt && context.mounted) {
      await _showDialog(context, prefs);
    }
  }

  static Future<void> _showDialog(
    BuildContext context,
    SharedPreferences prefs,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reviewTitle),
        content: Text(l10n.reviewMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              prefs.setInt(_keyCount, 0);
            },
            child: Text(l10n.reviewLater),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await prefs.setBool(_keyDone, true);
              final uri = Uri.parse(_storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(l10n.reviewWrite),
          ),
        ],
      ),
    );
  }

  static String get _storeUrl {
    if (Platform.isIOS) {
      if (_iosAppId.isNotEmpty) {
        return 'https://apps.apple.com/app/id$_iosAppId?action=write-review';
      }
      // App Store ID 未設定時は App Store トップへ
      return 'https://apps.apple.com';
    }
    return 'market://details?id=$_androidPackage';
  }
}
