import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../l10n/app_localizations.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.onEmailLogin,
    required this.onCreateAccount,
    required this.onGoogleLogin,
    this.onAppleLogin,
    this.onReviewLogin,
    this.onGuestMode,
  });

  final Future<void> Function(String email, String password) onEmailLogin;
  final Future<void> Function(String email, String password) onCreateAccount;
  final Future<void> Function() onGoogleLogin;
  final Future<void> Function()? onAppleLogin;
  final Future<void> Function()? onReviewLogin;
  final Future<void> Function()? onGuestMode;

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
    final l10n = AppLocalizations.of(context)!;
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
              creatingAccount ? l10n.createAccountTitle : l10n.loginTitle,
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
              decoration: InputDecoration(
                labelText: l10n.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
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
              label: Text(
                creatingAccount ? l10n.createAccountBtn : l10n.loginWithEmail,
              ),
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
              child: Text(
                creatingAccount ? l10n.backToLogin : l10n.createAccountBtn,
              ),
            ),
            if (!creatingAccount) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () => runAuthAction(widget.onGoogleLogin),
                icon: const Icon(Icons.g_mobiledata),
                label: Text(l10n.loginWithGoogle),
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
                child: Text(l10n.forgotPassword),
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
            if (widget.onGuestMode != null) ...[
              const Divider(height: 40),
              TextButton(
                onPressed: loading ? null : () => _confirmGuestMode(context),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                child: Text(l10n.continueAsGuest),
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
    final l10n = AppLocalizations.of(context)!;
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterEmailFirst)));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordResetSent)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sendFailed(error.toString()))));
    }
  }

  Future<void> _confirmGuestMode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.guestModeWarningTitle),
        content: Text(l10n.guestModeWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.guestModeWarningConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await runAuthAction(widget.onGuestMode!);
  }

  Future<void> runAuthAction(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
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
      setState(() => errorMessage = authErrorMessage(error, l10n));
    } on GoogleSignInException catch (error) {
      debugPrint(
        'GoogleSignInException: code=${error.code.name}, '
        'description=${error.description}, details=${error.details}',
      );
      setState(() => errorMessage = googleSignInErrorMessage(error, l10n));
    } on SignInWithAppleAuthorizationException catch (error) {
      debugPrint(
        'AppleSignInException: code=${error.code}, message=${error.message}',
      );
      if (error.code != AuthorizationErrorCode.canceled) {
        setState(
          () => errorMessage = l10n.appleLoginFailed(error.message),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Auth error: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() => errorMessage = l10n.loginFailed(error.toString()));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}

String googleSignInErrorMessage(
  GoogleSignInException error,
  AppLocalizations l10n,
) {
  return switch (error.code) {
    GoogleSignInExceptionCode.canceled => l10n.googleErrCanceled,
    GoogleSignInExceptionCode.clientConfigurationError =>
      l10n.googleErrClientConfig,
    GoogleSignInExceptionCode.providerConfigurationError =>
      l10n.googleErrProviderConfig,
    GoogleSignInExceptionCode.uiUnavailable => l10n.googleErrUiUnavailable,
    _ => l10n.googleErrGeneric(error.code.name),
  };
}

String authErrorMessage(FirebaseAuthException error, AppLocalizations l10n) {
  return switch (error.code) {
    'invalid-email' => l10n.authErrInvalidEmail,
    'missing-password' => l10n.authErrMissingPw,
    'weak-password' => l10n.authErrWeakPw,
    'email-already-in-use' => l10n.authErrEmailInUse,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => l10n.authErrInvalidCred,
    'network-request-failed' => l10n.authErrNetwork,
    'popup-closed-by-user' || 'canceled' => l10n.authErrCanceled,
    _ => l10n.authErrGeneric(error.code),
  };
}
