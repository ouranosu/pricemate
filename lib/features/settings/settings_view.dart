import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../ad_banner.dart';
import '../../core/debug.dart';
import '../../l10n/app_localizations.dart';
import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'invite_sheets.dart';
import 'language_sheet.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ViewTitle(
          title: l10n.settingsTitle,
          subtitle: l10n.settingsSubtitle,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: l10n.themeColorSetting,
                subtitle: store.selectedTheme.name,
                onTap: () => showThemeSheet(context, store),
              ),
              const Divider(height: 1),
              ValueListenableBuilder<Locale?>(
                valueListenable: store.localeNotifier,
                builder: (context, locale, _) => _SettingsTile(
                  icon: Icons.language_outlined,
                  title: l10n.languageSetting,
                  subtitle: localeName(locale),
                  onTap: () => showLanguageSheet(context, store),
                ),
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
                title: l10n.invitePartner,
                onTap: () => showInviteSheet(context, store),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.vpn_key_outlined,
                title: l10n.enterInviteCode,
                onTap: () => showAcceptInviteSheet(context, store),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.group_outlined,
                title: l10n.manageFamilyMembers,
                onTap: () => showMembersSheet(context, store),
              ),
              if (store.activeSpaceId != null &&
                  store.activeSpaceId != store.activeUserId) ...[
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.exit_to_app_outlined,
                  title: l10n.leaveSpaceSetting,
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
                title: l10n.termsOfService,
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
                title: l10n.privacyPolicy,
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
                title: l10n.specialThanks,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.specialThanks),
                    content: Text(l10n.specialThanksBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.versionLabel),
                trailing: const Text('1.0.0'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: Text(l10n.logout),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
          onPressed: () => _confirmDeleteAccount(context, store, onLogout),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(l10n.deleteAccountSetting),
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
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.leaveSpaceTitle),
      content: Text(l10n.leaveSpaceBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.leave),
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
    ).showSnackBar(SnackBar(content: Text(l10n.leaveSuccess)));
  } catch (e) {
    debugLog('leaveSharedSpace error: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.leaveFailed(e.toString()))));
  }
}

Future<void> _confirmDeleteAccount(
  BuildContext context,
  AppStore store,
  VoidCallback onLogout,
) async {
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Text(l10n.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    final message = e.code == 'requires-recent-login'
        ? l10n.requiresRecentLogin
        : l10n.deleteFailedCode(e.code);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    return;
  }

  await FirebaseFirestore.instance.collection('users').doc(uid).delete();

  onLogout();
}
