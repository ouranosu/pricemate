// Export actual app widgets inside a code-native marketing layout.
// flutter test test/app_store_capture_test.dart --dart-define=STORE_CAPTURE=true
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pricemate/core/theme.dart';
import 'package:pricemate/l10n/app_localizations.dart';
import 'package:pricemate/models/product.dart';
import 'package:pricemate/models/purchase_record.dart';
import 'package:pricemate/models/shopping_item.dart';
import 'package:pricemate/models/enums.dart';
import 'package:pricemate/widgets/app_shell.dart';
import 'widget_test.dart' as fixtures;

const stories = [
  (3, '01-price', 'その値段、\nわが家の買いどき？', '底値と「ここまでなら買う」を、ひと目で。', '価格メモ'),
  (1, '02-list', '買うものメモを、\n家族でひとつに。', '「すぐ買う」「そのうち」で、すっきり整理。', '買い物リスト'),
  (0, '03-sales', 'いつもの特売日を、\n忘れない。', '登録した曜日から、今日の特売をチェック。', '特売日'),
  (2, '04-history', '前はいくら？を、\n買い物の味方に。', '買った値段とお店を、履歴に残そう。', '購入履歴'),
];

void main() {
  for (final tablet in [false, true]) {
    testWidgets(
      'Export ${tablet ? "iPad" : "iPhone"} store assets',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'tourDoneProducts': true,
          'tourDoneHistory': true,
          'review_done': true,
        });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
              'plugins.flutter.io/google_mobile_ads',
              (_) async =>
                  const StandardMethodCodec().encodeSuccessEnvelope(null),
            );
        for (final family in ['StoreFont', 'Roboto', 'Ahem']) {
          await (FontLoader(family)..addFont(
                Future.value(
                  ByteData.sublistView(
                    File('C:/Windows/Fonts/YuGothM.ttc').readAsBytesSync(),
                  ),
                ),
              ))
              .load();
        }
        await (FontLoader('StoreBold')..addFont(
              Future.value(
                ByteData.sublistView(
                  File('C:/Windows/Fonts/YuGothB.ttc').readAsBytesSync(),
                ),
              ),
            ))
            .load();
        await (FontLoader('StoreEmoji')..addFont(
              Future.value(
                ByteData.sublistView(
                  File('C:/Windows/Fonts/seguiemj.ttf').readAsBytesSync(),
                ),
              ),
            ))
            .load();
        await (FontLoader('Segoe UI Emoji')..addFont(
              Future.value(
                ByteData.sublistView(
                  File('C:/Windows/Fonts/seguiemj.ttf').readAsBytesSync(),
                ),
              ),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        final store = fixtures.sampleStore();
        addTearDown(store.dispose);
        for (final p in [
          ('eggs', 'たまご', 198, 258, '10個', 'egg'),
          ('bread', '朝食の食パン', 128, 178, '6枚切り', 'other'),
          ('tomato', 'ミニトマト', 198, 298, '1パック', 'vegetable'),
          ('soap', '食器用洗剤', 158, 218, '240ml', 'daily'),
        ]) {
          store.products.add(
            Product(
              id: p.$1,
              name: p.$2,
              storeName: 'まちのスーパー',
              bestPrice: p.$3,
              acceptablePrice: p.$4,
              size: p.$5,
              category: p.$6,
              saleDays: {DateTime.now().weekday},
            ),
          );
        }
        store.shoppingItems.addAll([
          ShoppingItem(id: 'milk', name: 'いつもの牛乳', urgency: Urgency.now),
          ShoppingItem(id: 'bread', name: '朝食の食パン', urgency: Urgency.now),
          ShoppingItem(id: 'tomato', name: 'ミニトマト', urgency: Urgency.later),
          ShoppingItem(id: 'soap', name: '食器用洗剤', urgency: Urgency.later),
        ]);
        for (var i = 0; i < 5; i++) {
          store.purchaseRecords.add(
            PurchaseRecord(
              id: 'r$i',
              productName: ['たまご', '朝食の食パン', 'ミニトマト', 'いつもの牛乳', '食器用洗剤'][i],
              storeName: 'まちのスーパー',
              price: [198, 128, 198, 178, 158][i],
              purchasedAt: DateTime.now().subtract(Duration(days: i)),
              source: 'manual',
            ),
          );
        }
        final size = tablet ? const Size(1032, 1376) : const Size(414, 896);
        final ratio = tablet ? 2.0 : 3.0;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final outerKey = GlobalKey();
        final rawKey = GlobalKey();
        final story = ValueNotifier<int>(0);
        addTearDown(story.dispose);
        final theme = buildAppTheme(
          themePresets.first,
          Brightness.light,
        ).copyWith(platform: TargetPlatform.iOS);
        final app = SizedBox(
          width: size.width,
          height: size.height,
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme.copyWith(
                textTheme: theme.textTheme.apply(
                  fontFamily: 'StoreFont',
                  fontFamilyFallback: ['StoreEmoji'],
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: theme.filledButtonTheme.style?.copyWith(
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(
                        fontFamily: 'StoreFont',
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
                key: rawKey,
                child: PriceMateShell(store: store, onLogout: () {}),
              ),
            ),
          ),
        );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: outerKey,
              child: ValueListenableBuilder<int>(
                valueListenable: story,
                child: app,
                builder: (context, index, child) {
                  final s = stories[index];
                  final dark = index == 0 || index == 3;
                  final fg = dark
                      ? const Color(0xFFFFFBEE)
                      : const Color(0xFF153F34);
                  return ColoredBox(
                    color: dark
                        ? const Color(0xFF153F34)
                        : const Color(0xFFF5F0DF),
                    child: Stack(
                      children: [
                        Positioned(
                          right: tablet ? -100 : -95,
                          bottom: tablet ? -200 : -70,
                          child: Container(
                            width: tablet ? 900 : 450,
                            height: tablet ? 900 : 450,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dark
                                  ? const Color(0xFF245647)
                                  : const Color(0xFFE4E6CE),
                            ),
                          ),
                        ),
                        Positioned(
                          top: tablet ? 42 : 27,
                          left: tablet ? 70 : 26,
                          right: tablet ? 70 : 26,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PriceMate',
                                style: TextStyle(
                                  fontFamily: 'StoreBold',
                                  fontSize: tablet ? 25 : 16,
                                  color: fg,
                                ),
                              ),
                              Text(
                                '0${index + 1} / 04',
                                style: TextStyle(
                                  fontFamily: 'StoreFont',
                                  fontSize: tablet ? 18 : 11,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: tablet ? 100 : 72,
                          left: tablet ? 70 : 26,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.$3,
                                style: TextStyle(
                                  fontFamily: 'StoreBold',
                                  fontSize: tablet ? 55 : 34,
                                  height: 1.22,
                                  color: fg,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              SizedBox(height: tablet ? 18 : 14),
                              Text(
                                s.$4,
                                style: TextStyle(
                                  fontFamily: 'StoreFont',
                                  fontSize: tablet ? 23 : 13,
                                  color: fg,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: tablet ? 310 : 222,
                          left: tablet ? 125 : 29,
                          right: tablet ? 125 : 29,
                          bottom: tablet ? 50 : 35,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio:
                                  (size.width + 12) / (size.height + 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF20332D),
                                  borderRadius: BorderRadius.circular(
                                    tablet ? 30 : 25,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 22,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(tablet ? 10 : 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    tablet ? 21 : 19,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final device = tablet ? 'ipad-13' : 'iphone-6.5';
        for (var i = 0; i < stories.length; i++) {
          story.value = i;
          await fixtures.tab(tester, stories[i].$1);
          expect(tester.takeException(), isNull);
          for (final entry in [(outerKey, device), (rawKey, 'raw/$device')]) {
            await tester.runAsync(() async {
              final boundary =
                  entry.$1.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: ratio);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'deliverables/app-store/${entry.$2}/${stories[i].$2}.png',
              );
              file.parent.createSync(recursive: true);
              file.writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      },
      skip: !const bool.fromEnvironment('STORE_CAPTURE'),
    );
  }
}
