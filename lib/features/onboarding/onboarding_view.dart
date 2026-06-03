import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../store/app_store.dart';
import '../settings/invite_sheets.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.onComplete,
    required this.store,
  });

  final VoidCallback onComplete;
  final AppStore store;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const int _totalPages = 6;

  bool get _pageHasOwnNav => _currentPage == 3 || _currentPage == 4;
  bool get _showSkip => _currentPage < 3;
  bool get _isFinalPage => _currentPage == _totalPages - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == _totalPages - 1) {
      widget.onComplete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      _OnboardingPage(
        icon: Icons.price_check_outlined,
        body: l10n.ob1Body,
      ),
      _OnboardingPage(
        icon: Icons.document_scanner_outlined,
        body: l10n.ob2Body,
      ),
      _OnboardingPage(
        icon: Icons.favorite_outline_rounded,
        body: l10n.ob3Body,
      ),
      _OnboardingInvitePage(store: widget.store, onNext: _nextPage),
      _OnboardingTrackingPage(onNext: _nextPage),
      _OnboardingPage(
        icon: Icons.check_circle_outline_rounded,
        body: l10n.ob5Body,
        iconColor: colorScheme.primaryContainer,
        iconOnColor: colorScheme.onPrimaryContainer,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: _showSkip
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onComplete,
                          child: Text(l10n.obSkip),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _PageDot(active: index == _currentPage),
                ),
              ),
              const SizedBox(height: 20),
              if (!_pageHasOwnNav)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _nextPage,
                    child: Text(_isFinalPage ? l10n.obStart : l10n.obNext),
                  ),
                )
              else
                const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.body,
    this.iconColor,
    this.iconOnColor,
  });

  final IconData icon;
  final String body;
  final Color? iconColor;
  final Color? iconOnColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: iconColor ?? colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 48,
              color: iconOnColor ?? colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            body,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.75,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingInvitePage extends StatelessWidget {
  const _OnboardingInvitePage({required this.store, required this.onNext});

  final AppStore store;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.group_outlined,
              size: 48,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.obInviteBody,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.75,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await showInviteSheet(context, store);
                onNext();
              },
              child: Text(l10n.obInviteIssue),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await showAcceptInviteSheet(context, store);
                onNext();
              },
              child: Text(l10n.obInviteEnter),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onNext, child: Text(l10n.obInviteSkip)),
        ],
      ),
    );
  }
}

class _OnboardingTrackingPage extends StatelessWidget {
  const _OnboardingTrackingPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.privacy_tip_outlined,
              size: 48,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.obTrackingBody,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.75,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (Platform.isIOS) {
                  await AppTrackingTransparency.requestTrackingAuthorization();
                }
                onNext();
              },
              child: Text(l10n.obTrackingAllow),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onNext, child: Text(l10n.skip)),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 22 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
