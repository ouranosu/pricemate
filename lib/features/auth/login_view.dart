import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.onEmailLogin,
    required this.onCreateAccount,
    required this.onGoogleLogin,
    this.onAppleLogin,
    this.onReviewLogin,
  });

  final Future<void> Function(String email, String password) onEmailLogin;
  final Future<void> Function(String email, String password) onCreateAccount;
  final Future<void> Function() onGoogleLogin;
  final Future<void> Function()? onAppleLogin;
  final Future<void> Function()? onReviewLogin;

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
              if (Platform.isIOS && widget.onAppleLogin != null) ...[
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: loading,
                  child: SignInWithAppleButton(
                    onPressed: () => runAuthAction(widget.onAppleLogin!),
                    style: Theme.of(context).brightness == Brightness.dark
                        ? SignInWithAppleButtonStyle.white
                        : SignInWithAppleButtonStyle.black,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ],
              TextButton(
                onPressed: loading ? null : resetPassword,
                child: const Text('パスワードを忘れた方はこちら'),
              ),
            ],
            if (loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (widget.onReviewLogin != null) ...[
              const Divider(height: 40),
              TextButton(
                onPressed: loading
                    ? null
                    : () => runAuthAction(widget.onReviewLogin!),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('審査担当者の方はこちら'),
              ),
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

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メールアドレスを入力してからタップしてください')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('パスワードリセットメールを送信しました')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('送信に失敗しました。$error')));
    }
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
    } on SignInWithAppleAuthorizationException catch (error) {
      debugPrint(
        'AppleSignInException: code=${error.code}, message=${error.message}',
      );
      if (error.code != AuthorizationErrorCode.canceled) {
        setState(
          () => errorMessage = 'Appleログインに失敗しました。${error.message}',
        );
      }
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
