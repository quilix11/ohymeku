# Firebase accounts for Ohymeku

The app uses Firebase Authentication and Firestore REST APIs. No admin key or
Firebase SDK is shipped. Passwords go directly to Firebase over HTTPS; ID tokens
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
