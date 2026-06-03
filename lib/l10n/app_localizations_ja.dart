// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTagline => '家族で使う買い物の価格メモ';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get skip => 'スキップ';

  @override
  String get later => 'あとで';

  @override
  String get productName => '商品名';

  @override
  String get storeName => '店舗名';

  @override
  String get enterProductName => '商品名を入力してください';

  @override
  String get enterStoreName => '店舗名を入力してください';

  @override
  String get noSearchResults => '検索結果がありません。';

  @override
  String get obSkip => 'スキップ';

  @override
  String get obNext => '次へ';

  @override
  String get obStart => 'はじめる';

  @override
  String get ob1Body =>
      'このアプリでは、日頃買うものの商品金額を登録できます。また、買うものメモ機能もあります。\n\n安かった金額を記録することで、スーパーで「これ高い？」と悩む時間をなくせます。';

  @override
  String get ob2Body =>
      'レシートを撮るだけでAIが読み取り、買い物履歴を記録できます。\n\n最近買った物を見返して、重複購入を防げます。';

  @override
  String get ob3Body =>
      'プライスメイト最大の特徴は、パートナーと情報を共有できること。\n\n買い物メモも商品の購入金額もパートナーと共有し、すれ違いの原因を一つ取り除きましょう。';

  @override
  String get obInviteBody =>
      'パートナーはAさんが招待コードを発行し、Bさんが入力することで完了します。今すぐ誰かと共有しますか？';

  @override
  String get obInviteIssue => 'コードを発行する';

  @override
  String get obInviteEnter => 'コードを入力する';

  @override
  String get obInviteSkip => '今はスキップ';

  @override
  String get obTrackingBody =>
      '広告の最適化のため、トラッキングの許可をお願いします。\n\n許可しなくてもプライスメイトは問題なくご利用いただけます。';

  @override
  String get obTrackingAllow => '許可する';

  @override
  String get ob5Body =>
      'お疲れ様でした。それでは始めましょう。\n\nまずはレシートを読み取り、買い物履歴を登録するところから始めるのがオススメです。';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get createAccountTitle => '新規アカウント作成';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get loginWithEmail => 'メールでログイン';

  @override
  String get loginWithGoogle => 'Googleでログイン';

  @override
  String get createAccountBtn => 'アカウントを作成';

  @override
  String get backToLogin => 'ログインに戻る';

  @override
  String get forgotPassword => 'パスワードを忘れた方はこちら';

  @override
  String get enterEmailFirst => 'メールアドレスを入力してからタップしてください';

  @override
  String get passwordResetSent => 'パスワードリセットメールを送信しました';

  @override
  String sendFailed(String error) {
    return '送信に失敗しました。$error';
  }

  @override
  String appleLoginFailed(String message) {
    return 'Appleログインに失敗しました。$message';
  }

  @override
  String loginFailed(String error) {
    return 'ログインに失敗しました。$error';
  }

  @override
  String get authErrInvalidEmail => 'メールアドレスの形式を確認してください。';

  @override
  String get authErrMissingPw => 'パスワードを入力してください。';

  @override
  String get authErrWeakPw => 'パスワードは6文字以上で入力してください。';

  @override
  String get authErrEmailInUse => 'このメールアドレスは既に登録されています。';

  @override
  String get authErrInvalidCred => 'メールアドレスまたはパスワードが違います。';

  @override
  String get authErrNetwork => 'ネットワーク接続を確認してください。';

  @override
  String get authErrCanceled => 'ログインがキャンセルされました。';

  @override
  String authErrGeneric(String code) {
    return 'ログインに失敗しました。$code';
  }

  @override
  String get googleErrCanceled =>
      'Googleログインが完了しませんでした。アカウント選択後に出る場合は、FirebaseのAndroid SHA設定とgoogle-services.jsonを確認してください。';

  @override
  String get googleErrClientConfig =>
      'Googleログイン設定が未完了です。FirebaseにAndroidのSHA-1/SHA-256を登録し、google-services.jsonを更新してください。';

  @override
  String get googleErrProviderConfig => 'Googleログインのプロバイダ設定を確認してください。';

  @override
  String get googleErrUiUnavailable => 'Googleログイン画面を表示できませんでした。';

  @override
  String googleErrGeneric(String code) {
    return 'Googleログインに失敗しました。code=$code';
  }

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabShopping => '買い物';

  @override
  String get tabHistory => '履歴';

  @override
  String get tabProducts => '商品';

  @override
  String get tabSettings => '設定';

  @override
  String get fabTooltip => '入力';

  @override
  String get notifTooltip => '通知（近日公開）';

  @override
  String get notifComingSoon => '通知機能は近日公開予定です';

  @override
  String get home => 'ホーム';

  @override
  String get todaysSale => '今日の特売';

  @override
  String get noSaleToday => '今日の特売なし';

  @override
  String get urgentNeeded => 'すぐ必要';

  @override
  String countItems(int count) {
    return '$count件';
  }

  @override
  String get nothingUrgent => 'すぐ必要なものはありません';

  @override
  String get recentPurchases => '最近の購入';

  @override
  String get noHistory => '履歴なし';

  @override
  String get shoppingListTitle => '買うものリスト';

  @override
  String get shoppingListSubtitle => 'スワイプで削除、タップで編集できます。';

  @override
  String get addShoppingItemTooltip => '買うものを追加';

  @override
  String get emptyShoppingList => '買うものはまだありません。';

  @override
  String get addShoppingItemSheet => '買うものを登録';

  @override
  String get editShoppingItemSheet => '買うものを編集';

  @override
  String get urgencyNow => 'すぐ必要';

  @override
  String get urgencyLater => 'そのうち';

  @override
  String get shoppingItemAdded => '買うものを追加しました';

  @override
  String get shoppingItemUpdated => '買うものを更新しました';

  @override
  String get historyTitle => '購入履歴';

  @override
  String get historySubtitle => 'スワイプで削除、タップで編集できます。';

  @override
  String get addPurchaseTooltip => '購入履歴を追加';

  @override
  String get searchByNameStore => '商品名・店舗名で検索';

  @override
  String get emptyHistory => '購入履歴はまだありません。';

  @override
  String get addManually => '手動で登録';

  @override
  String get scanReceipt => 'レシートを読み取る';

  @override
  String get addPurchaseSheet => '購入履歴を登録';

  @override
  String get editPurchaseSheet => '購入履歴を編集';

  @override
  String get purchasePrice => '購入価格';

  @override
  String get enterPurchasePrice => '購入価格を入力してください';

  @override
  String get purchaseAdded => '購入履歴を登録しました';

  @override
  String get purchaseUpdated => '購入履歴を更新しました';

  @override
  String get productListTitle => '商品リスト';

  @override
  String get productListSubtitle => '家庭内の価格基準を一覧できます。';

  @override
  String get sortTooltip => '並び替え';

  @override
  String get addProductTooltip => '商品を追加';

  @override
  String get searchByNameStoreCat => '商品名・店舗・カテゴリーで検索';

  @override
  String get filterAll => 'すべて';

  @override
  String get sortTitle => '並び替え';

  @override
  String get sortRecentFirst => '最近追加順';

  @override
  String get sortNameAsc => '名前順（A→Z）';

  @override
  String get sortBestPriceAsc => 'ベスト価格が安い順';

  @override
  String get sortBestPriceDesc => 'ベスト価格が高い順';

  @override
  String get emptyProductList => '商品はまだ登録されていません。';

  @override
  String get bestLabel => 'ベスト';

  @override
  String get acceptableLabel => '許容';

  @override
  String get addProductSheet => '商品を登録';

  @override
  String get editProductSheet => '商品を編集';

  @override
  String get sizeOptional => 'サイズ（任意）';

  @override
  String get bestPrice => 'ベスト価格';

  @override
  String get acceptablePrice => '許容価格';

  @override
  String get memoOptional => 'メモ（任意）';

  @override
  String get categoryHeading => 'カテゴリー';

  @override
  String get saleDaysHeading => '特売日';

  @override
  String get noSaleDays => '特売日未設定';

  @override
  String get enterBestPrice => 'ベスト価格を入力してください';

  @override
  String get acceptablePriceConstraint => '許容価格はベスト価格以上にしてください';

  @override
  String get productAdded => '商品を登録しました';

  @override
  String get productUpdated => '商品を更新しました';

  @override
  String get inputTitle => '入力';

  @override
  String get inputSubtitle => '価格基準、買うもの、購入履歴をここから追加します。';

  @override
  String get segProduct => '商品';

  @override
  String get segShopping => '買うもの';

  @override
  String get segPurchase => '購入';

  @override
  String get addProductBtn => '商品を登録';

  @override
  String get addShoppingBtn => '買うものを登録';

  @override
  String get addPurchaseBtn => '購入履歴を登録';

  @override
  String get scanReceiptBtn => 'レシートを読み取る';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '共有、アプリ情報、アカウントを管理します。';

  @override
  String get themeColorSetting => 'テーマカラー';

  @override
  String get languageSetting => '言語';

  @override
  String get invitePartner => 'パートナーを招待';

  @override
  String get enterInviteCode => '招待コードを入力';

  @override
  String get manageFamilyMembers => '家族メンバー管理';

  @override
  String get leaveSpaceSetting => 'スペースを離れる';

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get specialThanks => 'スペシャルサンクス';

  @override
  String get versionLabel => 'バージョン';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteAccountSetting => 'アカウントを削除';

  @override
  String get leaveSpaceTitle => 'スペースを離れる';

  @override
  String get leaveSpaceBody => '共有スペースを離れると、自分の個人スペースに戻ります。再度参加するには招待コードが必要です。';

  @override
  String get leave => '離れる';

  @override
  String get leaveSuccess => '個人スペースに戻りました';

  @override
  String leaveFailed(String error) {
    return '離脱に失敗しました。$error';
  }

  @override
  String get deleteAccountTitle => 'アカウントを削除';

  @override
  String get deleteAccountBody => 'すべてのデータが失われます。この操作は取り消せません。';

  @override
  String get delete => '削除する';

  @override
  String get requiresRecentLogin =>
      'セキュリティのため再ログインが必要です。一度ログアウトして再度ログインしてください。';

  @override
  String deleteFailedCode(String code) {
    return '削除に失敗しました。$code';
  }

  @override
  String get specialThanksBody => 'このアプリの開発にご協力いただいた皆さまに感謝します。';

  @override
  String get returnedToPersonalSpace => '個人スペースに戻りました';

  @override
  String get inviteTitle => 'パートナーを招待';

  @override
  String get inviteDesc => '招待コードを作成して、家族に共有します。有効期限は7日間です。';

  @override
  String get inviteCodeCopied => '招待コードをコピーしました';

  @override
  String get copyCode => '招待コードをコピー';

  @override
  String get createCode => '招待コードを作成';

  @override
  String get regenerate => '作り直す';

  @override
  String get createCodeFailed => '招待コードを作成できませんでした。';

  @override
  String get enterCodeTitle => '招待コードを入力';

  @override
  String get enterCodeDesc => '共有された8文字の招待コードを入力してください。';

  @override
  String get inviteCodeLabel => '招待コード';

  @override
  String get join => '参加する';

  @override
  String get joinedSpace => '共有スペースに参加しました。';

  @override
  String get inviteErrPermission => '招待コードを確認できませんでした。コードが正しいか、招待が有効か確認してください。';

  @override
  String get inviteErrInvalidArg => '招待コードの形式を確認してください。';

  @override
  String inviteErrGeneric(String code) {
    return '招待コードを確認できませんでした。$code';
  }

  @override
  String get familyMembersTitle => '家族メンバー';

  @override
  String get notInSpace => 'スペースに参加していません。';

  @override
  String get fetchMembersFailed => 'メンバーを取得できませんでした。';

  @override
  String get noMembers => 'メンバーはいません。';

  @override
  String get roleOwner => '招待者';

  @override
  String get roleMember => 'メンバー';

  @override
  String get themeColorTitle => 'テーマカラー';

  @override
  String get themeColorDesc => 'アプリ全体の雰囲気を選べます。';

  @override
  String get languageSheetTitle => '言語';

  @override
  String get systemLanguage => 'システム設定に合わせる';

  @override
  String get catMeat => '肉';

  @override
  String get catFish => '魚';

  @override
  String get catEgg => '卵';

  @override
  String get catVegetable => '野菜';

  @override
  String get catFruit => '果物';

  @override
  String get catDairy => '乳製品';

  @override
  String get catDrink => '飲料';

  @override
  String get catSnack => 'お菓子';

  @override
  String get catDaily => '日用品';

  @override
  String get catOther => 'その他';

  @override
  String get wdMon => '月';

  @override
  String get wdTue => '火';

  @override
  String get wdWed => '水';

  @override
  String get wdThu => '木';

  @override
  String get wdFri => '金';

  @override
  String get wdSat => '土';

  @override
  String get wdSun => '日';

  @override
  String get capturePhoto => 'カメラで撮影';

  @override
  String get chooseGallery => 'ギャラリーから選択';

  @override
  String get processingReceipt => '読み取り中...';

  @override
  String get receiptReadFailed => 'レシートの読み取りに失敗しました。もう一度お試しください。';

  @override
  String get registerRegularTitle => '定番商品として登録しますか？';

  @override
  String get registerRegularDesc => '購入した商品を価格メモに追加しておくと、次回の買い物で役立ちます。';

  @override
  String get selectAndRegister => '商品を選んで登録する';

  @override
  String get confirmReceiptTitle => 'レシートを確認';

  @override
  String get confirmReceiptSubtitle => 'タップで編集・スワイプで削除できます';

  @override
  String purchaseDateLabel(String date) {
    return '購入日: $date';
  }

  @override
  String saveAsPurchases(int count) {
    return '$count件を購入履歴として保存';
  }

  @override
  String get editItemTitle => '商品を編集';

  @override
  String get priceYen => '価格（円）';

  @override
  String get selectProductsTitle => '登録する商品を選択';

  @override
  String get alreadyRegistered => '登録済み';

  @override
  String registerCount(int count) {
    return '$count件を登録する';
  }

  @override
  String get organizing => '整理しています...';

  @override
  String progressOf(int current, int total) {
    return '$total件中 $current件目';
  }

  @override
  String get reviewHere => 'ここを確認してください';

  @override
  String get saveAndNext => '保存して次へ';

  @override
  String get skipThisProduct => 'この商品はスキップ';

  @override
  String get registrationComplete => '商品の登録が完了しました';
}
