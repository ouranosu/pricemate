import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(serverClientId: googleServerClientId);
  runApp(const PriceMateApp());
}

const googleServerClientId =
    '734452752206-im65vqqdfoq4clcs0nf6uja0264jku1q.apps.googleusercontent.com';

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
    loadOnboardingState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => showSplash = false);
    });
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
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final theme = store.selectedTheme;

        return MaterialApp(
          title: 'PriceMate',
          debugShowCheckedModeBanner: false,
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
          if (user == null) {
            return LoginView(
              onEmailLogin: signInWithEmail,
              onCreateAccount: createAccountWithEmail,
              onGoogleLogin: signInWithGoogle,
            );
          }

          store.connectUser(user);
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
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
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
        message: '招待リンクで共有スペースに参加し、同じ商品リストと買い物リストを使えます。',
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
      setState(() => errorMessage = authErrorMessage(error));
    } on GoogleSignInException catch (error) {
      setState(() => errorMessage = googleSignInErrorMessage(error));
    } catch (error) {
      setState(() => errorMessage = 'ログインに失敗しました。もう一度お試しください。');
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
      'Googleログインが完了しませんでした。アカウント選択後に出る場合は、FirebaseのAndroid SHA設定とgoogle-services.jsonを確認してください。',
    GoogleSignInExceptionCode.clientConfigurationError =>
      'Googleログイン設定が未完了です。FirebaseにAndroidのSHA-1/SHA-256を登録し、google-services.jsonを更新してください。',
    GoogleSignInExceptionCode.providerConfigurationError =>
      'Googleログインのプロバイダ設定を確認してください。',
    GoogleSignInExceptionCode.uiUnavailable => 'Googleログイン画面を表示できませんでした。',
    _ => 'Googleログインに失敗しました。${error.description ?? error.code.name}',
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
  AppThemePreset selectedTheme = themePresets.first;
  String? activeUserId;
  String? activeSpaceId;
  bool _connecting = false;

  final List<Product> products = [
    Product(
      id: 'p1',
      name: '牛乳',
      storeName: 'スーパー青葉',
      size: '1L',
      bestPrice: 178,
      acceptablePrice: 218,
      saleDays: {1, 4},
      memo: '成分無調整を優先',
    ),
    Product(
      id: 'p2',
      name: '卵',
      storeName: 'まいにち市場',
      size: '10個入り',
      bestPrice: 198,
      acceptablePrice: 248,
      saleDays: {2},
    ),
  ];

  final List<ShoppingItem> shoppingItems = [
    ShoppingItem(id: 's1', name: '牛乳', urgency: Urgency.now),
    ShoppingItem(id: 's2', name: '食器用洗剤', urgency: Urgency.later),
  ];

  final List<PurchaseRecord> purchaseRecords = [
    PurchaseRecord(
      id: 'r1',
      productName: '牛乳',
      storeName: 'スーパー青葉',
      price: 188,
      purchasedAt: DateTime.now().subtract(const Duration(days: 2)),
      source: 'manual',
    ),
  ];

  int _nextId = 10;

  String get _id => '${DateTime.now().millisecondsSinceEpoch}-${_nextId++}';

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
    if (_connecting || activeUserId == user.uid) return;
    _connecting = true;

    try {
      activeUserId = user.uid;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();
      activeSpaceId =
          userSnapshot.data()?['activeSpaceId'] as String? ?? user.uid;

      await userRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'activeSpaceId': activeSpaceId,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final spaceRef = firestore.collection('sharedSpaces').doc(activeSpaceId);
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

      await loadCloudData();
    } finally {
      _connecting = false;
    }
  }

  Future<String> createInviteCode() async {
    if (activeUserId == null || activeSpaceId == null) {
      throw StateError('ログインが必要です。');
    }

    final code = _newInviteCode();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('ログインが必要です。');
    }

    final normalizedCode = code.trim().toUpperCase();
    final inviteRef = FirebaseFirestore.instance
        .collection('invites')
        .doc(normalizedCode);
    final inviteSnapshot = await inviteRef.get();
    if (!inviteSnapshot.exists) {
      throw StateError('招待コードが見つかりません。');
    }

    final invite = inviteSnapshot.data()!;
    final expiresAt = invite['expiresAt'];
    if (invite['status'] != 'active' ||
        (expiresAt is Timestamp &&
            expiresAt.toDate().isBefore(DateTime.now()))) {
      throw StateError('この招待コードは期限切れです。');
    }

    final spaceId = invite['spaceId'] as String;
    await FirebaseFirestore.instance
        .collection('sharedSpaces')
        .doc(spaceId)
        .collection('members')
        .doc(user.uid)
        .set({
          'role': 'member',
          'displayName': user.displayName ?? user.email ?? 'メンバー',
          'inviteId': normalizedCode,
          'joinedAt': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'activeSpaceId': spaceId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    activeUserId = user.uid;
    activeSpaceId = spaceId;
    await loadCloudData();
  }

  String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void clearCloudSession() {
    activeUserId = null;
    activeSpaceId = null;
  }

  Future<void> loadCloudData() async {
    if (activeSpaceId == null) return;

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
    notifyListeners();
  }

  void selectTheme(AppThemePreset theme) {
    selectedTheme = theme;
    notifyListeners();
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
      products[index] = savedProduct;
    }
    if (activeSpaceId != null) {
      _productsRef.doc(savedProduct.id).set(productToMap(savedProduct));
    }
    notifyListeners();
  }

  void deleteProduct(Product product) {
    products.removeWhere((item) => item.id == product.id);
    if (activeSpaceId != null) {
      _productsRef.doc(product.id).delete();
    }
    notifyListeners();
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
      shoppingItems[index] = savedItem;
    }
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(savedItem.id).set(shoppingItemToMap(savedItem));
    }
    notifyListeners();
  }

  void toggleShoppingItem(ShoppingItem item) {
    final index = shoppingItems.indexWhere((entry) => entry.id == item.id);
    final updatedItem = item.copyWith(checked: !item.checked);
    shoppingItems[index] = updatedItem;
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(updatedItem.id).set(shoppingItemToMap(updatedItem));
    }
    notifyListeners();
  }

  void deleteShoppingItem(ShoppingItem item) {
    shoppingItems.removeWhere((entry) => entry.id == item.id);
    if (activeSpaceId != null) {
      _shoppingItemsRef.doc(item.id).delete();
    }
    notifyListeners();
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
    notifyListeners();
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
  Widget build(BuildContext context) {
    final store = widget.store;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pages = [
          HomeView(store: store),
          ShoppingListView(store: store),
          InputView(store: store),
          ProductListView(store: store),
          SettingsView(store: store, onLogout: widget.onLogout),
        ];
        final pageVersion = Object.hash(
          selectedIndex,
          store.products.length,
          store.shoppingItems.length,
          store.purchaseRecords.length,
        );

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
            child: KeyedSubtree(
              key: ValueKey(pageVersion),
              child: pages[selectedIndex],
            ),
          ),
          floatingActionButton: SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              tooltip: '入力',
              shape: const CircleBorder(),
              onPressed: () => setState(() => selectedIndex = 2),
              child: const Icon(Icons.add, size: 32),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
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
                  onTap: () => setState(() => selectedIndex = 0),
                ),
                _TabButton(
                  icon: Icons.checklist_outlined,
                  activeIcon: Icons.checklist,
                  label: '買い物',
                  active: selectedIndex == 1,
                  onTap: () => setState(() => selectedIndex = 1),
                ),
                const SizedBox(width: 72),
                _TabButton(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: '商品',
                  active: selectedIndex == 3,
                  onTap: () => setState(() => selectedIndex = 3),
                ),
                _TabButton(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: '設定',
                  active: selectedIndex == 4,
                  onTap: () => setState(() => selectedIndex = 4),
                ),
              ],
            ),
          ),
        );
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
              onDismissed: (_) => store.deleteShoppingItem(item),
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
              onDismissed: (_) => store.deleteProduct(product),
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
                onTap: () {},
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシーポリシー',
                onTap: () {},
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
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
                    onPressed: () {
                      store.upsertProduct(
                        product,
                        Product(
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
                        ),
                      );
                      Navigator.pop(context);
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
}

Future<void> showShoppingItemSheet(
  BuildContext context,
  AppStore store, {
  ShoppingItem? item,
}) async {
  final name = TextEditingController(text: item?.name ?? '');
  var urgency = item?.urgency ?? Urgency.now;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
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
                  onPressed: () {
                    store.upsertShoppingItem(
                      item,
                      ShoppingItem(
                        id: item?.id ?? 'new',
                        name: name.text.trim(),
                        urgency: urgency,
                        checked: item?.checked ?? false,
                      ),
                    );
                    Navigator.pop(context);
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
}

Future<void> showPurchaseSheet(
  BuildContext context,
  AppStore store, {
  Product? product,
}) async {
  final productName = TextEditingController(text: product?.name ?? '');
  final storeName = TextEditingController(text: product?.storeName ?? '');
  final price = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
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
              onPressed: () {
                store.addPurchaseRecord(
                  PurchaseRecord(
                    id: 'new',
                    productName: productName.text.trim(),
                    storeName: storeName.text.trim(),
                    price: int.tryParse(price.text) ?? 0,
                    purchasedAt: DateTime.now(),
                    source: 'manual',
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showInviteSheet(BuildContext context, AppStore store) async {
  String? inviteCode;
  String? errorMessage;
  var loading = false;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final inviteUrl = inviteCode == null
              ? null
              : 'https://pricemate.example.com/invite/$inviteCode';

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(inviteUrl!),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: inviteUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('招待リンクをコピーしました')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('招待リンクをコピー'),
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
                            final code = await store.createInviteCode();
                            setSheetState(() => inviteCode = code);
                          } catch (_) {
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
                      : const Icon(Icons.link),
                  label: Text(inviteCode == null ? '招待コードを作成' : '作り直す'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showAcceptInviteSheet(BuildContext context, AppStore store) async {
  final codeController = TextEditingController();
  String? errorMessage;
  var loading = false;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetTitle(title: '招待コードを入力'),
                const Text('家族から共有された8文字の招待コードを入力してください。'),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: '招待コード',
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
                  onPressed: loading
                      ? null
                      : () async {
                          setSheetState(() {
                            loading = true;
                            errorMessage = null;
                          });
                          try {
                            await store.acceptInviteCode(codeController.text);
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            setSheetState(() {
                              errorMessage = error is StateError
                                  ? error.message
                                  : '招待コードを確認できませんでした。';
                            });
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
                      : const Icon(Icons.login),
                  label: const Text('参加する'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  codeController.dispose();
}

Future<void> showThemeSheet(BuildContext context, AppStore store) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      return AnimatedBuilder(
        animation: store,
        builder: (context, _) {
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
                                onTap: () {
                                  store.selectTheme(theme);
                                  Navigator.pop(context);
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
  final VoidCallback onTap;

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

const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

String formatYen(int value) => '¥$value';

String weekdayText(Set<int> days) {
  if (days.isEmpty) return '特売日未設定';
  final sorted = days.toList()..sort();
  return sorted.map((day) => weekdayLabels[day - 1]).join('・');
}
