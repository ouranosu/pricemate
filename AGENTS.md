# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (connected device or emulator required)
flutter run

# Run with Firebase disabled (local UI testing)
# Set useFirebase: false in PriceMateApp constructor in main.dart

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Regenerate firebase_options.dart after Firebase config changes
flutterfire configure
```

No tests exist yet — `flutter test` runs nothing.

## Architecture

**Everything lives in `lib/main.dart`** — the entire app is a single file. There is no separate routing, state management library, or feature directory. When this grows, split by feature into `lib/features/<name>/`.

### State Management

`AppStore extends ChangeNotifier` is the single source of truth. It holds in-memory lists (`products`, `shoppingItems`, `purchaseRecords`) and writes to Firestore on every mutation. `PriceMateApp` wraps the whole widget tree in an `AnimatedBuilder(animation: store)` to rebuild on changes.

Data is loaded once at login via `AppStore.connectUser()` → `loadCloudData()`. There are no real-time Firestore listeners; the app does a one-shot fetch and keeps the local list authoritative. This means concurrent edits from other family members are not reflected until re-login.

### Auth + Navigation Flow

The navigation stack is entirely driven by state in `_PriceMateAppState`:

```
SplashView (1.2 s)
  → OnboardingView (shown once, gated by SharedPreferences 'onboardingDone')
    → LoginView (gated by FirebaseAuth.authStateChanges stream)
      → PriceMateShell (5-tab UI)
```

Google Sign-In uses `google_sign_in ^7.2.0` with the new singleton API (`GoogleSignIn.instance`). The flow in `signInWithGoogle()`:
1. `GoogleSignIn.instance.signOut()` — clear stale session
2. `GoogleSignIn.instance.authenticate()` — shows account picker, returns `GoogleSignInAccount`
3. `googleUser.authentication.idToken` — get ID token (synchronous in v7)
4. `GoogleAuthProvider.credential(idToken:)` → `FirebaseAuth.signInWithCredential()`

### Firebase / Firestore

Firebase project: **priceshare-98812**  
Android package: `com.okstore.pricemate`

Firestore data shape (see `firestore.rules` for access control):
```
users/{userId}
sharedSpaces/{spaceId}
sharedSpaces/{spaceId}/members/{userId}
sharedSpaces/{spaceId}/products/{productId}
sharedSpaces/{spaceId}/shoppingItems/{itemId}
sharedSpaces/{spaceId}/purchaseRecords/{recordId}
invites/{inviteId}   ← 8-char uppercase codes, 7-day TTL
```

`AppStore.connectUser()` creates the user doc and a default shared space (keyed to `userId`) on first login. `acceptInviteCode()` switches the user's `activeSpaceId` to join another family's space.

### Critical: Android SHA-1 for Google Sign-In

`google-services.json` contains an Android OAuth client entry with a `certificate_hash` (SHA-1). **This must match the SHA-1 of the signing key in use.** For debug builds, each developer machine has a unique debug keystore at `~/.android/debug.keystore`. If it doesn't match what's in Firebase Console, Google Sign-In will fail silently after the account picker closes.

To add your debug SHA-1:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Then add the SHA-1 (and SHA-256) in Firebase Console → Project settings → Android app → Add fingerprint, and re-download `google-services.json`.

### Theme System

`AppThemePreset` defines 5 seed-color themes stored in `themePresets`. `AppStore.selectTheme()` updates `selectedTheme` and notifies listeners. Theme preference is in-memory only (not persisted to SharedPreferences or Firestore yet).
