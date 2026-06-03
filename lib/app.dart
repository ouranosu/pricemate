import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';

import 'core/debug.dart';
import 'core/theme.dart';
import 'features/auth/login_view.dart';
import 'features/onboarding/language_view.dart';
import 'features/onboarding/loading_view.dart';
import 'features/onboarding/onboarding_view.dart';
import 'features/onboarding/splash_view.dart';
import 'review_mode.dart';
import 'store/app_store.dart';
import 'widgets/app_shell.dart';

class PriceMateApp extends StatefulWidget {
  const PriceMateApp({super.key, this.useFirebase = true});

  final bool useFirebase;

  @override
  State<PriceMateApp> createState() => _PriceMateAppState();
}

class _PriceMateAppState extends State<PriceMateApp> {
  final AppStore store = AppStore();
  late final ReviewModeStore _reviewStore;
  bool showSplash = true;
  bool onboardingLoaded = false;
  bool onboardingDone = false;
  bool languageDone = false;
  bool signedIn = false;
  bool _reviewMode = false;

  @override
  void initState() {
    super.initState();
    _reviewStore = ReviewModeStore();
    debugLog('PriceMateApp initState');
    loadOnboardingState();
    store.loadSavedTheme();
    store.loadSavedLocale();
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      debugLog('Splash finished');
      setState(() => showSplash = false);
    });
  }

  @override
  void dispose() {
    debugLog('PriceMateApp dispose');
    store.dispose();
    _reviewStore.dispose();
    super.dispose();
  }

  Future<void> _reviewLogout() async {
    _reviewStore.clearCloudSession();
    setState(() => _reviewMode = false);
  }

  Future<void> loadOnboardingState() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      onboardingDone = preferences.getBool('onboardingDone') ?? false;
      languageDone = preferences.getBool('languageDone') ?? false;
      onboardingLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePreset>(
      valueListenable: store.themeNotifier,
      builder: (context, theme, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: store.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'PriceMate',
              debugShowCheckedModeBanner: false,
              navigatorObservers: [debugNavigatorObserver],
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ja'),
                Locale('en'),
              ],
              themeMode: ThemeMode.system,
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
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.seedColor,
              brightness: Brightness.dark,
            ),
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
      },
    );
  }

  Widget _buildHome() {
    debugLog(
      'buildHome splash=$showSplash onboardingLoaded=$onboardingLoaded '
      'languageDone=$languageDone onboardingDone=$onboardingDone '
      'signedIn=$signedIn reviewMode=$_reviewMode',
    );
    if (showSplash || !onboardingLoaded) {
      return const SplashView();
    }
    if (!onboardingDone && !languageDone) {
      return LanguageView(onSelect: _completeLanguage);
    }
    if (!onboardingDone) {
      return OnboardingView(onComplete: completeOnboarding, store: store);
    }
    if (_reviewMode) {
      return PriceMateShell(store: _reviewStore, onLogout: _reviewLogout);
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
              onAppleLogin: signInWithApple,
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
        onAppleLogin: () async => setState(() => signedIn = true),
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

  Future<void> _completeLanguage(Locale? locale) async {
    if (locale != null) store.selectLocale(locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('languageDone', true);
    if (!mounted) return;
    setState(() => languageDone = true);
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

  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );

    await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    store.clearCloudSession();
    await FirebaseAuth.instance.signOut();
  }
}

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}

