import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In ja, this message translates to:
  /// **'家族で使う買い物の価格メモ'**
  String get appTagline;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @skip.
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get skip;

  /// No description provided for @later.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get later;

  /// No description provided for @productName.
  ///
  /// In ja, this message translates to:
  /// **'商品名'**
  String get productName;

  /// No description provided for @storeName.
  ///
  /// In ja, this message translates to:
  /// **'店舗名'**
  String get storeName;

  /// No description provided for @enterProductName.
  ///
  /// In ja, this message translates to:
  /// **'商品名を入力してください'**
  String get enterProductName;

  /// No description provided for @enterStoreName.
  ///
  /// In ja, this message translates to:
  /// **'店舗名を入力してください'**
  String get enterStoreName;

  /// No description provided for @noSearchResults.
  ///
  /// In ja, this message translates to:
  /// **'検索結果がありません。'**
  String get noSearchResults;

  /// No description provided for @obSkip.
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get obSkip;

  /// No description provided for @obNext.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get obNext;

  /// No description provided for @obStart.
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get obStart;

  /// No description provided for @ob1Body.
  ///
  /// In ja, this message translates to:
  /// **'このアプリでは、日頃買うものの商品金額を登録できます。また、買うものメモ機能もあります。\n\n安かった金額を記録することで、スーパーで「これ高い？」と悩む時間をなくせます。'**
  String get ob1Body;

  /// No description provided for @ob2Body.
  ///
  /// In ja, this message translates to:
  /// **'レシートを撮るだけでAIが読み取り、買い物履歴を記録できます。\n\n最近買った物を見返して、重複購入を防げます。'**
  String get ob2Body;

  /// No description provided for @ob3Body.
  ///
  /// In ja, this message translates to:
  /// **'プライスメイト最大の特徴は、パートナーと情報を共有できること。\n\n買い物メモも商品の購入金額もパートナーと共有し、すれ違いの原因を一つ取り除きましょう。'**
  String get ob3Body;

  /// No description provided for @obInviteBody.
  ///
  /// In ja, this message translates to:
  /// **'パートナーはAさんが招待コードを発行し、Bさんが入力することで完了します。今すぐ誰かと共有しますか？'**
  String get obInviteBody;

  /// No description provided for @obInviteIssue.
  ///
  /// In ja, this message translates to:
  /// **'コードを発行する'**
  String get obInviteIssue;

  /// No description provided for @obInviteEnter.
  ///
  /// In ja, this message translates to:
  /// **'コードを入力する'**
  String get obInviteEnter;

  /// No description provided for @obInviteSkip.
  ///
  /// In ja, this message translates to:
  /// **'今はスキップ'**
  String get obInviteSkip;

  /// No description provided for @obTrackingBody.
  ///
  /// In ja, this message translates to:
  /// **'広告の最適化のため、トラッキングの許可をお願いします。\n\n許可しなくてもプライスメイトは問題なくご利用いただけます。'**
  String get obTrackingBody;

  /// No description provided for @obTrackingAllow.
  ///
  /// In ja, this message translates to:
  /// **'許可する'**
  String get obTrackingAllow;

  /// No description provided for @ob5Body.
  ///
  /// In ja, this message translates to:
  /// **'お疲れ様でした。それでは始めましょう。\n\nまずはレシートを読み取り、買い物履歴を登録するところから始めるのがオススメです。'**
  String get ob5Body;

  /// No description provided for @loginTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get loginTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In ja, this message translates to:
  /// **'新規アカウント作成'**
  String get createAccountTitle;

  /// No description provided for @emailAddress.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get password;

  /// No description provided for @loginWithEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールでログイン'**
  String get loginWithEmail;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ja, this message translates to:
  /// **'Googleでログイン'**
  String get loginWithGoogle;

  /// No description provided for @createAccountBtn.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成'**
  String get createAccountBtn;

  /// No description provided for @backToLogin.
  ///
  /// In ja, this message translates to:
  /// **'ログインに戻る'**
  String get backToLogin;

  /// No description provided for @forgotPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れた方はこちら'**
  String get forgotPassword;

  /// No description provided for @enterEmailFirst.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してからタップしてください'**
  String get enterEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセットメールを送信しました'**
  String get passwordResetSent;

  /// No description provided for @sendFailed.
  ///
  /// In ja, this message translates to:
  /// **'送信に失敗しました。{error}'**
  String sendFailed(String error);

  /// No description provided for @appleLoginFailed.
  ///
  /// In ja, this message translates to:
  /// **'Appleログインに失敗しました。{message}'**
  String appleLoginFailed(String message);

  /// No description provided for @loginFailed.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました。{error}'**
  String loginFailed(String error);

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式を確認してください。'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrMissingPw.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください。'**
  String get authErrMissingPw;

  /// No description provided for @authErrWeakPw.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください。'**
  String get authErrWeakPw;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に登録されています。'**
  String get authErrEmailInUse;

  /// No description provided for @authErrInvalidCred.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスまたはパスワードが違います。'**
  String get authErrInvalidCred;

  /// No description provided for @authErrNetwork.
  ///
  /// In ja, this message translates to:
  /// **'ネットワーク接続を確認してください。'**
  String get authErrNetwork;

  /// No description provided for @authErrCanceled.
  ///
  /// In ja, this message translates to:
  /// **'ログインがキャンセルされました。'**
  String get authErrCanceled;

  /// No description provided for @authErrGeneric.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました。{code}'**
  String authErrGeneric(String code);

  /// No description provided for @googleErrCanceled.
  ///
  /// In ja, this message translates to:
  /// **'Googleログインが完了しませんでした。アカウント選択後に出る場合は、FirebaseのAndroid SHA設定とgoogle-services.jsonを確認してください。'**
  String get googleErrCanceled;

  /// No description provided for @googleErrClientConfig.
  ///
  /// In ja, this message translates to:
  /// **'Googleログイン設定が未完了です。FirebaseにAndroidのSHA-1/SHA-256を登録し、google-services.jsonを更新してください。'**
  String get googleErrClientConfig;

  /// No description provided for @googleErrProviderConfig.
  ///
  /// In ja, this message translates to:
  /// **'Googleログインのプロバイダ設定を確認してください。'**
  String get googleErrProviderConfig;

  /// No description provided for @googleErrUiUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'Googleログイン画面を表示できませんでした。'**
  String get googleErrUiUnavailable;

  /// No description provided for @googleErrGeneric.
  ///
  /// In ja, this message translates to:
  /// **'Googleログインに失敗しました。code={code}'**
  String googleErrGeneric(String code);

  /// No description provided for @tabHome.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get tabHome;

  /// No description provided for @tabShopping.
  ///
  /// In ja, this message translates to:
  /// **'買い物'**
  String get tabShopping;

  /// No description provided for @tabHistory.
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get tabHistory;

  /// No description provided for @tabProducts.
  ///
  /// In ja, this message translates to:
  /// **'商品'**
  String get tabProducts;

  /// No description provided for @tabSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get tabSettings;

  /// No description provided for @fabTooltip.
  ///
  /// In ja, this message translates to:
  /// **'入力'**
  String get fabTooltip;

  /// No description provided for @notifTooltip.
  ///
  /// In ja, this message translates to:
  /// **'通知（近日公開）'**
  String get notifTooltip;

  /// No description provided for @notifComingSoon.
  ///
  /// In ja, this message translates to:
  /// **'通知機能は近日公開予定です'**
  String get notifComingSoon;

  /// No description provided for @home.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get home;

  /// No description provided for @todaysSale.
  ///
  /// In ja, this message translates to:
  /// **'今日の特売'**
  String get todaysSale;

  /// No description provided for @noSaleToday.
  ///
  /// In ja, this message translates to:
  /// **'今日の特売なし'**
  String get noSaleToday;

  /// No description provided for @urgentNeeded.
  ///
  /// In ja, this message translates to:
  /// **'すぐ必要'**
  String get urgentNeeded;

  /// No description provided for @countItems.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String countItems(int count);

  /// No description provided for @nothingUrgent.
  ///
  /// In ja, this message translates to:
  /// **'すぐ必要なものはありません'**
  String get nothingUrgent;

  /// No description provided for @recentPurchases.
  ///
  /// In ja, this message translates to:
  /// **'最近の購入'**
  String get recentPurchases;

  /// No description provided for @noHistory.
  ///
  /// In ja, this message translates to:
  /// **'履歴なし'**
  String get noHistory;

  /// No description provided for @shoppingListTitle.
  ///
  /// In ja, this message translates to:
  /// **'買うものリスト'**
  String get shoppingListTitle;

  /// No description provided for @shoppingListSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'スワイプで削除、タップで編集できます。'**
  String get shoppingListSubtitle;

  /// No description provided for @addShoppingItemTooltip.
  ///
  /// In ja, this message translates to:
  /// **'買うものを追加'**
  String get addShoppingItemTooltip;

  /// No description provided for @emptyShoppingList.
  ///
  /// In ja, this message translates to:
  /// **'買うものはまだありません。'**
  String get emptyShoppingList;

  /// No description provided for @addShoppingItemSheet.
  ///
  /// In ja, this message translates to:
  /// **'買うものを登録'**
  String get addShoppingItemSheet;

  /// No description provided for @editShoppingItemSheet.
  ///
  /// In ja, this message translates to:
  /// **'買うものを編集'**
  String get editShoppingItemSheet;

  /// No description provided for @urgencyNow.
  ///
  /// In ja, this message translates to:
  /// **'すぐ必要'**
  String get urgencyNow;

  /// No description provided for @urgencyLater.
  ///
  /// In ja, this message translates to:
  /// **'そのうち'**
  String get urgencyLater;

  /// No description provided for @shoppingItemAdded.
  ///
  /// In ja, this message translates to:
  /// **'買うものを追加しました'**
  String get shoppingItemAdded;

  /// No description provided for @shoppingItemUpdated.
  ///
  /// In ja, this message translates to:
  /// **'買うものを更新しました'**
  String get shoppingItemUpdated;

  /// No description provided for @historyTitle.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In ja, this message translates to:
  /// **'スワイプで削除、タップで編集できます。'**
  String get historySubtitle;

  /// No description provided for @addPurchaseTooltip.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を追加'**
  String get addPurchaseTooltip;

  /// No description provided for @searchByNameStore.
  ///
  /// In ja, this message translates to:
  /// **'商品名・店舗名で検索'**
  String get searchByNameStore;

  /// No description provided for @emptyHistory.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴はまだありません。'**
  String get emptyHistory;

  /// No description provided for @addManually.
  ///
  /// In ja, this message translates to:
  /// **'手動で登録'**
  String get addManually;

  /// No description provided for @scanReceipt.
  ///
  /// In ja, this message translates to:
  /// **'レシートを読み取る'**
  String get scanReceipt;

  /// No description provided for @addPurchaseSheet.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を登録'**
  String get addPurchaseSheet;

  /// No description provided for @editPurchaseSheet.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を編集'**
  String get editPurchaseSheet;

  /// No description provided for @purchasePrice.
  ///
  /// In ja, this message translates to:
  /// **'購入価格'**
  String get purchasePrice;

  /// No description provided for @enterPurchasePrice.
  ///
  /// In ja, this message translates to:
  /// **'購入価格を入力してください'**
  String get enterPurchasePrice;

  /// No description provided for @purchaseAdded.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を登録しました'**
  String get purchaseAdded;

  /// No description provided for @purchaseUpdated.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を更新しました'**
  String get purchaseUpdated;

  /// No description provided for @productListTitle.
  ///
  /// In ja, this message translates to:
  /// **'商品リスト'**
  String get productListTitle;

  /// No description provided for @productListSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'家庭内の価格基準を一覧できます。'**
  String get productListSubtitle;

  /// No description provided for @sortTooltip.
  ///
  /// In ja, this message translates to:
  /// **'並び替え'**
  String get sortTooltip;

  /// No description provided for @addProductTooltip.
  ///
  /// In ja, this message translates to:
  /// **'商品を追加'**
  String get addProductTooltip;

  /// No description provided for @searchByNameStoreCat.
  ///
  /// In ja, this message translates to:
  /// **'商品名・店舗・カテゴリーで検索'**
  String get searchByNameStoreCat;

  /// No description provided for @filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get filterAll;

  /// No description provided for @sortTitle.
  ///
  /// In ja, this message translates to:
  /// **'並び替え'**
  String get sortTitle;

  /// No description provided for @sortRecentFirst.
  ///
  /// In ja, this message translates to:
  /// **'最近追加順'**
  String get sortRecentFirst;

  /// No description provided for @sortNameAsc.
  ///
  /// In ja, this message translates to:
  /// **'名前順（A→Z）'**
  String get sortNameAsc;

  /// No description provided for @sortBestPriceAsc.
  ///
  /// In ja, this message translates to:
  /// **'ベスト価格が安い順'**
  String get sortBestPriceAsc;

  /// No description provided for @sortBestPriceDesc.
  ///
  /// In ja, this message translates to:
  /// **'ベスト価格が高い順'**
  String get sortBestPriceDesc;

  /// No description provided for @emptyProductList.
  ///
  /// In ja, this message translates to:
  /// **'商品はまだ登録されていません。'**
  String get emptyProductList;

  /// No description provided for @bestLabel.
  ///
  /// In ja, this message translates to:
  /// **'ベスト'**
  String get bestLabel;

  /// No description provided for @acceptableLabel.
  ///
  /// In ja, this message translates to:
  /// **'許容'**
  String get acceptableLabel;

  /// No description provided for @addProductSheet.
  ///
  /// In ja, this message translates to:
  /// **'商品を登録'**
  String get addProductSheet;

  /// No description provided for @editProductSheet.
  ///
  /// In ja, this message translates to:
  /// **'商品を編集'**
  String get editProductSheet;

  /// No description provided for @sizeOptional.
  ///
  /// In ja, this message translates to:
  /// **'サイズ（任意）'**
  String get sizeOptional;

  /// No description provided for @bestPrice.
  ///
  /// In ja, this message translates to:
  /// **'ベスト価格'**
  String get bestPrice;

  /// No description provided for @acceptablePrice.
  ///
  /// In ja, this message translates to:
  /// **'許容価格'**
  String get acceptablePrice;

  /// No description provided for @memoOptional.
  ///
  /// In ja, this message translates to:
  /// **'メモ（任意）'**
  String get memoOptional;

  /// No description provided for @categoryHeading.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリー'**
  String get categoryHeading;

  /// No description provided for @saleDaysHeading.
  ///
  /// In ja, this message translates to:
  /// **'特売日'**
  String get saleDaysHeading;

  /// No description provided for @noSaleDays.
  ///
  /// In ja, this message translates to:
  /// **'特売日未設定'**
  String get noSaleDays;

  /// No description provided for @enterBestPrice.
  ///
  /// In ja, this message translates to:
  /// **'ベスト価格を入力してください'**
  String get enterBestPrice;

  /// No description provided for @acceptablePriceConstraint.
  ///
  /// In ja, this message translates to:
  /// **'許容価格はベスト価格以上にしてください'**
  String get acceptablePriceConstraint;

  /// No description provided for @productAdded.
  ///
  /// In ja, this message translates to:
  /// **'商品を登録しました'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In ja, this message translates to:
  /// **'商品を更新しました'**
  String get productUpdated;

  /// No description provided for @inputTitle.
  ///
  /// In ja, this message translates to:
  /// **'入力'**
  String get inputTitle;

  /// No description provided for @inputSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'価格基準、買うもの、購入履歴をここから追加します。'**
  String get inputSubtitle;

  /// No description provided for @segProduct.
  ///
  /// In ja, this message translates to:
  /// **'商品'**
  String get segProduct;

  /// No description provided for @segShopping.
  ///
  /// In ja, this message translates to:
  /// **'買うもの'**
  String get segShopping;

  /// No description provided for @segPurchase.
  ///
  /// In ja, this message translates to:
  /// **'購入'**
  String get segPurchase;

  /// No description provided for @addProductBtn.
  ///
  /// In ja, this message translates to:
  /// **'商品を登録'**
  String get addProductBtn;

  /// No description provided for @addShoppingBtn.
  ///
  /// In ja, this message translates to:
  /// **'買うものを登録'**
  String get addShoppingBtn;

  /// No description provided for @addPurchaseBtn.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴を登録'**
  String get addPurchaseBtn;

  /// No description provided for @scanReceiptBtn.
  ///
  /// In ja, this message translates to:
  /// **'レシートを読み取る'**
  String get scanReceiptBtn;

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'共有、アプリ情報、アカウントを管理します。'**
  String get settingsSubtitle;

  /// No description provided for @themeColorSetting.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー'**
  String get themeColorSetting;

  /// No description provided for @languageSetting.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get languageSetting;

  /// No description provided for @invitePartner.
  ///
  /// In ja, this message translates to:
  /// **'パートナーを招待'**
  String get invitePartner;

  /// No description provided for @enterInviteCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを入力'**
  String get enterInviteCode;

  /// No description provided for @manageFamilyMembers.
  ///
  /// In ja, this message translates to:
  /// **'家族メンバー管理'**
  String get manageFamilyMembers;

  /// No description provided for @leaveSpaceSetting.
  ///
  /// In ja, this message translates to:
  /// **'スペースを離れる'**
  String get leaveSpaceSetting;

  /// No description provided for @termsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// No description provided for @specialThanks.
  ///
  /// In ja, this message translates to:
  /// **'スペシャルサンクス'**
  String get specialThanks;

  /// No description provided for @versionLabel.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get versionLabel;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// No description provided for @deleteAccountSetting.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除'**
  String get deleteAccountSetting;

  /// No description provided for @leaveSpaceTitle.
  ///
  /// In ja, this message translates to:
  /// **'スペースを離れる'**
  String get leaveSpaceTitle;

  /// No description provided for @leaveSpaceBody.
  ///
  /// In ja, this message translates to:
  /// **'共有スペースを離れると、自分の個人スペースに戻ります。再度参加するには招待コードが必要です。'**
  String get leaveSpaceBody;

  /// No description provided for @leave.
  ///
  /// In ja, this message translates to:
  /// **'離れる'**
  String get leave;

  /// No description provided for @leaveSuccess.
  ///
  /// In ja, this message translates to:
  /// **'個人スペースに戻りました'**
  String get leaveSuccess;

  /// No description provided for @leaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'離脱に失敗しました。{error}'**
  String leaveFailed(String error);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ja, this message translates to:
  /// **'すべてのデータが失われます。この操作は取り消せません。'**
  String get deleteAccountBody;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除する'**
  String get delete;

  /// No description provided for @requiresRecentLogin.
  ///
  /// In ja, this message translates to:
  /// **'セキュリティのため再ログインが必要です。一度ログアウトして再度ログインしてください。'**
  String get requiresRecentLogin;

  /// No description provided for @deleteFailedCode.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました。{code}'**
  String deleteFailedCode(String code);

  /// No description provided for @specialThanksBody.
  ///
  /// In ja, this message translates to:
  /// **'このアプリの開発にご協力いただいた皆さまに感謝します。'**
  String get specialThanksBody;

  /// No description provided for @returnedToPersonalSpace.
  ///
  /// In ja, this message translates to:
  /// **'個人スペースに戻りました'**
  String get returnedToPersonalSpace;

  /// No description provided for @inviteTitle.
  ///
  /// In ja, this message translates to:
  /// **'パートナーを招待'**
  String get inviteTitle;

  /// No description provided for @inviteDesc.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを作成して、家族に共有します。有効期限は7日間です。'**
  String get inviteDesc;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In ja, this message translates to:
  /// **'招待コードをコピーしました'**
  String get inviteCodeCopied;

  /// No description provided for @copyCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードをコピー'**
  String get copyCode;

  /// No description provided for @createCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを作成'**
  String get createCode;

  /// No description provided for @regenerate.
  ///
  /// In ja, this message translates to:
  /// **'作り直す'**
  String get regenerate;

  /// No description provided for @createCodeFailed.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを作成できませんでした。'**
  String get createCodeFailed;

  /// No description provided for @enterCodeTitle.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを入力'**
  String get enterCodeTitle;

  /// No description provided for @enterCodeDesc.
  ///
  /// In ja, this message translates to:
  /// **'共有された8文字の招待コードを入力してください。'**
  String get enterCodeDesc;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In ja, this message translates to:
  /// **'招待コード'**
  String get inviteCodeLabel;

  /// No description provided for @join.
  ///
  /// In ja, this message translates to:
  /// **'参加する'**
  String get join;

  /// No description provided for @joinedSpace.
  ///
  /// In ja, this message translates to:
  /// **'共有スペースに参加しました。'**
  String get joinedSpace;

  /// No description provided for @inviteErrPermission.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを確認できませんでした。コードが正しいか、招待が有効か確認してください。'**
  String get inviteErrPermission;

  /// No description provided for @inviteErrInvalidArg.
  ///
  /// In ja, this message translates to:
  /// **'招待コードの形式を確認してください。'**
  String get inviteErrInvalidArg;

  /// No description provided for @inviteErrGeneric.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを確認できませんでした。{code}'**
  String inviteErrGeneric(String code);

  /// No description provided for @familyMembersTitle.
  ///
  /// In ja, this message translates to:
  /// **'家族メンバー'**
  String get familyMembersTitle;

  /// No description provided for @notInSpace.
  ///
  /// In ja, this message translates to:
  /// **'スペースに参加していません。'**
  String get notInSpace;

  /// No description provided for @fetchMembersFailed.
  ///
  /// In ja, this message translates to:
  /// **'メンバーを取得できませんでした。'**
  String get fetchMembersFailed;

  /// No description provided for @noMembers.
  ///
  /// In ja, this message translates to:
  /// **'メンバーはいません。'**
  String get noMembers;

  /// No description provided for @roleOwner.
  ///
  /// In ja, this message translates to:
  /// **'招待者'**
  String get roleOwner;

  /// No description provided for @roleMember.
  ///
  /// In ja, this message translates to:
  /// **'メンバー'**
  String get roleMember;

  /// No description provided for @themeColorTitle.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー'**
  String get themeColorTitle;

  /// No description provided for @themeColorDesc.
  ///
  /// In ja, this message translates to:
  /// **'アプリ全体の雰囲気を選べます。'**
  String get themeColorDesc;

  /// No description provided for @languageSheetTitle.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get languageSheetTitle;

  /// No description provided for @systemLanguage.
  ///
  /// In ja, this message translates to:
  /// **'システム設定に合わせる'**
  String get systemLanguage;

  /// No description provided for @catMeat.
  ///
  /// In ja, this message translates to:
  /// **'肉'**
  String get catMeat;

  /// No description provided for @catFish.
  ///
  /// In ja, this message translates to:
  /// **'魚'**
  String get catFish;

  /// No description provided for @catEgg.
  ///
  /// In ja, this message translates to:
  /// **'卵'**
  String get catEgg;

  /// No description provided for @catVegetable.
  ///
  /// In ja, this message translates to:
  /// **'野菜'**
  String get catVegetable;

  /// No description provided for @catFruit.
  ///
  /// In ja, this message translates to:
  /// **'果物'**
  String get catFruit;

  /// No description provided for @catDairy.
  ///
  /// In ja, this message translates to:
  /// **'乳製品'**
  String get catDairy;

  /// No description provided for @catDrink.
  ///
  /// In ja, this message translates to:
  /// **'飲料'**
  String get catDrink;

  /// No description provided for @catSnack.
  ///
  /// In ja, this message translates to:
  /// **'お菓子'**
  String get catSnack;

  /// No description provided for @catDaily.
  ///
  /// In ja, this message translates to:
  /// **'日用品'**
  String get catDaily;

  /// No description provided for @catOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get catOther;

  /// No description provided for @wdMon.
  ///
  /// In ja, this message translates to:
  /// **'月'**
  String get wdMon;

  /// No description provided for @wdTue.
  ///
  /// In ja, this message translates to:
  /// **'火'**
  String get wdTue;

  /// No description provided for @wdWed.
  ///
  /// In ja, this message translates to:
  /// **'水'**
  String get wdWed;

  /// No description provided for @wdThu.
  ///
  /// In ja, this message translates to:
  /// **'木'**
  String get wdThu;

  /// No description provided for @wdFri.
  ///
  /// In ja, this message translates to:
  /// **'金'**
  String get wdFri;

  /// No description provided for @wdSat.
  ///
  /// In ja, this message translates to:
  /// **'土'**
  String get wdSat;

  /// No description provided for @wdSun.
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get wdSun;

  /// No description provided for @capturePhoto.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get capturePhoto;

  /// No description provided for @chooseGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get chooseGallery;

  /// No description provided for @processingReceipt.
  ///
  /// In ja, this message translates to:
  /// **'読み取り中...'**
  String get processingReceipt;

  /// No description provided for @receiptReadFailed.
  ///
  /// In ja, this message translates to:
  /// **'レシートの読み取りに失敗しました。もう一度お試しください。'**
  String get receiptReadFailed;

  /// No description provided for @registerRegularTitle.
  ///
  /// In ja, this message translates to:
  /// **'定番商品として登録しますか？'**
  String get registerRegularTitle;

  /// No description provided for @registerRegularDesc.
  ///
  /// In ja, this message translates to:
  /// **'購入した商品を価格メモに追加しておくと、次回の買い物で役立ちます。'**
  String get registerRegularDesc;

  /// No description provided for @selectAndRegister.
  ///
  /// In ja, this message translates to:
  /// **'商品を選んで登録する'**
  String get selectAndRegister;

  /// No description provided for @confirmReceiptTitle.
  ///
  /// In ja, this message translates to:
  /// **'レシートを確認'**
  String get confirmReceiptTitle;

  /// No description provided for @confirmReceiptSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'タップで編集・スワイプで削除できます'**
  String get confirmReceiptSubtitle;

  /// No description provided for @purchaseDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'購入日: {date}'**
  String purchaseDateLabel(String date);

  /// No description provided for @saveAsPurchases.
  ///
  /// In ja, this message translates to:
  /// **'{count}件を購入履歴として保存'**
  String saveAsPurchases(int count);

  /// No description provided for @editItemTitle.
  ///
  /// In ja, this message translates to:
  /// **'商品を編集'**
  String get editItemTitle;

  /// No description provided for @priceYen.
  ///
  /// In ja, this message translates to:
  /// **'価格（円）'**
  String get priceYen;

  /// No description provided for @selectProductsTitle.
  ///
  /// In ja, this message translates to:
  /// **'登録する商品を選択'**
  String get selectProductsTitle;

  /// No description provided for @alreadyRegistered.
  ///
  /// In ja, this message translates to:
  /// **'登録済み'**
  String get alreadyRegistered;

  /// No description provided for @registerCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件を登録する'**
  String registerCount(int count);

  /// No description provided for @organizing.
  ///
  /// In ja, this message translates to:
  /// **'整理しています...'**
  String get organizing;

  /// No description provided for @progressOf.
  ///
  /// In ja, this message translates to:
  /// **'{total}件中 {current}件目'**
  String progressOf(int current, int total);

  /// No description provided for @reviewHere.
  ///
  /// In ja, this message translates to:
  /// **'ここを確認してください'**
  String get reviewHere;

  /// No description provided for @saveAndNext.
  ///
  /// In ja, this message translates to:
  /// **'保存して次へ'**
  String get saveAndNext;

  /// No description provided for @skipThisProduct.
  ///
  /// In ja, this message translates to:
  /// **'この商品はスキップ'**
  String get skipThisProduct;

  /// No description provided for @registrationComplete.
  ///
  /// In ja, this message translates to:
  /// **'商品の登録が完了しました'**
  String get registrationComplete;

  /// No description provided for @reviewTitle.
  ///
  /// In ja, this message translates to:
  /// **'アプリのご評価をお願いします'**
  String get reviewTitle;

  /// No description provided for @reviewMessage.
  ///
  /// In ja, this message translates to:
  /// **'プライスメイトはいかがですか？レビューをいただけると、開発の励みになります。'**
  String get reviewMessage;

  /// No description provided for @reviewWrite.
  ///
  /// In ja, this message translates to:
  /// **'記入する'**
  String get reviewWrite;

  /// No description provided for @reviewLater.
  ///
  /// In ja, this message translates to:
  /// **'また今度'**
  String get reviewLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
