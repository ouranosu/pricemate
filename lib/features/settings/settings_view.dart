import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'invite_sheets.dart';
import 'legal_view.dart';
import 'members_sheet.dart';
import 'theme_sheet.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.store,
    required this.onLogout,
  });

  final AppStore store;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const ViewTitle(
        title: '設定',
        subtitle: '共有、アプリ情報、アカウントを管理します。',
      ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'テーマカラー',
                subtitle: store.selectedTheme.name,
                onTap: () => showThemeSheet(context, store),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_add_alt,
                title: 'パートナーを招待',
                onTap: () => showInviteSheet(context, store),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.vpn_key_outlined,
                title: '招待コードを入力',
                onTap: () => showAcceptInviteSheet(context, store),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.group_outlined,
                title: '家族メンバー管理',
                onTap: () => showMembersSheet(context, store),
              ),
              if (store.activeSpaceId != null &&
                  store.activeSpaceId != store.activeUserId) ...[
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.exit_to_app_outlined,
                  title: 'スペースを離れる',
                  onTap: () => _confirmLeaveSpace(context, store),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const BannerAdWidget(),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '利用規約',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalView(
                      title: '利用規約',
                      lastUpdated: '2026年5月18日',
                      sections: termsOfService,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシーポリシー',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalView(
                      title: 'プライバシーポリシー',
                      lastUpdated: '2026年5月18日',
                      sections: privacyPolicy,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.favorite_border,
                title: 'スペシャルサンクス',
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('スペシャルサンクス'),
                    content: const Text('このアプリの開発にご協力いただいた皆さまに感謝します。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('バージョン'),
                trailing: Text('1.0.0'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('ログアウト'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
          onPressed: () => _confirmDeleteAccount(context, store, onLogout),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('アカウントを削除'),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

Future<void> _confirmLeaveSpace(BuildContext context, AppStore store) async {
  final userId = store.activeUserId;
  if (userId == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('スペースを離れる'),
      content: const Text('共有スペースを離れると、自分の個人スペースに戻ります。再度参加するには招待コードが必要です。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('離れる'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await store.leaveSharedSpace(userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('個人スペースに戻りました')));
  } catch (e) {
    debugLog('leaveSharedSpace error: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('離脱に失敗しました。$e')));
  }
}

Future<void> _confirmDeleteAccount(
  BuildContext context,
  AppStore store,
  VoidCallback onLogout,
) async {
  final colorScheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('アカウントを削除'),
      content: const Text('すべてのデータが失われます。この操作は取り消せません。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('削除する'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  store.clearCloudSession();

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    onLogout();
    return;
  }

  final uid = user.uid;

  final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
  if (isGoogle) {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  try {
    await user.delete();
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    final message = e.code == 'requires-recent-login'
        ? 'セキュリティのため再ログインが必要です。一度ログアウトして再度ログインしてください。'
        : '削除に失敗しました。${e.code}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    return;
  }

  await FirebaseFirestore.instance.collection('users').doc(uid).delete();

  onLogout();
}
