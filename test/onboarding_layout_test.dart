import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pricemate/core/theme.dart';
import 'package:pricemate/features/onboarding/onboarding_view.dart';
import 'package:pricemate/l10n/app_localizations.dart';
import 'package:pricemate/store/app_store.dart';

void main() {
  testWidgets('Onboarding fits a compact screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore();
    addTearDown(store.dispose);
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(themePresets.first, Brightness.light),
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: OnboardingView(store: store, onComplete: () => completed = true),
      ),
    );
    await tester.pumpAndSettle();
    final pageCount = Platform.isIOS ? 5 : 4;
    for (var page = 0; page < pageCount; page++) {
      expect(tester.takeException(), isNull, reason: 'Page $page overflowed');
      if (page < 3) {
        final image = tester.widget<Image>(find.byType(Image).first);
        expect(image.width, 160);
        expect(image.height, 160);
      }
      final button = find.widgetWithText(
        FilledButton,
        page == pageCount - 1 ? 'はじめる' : '次へ',
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    if (!Platform.isIOS) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnboardingView)),
      )!;
      expect(find.text(l10n.obTrackingBody), findsNothing);
    }
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Non-iOS skip goes straight to the final page', (tester) async {
    final store = AppStore();
    addTearDown(store.dispose);
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(themePresets.first, Brightness.light),
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingView(store: store, onComplete: () => completed = true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();
    expect(find.text('はじめる'), findsOneWidget);
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  }, skip: Platform.isIOS);
}
