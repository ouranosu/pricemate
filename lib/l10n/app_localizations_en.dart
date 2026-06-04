// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Shopping price memo for families';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get skip => 'Skip';

  @override
  String get later => 'Later';

  @override
  String get productName => 'Product Name';

  @override
  String get storeName => 'Store Name';

  @override
  String get enterProductName => 'Please enter a product name.';

  @override
  String get enterStoreName => 'Please enter a store name.';

  @override
  String get noSearchResults => 'No results found.';

  @override
  String get obSkip => 'Skip';

  @override
  String get obNext => 'Next';

  @override
  String get obStart => 'Get Started';

  @override
  String get ob1Body =>
      'With this app, you can record the prices of everyday purchases. It also has a shopping list feature.\n\nBy logging the best prices you find, you\'ll never wonder \"Is this expensive?\" at the supermarket again.';

  @override
  String get ob2Body =>
      'Just take a photo of your receipt and AI will scan it to record your purchase history.\n\nReview recent purchases to avoid buying duplicates.';

  @override
  String get ob3Body =>
      'PriceMate\'s biggest feature is the ability to share information with your partner.\n\nShare your shopping list and purchase prices to eliminate one source of miscommunication.';

  @override
  String get obInviteBody =>
      'Person A issues an invite code, and Person B enters it to connect. Would you like to share with someone right now?';

  @override
  String get obInviteIssue => 'Issue a Code';

  @override
  String get obInviteEnter => 'Enter a Code';

  @override
  String get obInviteSkip => 'Skip for now';

  @override
  String get obTrackingBody =>
      'Please allow tracking to help us optimize ads.\n\nYou can still use PriceMate without allowing tracking.';

  @override
  String get obTrackingAllow => 'Allow';

  @override
  String get ob5Body =>
      'You\'re all set. Let\'s get started!\n\nWe recommend starting by scanning a receipt to record your purchase history.';

  @override
  String get loginTitle => 'Log In';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get loginWithEmail => 'Log In with Email';

  @override
  String get loginWithGoogle => 'Log In with Google';

  @override
  String get createAccountBtn => 'Create Account';

  @override
  String get backToLogin => 'Back to Log In';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get enterEmailFirst => 'Please enter your email address first.';

  @override
  String get passwordResetSent => 'Password reset email sent.';

  @override
  String sendFailed(String error) {
    return 'Failed to send. $error';
  }

  @override
  String appleLoginFailed(String message) {
    return 'Apple login failed. $message';
  }

  @override
  String loginFailed(String error) {
    return 'Login failed. $error';
  }

  @override
  String get authErrInvalidEmail => 'Please check the email address format.';

  @override
  String get authErrMissingPw => 'Please enter your password.';

  @override
  String get authErrWeakPw => 'Password must be at least 6 characters.';

  @override
  String get authErrEmailInUse => 'This email address is already registered.';

  @override
  String get authErrInvalidCred => 'Incorrect email address or password.';

  @override
  String get authErrNetwork => 'Please check your network connection.';

  @override
  String get authErrCanceled => 'Login was canceled.';

  @override
  String authErrGeneric(String code) {
    return 'Login failed. $code';
  }

  @override
  String get googleErrCanceled =>
      'Google login did not complete. If this appears after selecting an account, please check the Android SHA settings in Firebase and your google-services.json.';

  @override
  String get googleErrClientConfig =>
      'Google login is not fully configured. Please register the Android SHA-1/SHA-256 in Firebase and update google-services.json.';

  @override
  String get googleErrProviderConfig =>
      'Please check the Google login provider settings.';

  @override
  String get googleErrUiUnavailable =>
      'Could not display the Google login screen.';

  @override
  String googleErrGeneric(String code) {
    return 'Google login failed. code=$code';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabShopping => 'Shopping';

  @override
  String get tabHistory => 'History';

  @override
  String get tabProducts => 'Products';

  @override
  String get tabSettings => 'Settings';

  @override
  String get fabTooltip => 'Add';

  @override
  String get notifTooltip => 'Notifications (coming soon)';

  @override
  String get notifComingSoon => 'Notifications coming soon';

  @override
  String get home => 'Home';

  @override
  String get todaysSale => 'Today\'s Sales';

  @override
  String get noSaleToday => 'No sales today';

  @override
  String get urgentNeeded => 'Needed Now';

  @override
  String countItems(int count) {
    return '$count items';
  }

  @override
  String get nothingUrgent => 'Nothing needed urgently';

  @override
  String get recentPurchases => 'Recent Purchases';

  @override
  String get noHistory => 'No history';

  @override
  String get shoppingListTitle => 'Shopping List';

  @override
  String get shoppingListSubtitle => 'Swipe to delete, tap to edit.';

  @override
  String get addShoppingItemTooltip => 'Add item';

  @override
  String get emptyShoppingList => 'Nothing to buy yet.';

  @override
  String get addShoppingItemSheet => 'Add Shopping Item';

  @override
  String get editShoppingItemSheet => 'Edit Shopping Item';

  @override
  String get urgencyNow => 'Needed Now';

  @override
  String get urgencyLater => 'Eventually';

  @override
  String get shoppingItemAdded => 'Shopping item added.';

  @override
  String get shoppingItemUpdated => 'Shopping item updated.';

  @override
  String get historyTitle => 'Purchase History';

  @override
  String get historySubtitle => 'Swipe to delete, tap to edit.';

  @override
  String get addPurchaseTooltip => 'Add purchase';

  @override
  String get searchByNameStore => 'Search by product or store';

  @override
  String get emptyHistory => 'No purchase history yet.';

  @override
  String get addManually => 'Add manually';

  @override
  String get scanReceipt => 'Scan Receipt';

  @override
  String get addPurchaseSheet => 'Add Purchase';

  @override
  String get editPurchaseSheet => 'Edit Purchase';

  @override
  String get purchasePrice => 'Purchase Price';

  @override
  String get enterPurchasePrice => 'Please enter a purchase price.';

  @override
  String get purchaseAdded => 'Purchase added.';

  @override
  String get purchaseUpdated => 'Purchase updated.';

  @override
  String get productListTitle => 'Product List';

  @override
  String get productListSubtitle =>
      'Your household price reference at a glance.';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get addProductTooltip => 'Add product';

  @override
  String get searchByNameStoreCat => 'Search by product, store, or category';

  @override
  String get filterAll => 'All';

  @override
  String get sortTitle => 'Sort';

  @override
  String get sortRecentFirst => 'Recently Added';

  @override
  String get sortNameAsc => 'Name (A→Z)';

  @override
  String get sortBestPriceAsc => 'Best Price (Low to High)';

  @override
  String get sortBestPriceDesc => 'Best Price (High to Low)';

  @override
  String get emptyProductList => 'No products registered yet.';

  @override
  String get bestLabel => 'Best';

  @override
  String get acceptableLabel => 'Max';

  @override
  String get addProductSheet => 'Add Product';

  @override
  String get editProductSheet => 'Edit Product';

  @override
  String get sizeOptional => 'Size (optional)';

  @override
  String get bestPrice => 'Best Price';

  @override
  String get acceptablePrice => 'Acceptable Price';

  @override
  String get memoOptional => 'Note (optional)';

  @override
  String get categoryHeading => 'Category';

  @override
  String get saleDaysHeading => 'Sale Days';

  @override
  String get noSaleDays => 'No sale days set';

  @override
  String get enterBestPrice => 'Please enter a best price.';

  @override
  String get acceptablePriceConstraint =>
      'Acceptable price must be ≥ best price.';

  @override
  String get productAdded => 'Product added.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get inputTitle => 'Add';

  @override
  String get inputSubtitle =>
      'Add products, shopping items, and purchase history here.';

  @override
  String get segProduct => 'Product';

  @override
  String get segShopping => 'Shopping';

  @override
  String get segPurchase => 'Purchase';

  @override
  String get addProductBtn => 'Add Product';

  @override
  String get addShoppingBtn => 'Add Shopping Item';

  @override
  String get addPurchaseBtn => 'Add Purchase';

  @override
  String get scanReceiptBtn => 'Scan Receipt';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage sharing, app info, and your account.';

  @override
  String get themeColorSetting => 'Theme Color';

  @override
  String get languageSetting => 'Language';

  @override
  String get invitePartner => 'Invite Partner';

  @override
  String get enterInviteCode => 'Enter Invite Code';

  @override
  String get manageFamilyMembers => 'Manage Family Members';

  @override
  String get leaveSpaceSetting => 'Leave Space';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get specialThanks => 'Special Thanks';

  @override
  String get versionLabel => 'Version';

  @override
  String get logout => 'Log Out';

  @override
  String get deleteAccountSetting => 'Delete Account';

  @override
  String get leaveSpaceTitle => 'Leave Space';

  @override
  String get leaveSpaceBody =>
      'If you leave the shared space, you will return to your personal space. You will need an invite code to rejoin.';

  @override
  String get leave => 'Leave';

  @override
  String get leaveSuccess => 'Returned to personal space.';

  @override
  String leaveFailed(String error) {
    return 'Failed to leave. $error';
  }

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountBody =>
      'All your data will be lost. This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get requiresRecentLogin =>
      'Re-login is required for security. Please log out and log in again.';

  @override
  String deleteFailedCode(String code) {
    return 'Deletion failed. $code';
  }

  @override
  String get specialThanksBody =>
      'Thank you to everyone who helped develop this app.';

  @override
  String get returnedToPersonalSpace => 'Returned to personal space.';

  @override
  String get inviteTitle => 'Invite Partner';

  @override
  String get inviteDesc =>
      'Create an invite code to share with your family. Valid for 7 days.';

  @override
  String get inviteCodeCopied => 'Invite code copied.';

  @override
  String get copyCode => 'Copy Invite Code';

  @override
  String get createCode => 'Create Invite Code';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get createCodeFailed => 'Failed to create invite code.';

  @override
  String get enterCodeTitle => 'Enter Invite Code';

  @override
  String get enterCodeDesc =>
      'Enter the 8-character invite code that was shared with you.';

  @override
  String get inviteCodeLabel => 'Invite Code';

  @override
  String get join => 'Join';

  @override
  String get joinedSpace => 'Joined the shared space.';

  @override
  String get inviteErrPermission =>
      'Could not verify the invite code. Please check that the code is correct and the invite is still valid.';

  @override
  String get inviteErrInvalidArg => 'Please check the invite code format.';

  @override
  String inviteErrGeneric(String code) {
    return 'Could not verify the invite code. $code';
  }

  @override
  String get familyMembersTitle => 'Family Members';

  @override
  String get notInSpace => 'Not in a shared space.';

  @override
  String get fetchMembersFailed => 'Failed to fetch members.';

  @override
  String get noMembers => 'No members.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleMember => 'Member';

  @override
  String get themeColorTitle => 'Theme Color';

  @override
  String get themeColorDesc => 'Choose the look and feel of the app.';

  @override
  String get languageSheetTitle => 'Language';

  @override
  String get systemLanguage => 'Follow system language';

  @override
  String get catMeat => 'Meat';

  @override
  String get catFish => 'Fish';

  @override
  String get catEgg => 'Eggs';

  @override
  String get catVegetable => 'Vegetables';

  @override
  String get catFruit => 'Fruit';

  @override
  String get catDairy => 'Dairy';

  @override
  String get catDrink => 'Drinks';

  @override
  String get catSnack => 'Snacks';

  @override
  String get catDaily => 'Household';

  @override
  String get catOther => 'Other';

  @override
  String get wdMon => 'Mon';

  @override
  String get wdTue => 'Tue';

  @override
  String get wdWed => 'Wed';

  @override
  String get wdThu => 'Thu';

  @override
  String get wdFri => 'Fri';

  @override
  String get wdSat => 'Sat';

  @override
  String get wdSun => 'Sun';

  @override
  String get capturePhoto => 'Take Photo';

  @override
  String get chooseGallery => 'Choose from Gallery';

  @override
  String get processingReceipt => 'Processing...';

  @override
  String get receiptReadFailed => 'Failed to read receipt. Please try again.';

  @override
  String get registerRegularTitle => 'Register as a regular product?';

  @override
  String get registerRegularDesc =>
      'Adding purchased items to your price memo helps with future shopping.';

  @override
  String get selectAndRegister => 'Select and Register';

  @override
  String get confirmReceiptTitle => 'Confirm Receipt';

  @override
  String get confirmReceiptSubtitle => 'Tap to edit, swipe to delete';

  @override
  String purchaseDateLabel(String date) {
    return 'Purchase Date: $date';
  }

  @override
  String saveAsPurchases(int count) {
    return 'Save $count items as purchases';
  }

  @override
  String get editItemTitle => 'Edit Item';

  @override
  String get priceYen => 'Price (¥)';

  @override
  String get selectProductsTitle => 'Select Products to Register';

  @override
  String get alreadyRegistered => 'Already Registered';

  @override
  String registerCount(int count) {
    return 'Register $count items';
  }

  @override
  String get organizing => 'Organizing...';

  @override
  String progressOf(int current, int total) {
    return 'Item $current of $total';
  }

  @override
  String get reviewHere => 'Please review';

  @override
  String get saveAndNext => 'Save & Next';

  @override
  String get skipThisProduct => 'Skip This Item';

  @override
  String get registrationComplete => 'All products registered.';

  @override
  String get reviewTitle => 'Enjoying PriceMate?';

  @override
  String get reviewMessage =>
      'We\'d love to hear what you think! Would you mind leaving us a review?';

  @override
  String get reviewWrite => 'Write a Review';

  @override
  String get reviewLater => 'Maybe Later';
}
