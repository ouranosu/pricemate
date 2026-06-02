import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pricemate/app.dart';

void main() {
  testWidgets('PriceMate shows onboarding, login, and main tabs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PriceMateApp(useFirebase: false));

    expect(find.text('PriceMate'), findsOneWidget);
    expect(find.text('家族で使う買い物の価格メモ'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('いつもの価格を共有'), findsOneWidget);

    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsOneWidget);

    await tester.tap(find.text('メールでログイン'));
    await tester.pumpAndSettle();

    expect(find.text('ホーム'), findsOneWidget);
    expect(find.text('買い物'), findsOneWidget);
    expect(find.text('商品'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('入力'), findsOneWidget);
    expect(find.text('商品を登録'), findsOneWidget);
  });
}
