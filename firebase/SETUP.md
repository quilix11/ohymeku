# Firebase accounts for Ohymeku

The app uses Firebase Authentication and Firestore REST APIs. No admin key is shipped. Google sign-in uses the official Google Sign-In SDK on Android and Firebase Auth popup on web. Passwords go directly to Firebase over HTTPS; ID tokens
stay in memory and expire after at most one hour. Reopen/reload requires login.
Only the profile is synced. Learning progress, stories and words remain local.

1. In https://console.firebase.google.com create a project and register a Web app.
2. In Authentication → Sign-in method enable Email/Password. In Settings →
   Authorized domains add `quilix11.github.io` and your custom domain if used.
3. Create a Firestore database in production mode. Pick the region before creation.
   Review and publish `firebase/firestore.rules` using the Firestore Rules editor.
   Never enable public access. The rules require verified email to write profiles.
4. From Project settings → Your apps copy the public Web `apiKey` and `projectId`.
   In GitHub → repo Settings → Secrets and variables → Actions → Variables add
   `FIREBASE_API_KEY` and `FIREBASE_PROJECT_ID`. These are public client config,
   not service-account credentials. Restrict the API key to the needed Firebase
   APIs and your app using Google Cloud's supported application restrictions.
5. Run the Pages workflow. For local builds use:

   ```sh
   flutter run -d chrome --dart-define=FIREBASE_API_KEY=YOUR_WEB_API_KEY --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
   ```

6. Profile → Account: create account, request verification email, follow the email
   link, sign out and sign in again (refreshes email_verified), then upload profile.
   On a second device, sign in and explicitly download the profile. Nothing is
   silently overwritten. Nicknames are display names, not globally unique handles.

The UI clearly says accounts are not connected when config is absent. This repo
cannot create a Firebase project or change your billing without a connected Google
identity. Use Firebase's free limits, configure monitoring, and test the rules in
Firebase's Rules Playground before accepting real users.

## Google sign-in (Android and web)

Enable Google in Firebase Authentication. Android uses the OAuth client in
`android/app/google-services.json`; register every signing SHA-1 in Firebase
before downloading that file. The current test APK certificate is registered;
Play signing or another release keystore needs its own SHA-1. Google ID tokens
are exchanged for Firebase ID tokens with `accounts:signInWithIdp`. Only the
Firebase UID identifies the profile. Cancellation does not sign a user in.

Web uses Firebase Auth `signInWithPopup` with `Persistence.NONE`, then signs out
of the SDK after handing the short-lived token to AccountService. Public build
settings remain `FIREBASE_API_KEY` and `FIREBASE_PROJECT_ID`. For a different
project also set `FIREBASE_WEB_APP_ID` and `FIREBASE_MESSAGING_SENDER_ID` (defaults
are the registered ohymeku web app). Allow the hosting domain in Firebase Auth.
Popups must be allowed. Existing email-account conflicts require using the
existing method; this implementation does not silently link accounts.

Google login is offered on Android and web. iOS requires separate URL scheme,
client configuration, deployment-target setup and validation on macOS; it is
not enabled by this change. No token/password is stored in preferences. Profile
sync remains explicit, with the existing Firestore security rules.

The initial placement screen now supports skipping before or during the test.
Skipping only bypasses onboarding, keeps the current level, and never records a
score. Placement can be taken later from the profile.

Android uses Kotlin 2.4.21 and the compilerOptions DSL to match the Firebase Auth SDK metadata.
