# Firebase App Distribution

Owner-provided tester release:

https://appdistribution.firebase.google.com/testerapps/1:933394961865:android:0242853e91b8ef28100418/releases/4k5a5lfmsncvg?utm_source=firebase-console

Android app ID: `1:933394961865:android:0242853e91b8ef28100418`.
Project number: `933394961865`.

The drawer links directly to this release; `web/install.html` gives matching instructions. Update both URLs when the owner supplies a new release or enrollment link. A release link does not grant access: testers may need a Google account and an accepted invitation. To let anyone enroll, the Firebase project owner can create an invitation link under App Distribution → Testers & Groups → Invite links, then share that link. Do not label the release URL as unrestricted enrollment.

`adminnovik@gmail.com` is the feedback contact. It has not been added as a tester by these code changes. Inviting it requires authenticated access to this Firebase project.

Meku launcher resources are already in Android/iOS/web. Updating the binary in Firebase requires a fresh Android build, signing compatible with the existing installed app, and an authenticated upload to this app ID. No usable Firebase CLI session/service-account configuration or configured Android SDK is available in the current environment; compatibility with the existing APK signing key has not been verified. A tester download URL does not provide upload/admin access. Do not upload a differently signed debug APK as an update or claim that GitHub Pages deployment updates this release.
