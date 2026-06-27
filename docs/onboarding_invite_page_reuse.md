# _OnboardingInvitePage 再利用ガイド

## 概要

`_OnboardingInvitePage` は招待コードの発行・入力をオンボーディング内で行うページです。
現在は非表示にしていますが、クラス定義は以下のファイルに残っています。

**ファイル:** `lib/features/onboarding/onboarding_view.dart`

---

## オンボーディングに戻す手順

### 1. ページリストに追加する

`_OnboardingViewState.build()` 内の `pages` リストに追記します。

```dart
final pages = [
  _OnboardingPage(imagePath: 'assets/images/onboarding_1.png', body: l10n.ob1Body),
  _OnboardingPage(imagePath: 'assets/images/onboarding_2.png', body: l10n.ob2Body),
  _OnboardingPage(imagePath: 'assets/images/onboarding_3.png', body: l10n.ob3Body),
  _OnboardingInvitePage(store: widget.store, onNext: _nextPage), // ← ここを追加
  _OnboardingTrackingPage(onNext: _nextPage),
  _OnboardingPage(
    icon: Icons.check_circle_outline_rounded,
    body: l10n.ob5Body,
    iconColor: colorScheme.primaryContainer,
    iconOnColor: colorScheme.onPrimaryContainer,
  ),
];
```

### 2. ページ数を修正する

```dart
// 現在
static const int _totalPages = 5;

// 戻す場合
static const int _totalPages = 6;
```

### 3. 独自ナビゲーションの対象ページを修正する

このページは自前のボタン（コード発行・入力・スキップ）を持つため、
シェルの「次へ」ボタンを非表示にする必要があります。

```dart
// 現在（トラッキングページのみ）
bool get _pageHasOwnNav => _currentPage == 3;

// 招待ページを index 3 に挿入した場合
bool get _pageHasOwnNav => _currentPage == 3 || _currentPage == 4;
```

> **注意:** 招待ページを何番目に挿入するかによって index が変わります。
> 常に `_OnboardingTrackingPage` の index より 1 小さい値が招待ページの index です。

---

## 別の画面で単体利用する手順

オンボーディング以外（例: 設定画面後、ログイン直後など）でも単体で使えます。

### モーダルとして表示する例

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => Padding(
    padding: const EdgeInsets.all(24),
    child: _OnboardingInvitePage(
      store: store,
      onNext: () => Navigator.pop(ctx),
    ),
  ),
);
```

ただし `_OnboardingInvitePage` はプライベートクラス（`_` プレフィックス）のため、
**同一ファイル外からは直接参照できません。**

### 別ファイルから使う場合

1. `_OnboardingInvitePage` を `onboarding_view.dart` からファイルに切り出す
2. クラス名を `OnboardingInvitePage`（`_` なし）に変更する

```dart
// lib/features/onboarding/onboarding_invite_page.dart として新規作成
class OnboardingInvitePage extends StatelessWidget {
  const OnboardingInvitePage({
    super.key,
    required this.store,
    required this.onNext,
  });

  final AppStore store;
  final VoidCallback onNext;

  // ... 既存の build() をそのままコピー
}
```

3. 元ファイルの `_OnboardingInvitePage` を削除し、新ファイルを import して使う

---

## _OnboardingInvitePage が持つ機能

| ボタン | 処理 |
|---|---|
| 「コードを発行する」| `showInviteSheet(context, store)` を開く → 完了後 `onNext()` |
| 「コードを入力する」| `showAcceptInviteSheet(context, store)` を開く → 完了後 `onNext()` |
| 「今はスキップ」| 即座に `onNext()` を呼ぶ |

シート自体の実装は `lib/features/settings/invite_sheets.dart` にあります。
