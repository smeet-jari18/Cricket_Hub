// ⚠️⚠️  PLACEHOLDER FILE — READ THIS BEFORE FILING A BUG  ⚠️⚠️
//
// Ye example repo me committed hai. `.gitignore` `lib/firebase_options.dart`
// ko ignore karta hai — asli file wahan rakhiye, ise copy karke:
//   cp lib/firebase_options.example.dart lib/firebase_options.dart
//
// ya `dart run tools/sync_firebase_options.dart` chala ke asli values bhar dijiye.
// Jo aap dekh rahe ho wo ek PLACEHOLDER hai, sirf isliye ki `flutter analyze` /
// `flutter test` / emulator build chal sake. Iska `apiKey` jhoota hai:
//
//     AIzaSyPLACEHOLDER-replace-with-flutterfire-configure
//
// ⚠️  Agar aapne zip extract kiya aur aapki machine pe PEHLE SE ek asli
//     `firebase_options.dart` thi, to zip ne usko is placeholder se OVERWRITE
//     kar diya hoga. Isi wajah se Android pe ye crash aata tha:
//
//         [core/duplicate-app] A Firebase App named "[DEFAULT]" already exists
//
//     Kyun? `google-services.json` + google-services Gradle plugin pehle se
//     `[DEFAULT]` app bana dete hain ASLI apiKey ke saath. Phir ye file ki
//     placeholder apiKey se dobara banane par options match nahi karte →
//     crash. Ab `lib/core/firebase_bootstrap.dart` us native app ko adopt kar
//     leta hai, isliye crash nahi hoga — par ASLI fix ye hai:
//
//         flutterfire configure --project=crickethub-dev
//
//     (Ya Firebase Console → Project settings → Your apps → config se ek asli
//     file banao — repo mein commit mat karna.)
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:208815142654:web:bb6f73d5be5bf3864ed7af',
    messagingSenderId: '208815142654',
    projectId: 'crickethub-dev',
    authDomain: 'crickethub-dev.firebaseapp.com',
    storageBucket: 'crickethub-dev.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:208815142654:android:3da0201cbddafbcf4ed7af',
    messagingSenderId: '208815142654',
    projectId: 'crickethub-dev',
    storageBucket: 'crickethub-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:208815142654:ios:32a84edf95e89f734ed7af',
    messagingSenderId: '208815142654',
    projectId: 'crickethub-dev',
    storageBucket: 'crickethub-dev.firebasestorage.app',
    iosBundleId: 'com.example.cricketHub',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:208815142654:ios:32a84edf95e89f734ed7af',
    messagingSenderId: '208815142654',
    projectId: 'crickethub-dev',
    storageBucket: 'crickethub-dev.firebasestorage.app',
    iosBundleId: 'com.example.cricketHub',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:208815142654:web:46a91da5916b4efd4ed7af',
    messagingSenderId: '208815142654',
    projectId: 'crickethub-dev',
    authDomain: 'crickethub-dev.firebaseapp.com',
    storageBucket: 'crickethub-dev.firebasestorage.app',
  );
}
