// Optional visual review: flutter test test/design_preview_test.dart
// --dart-define=DESIGN_PREVIEW=true --dart-define=PREVIEW_FONT=/path/to/font.ttf
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pricemate/core/theme.dart';
import 'package:pricemate/l10n/app_localizations.dart';
import 'package:pricemate/models/enums.dart';
import 'package:pricemate/models/product.dart';
import 'package:pricemate/models/shopping_item.dart';
import 'package:pricemate/widgets/app_shell.dart';
import 'widget_test.dart' as fixtures;

void main() {
  testWidgets(
    'Export design previews using the actual widgets',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'tourDoneProducts': true,
        'tourDoneHistory': true,
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'plugins.flutter.io/google_mobile_ads',
            (_) async =>
                const StandardMethodCodec().encodeSuccessEnvelope(null),
          );
      const fontPath = String.fromEnvironment('PREVIEW_FONT');
      if (fontPath.isNotEmpty) {
        for (final family in ['PreviewFont', 'Roboto', 'Ahem']) {
          final loader = FontLoader(family)
            ..addFont(
              Future.value(
                ByteData.sublistView(File(fontPath).readAsBytesSync()),
              ),
            );
          await loader.load();
        }
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      const emojiPath = String.fromEnvironment('PREVIEW_EMOJI_FONT');
      if (emojiPath.isNotEmpty) {
        final emoji = FontLoader('Segoe UI Emoji')
          ..addFont(
            Future.value(
              ByteData.sublistView(File(emojiPath).readAsBytesSync()),
            ),
          );
        await emoji.load();
      }
      final store = fixtures.sampleStore();
      addTearDown(store.dispose);
      store.products.add(
        Product(
          id: 'bread',
          name: '朝食の食パン',
          storeName: '駅前ベーカリー',
          bestPrice: 148,
          acceptablePrice: 198,
          saleDays: {},
          category: 'other',
          size: '6枚切り',
        ),
      );
      store.shoppingItems.addAll([
        ShoppingItem(id: 'milk', name: 'いつもの牛乳', urgency: Urgency.now),
        ShoppingItem(id: 'tomato', name: 'ミニトマト', urgency: Urgency.later),
        ShoppingItem(
          id: 'bread',
          name: '朝食の食パン',
          urgency: Urgency.now,
          checked: true,
        ),
      ]);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      final theme = buildAppTheme(themePresets.first, Brightness.light);
      await tester.pumpWidget(
        MaterialApp(
          theme: fontPath.isEmpty
              ? theme
              : theme.copyWith(
                  textTheme: theme.textTheme.apply(fontFamily: 'PreviewFont'),
                  filledButtonTheme: FilledButtonThemeData(
                    style: theme.filledButtonTheme.style?.copyWith(
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontFamily: 'PreviewFont',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: boundaryKey,
            child: PriceMateShell(store: store, onLogout: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final directory = Directory('build/design-previews')
        ..createSync(recursive: true);
      for (var index = 0; index < 5; index++) {
        if (index != 0) await fixtures.tab(tester, index);
        expect(tester.takeException(), isNull);
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${directory.path}/tab-$index.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
    skip: !const bool.fromEnvironment('DESIGN_PREVIEW'),
  );
}
