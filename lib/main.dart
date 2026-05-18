import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    final sb = StringBuffer();
    sb.writeln('FlutterError: ${details.exceptionAsString()}');
    sb.writeln(
      'schedulerPhase=${SchedulerBinding.instance.schedulerPhase}',
    );
    if (details.informationCollector != null) {
      for (final info in details.informationCollector!()) {
        sb.writeln(info.toStringDeep());
      }
    }
    debugLog(sb.toString());
    debugPrintStack(stackTrace: details.stack);
    FlutterError.presentError(details);
  };
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(serverClientId: googleServerClientId);
  debugLog('runApp PriceMateApp');
  runApp(const PriceMateApp());
}

const googleServerClientId =
    '734452752206-im65vqqdfoq4clcs0nf6uja0264jku1q.apps.googleusercontent.com';

final debugNavigatorObserver = _DebugNavigatorObserver();

void debugLog(String message) {
  assert(() {
    debugPrint('[PriceMateDebug] ${DateTime.now().toIso8601String()} $message');
    return true;
  }());
}

String routeLabel(Route<dynamic>? route) {
  if (route == null) return 'null';
  return '${route.settings.name ?? route.runtimeType}';
}

class _DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugLog(
      'Navigator didPush ${routeLabel(route)} from ${routeLabel(previousRoute)}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugLog(
      'Navigator didPop ${routeLabel(route)} to ${routeLabel(previousRoute)}',
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugLog(
      'Navigator didRemove ${routeLabel(route)} previous ${routeLabel(previousRoute)}',
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugLog(
      'Navigator didReplace ${routeLabel(oldRoute)} with ${routeLabel(newRoute)}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class PriceMateApp extends StatefulWidget {
  const PriceMateApp({super.key, this.useFirebase = true});

  final bool useFirebase;

  @override
  State<PriceMateApp> createState() => _PriceMateAppState();
}

class _PriceMateAppState extends State<PriceMateApp> {
  final AppStore store = AppStore();
  bool showSplash = true;
  bool onboardingLoaded = false;
  bool onboardingDone = false;
  bool signedIn = false;

  @override
  void initState() {
    super.initState();
    debugLog('PriceMateApp initState');
    loadOnboardingState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      debugLog('Splash finished');
      setState(() => showSplash = false);
    });
  }

  @override
  void dispose() {
    debugLog('PriceMateApp dispose');
    store.dispose();
    super.dispose();
  }

  Future<void> loadOnboardingState() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      onboardingDone = preferences.getBool('onboardingDone') ?? false;
      onboardingLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePreset>(
      valueListenable: store.themeNotifier,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'PriceMate',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [debugNavigatorObserver],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.seedColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: theme.scaffoldColor,
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    debugLog(
      'buildHome splash=$showSplash onboardingLoaded=$onboardingLoaded '
      'onboardingDone=$onboardingDone signedIn=$signedIn',
    );
    if (showSplash || !onboardingLoaded) {
      return const SplashView();
    }
    if (!onboardingDone) {
      return OnboardingView(onComplete: completeOnboarding);
    }
    if (widget.useFirebase) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          final user = snapshot.data;
          debugLog(
            'authState snapshot=${snapshot.connectionState} '
            'hasUser=${user != null} uid=${user?.uid}',
          );
          if (user == null) {
            return LoginView(
              onEmailLogin: signInWithEmail,
              onCreateAccount: createAccountWithEmail,
              onGoogleLogin: signInWithGoogle,
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            store.connectUser(user);
          });
          return PriceMateShell(store: store, onLogout: signOut);
        },
      );
    }
    if (!signedIn) {
      return LoginView(
        onEmailLogin: (_, _) async => setState(() => signedIn = true),
        onCreateAccount: (_, _) async => setState(() => signedIn = true),
        onGoogleLogin: () async => setState(() => signedIn = true),
      );
    }
    return PriceMateShell(
      store: store,
      onLogout: () => setState(() => signedIn = false),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboardingDone', true);
    if (!mounted) return;
    setState(() => onboardingDone = true);
  }

  Future<void> createAccountWithEmail(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    debugPrint('Google Sign-In: start');
    await GoogleSignIn.instance.signOut();
    debugPrint('Google Sign-In: previous session cleared');
    final googleUser = await GoogleSignIn.instance.authenticate();
    debugPrint('Google Sign-In: account selected ${googleUser.email}');
    final googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Google ID token was null.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    debugPrint('Google Sign-In: signing in to Firebase Auth');
    await FirebaseAuth.instance.signInWithCredential(credential);
    debugPrint('Google Sign-In: Firebase Auth sign-in complete');
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    store.clearCloudSession();
    await FirebaseAuth.instance.signOut();
  }
}

enum Urgency { now, later }

enum EntryMode { product, shoppingItem, purchase }

class AppThemePreset {
  const AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.seedColor,
    required this.scaffoldColor,
  });

  final String id;
  final String name;
  final String description;
  final Color seedColor;
  final Color scaffoldColor;
}

const themePresets = [
  AppThemePreset(
    id: 'fresh',
    name: 'Fresh Green',
    description: '落ち着いた食品アプリらしいグリーン',
    seedColor: Color(0xFF2F6F5E),
    scaffoldColor: Color(0xFFF8FAF8),
  ),
  AppThemePreset(
    id: 'market',
    name: 'Market Blue',
    description: '見やすく清潔感のあるブルー',
    seedColor: Color(0xFF2563A8),
    scaffoldColor: Color(0xFFF6F9FC),
  ),
  AppThemePreset(
    id: 'tomato',
    name: 'Tomato Red',
    description: '買い物メモが目に入りやすいレッド',
    seedColor: Color(0xFFC9493A),
    scaffoldColor: Color(0xFFFFF8F5),
  ),
  AppThemePreset(
    id: 'citrus',
    name: 'Citrus Yellow',
    description: '明るく親しみやすいイエロー',
    seedColor: Color(0xFFB7791F),
    scaffoldColor: Color(0xFFFFFBF0),
  ),
  AppThemePreset(
    id: 'mono',
    name: 'Calm Mono',
    description: '情報量が多くても読みやすいニュートラル',
    seedColor: Color(0xFF4B5563),
    scaffoldColor: Color(0xFFF8F8F7),
  ),
];

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  size: 44,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'PriceMate',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '家族で使う買い物の価格メモ',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController controller = PageController();
  int currentPage = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _OnboardingPage(
        icon: Icons.price_check_outlined,
        title: 'いつもの価格を共有',
        message: 'ベスト価格と許容価格を家族で見られるので、買い物の判断がしやすくなります。',
      ),
      _OnboardingPage(
        icon: Icons.checklist_outlined,
        title: '買うものを迷わない',
        message: 'すぐ必要なものと、そのうち買うものを分けて、買い忘れを減らします。',
      ),
      _OnboardingPage(
        icon: Icons.group_outlined,
        title: '家族みんなで使える',
        message: '招待コードで共有スペースに参加し、同じ商品リストと買い物リストを使えます。',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: const Text('スキップ'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: controller,
                  onPageChanged: (index) => setState(() => currentPage = index),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => _PageDot(active: index == currentPage),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (currentPage == pages.length - 1) {
                    widget.onComplete();
                    return;
                  }
                  controller.nextPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(currentPage == pages.length - 1 ? 'はじめる' : '次へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 52, color: colorScheme.onSecondaryContainer),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 22 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '読み込み中',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.onEmailLogin,
    required this.onCreateAccount,
    required this.onGoogleLogin,
  });

  final Future<void> Function(String email, String password) onEmailLogin;
  final Future<void> Function(String email, String password) onCreateAccount;
  final Future<void> Function() onGoogleLogin;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool creatingAccount = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.shopping_basket_outlined,
                size: 36,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              creatingAccount ? '新規アカウント作成' : 'ログイン',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                labelText: 'パスワード',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(errorMessage!, style: TextStyle(color: colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () => runAuthAction(
                      creatingAccount ? createAccount : emailLogin,
                    ),
              icon: const Icon(Icons.mail_outline),
              label: Text(creatingAccount ? 'アカウントを作成' : 'メールでログイン'),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      setState(() {
                        creatingAccount = !creatingAccount;
                        errorMessage = null;
                      });
                    },
              child: Text(creatingAccount ? 'ログインに戻る' : 'アカウントを作成'),
            ),
            if (!creatingAccount) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () => runAuthAction(widget.onGoogleLogin),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Googleでログイン'),
              ),
            ],
            if (loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> emailLogin() {
    return widget.onEmailLogin(emailController.text, passwordController.text);
  }

  Future<void> createAccount() {
    return widget.onCreateAccount(
      emailController.text,
      passwordController.text,
    );
  }

  Future<void> runAuthAction(Future<void> Function() action) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'FirebaseAuthException: code=${error.code}, message=${error.message}',
      );
      setState(() => errorMessage = authErrorMessage(error));
    } on GoogleSignInException catch (error) {
      debugPrint(
        'GoogleSignInException: code=${error.code.name}, '
        'description=${error.description}, details=${error.details}',
      );
      setState(() => errorMessage = googleSignInErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint('Auth error: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() => errorMessage = 'ログインに失敗しました。$error');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

String googleSignInErrorMessage(GoogleSignInException error) {
  return switch (error.code) {
    GoogleSignInExceptionCode.canceled =>
      'Googleログインが完了しませんでした。${error.description ?? 'アカウント選択後に出る場合は、FirebaseのAndroid SHA設定とgoogle-services.jsonを確認してください。'}',
    GoogleSignInExceptionCode.clientConfigurationError =>
      'Googleログイン設定が未完了です。${error.description ?? 'FirebaseにAndroidのSHA-1/SHA-256を登録し、google-services.jsonを更新してください。'}',
    GoogleSignInExceptionCode.providerConfigurationError =>
      'Googleログインのプロバイダ設定を確認してください。${error.description ?? ''}',
    GoogleSignInExceptionCode.uiUnavailable =>
      'Googleログイン画面を表示できませんでした。${error.description ?? ''}',
    _ =>
      'Googleログインに失敗しました。code=${error.code.name}, description=${error.description ?? 'なし'}',
  };
}

String authErrorMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'メールアドレスの形式を確認してください。',
    'missing-password' => 'パスワードを入力してください。',
    'weak-password' => 'パスワードは6文字以上で入力してください。',
    'email-already-in-use' => 'このメールアドレスは既に登録されています。',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'メールアドレスまたはパスワードが違います。',
    'network-request-failed' => 'ネットワーク接続を確認してください。',
    'popup-closed-by-user' || 'canceled' => 'ログインがキャンセルされました。',
    _ => 'ログインに失敗しました。${error.code}',
  };
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.storeName,
    this.size,
    required this.bestPrice,
    required this.acceptablePrice,
    required this.saleDays,
    this.memo,
  });

  final String id;
  final String name;
  final String storeName;
  final String? size;
  final int bestPrice;
  final int acceptablePrice;
  final Set<int> saleDays;
  final String? memo;

  Product copyWith({
    String? name,
    String? storeName,
    String? size,
    int? bestPrice,
    int? acceptablePrice,
    Set<int>? saleDays,
    String? memo,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      size: size ?? this.size,
      bestPrice: bestPrice ?? this.bestPrice,
      acceptablePrice: acceptablePrice ?? this.acceptablePrice,
      saleDays: saleDays ?? this.saleDays,
      memo: memo ?? this.memo,
    );
  }
}

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.name,
    required this.urgency,
    this.checked = false,
  });

  final String id;
  final String name;
  final Urgency urgency;
  final bool checked;

  ShoppingItem copyWith({String? name, Urgency? urgency, bool? checked}) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      urgency: urgency ?? this.urgency,
      checked: checked ?? this.checked,
    );
  }
}

class PurchaseRecord {
  PurchaseRecord({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.purchasedAt,
    required this.source,
  });

  final String id;
  final String productName;
  final String storeName;
  final int price;
  final DateTime purchasedAt;
  final String source;
}

class AppStore extends ChangeNotifier {
  final ValueNotifier<AppThemePreset> themeNotifier = ValueNotifier(
    themePresets.first,
  );
  String? activeUserId;
  String? activeSpaceId;
  bool _connecting = false;
  bool _notifyScheduled = false;

  final List<Product> products = [];

  final List<ShoppingItem> shoppingItems = [];

  final List<PurchaseRecord> purchaseRecords = [];

  int _nextId = 10;

  AppThemePreset get selectedTheme => themeNotifier.value;

  String get _id => '${DateTime.now().millisecondsSinceEpoch}-${_nextId++}';

  @override
  void dispose() {
    debugLog('AppStore dispose');
    themeNotifier.dispose();
    super.dispose();
  }

  void notifyStoreListeners(String reason) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    debugLog(
      'AppStore scheduleNotify[$reason] phase=$phase '
      'user=$activeUserId space=$activeSpaceId '
      'products=${products.length} shopping=${shoppingItems.length} '
      'records=${purchaseRecords.length}',
    );

    // If we are between frames (idle or post-frame callbacks already running),
    // it is safe to call notifyListeners() directly.  No build scope is active,
    // and all inactive elements have already been disposed by finalizeTree().
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) {
        debugLog('AppStore notifyDirect[$reason]');
        notifyListeners();
      }
      return;
    }

    // During a frame (transientCallbacks / persistentCallbacks / build) we must
    // defer until the frame has fully settled.  A single post-frame callback
    // fires after finalizeTree(), so inactive elements are already disposed.
    if (_notifyScheduled) {
      debugLog('AppStore notifySkipped[$reason] already queued');
      return;
    }
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      final nowPhase = SchedulerBinding.instance.schedulerPhase;
      debugLog('AppStore notifyDeferred[$reason] nowPhase=$nowPhase');
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance
          .collection('sharedSpaces')
          .doc(activeSpaceId)
          .collection('products');

  CollectionReference<Map<String, dynamic>> get _shoppingItemsRef =>
      FirebaseFirestore.instance
          .collection('sharedSpaces')
          .doc(activeSpaceId)
          .collection('shoppingItems');

  CollectionReference<Map<String, dynamic>> get _purchaseRecordsRef =>
      FirebaseFirestore.instance
          .collection('sharedSpaces')
          .doc(activeSpaceId)
          .collection('purchaseRecords');

  Future<void> connectUser(User user) async {
    debugLog(
      'connectUser start uid=${user.uid} currentUser=$activeUserId '
      'currentSpace=$activeSpaceId connecting=$_connecting',
    );
    if (_connecting || (activeUserId == user.uid && activeSpaceId != null)) {
      debugLog('connectUser skipped');
      return;
    }
    _connecting = true;

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();
      final savedSpaceId = userSnapshot.data()?['activeSpaceId'] as String?;
      var spaceId = savedSpaceId ?? user.uid;
      debugLog(
        'connectUser savedSpaceId=$savedSpaceId resolvedSpaceId=$spaceId',
      );

      final userData = <String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'activeSpaceId': spaceId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!userSnapshot.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }
      await userRef.set(userData, SetOptions(merge: true));

      if (spaceId == user.uid) {
        await _ensurePersonalSpace(firestore, user);
      } else {
        final memberRef = firestore
            .collection('sharedSpaces')
            .doc(spaceId)
            .collection('members')
            .doc(user.uid);
        var isMember = false;
        try {
          isMember = (await memberRef.get()).exists;
        } on FirebaseException catch (error) {
          if (error.code != 'permission-denied') rethrow;
        }
        if (!isMember) {
          debugLog(
            'connectUser user is not a member of saved space $spaceId; '
            'falling back to personal space',
          );
          spaceId = user.uid;
          await userRef.set({
            'activeSpaceId': spaceId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await _ensurePersonalSpace(firestore, user);
        }
      }

      activeUserId = user.uid;
      activeSpaceId = spaceId;
      debugLog('connectUser connected uid=$activeUserId space=$activeSpaceId');
      await loadCloudData();
    } finally {
      _connecting = false;
      debugLog('connectUser finish connecting=$_connecting');
    }
  }

  Future<void> _ensurePersonalSpace(
    FirebaseFirestore firestore,
    User user,
  ) async {
    final spaceRef = firestore.collection('sharedSpaces').doc(user.uid);
    await spaceRef.set({
      'name': 'マイスペース',
      'ownerId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await spaceRef.collection('members').doc(user.uid).set({
      'role': 'owner',
      'displayName': user.displayName ?? user.email ?? '自分',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> createInviteCode() async {
    if (activeUserId == null || activeSpaceId == null) {
      throw StateError('ログインが必要です。');
    }

    final code = _newInviteCode();
    debugLog('createInviteCode space=$activeSpaceId code=$code');
    await FirebaseFirestore.instance.collection('invites').doc(code).set({
      'spaceId': activeSpaceId,
      'role': 'member',
      'status': 'active',
      'invitedBy': activeUserId,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<void> acceptInviteCode(String code) async {
    debugLog(
      'acceptInviteCode start input="$code" currentSpace=$activeSpaceId',
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('ログインが必要です。');
    }

    final normalizedCode = normalizeInviteCode(code);
    if (normalizedCode == null) {
      throw StateError('8文字の招待コードを入力してください。');
    }
    final firestore = FirebaseFirestore.instance;
    final inviteRef = firestore.collection('invites').doc(normalizedCode);
    String? acceptedSpaceId;
    debugLog('acceptInviteCode normalized=$normalizedCode');

    await firestore.runTransaction((transaction) async {
      final inviteSnapshot = await transaction.get(inviteRef);
      if (!inviteSnapshot.exists) {
        throw StateError('招待コードが見つかりません。');
      }

      final invite = inviteSnapshot.data()!;
      debugLog('acceptInviteCode invite=${invite.toString()}');
      final expiresAt = invite['expiresAt'];
      if (invite['status'] != 'active' ||
          (expiresAt is Timestamp &&
              expiresAt.toDate().isBefore(DateTime.now()))) {
        throw StateError('この招待コードは期限切れです。');
      }

      final spaceId = invite['spaceId'];
      if (spaceId is! String || spaceId.isEmpty) {
        throw StateError('招待コードの共有先が壊れています。');
      }

      final memberRef = firestore
          .collection('sharedSpaces')
          .doc(spaceId)
          .collection('members')
          .doc(user.uid);
      final userRef = firestore.collection('users').doc(user.uid);

      transaction.set(memberRef, {
        'role': 'member',
        'displayName': user.displayName ?? user.email ?? 'メンバー',
        'inviteId': normalizedCode,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(userRef, {
        'activeSpaceId': spaceId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      acceptedSpaceId = spaceId;
    });

    activeUserId = user.uid;
    activeSpaceId = acceptedSpaceId;
    if (activeSpaceId == null) {
      throw StateError('共有スペースに参加できませんでした。');
    }
    debugLog(
      'acceptInviteCode accepted user=$activeUserId space=$activeSpaceId',
    );
  }

  String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String? normalizeInviteCode(String input) {
    final trimmed = input.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    final normalized = trimmed.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    return normalized.length == 8 ? normalized : null;
  }

  void clearCloudSession() {
    activeUserId = null;
    activeSpaceId = null;
  }

  Future<void> loadCloudData() async {
    debugLog('loadCloudData start space=$activeSpaceId');
    if (activeSpaceId == null) {
      debugLog('loadCloudData skipped: no activeSpaceId');
      return;
    }

    final productSnapshot = await _productsRef.get();
    final shoppingSnapshot = await _shoppingItemsRef.get();
    final purchaseSnapshot = await _purchaseRecordsRef
        .orderBy('purchasedAt', descending: true)
        .get();

    products
      ..clear()
      ..addAll(productSnapshot.docs.map(productFromDoc));
    shoppingItems
      ..clear()
      ..addAll(shoppingSnapshot.docs.map(shoppingItemFromDoc));
    purchaseRecords
      ..clear()
      ..addAll(purchaseSnapshot.docs.map(purchaseRecordFromDoc));
    notifyStoreListeners('loadCloudData');
  }

  void selectTheme(AppThemePreset theme) {
    themeNotifier.value = theme;
    notifyStoreListeners('selectTheme:${theme.id}');
  }

  void upsertProduct(Product? current, Product product) {
    final savedProduct = Product(
      id: current?.id ?? _id,
      name: product.name,
      storeName: product.storeName,
      size: product.size,
      bestPrice: product.bestPrice,
      acceptablePrice: product.acceptablePrice,
      saleDays: product.saleDays,
      memo: product.memo,
    );

    if (current == null) {
      products.insert(0, savedProduct);
    } else {
      final index = products.indexWhere((item) => item.id == current.id);
      if (index == -1) {
        debugLog('upsertProduct missing existing id=${current.id}; inserting');
        products.insert(0, savedProduct);
      } else {
        products[index] = savedProduct;
      }
    }
    if (activeSpaceId != null) {
      _productsRef.doc(savedProduct.id).set(productToMap(savedProduct));
    }
    notifyStoreListeners('upsertProduct:${savedProduct.id}');
  }

  void deleteProduct(Product product) {
    debugLog('deleteProduct id=${product.id}');
    products.removeWhere((item) => item.id == product.id);
    if (activeSpaceId != null) {
      _productsRef.doc(product.id).delete();
    }
    notifyStoreListeners('deleteProduct:${product.id}');
  }

  void upsertShoppingItem(ShoppingItem? current, ShoppingItem item) {
    final savedItem = ShoppingItem(
      id: current?.id ?? _id,
      name: item.name,
      urgency: item.urgency,
      checked: item.checked,
    );

    if (current == null) {
      shoppingItems.insert(0, savedItem);
    } else {
      final index = shoppingItems.indexWhere((entry) => entry.id == current.id);
      if (index == -1) {
        debugLog(
          'upsertShoppingItem missing existing id=${current.id}; inserting',
        );
        shoppingItems.insert(0, savedItem);
      } else {
        shoppingItems[index] = savedItem;
      }
    }
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(savedItem.id).set(shoppingItemToMap(savedItem));
    }
    notifyStoreListeners('upsertShoppingItem:${savedItem.id}');
  }

  void toggleShoppingItem(ShoppingItem item) {
    final index = shoppingItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      debugLog('toggleShoppingItem missing id=${item.id}');
      return;
    }
    final updatedItem = item.copyWith(checked: !item.checked);
    shoppingItems[index] = updatedItem;
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(updatedItem.id).set(shoppingItemToMap(updatedItem));
    }
    notifyStoreListeners('toggleShoppingItem:${updatedItem.id}');
  }

  void deleteShoppingItem(ShoppingItem item) {
    debugLog('deleteShoppingItem id=${item.id}');
    shoppingItems.removeWhere((entry) => entry.id == item.id);
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(item.id).delete();
    }
    notifyStoreListeners('deleteShoppingItem:${item.id}');
  }

  void addPurchaseRecord(PurchaseRecord record) {
    final savedRecord = PurchaseRecord(
      id: _id,
      productName: record.productName,
      storeName: record.storeName,
      price: record.price,
      purchasedAt: record.purchasedAt,
      source: record.source,
    );
    purchaseRecords.insert(0, savedRecord);
    if (activeSpaceId != null) {
      _purchaseRecordsRef
          .doc(savedRecord.id)
          .set(purchaseRecordToMap(savedRecord));
    }
    notifyStoreListeners('addPurchaseRecord:${savedRecord.id}');
  }

  Map<String, dynamic> productToMap(Product product) {
    return {
      'name': product.name,
      'storeName': product.storeName,
      'size': product.size,
      'bestPrice': product.bestPrice,
      'acceptablePrice': product.acceptablePrice,
      'saleDays': product.saleDays.toList()..sort(),
      'memo': product.memo,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Product productFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      size: data['size'] as String?,
      bestPrice: data['bestPrice'] as int? ?? 0,
      acceptablePrice: data['acceptablePrice'] as int? ?? 0,
      saleDays: Set<int>.from(data['saleDays'] as List? ?? const []),
      memo: data['memo'] as String?,
    );
  }

  Map<String, dynamic> shoppingItemToMap(ShoppingItem item) {
    return {
      'name': item.name,
      'urgency': item.urgency.name,
      'checked': item.checked,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ShoppingItem shoppingItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ShoppingItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      urgency: data['urgency'] == Urgency.later.name
          ? Urgency.later
          : Urgency.now,
      checked: data['checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> purchaseRecordToMap(PurchaseRecord record) {
    return {
      'productName': record.productName,
      'storeName': record.storeName,
      'price': record.price,
      'purchasedAt': Timestamp.fromDate(record.purchasedAt),
      'source': record.source,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PurchaseRecord purchaseRecordFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final purchasedAt = data['purchasedAt'];
    return PurchaseRecord(
      id: doc.id,
      productName: data['productName'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      price: data['price'] as int? ?? 0,
      purchasedAt: purchasedAt is Timestamp
          ? purchasedAt.toDate()
          : DateTime.now(),
      source: data['source'] as String? ?? 'manual',
    );
  }
}

class PriceMateShell extends StatefulWidget {
  const PriceMateShell({
    super.key,
    required this.store,
    required this.onLogout,
  });

  final AppStore store;
  final VoidCallback onLogout;

  @override
  State<PriceMateShell> createState() => _PriceMateShellState();
}

class _PriceMateShellState extends State<PriceMateShell> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    debugLog('PriceMateShell initState');
  }

  @override
  void dispose() {
    debugLog('PriceMateShell dispose selectedIndex=$selectedIndex');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    debugLog('PriceMateShell build selectedIndex=$selectedIndex');
    return Scaffold(
      appBar: AppBar(
        title: const Text('PriceMate'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '通知',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: _StorePage(
          store: store,
          selectedIndex: selectedIndex,
          onLogout: widget.onLogout,
        ),
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          tooltip: '入力',
          shape: const CircleBorder(),
          onPressed: () {
            debugLog('FAB tap input');
            setState(() => selectedIndex = 2);
          },
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 74,
        padding: EdgeInsets.zero,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabButton(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'ホーム',
              active: selectedIndex == 0,
              onTap: () {
                debugLog('Tab tap home');
                setState(() => selectedIndex = 0);
              },
            ),
            _TabButton(
              icon: Icons.checklist_outlined,
              activeIcon: Icons.checklist,
              label: '買い物',
              active: selectedIndex == 1,
              onTap: () {
                debugLog('Tab tap shopping');
                setState(() => selectedIndex = 1);
              },
            ),
            const SizedBox(width: 72),
            _TabButton(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: '商品',
              active: selectedIndex == 3,
              onTap: () {
                debugLog('Tab tap products');
                setState(() => selectedIndex = 3);
              },
            ),
            _TabButton(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: '設定',
              active: selectedIndex == 4,
              onTap: () {
                debugLog('Tab tap settings');
                setState(() => selectedIndex = 4);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StorePage extends StatelessWidget {
  const _StorePage({
    required this.store,
    required this.selectedIndex,
    required this.onLogout,
  });

  final AppStore store;
  final int selectedIndex;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        debugLog(
          'StorePage rebuild selectedIndex=$selectedIndex '
          'space=${store.activeSpaceId}',
        );
        return switch (selectedIndex) {
          0 => HomeView(store: store),
          1 => ShoppingListView(store: store),
          2 => InputView(store: store),
          3 => ProductListView(store: store),
          _ => SettingsView(store: store, onLogout: onLogout),
        };
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final urgentCount = store.shoppingItems
        .where((item) => item.urgency == Urgency.now && !item.checked)
        .length;
    final todayProducts = store.products
        .where((product) => product.saleDays.contains(DateTime.now().weekday))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '家族の買い物基準',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '価格と買うものを共有して、買い物のすれ違いを減らします。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'すぐ必要',
                value: '$urgentCount',
                icon: Icons.priority_high,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: '登録商品',
                value: '${store.products.length}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: '今日の特売'),
        if (todayProducts.isEmpty)
          const _EmptyMessage(message: '今日に設定された特売商品はありません。')
        else
          ...todayProducts.map((product) => _ProductTile(product: product)),
        const SizedBox(height: 20),
        _SectionHeader(title: '最近の購入履歴'),
        ...store.purchaseRecords.map((record) => _PurchaseTile(record: record)),
      ],
    );
  }
}

class ShoppingListView extends StatelessWidget {
  const ShoppingListView({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final sorted = [...store.shoppingItems]
      ..sort((a, b) {
        if (a.checked != b.checked) return a.checked ? 1 : -1;
        return a.urgency == Urgency.now ? -1 : 1;
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ViewTitle(
          title: '買うものリスト',
          subtitle: 'スワイプで削除、タップで編集できます。',
          action: IconButton.filledTonal(
            tooltip: '買うものを追加',
            icon: const Icon(Icons.add),
            onPressed: () => showShoppingItemSheet(context, store),
          ),
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          const _EmptyMessage(message: '買うものはまだありません。')
        else
          ...sorted.map((item) {
            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              onDismissed: (_) {
                debugLog('Dismiss shopping item id=${item.id}');
                store.deleteShoppingItem(item);
              },
              child: Card(
                child: ListTile(
                  leading: Checkbox(
                    value: item.checked,
                    onChanged: (_) => store.toggleShoppingItem(item),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(item.urgency == Urgency.now ? 'すぐ必要' : 'そのうち'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      showShoppingItemSheet(context, store, item: item),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class InputView extends StatefulWidget {
  const InputView({super.key, required this.store});

  final AppStore store;

  @override
  State<InputView> createState() => _InputViewState();
}

class _InputViewState extends State<InputView> {
  EntryMode mode = EntryMode.product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ViewTitle(title: '入力', subtitle: '価格基準、買うもの、購入履歴をここから追加します。'),
        const SizedBox(height: 16),
        SegmentedButton<EntryMode>(
          segments: const [
            ButtonSegment(
              value: EntryMode.product,
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('商品'),
            ),
            ButtonSegment(
              value: EntryMode.shoppingItem,
              icon: Icon(Icons.checklist),
              label: Text('買うもの'),
            ),
            ButtonSegment(
              value: EntryMode.purchase,
              icon: Icon(Icons.receipt_long_outlined),
              label: Text('購入'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => setState(() => mode = value.first),
        ),
        const SizedBox(height: 20),
        if (mode == EntryMode.product)
          FilledButton.icon(
            onPressed: () => showProductSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: const Text('商品を登録'),
          )
        else if (mode == EntryMode.shoppingItem)
          FilledButton.icon(
            onPressed: () => showShoppingItemSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: const Text('買うものを登録'),
          )
        else
          FilledButton.icon(
            onPressed: () => showPurchaseSheet(context, widget.store),
            icon: const Icon(Icons.add),
            label: const Text('購入履歴を登録'),
          ),
        const SizedBox(height: 16),
        const _HintPanel(
          text: 'Firebase 接続後は、この入力が共有スペース内の Firestore に保存されます。',
        ),
      ],
    );
  }
}

class ProductListView extends StatelessWidget {
  const ProductListView({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ViewTitle(
          title: '商品リスト',
          subtitle: '家庭内の価格基準を一覧できます。',
          action: IconButton.filledTonal(
            tooltip: '商品を追加',
            icon: const Icon(Icons.add),
            onPressed: () => showProductSheet(context, store),
          ),
        ),
        const SizedBox(height: 12),
        if (store.products.isEmpty)
          const _EmptyMessage(message: '商品はまだ登録されていません。')
        else
          ...store.products.map((product) {
            return Dismissible(
              key: ValueKey(product.id),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              onDismissed: (_) {
                debugLog('Dismiss product id=${product.id}');
                store.deleteProduct(product);
              },
              child: Card(
                child: ListTile(
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${product.storeName}${product.size == null || product.size!.isEmpty ? '' : ' / ${product.size}'}\n'
                    'ベスト ${formatYen(product.bestPrice)} / 許容 ${formatYen(product.acceptablePrice)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      showProductSheet(context, store, product: product),
                  onLongPress: () =>
                      showPurchaseSheet(context, store, product: product),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.store, required this.onLogout});

  final AppStore store;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const _ViewTitle(title: '設定', subtitle: '共有、アプリ情報、アカウントを管理します。'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'テーマカラー',
                subtitle: store.selectedTheme.name,
                onTap: () => showThemeSheet(context, store),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_add_alt,
                title: 'パートナーを招待',
                onTap: () => showInviteSheet(context, store),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.vpn_key_outlined,
                title: '招待コードを入力',
                onTap: () => showAcceptInviteSheet(context, store),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.group_outlined,
                title: '家族メンバー管理',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '利用規約',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const _LegalView(
                      title: '利用規約',
                      lastUpdated: '2026年5月18日',
                      sections: _termsOfService,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシーポリシー',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const _LegalView(
                      title: 'プライバシーポリシー',
                      lastUpdated: '2026年5月18日',
                      sections: _privacyPolicy,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.favorite_border,
                title: 'スペシャルサンクス',
                onTap: () {},
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('バージョン'),
                trailing: Text('1.0.0'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('ログアウト'),
        ),
      ],
    );
  }
}

Future<void> showProductSheet(
  BuildContext context,
  AppStore store, {
  Product? product,
}) async {
  final name = TextEditingController(text: product?.name ?? '');
  final storeName = TextEditingController(text: product?.storeName ?? '');
  final size = TextEditingController(text: product?.size ?? '');
  final bestPrice = TextEditingController(
    text: product?.bestPrice.toString() ?? '',
  );
  final acceptablePrice = TextEditingController(
    text: product?.acceptablePrice.toString() ?? '',
  );
  final memo = TextEditingController(text: product?.memo ?? '');
  final saleDays = {...?product?.saleDays};
  var isProcessing = false;
  // Captured inside the builder so we can wait for the dismiss animation to
  // complete before disposing controllers and updating the store.
  // showModalBottomSheet's future resolves the moment Navigator.pop is called
  // (not when the animation finishes), so the sheet's widget tree is still
  // alive during the reverse animation.
  Animation<double>? sheetAnimation;

  debugLog('showProductSheet open product=${product?.id}');
  final result = await showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetTitle(title: product == null ? '商品を登録' : '商品を編集'),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '商品名'),
                  ),
                  TextField(
                    controller: storeName,
                    decoration: const InputDecoration(labelText: '店舗名'),
                  ),
                  TextField(
                    controller: size,
                    decoration: const InputDecoration(labelText: 'サイズ（任意）'),
                  ),
                  TextField(
                    controller: bestPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ベスト価格'),
                  ),
                  TextField(
                    controller: acceptablePrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '許容価格'),
                  ),
                  TextField(
                    controller: memo,
                    decoration: const InputDecoration(labelText: 'メモ（任意）'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '特売日',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final weekday = index + 1;
                      return FilterChip(
                        label: Text(weekdayLabels[index]),
                        selected: saleDays.contains(weekday),
                        onSelected: (selected) {
                          setSheetState(() {
                            selected
                                ? saleDays.add(weekday)
                                : saleDays.remove(weekday);
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    // Duration.zero prevents AnimatedDefaultTextStyle from
                    // starting a Ticker when the button goes disabled, avoiding
                    // the "wrong build scope" assertion in newer Flutter.
                    style: const ButtonStyle(
                      animationDuration: Duration.zero,
                    ),
                    onPressed: isProcessing
                        ? null
                        : () {
                            debugLog(
                              'showProductSheet safeClose '
                              'phase=${SchedulerBinding.instance.schedulerPhase}',
                            );
                            final saved = Product(
                              id: product?.id ?? 'new',
                              name: name.text.trim(),
                              storeName: storeName.text.trim(),
                              size: size.text.trim().isEmpty
                                  ? null
                                  : size.text.trim(),
                              bestPrice: int.tryParse(bestPrice.text) ?? 0,
                              acceptablePrice:
                                  int.tryParse(acceptablePrice.text) ?? 0,
                              saleDays: saleDays,
                              memo: memo.text.trim().isEmpty
                                  ? null
                                  : memo.text.trim(),
                            );
                            // setSheetState disables the button (onPressed→null),
                            // which causes InkResponse to call cancel() on the
                            // active InkRipple, clearing its InheritedWidget
                            // dependents before the modal is removed.
                            // animationDuration:zero on the button ensures that
                            // the resulting text-style change completes instantly
                            // (no Ticker) so it cannot fire markNeedsBuild() in
                            // the wrong build scope on a later frame.
                            setSheetState(() {
                              debugLog('showProductSheet setSheetState isProcessing=true');
                              isProcessing = true;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              debugLog(
                                'showProductSheet popCallback mounted=${context.mounted} '
                                'phase=${SchedulerBinding.instance.schedulerPhase}',
                              );
                              if (context.mounted) Navigator.pop(context, saved);
                            });
                          },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  debugLog(
    'showProductSheet future resolved product=${product?.id} '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  // Do NOT dispose controllers or update the store here yet.
  // The dismiss animation is still running; the sheet's TextField widgets are
  // still in the tree and may rebuild, causing "controller used after dispose".
  // Wait for AnimationStatus.dismissed before finalizing.
  void finalizeProductSheet() {
    debugLog(
      'showProductSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    name.dispose();
    storeName.dispose();
    size.dispose();
    bestPrice.dispose();
    acceptablePrice.dispose();
    memo.dispose();
    if (result != null) {
      store.upsertProduct(product, result);
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizeProductSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizeProductSheet();
      }
    }
    anim.addStatusListener(onStatus);
  }
}

Future<void> showShoppingItemSheet(
  BuildContext context,
  AppStore store, {
  ShoppingItem? item,
}) async {
  final name = TextEditingController(text: item?.name ?? '');
  var urgency = item?.urgency ?? Urgency.now;
  var isProcessing = false;
  Animation<double>? sheetAnimation;

  debugLog('showShoppingItemSheet open item=${item?.id}');
  final savedItem = await showModalBottomSheet<ShoppingItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetTitle(title: item == null ? '買うものを登録' : '買うものを編集'),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '商品名'),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Urgency>(
                  segments: const [
                    ButtonSegment(value: Urgency.now, label: Text('すぐ必要')),
                    ButtonSegment(value: Urgency.later, label: Text('そのうち')),
                  ],
                  selected: {urgency},
                  onSelectionChanged: (value) =>
                      setSheetState(() => urgency = value.first),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: const ButtonStyle(animationDuration: Duration.zero),
                  onPressed: isProcessing
                      ? null
                      : () {
                          debugLog(
                            'showShoppingItemSheet safeClose '
                            'phase=${SchedulerBinding.instance.schedulerPhase}',
                          );
                          final result = ShoppingItem(
                            id: item?.id ?? 'new',
                            name: name.text.trim(),
                            urgency: urgency,
                            checked: item?.checked ?? false,
                          );
                          setSheetState(() {
                            debugLog('showShoppingItemSheet setSheetState isProcessing=true');
                            isProcessing = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            debugLog(
                              'showShoppingItemSheet popCallback mounted=${context.mounted} '
                              'phase=${SchedulerBinding.instance.schedulerPhase}',
                            );
                            if (context.mounted) Navigator.pop(context, result);
                          });
                        },
                  child: const Text('保存'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  debugLog(
    'showShoppingItemSheet future resolved item=${item?.id} '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  void finalizeShoppingSheet() {
    debugLog(
      'showShoppingItemSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    name.dispose();
    if (savedItem != null) {
      store.upsertShoppingItem(item, savedItem);
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizeShoppingSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizeShoppingSheet();
      }
    }
    anim.addStatusListener(onStatus);
  }
}

Future<void> showPurchaseSheet(
  BuildContext context,
  AppStore store, {
  Product? product,
}) async {
  final productName = TextEditingController(text: product?.name ?? '');
  final storeName = TextEditingController(text: product?.storeName ?? '');
  final price = TextEditingController();
  var isProcessing = false;
  Animation<double>? sheetAnimation;

  debugLog('showPurchaseSheet open product=${product?.id}');
  final result = await showModalBottomSheet<PurchaseRecord>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetTitle(title: '購入履歴を登録'),
                TextField(
                  controller: productName,
                  decoration: const InputDecoration(labelText: '商品名'),
                ),
                TextField(
                  controller: storeName,
                  decoration: const InputDecoration(labelText: '店舗名'),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '購入価格'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: const ButtonStyle(animationDuration: Duration.zero),
                  onPressed: isProcessing
                      ? null
                      : () {
                          debugLog(
                            'showPurchaseSheet safeClose '
                            'phase=${SchedulerBinding.instance.schedulerPhase}',
                          );
                          final record = PurchaseRecord(
                            id: 'new',
                            productName: productName.text.trim(),
                            storeName: storeName.text.trim(),
                            price: int.tryParse(price.text) ?? 0,
                            purchasedAt: DateTime.now(),
                            source: 'manual',
                          );
                          setSheetState(() {
                            debugLog('showPurchaseSheet setSheetState isProcessing=true');
                            isProcessing = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            debugLog(
                              'showPurchaseSheet popCallback mounted=${context.mounted} '
                              'phase=${SchedulerBinding.instance.schedulerPhase}',
                            );
                            if (context.mounted) Navigator.pop(context, record);
                          });
                        },
                  child: const Text('保存'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  debugLog(
    'showPurchaseSheet future resolved product=${product?.id} '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  void finalizePurchaseSheet() {
    debugLog(
      'showPurchaseSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    productName.dispose();
    storeName.dispose();
    price.dispose();
    if (result != null) {
      store.addPurchaseRecord(result);
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizePurchaseSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizePurchaseSheet();
      }
    }
    anim.addStatusListener(onStatus);
  }
}

Future<void> showInviteSheet(BuildContext context, AppStore store) async {
  String? inviteCode;
  String? errorMessage;
  var loading = false;
  debugLog('showInviteSheet open');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetTitle(title: 'パートナーを招待'),
                  const Text('招待コードを作成して、家族に共有します。有効期限は7日間です。'),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (inviteCode != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      inviteCode!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: inviteCode!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('招待コードをコピーしました')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('招待コードをコピー'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () async {
                            setSheetState(() {
                              loading = true;
                              errorMessage = null;
                            });
                            try {
                              debugLog('showInviteSheet create invite start');
                              final code = await store.createInviteCode();
                              debugLog(
                                'showInviteSheet create invite success code=$code',
                              );
                              setSheetState(() => inviteCode = code);
                            } catch (_) {
                              debugLog('showInviteSheet create invite failed');
                              setSheetState(
                                () => errorMessage = '招待コードを作成できませんでした。',
                              );
                            } finally {
                              setSheetState(() => loading = false);
                            }
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.vpn_key_outlined),
                    label: Text(inviteCode == null ? '招待コードを作成' : '作り直す'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  debugLog('showInviteSheet closed');
}

Future<void> showAcceptInviteSheet(BuildContext context, AppStore store) async {
  final codeController = TextEditingController();
  String? errorMessage;
  var loading = false;
  Animation<double>? sheetAnimation;

  debugLog('showAcceptInviteSheet open');
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      sheetAnimation ??= ModalRoute.of(ctx)?.animation;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetTitle(title: '招待コードを入力'),
                  const Text('共有された8文字の招待コードを入力してください。'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: '招待コード',
                      hintText: '例: ABCD2345',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: const ButtonStyle(
                      animationDuration: Duration.zero,
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            setSheetState(() {
                              loading = true;
                              errorMessage = null;
                            });
                            try {
                              debugLog('showAcceptInviteSheet accept start');
                              await store.acceptInviteCode(codeController.text);
                              debugLog(
                                'showAcceptInviteSheet accept success; pop',
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                              return;
                            } catch (error) {
                              debugLog(
                                'showAcceptInviteSheet accept failed $error',
                              );
                              if (!context.mounted) return;
                              setSheetState(() {
                                errorMessage = inviteErrorMessage(error);
                              });
                            }
                            if (context.mounted) {
                              setSheetState(() => loading = false);
                            }
                          },
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('参加する'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  debugLog(
    'showAcceptInviteSheet future resolved accepted=$accepted '
    'animStatus=${sheetAnimation?.status} '
    'phase=${SchedulerBinding.instance.schedulerPhase}',
  );

  void finalizeAcceptSheet() {
    debugLog(
      'showAcceptInviteSheet finalize '
      'phase=${SchedulerBinding.instance.schedulerPhase}',
    );
    codeController.dispose();
    if (accepted == true) {
      store.loadCloudData().then((_) {
        debugLog('showAcceptInviteSheet loadCloudData done');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('共有スペースに参加しました。')),
          );
        }
      });
    }
  }

  final anim = sheetAnimation;
  if (anim == null || anim.status == AnimationStatus.dismissed) {
    finalizeAcceptSheet();
  } else {
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        finalizeAcceptSheet();
      }
    }
    anim.addStatusListener(onStatus);
  }
}

String inviteErrorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => '招待コードを確認できませんでした。コードが正しいか、招待が有効か確認してください。',
      'invalid-argument' => '招待コードの形式を確認してください。',
      _ => '招待コードを確認できませんでした。${error.code}',
    };
  }
  return '招待コードを確認できませんでした。';
}

Future<void> showThemeSheet(BuildContext context, AppStore store) async {
  var isProcessing = false;

  final selected = await showModalBottomSheet<AppThemePreset>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return FractionallySizedBox(
            heightFactor: 0.75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetTitle(title: 'テーマカラー'),
                  const Text('アプリ全体の雰囲気を選べます。'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...themePresets.map(
                              (theme) => _ThemePresetTile(
                                theme: theme,
                                selected: store.selectedTheme.id == theme.id,
                                onTap: isProcessing
                                    ? null
                                    : () {
                                        setSheetState(() => isProcessing = true);
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            Navigator.pop(context, theme);
                                          }
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  if (selected != null) {
    store.selectTheme(selected);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${product.storeName} / ${weekdayText(product.saleDays)}',
        ),
        trailing: Text(formatYen(product.acceptablePrice)),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.record});

  final PurchaseRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(record.productName),
        subtitle: Text(
          '${record.storeName} / ${record.purchasedAt.month}/${record.purchasedAt.day}',
        ),
        trailing: Text(formatYen(record.price)),
      ),
    );
  }
}

class _ViewTitle extends StatelessWidget {
  const _ViewTitle({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset theme;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _ColorSwatch(color: theme.seedColor),
      title: Text(theme.name),
      subtitle: Text(theme.description),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ─── Legal screens ───────────────────────────────────────────────────────────

class _LegalSection {
  const _LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}

class _LegalView extends StatelessWidget {
  const _LegalView({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '最終更新日: $lastUpdated',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final section = sections[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.heading,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(section.body, style: textTheme.bodyMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _termsOfService = [
  _LegalSection(
    heading: '第1条（適用）',
    body:
        '本利用規約（以下「本規約」）は、okstore（以下「当社」）が提供するスマートフォンアプリ「PriceMate」（以下「本サービス」）の利用条件を定めるものです。ユーザーの皆さまには、本規約に従って本サービスをご利用いただきます。',
  ),
  _LegalSection(
    heading: '第2条（利用登録）',
    body:
        '本サービスの利用を希望する方は、本規約に同意のうえ、当社の定める方法により利用登録を申請してください。当社が登録を承認した時点で、利用登録が完了するものとします。当社は、以下の場合に利用登録の申請を承認しないことがあります。\n\n・登録申請に虚偽の事項を届け出た場合\n・本規約に違反したことがある者からの申請である場合\n・その他、当社が利用登録を相当でないと判断した場合',
  ),
  _LegalSection(
    heading: '第3条（禁止事項）',
    body:
        'ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。\n\n・法令または公序良俗に違反する行為\n・犯罪行為に関連する行為\n・当社または第三者の知的財産権、肖像権、プライバシー等を侵害する行為\n・当社または第三者のサーバーやネットワークの機能を破壊・妨害する行為\n・本サービスの運営を妨害するおそれのある行為\n・他のユーザーに関する個人情報等を収集または蓄積する行為\n・不正アクセスをし、またはこれを試みる行為\n・その他、当社が不適切と判断する行為',
  ),
  _LegalSection(
    heading: '第4条（本サービスの提供の停止等）',
    body:
        '当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。\n\n・本サービスにかかるコンピュータシステムの保守点検または更新を行う場合\n・地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合\n・コンピュータまたは通信回線等が事故により停止した場合\n・その他、当社が本サービスの提供が困難と判断した場合',
  ),
  _LegalSection(
    heading: '第5条（免責事項）',
    body:
        '当社の債務不履行責任は、当社の故意または重過失によらない場合には免責されるものとします。本サービスに関して、ユーザーと他のユーザーまたは第三者との間において生じた取引、連絡または紛争等については、当社は一切責任を負いません。',
  ),
  _LegalSection(
    heading: '第6条（利用規約の変更）',
    body:
        '当社は必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。なお、本規約の変更後、本サービスの利用を開始した場合には、当該ユーザーは変更後の規約に同意したものとみなします。',
  ),
  _LegalSection(
    heading: '第7条（準拠法・裁判管轄）',
    body:
        '本規約の解釈にあたっては、日本法を準拠法とします。本サービスに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。',
  ),
];

const _privacyPolicy = [
  _LegalSection(
    heading: '収集する情報',
    body:
        '当社は、本サービスの提供にあたり、以下の情報を収集することがあります。\n\n・氏名、メールアドレス等の登録情報\n・本サービスの利用に関するログ情報（アクセス日時、使用機能など）\n・デバイス情報（機種名、OSバージョンなど）\n・ユーザーが入力した商品情報・価格情報・購入記録',
  ),
  _LegalSection(
    heading: '情報の利用目的',
    body:
        '収集した情報は、以下の目的のために利用します。\n\n・本サービスの提供・運営・改善\n・ユーザーからのお問い合わせへの対応\n・利用規約に違反するユーザーの特定および利用停止\n・本サービスに関するお知らせの送信\n・その他、本サービスの運営上必要な業務',
  ),
  _LegalSection(
    heading: '第三者への情報提供',
    body:
        '当社は、以下の場合を除き、個人情報を第三者に提供することはありません。\n\n・ユーザーの同意がある場合\n・法令に基づき開示が必要な場合\n・人の生命、身体または財産の保護のために必要がある場合\n・国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合',
  ),
  _LegalSection(
    heading: 'データの保管と保護',
    body:
        '当社は、収集した個人情報をGoogle Firebaseのサービスを通じて保管します。不正アクセス・紛失・破損・改ざんなどのリスクに対して、適切なセキュリティ対策を講じています。ただし、インターネット上での完全な安全性を保証することはできません。',
  ),
  _LegalSection(
    heading: 'Cookieについて',
    body:
        '本サービスでは、サービスの向上を目的として、ユーザーの利用状況を把握するための情報収集ツールを使用する場合があります。これらはサービス改善にのみ使用し、個人を特定する目的では使用しません。',
  ),
  _LegalSection(
    heading: 'ユーザーの権利',
    body:
        'ユーザーは、当社が保有する自己の個人情報について、開示・訂正・削除・利用停止を請求することができます。お問い合わせは、設定画面に記載のメールアドレスまでご連絡ください。',
  ),
  _LegalSection(
    heading: 'プライバシーポリシーの変更',
    body:
        '当社は、必要に応じて本プライバシーポリシーを改定することがあります。重要な変更がある場合は、アプリ内またはその他適切な方法でお知らせします。変更後も本サービスを継続して利用された場合は、改定後のポリシーに同意したものとみなします。',
  ),
  _LegalSection(
    heading: 'お問い合わせ',
    body: '個人情報の取り扱いに関するお問い合わせは、以下までご連絡ください。\n\nokstore\nメール: support@okstore.example.com',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

String formatYen(int value) => '¥$value';

String weekdayText(Set<int> days) {
  if (days.isEmpty) return '特売日未設定';
  final sorted = days.toList()..sort();
  return sorted.map((day) => weekdayLabels[day - 1]).join('・');
}
