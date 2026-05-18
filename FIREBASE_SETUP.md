# Firebase Setup Guide for ScrapChef

## Overview
Firebase integration is now partially complete. The app uses Firebase Authentication for user login and Firestore for saving recipes. This guide explains how to complete the setup.

## Completed Steps ✅
- Firebase dependencies added to `pubspec.yaml` (firebase_core, firebase_auth, cloud_firestore, connectivity_plus)
- Firebase Auth service created (`lib/src/services/firebase_auth_service.dart`)
- Firestore recipe storage service created (`lib/src/services/firebase_recipe_store.dart`)
- AppState updated to use Firebase services instead of local persistence
- LoginScreen updated to support email/password Firebase authentication with auto-signup on first login
- Firebase initialization added to `main()` before app launch

## Remaining Steps ⏳

### 1. Firebase Project Setup (One-time)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use an existing one
3. Enable these services:
   - **Authentication**: Email/Password sign-in method
   - **Firestore Database**: Create in any region (suggest `asia-southeast1`)

### 2. Android Configuration
Run the Firebase CLI command to auto-configure Android:
```bash
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android
```

This will:
- Download `google-services.json` and place it in `android/app/`
- Update `android/build.gradle.kts` with required plugins
- Generate properly formatted `firebase_options.dart`

### 3. iOS Configuration (Optional)
If building for iOS, run:
```bash
flutterfire configure --project=YOUR_PROJECT_ID --platforms=ios
```

This will:
- Download `GoogleService-Info.plist` and place it in `ios/Runner/`
- Generate iOS-specific Firebase configuration

### 4. Gemini API Key Configuration
The Gemini image classifier still requires an API key. To enable image scanning:

**For Development (Local Testing):**
```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

**For APK/iOS Build:**
```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
# or
flutter build ios --dart-define=GEMINI_API_KEY=your_api_key_here
```

Get your API key from [Google AI Studio](https://aistudio.google.com/apikey)

### 5. Firestore Security Rules (Optional but Recommended)
In Firebase Console, go to Firestore → Rules and paste:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - user can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Recipes subcollection - same auth requirement
      match /savedRecipes/{recipeId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

## Testing the Setup

1. **Test Firebase Auth:**
   - Run the app on a device or emulator
   - On the login screen, enter an email and password (6+ characters)
   - First login creates a new account; subsequent logins sign in

2. **Test Firestore Recipe Saving:**
   - After login, navigate to the Recipes tab
   - Tap the heart icon on any recipe to save it
   - Check Firestore Console: `users/{userId}/savedRecipes` should show the saved recipe

3. **Test Gemini Image Scanning:**
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_api_key
   ```
   - Navigate to the Scan tab
   - Take a photo of food waste
   - Confirm the predicted category

## File Structure
- `lib/firebase_options.dart` — Generated Firebase configuration (auto-updated by flutterfire)
- `lib/main.dart` — Now initializes Firebase before app launch
- `lib/src/services/firebase_auth_service.dart` — Wraps Firebase Auth operations
- `lib/src/services/firebase_recipe_store.dart` — Wraps Firestore recipe CRUD
- `lib/src/state/app_state.dart` — Updated to use Firebase services
- `lib/src/screens/login_screen.dart` — Now uses Firebase Auth

## Troubleshooting

**"Firebase app not initialized"**
- Ensure `firebase_options.dart` has valid credentials
- Run `flutterfire configure` to regenerate it

**"user-not-found" on first login**
- This is expected! The app auto-creates an account on first login attempt

**"weak-password" error**
- Use a password with at least 6 characters, preferably mixed case and numbers

**Recipes not saving**
- Check Firestore security rules
- Verify user is authenticated (`appState.isSignedIn` should be true)
- Check browser console in Firebase for any write errors

## Next Steps (Optional)
1. **Backend Proxy for Gemini** — Create a backend service to hide the Gemini API key
2. **Offline Support** — Add local caching with `connectivity_plus` to handle offline recipe access
3. **User Profile** — Add profile picture, bio, and recipe sharing features
4. **Social Features** — Share recipes, follow other users, rate recipes

---

**Questions?** Check the [Firebase Documentation](https://firebase.google.com/docs) or [FlutterFire Setup Guide](https://firebase.flutter.dev/docs/overview).
