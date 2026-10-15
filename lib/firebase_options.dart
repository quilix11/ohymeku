// Firebase client configuration for project ohymeku.
// These public identifiers are not personal credentials or server secrets.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'Firebase is configured for Android, iOS and web only.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwPALRDMfFrr9yZRI_uVUjWCO86POvOkE',
    appId: '1:933394961865:web:7342ec08bec06f3b100418',
    messagingSenderId: '933394961865',
    projectId: 'ohymeku',
    authDomain: 'ohymeku.firebaseapp.com',
    storageBucket: 'ohymeku.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzQUwJT_RLdjYtuqq6p3JYfqb8xZvXDQE',
    appId: '1:933394961865:android:0242853e91b8ef28100418',
    messagingSenderId: '933394961865',
    projectId: 'ohymeku',
    storageBucket: 'ohymeku.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLuBVE9xQgOIFkWqh8bDUZ3xtibn412A8',
    appId: '1:933394961865:ios:095bbca892fc8ab8100418',
    messagingSenderId: '933394961865',
    projectId: 'ohymeku',
    storageBucket: 'ohymeku.firebasestorage.app',
    iosBundleId: 'com.dialectduel.dialectDuel',
  );
}
