// TODO: Generate this file using FlutterFire CLI
// Run: `flutterfire configure --project=your-project-id`
// Or configure manually with your Firebase project settings

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Helper to determine if running on web
const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

// Helper to get target platform at runtime
TargetPlatform get defaultTargetPlatform {
  if (kIsWeb) return TargetPlatform.android; // Default for web
  if (Platform.isAndroid) return TargetPlatform.android;
  if (Platform.isIOS) return TargetPlatform.iOS;
  if (Platform.isMacOS) return TargetPlatform.macOS;
  if (Platform.isWindows) return TargetPlatform.windows;
  if (Platform.isLinux) return TargetPlatform.linux;
  throw UnsupportedError('Unknown platform');
}

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAB7IHYNGUoaJqiudhlraUo1a-IFzpJ-Ws',
    appId: '1:732904051672:web:74d080cd0f4744911218ad',
    messagingSenderId: '732904051672',
    projectId: 'kaheet-aea21',
    authDomain: 'kaheet-aea21.firebaseapp.com',
    storageBucket: 'kaheet-aea21.firebasestorage.app',
    measurementId: null,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAB7IHYNGUoaJqiudhlraUo1a-IFzpJ-Ws',
    appId: '1:732904051672:android:74d080cd0f4744911218ad',
    messagingSenderId: '732904051672',
    projectId: 'kaheet-aea21',
    storageBucket: 'kaheet-aea21.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAkUcczWAbOKDpLkWDSYrHndtMG8FfxBd8',
    appId: '1:732904051672:ios:d490fb1f3902ee3b1218ad',
    messagingSenderId: '732904051672',
    projectId: 'kaheet-aea21',
    storageBucket: 'kaheet-aea21.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAkUcczWAbOKDpLkWDSYrHndtMG8FfxBd8',
    appId: '1:732904051672:ios:d490fb1f3902ee3b1218ad',
    messagingSenderId: '732904051672',
    projectId: 'kaheet-aea21',
    storageBucket: 'kaheet-aea21.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
