// Record real app screens frame by frame for the App Store preview video.
// flutter test test/app_preview_capture_test.dart --dart-define=STORE_CAPTURE=true
//   (add --dart-define=IPAD=true for the iPad 13" version)
// then: python scripts/make_app_preview.py [ipad]
import 'dart:convert';
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
import 'package:pricemate/models/purchase_record.dart';
import 'package:pricemate/models/shopping_item.dart';
import 'package:pricemate/widgets/app_shell.dart';
import 'widget_test.dart' as fixtures;

const ipad = bool.fromEnvironment('IPAD');
const out = ipad ? 'build/app_preview_ipad' : 'build/app_preview';
const fps = 30;
// iPhone: 443x960 @2x = 886x1920, Apple's 6.5"/6.9" app preview size.
// iPad: real 13" layout, scaled into the 1200x1600 canvas by the script.
const size = ipad ? Size(1032, 1376) : Size(443, 960);
const ratio = ipad ? 1.0 : 2.0;

void main() {
  testWidgets('Record app preview frames', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tourDoneProducts': true,
      'tourDoneHistory': true,
      'review_done': true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'plugins.flutter.io/google_mobile_ads',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
    for (final (family, file) in [
      ('StoreFont', 'YuGothM.ttc'),
      ('Roboto', 'YuGothM.ttc'),
      ('Ahem', 'YuGothM.ttc'),
      ('FlutterTest', 'YuGothM.ttc'),
      ('StoreEmoji', 'seguiemj.ttf'),
      ('Segoe UI Emoji', 'seguiemj.ttf'),
    ]) {
      final bytes = File('C:/Windows/Fonts/$file').readAsBytesSync();
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
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
      ('natto', '納豆 3個パック', 78, 98, '3個', 'other'),
      ('banana', 'バナナ', 128, 168, '1房', 'vegetable'),
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
    store.shoppingItems
      ..clear()
      ..addAll([
        ShoppingItem(id: 'milk', name: 'いつもの牛乳', urgency: Urgency.now),
        ShoppingItem(id: 'eggs', name: 'たまご', urgency: Urgency.now),
        ShoppingItem(id: 'bread', name: '朝食の食パン', urgency: Urgency.now),
        ShoppingItem(id: 'tomato', name: 'ミニトマト', urgency: Urgency.later),
        ShoppingItem(id: 'soap', name: '食器用洗剤', urgency: Urgency.later),
      ]);
    for (var i = 0; i < 6; i++) {
      store.purchaseRecords.add(
        PurchaseRecord(
          id: 'r$i',
          productName: ['たまご', '朝食の食パン', 'ミニトマト', 'いつもの牛乳', '食器用洗剤', 'バナナ'][i],
          storeName: i.isEven ? 'まちのスーパー' : 'えきまえ商店',
          price: [198, 128, 198, 178, 158, 128][i],
          purchasedAt: DateTime.now().subtract(Duration(days: i * 3)),
          source: 'manual',
        ),
      );
    }

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final theme = buildAppTheme(
      themePresets.first,
      Brightness.light,
    ).copyWith(platform: TargetPlatform.iOS);
    const buttonText = TextStyle(
      fontFamily: 'StoreFont',
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme.copyWith(
            textTheme: theme.textTheme.apply(
              fontFamily: 'StoreFont',
              fontFamilyFallback: ['StoreEmoji'],
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: theme.filledButtonTheme.style?.copyWith(
                textStyle: WidgetStateProperty.all(buttonText),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: theme.outlinedButtonTheme.style?.copyWith(
                textStyle: WidgetStateProperty.all(buttonText),
              ),
            ),
          ),
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PriceMateShell(store: store, onLogout: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dir = Directory('$out/frames');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final events = <Map<String, Object>>[];
    var n = 0;

    Future<void> frame() async {
      await tester.pump(const Duration(microseconds: 1000000 ~/ fps));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: ratio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${dir.path}/${n.toString().padLeft(5, '0')}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      n++;
    }

    Future<void> hold(double seconds) async {
      for (var i = 0; i < seconds * fps; i++) {
        await frame();
      }
    }

    void scene(String title, String sub) =>
        events.add({'scene': n, 'title': title, 'sub': sub});

    Future<void> tap(Finder finder, {double after = 0.8}) async {
      final c = tester.getCenter(finder);
      events.add({'tap': n, 'x': c.dx, 'y': c.dy});
      await hold(0.25); // let the tap marker appear before the UI reacts
      await tester.tap(finder, warnIfMissed: false);
      await hold(after);
    }

    Future<void> swipe(Finder on, double dy, double seconds) async {
      final c = tester.getCenter(on);
      final g = await tester.startGesture(c);
      final steps = (seconds * fps).round();
      for (var i = 0; i < steps; i++) {
        await g.moveBy(Offset(0, dy / steps));
        await frame();
      }
      await g.up();
    }

    final nav = find.byType(NavigationDestination);

    scene('いつもの特売日を、\n忘れない。', '今日が特売の商品を、ホームでひと目でチェック。');
    await hold(2.0);
    await swipe(find.byType(Scrollable).first, -260, 1.0);
    await hold(1.2);

    scene('その値段、\nわが家の買いどき？', '底値と「ここまでなら買う」を、家族で共有。');
    await tap(nav.at(3), after: 1.0);
    await swipe(find.byType(Scrollable).last, -320, 1.2);
    await hold(1.0);
    await swipe(find.byType(Scrollable).last, 320, 0.6);
    await hold(0.6);

    scene('買うものメモを、\n家族でひとつに。', '「すぐ必要」「そのうち」で、すっきり整理。');
    await tap(nav.at(1), after: 0.8);
    for (var i = 0; i < 2; i++) {
      await tap(find.byType(Checkbox).at(i), after: 0.7);
    }
    await hold(0.8);

    scene('前はいくら？を、\n買い物の味方に。', 'いつ・どこで・いくらで買ったか、履歴に残る。');
    await tap(nav.at(2), after: 1.2);
    await swipe(find.byType(Scrollable).last, -200, 1.0);
    await hold(1.4);

    expect(tester.takeException(), isNull);
    File('$out/events.json').writeAsStringSync(
      jsonEncode({
        'fps': fps,
        'frames': n,
        'width': size.width,
        'height': size.height,
        'events': events,
      }),
    );
  }, skip: !const bool.fromEnvironment('STORE_CAPTURE'));
}
