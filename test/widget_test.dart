import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pricemate/core/theme.dart';
import 'package:pricemate/l10n/app_localizations.dart';
import 'package:pricemate/models/enums.dart';
import 'package:pricemate/models/product.dart';
import 'package:pricemate/models/purchase_record.dart';
import 'package:pricemate/models/shopping_item.dart';
import 'package:pricemate/store/app_store.dart';
import 'package:pricemate/widgets/app_shell.dart';

AppStore sampleStore() => AppStore()
  ..products.add(
    Product(
      id: 'milk',
      name: 'いつもの牛乳',
      storeName: 'まちのスーパー',
      bestPrice: 178,
      acceptablePrice: 218,
      saleDays: {DateTime.now().weekday},
      size: '1L',
      category: 'dairy',
      memo: 'いつものブランド',
    ),
  )
  ..shoppingItems.add(
    ShoppingItem(id: 'eggs', name: 'たまご', urgency: Urgency.now),
  )
  ..purchaseRecords.add(
    PurchaseRecord(
      id: 'record',
      productName: 'いつもの牛乳',
      storeName: 'まちのスーパー',
      price: 198,
      source: 'manual',
      purchasedAt: DateTime.now(),
    ),
  );

Future<void> mount(
  WidgetTester tester,
  AppStore store, {
  double scale = 1,
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('ja'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(themePresets.first, brightness),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: PriceMateShell(store: store, onLogout: () {}),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, int index) async {
  await tester.tap(find.byType(NavigationDestination).at(index));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
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
  });

  for (final brightness in Brightness.values) {
    testWidgets('All tabs fit with large text in $brightness', (tester) async {
      final store = sampleStore();
      addTearDown(store.dispose);
      await mount(tester, store, scale: 1.5, brightness: brightness);
      expect(tester.takeException(), isNull);
      for (var i = 1; i < 5; i++) {
        await tab(tester, i);
        expect(tester.takeException(), isNull, reason: 'Tab $i overflowed');
      }
    });
  }

  testWidgets('Compact screens keep all five tabs usable with large text', (
    tester,
  ) async {
    final store = sampleStore();
    addTearDown(store.dispose);
    await mount(tester, store, size: const Size(320, 700), scale: 1.5);
    for (var index = 0; index < 5; index++) {
      if (index != 0) await tab(tester, index);
      expect(tester.takeException(), isNull, reason: 'Compact tab $index');
    }
  });

  testWidgets('Shopping completion can be expanded and undone', (tester) async {
    final store = sampleStore();
    addTearDown(store.dispose);
    await mount(tester, store);
    await tab(tester, 1);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('全部そろいました！'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.text('購入済み (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(store.shoppingItems.single.checked, isFalse);
    expect(find.text('0 / 1'), findsOneWidget);
  });

  testWidgets('Product search and collapsed optional values survive editing', (
    tester,
  ) async {
    final store = sampleStore();
    addTearDown(store.dispose);
    await mount(tester, store);
    await tab(tester, 3);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('いつもの牛乳'), findsNothing);
    await tester.enterText(find.byType(TextField), '牛乳');
    await tester.pumpAndSettle();
    await tester.tap(find.text('いつもの牛乳'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(store.products.single.size, '1L');
    expect(store.products.single.memo, 'いつものブランド');
    expect(store.products.single.category, 'dairy');
    expect(store.products.single.saleDays, {DateTime.now().weekday});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty English tabs render and shopping items can be added', (
    tester,
  ) async {
    final store = AppStore();
    addTearDown(store.dispose);
    await mount(tester, store, locale: const Locale('en'));
    for (var i = 1; i < 5; i++) {
      await tab(tester, i);
      expect(tester.takeException(), isNull);
    }
    await tab(tester, 1);
    await tester.tap(find.text('Add an item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bread');
    await tester.tap(find.widgetWithText(FilledButton, 'Add an item').last);
    await tester.pumpAndSettle();
    expect(store.shoppingItems.single.name, 'Bread');
    expect(tester.takeException(), isNull);
  });
}
