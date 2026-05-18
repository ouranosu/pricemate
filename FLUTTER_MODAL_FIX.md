# Flutter モーダルシート 非同期クローズ エラー 解決アプローチ

## 発生していたエラー

```
'_dependents.isEmpty': is not true
```
```
Tried to build dirty widget in the wrong build scope.
AnimatedDefaultTextStyle
```
```
A TextEditingController was used after being disposed.
```

---

## 根本原因

### `showModalBottomSheet` の Future は dismiss アニメーション完了前に resolve する

`Navigator.pop(context, result)` を呼び出した瞬間に `showModalBottomSheet` の Future が resolve される。
このとき dismiss アニメーション（約 300ms）はまだ動いており、シートの widget tree は生きている。

```
Navigator.pop 呼び出し
  │
  ├─ showModalBottomSheet の Future が即 resolve  ← ここが問題の起点
  │
  └─ dismiss アニメーション開始（～300ms 継続）
       └─ この間もシートの widget tree は mounted のまま
```

### このタイミングで行ってはいけない操作

| 操作 | 発生するエラー |
|------|----------------|
| `TextEditingController.dispose()` | アニメーション中にシートが rebuild → disposed なコントローラーを参照 → `TextEditingController was used after being disposed` |
| `notifyListeners()` / ストア更新 | メイン build scope が走る → シートの `AnimatedDefaultTextStyle` が別 build scope のダーティリストに残存 → `Tried to build dirty widget in the wrong build scope` |

---

## 副次的な原因: `AnimatedDefaultTextStyle` の Ticker 問題

ボタンを disabled にする（`setSheetState(() => isProcessing = true)`）と、
`FilledButton` 内の `Material` が `AnimatedDefaultTextStyle` を 200ms アニメーション開始する。
この Ticker がアニメーション中に `markNeedsBuild()` を発火し続けることで
「wrong build scope」エラーが起きやすくなる。

---

## 解決パターン

### 1. ルートのアニメーションを捕捉する

```dart
Animation<double>? sheetAnimation;

await showModalBottomSheet(
  builder: (ctx) {
    sheetAnimation ??= ModalRoute.of(ctx)?.animation;
    return StatefulBuilder(...);
  },
);
```

`builder` の引数を `ctx` にしてルートのアニメーションを取り出す。
`ModalRoute.of(ctx)?.animation` はシートが閉じるとき 1.0 → 0.0 に変化する。

### 2. `AnimationStatus.dismissed` 後に後処理を実行する

```dart
void finalize() {
  controller.dispose();       // コントローラー破棄
  store.upsertItem(result);   // ストア更新 → notifyListeners()
}

final anim = sheetAnimation;
if (anim == null || anim.status == AnimationStatus.dismissed) {
  finalize();
} else {
  void onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      anim.removeStatusListener(onStatus);
      finalize();
    }
  }
  anim.addStatusListener(onStatus);
}
```

`dismissed` が発火する時点では:
- Flutter の `TransitionRoute._handleStatusChanged` が先に呼ばれてルートが finalize 済み
- オーバーレイエントリが除去され、シートの全要素が deactivate / dispose 済み
- `notifyListeners()` を呼び出しても wrong build scope エラーは起きない

### 3. ボタンのアニメーション時間をゼロにする

```dart
FilledButton(
  style: const ButtonStyle(animationDuration: Duration.zero),
  onPressed: isProcessing ? null : () { ... },
  child: const Text('保存'),
),
```

`animationDuration: Duration.zero` を指定すると、ボタンが enabled → disabled に変わるとき
`AnimatedDefaultTextStyle` のアニメーションが即時完了し、Ticker が残らない。

---

## `notifyStoreListeners` の改善

`addPostFrameCallback` でラップしても、コールバック内のフェーズが
`postFrameCallbacks` のままだとシートがまだアニメーション中の場合がある。
`SchedulerPhase` を確認し、フレーム間（`idle`）であれば直接呼び出す。

```dart
void notifyStoreListeners(String reason) {
  final phase = SchedulerBinding.instance.schedulerPhase;

  if (phase == SchedulerPhase.idle ||
      phase == SchedulerPhase.postFrameCallbacks) {
    if (hasListeners) notifyListeners();
    return;
  }

  if (_notifyScheduled) return;
  _notifyScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _notifyScheduled = false;
    if (hasListeners) notifyListeners();
  });
}
```

---

## ステータスリスナーが `dismissed` を受け取るタイミング

```
transientCallbacks フェーズ
  └─ AnimationController._tick()
       └─ status = dismissed
            ├─ TransitionRoute._handleStatusChanged()  (先に実行)
            │    └─ navigator.finalizeRoute()
            │         └─ ルート除去 / 要素 deactivate
            │
            └─ 我々の onStatus()  (後に実行)
                  └─ finalize()
                       ├─ controller.dispose()
                       └─ store.upsert() → notifyStoreListeners()
                            └─ phase = transientCallbacks
                                 → addPostFrameCallback で 1 フレーム後に notifyListeners()
```

`notifyListeners()` が発火する post-frame callbacks フェーズでは
シートは完全に除去済みのため、build scope の衝突は起きない。

---

## 適用対象

この問題は `TextEditingController` を持つシートや、ストア更新を伴うシートで
`Navigator.pop` を使って閉じる場合に必ず発生する。

- `showProductSheet`
- `showShoppingItemSheet`
- `showPurchaseSheet`
- `showAcceptInviteSheet`
- 今後追加するシート全般

**テンプレートとして上記パターンをコピーして使うこと。**
