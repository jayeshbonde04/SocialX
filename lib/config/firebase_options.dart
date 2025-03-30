import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAwnZRMTRevlzQyTUqocsWhVcr4X0pgmnM',
    appId: '1:252809563846:android:4f27c29959bd24b70951c7',
    messagingSenderId: '252809563846',
    projectId: 'socialx-3d0c9',
    storageBucket: 'socialx-3d0c9.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCwZ5kz-VJc5Y4Q_Em5x9D0fD9Zx9PY8qQ",
    appId: "1:252809563846:web:4f27c29959bd24b70951c7",
    messagingSenderId: "252809563846",
    projectId: "socialx-3d0c9",
    authDomain: "socialx-3d0c9.firebaseapp.com",
    storageBucket: "socialx-3d0c9.appspot.com",
  );
}
