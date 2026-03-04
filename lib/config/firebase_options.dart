import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    if (Platform.isMacOS) return macos;
    if (Platform.isWindows) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for Windows.',
      );
    }
    if (Platform.isLinux) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for Linux.',
      );
    }
    throw UnsupportedError('Unknown platform');
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_WEB_API_KEY'),
    appId: dotenv.get('FIREBASE_WEB_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_WEB_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_WEB_PROJECT_ID'),
    authDomain: dotenv.get('FIREBASE_WEB_AUTH_DOMAIN'),
    storageBucket: dotenv.get('FIREBASE_WEB_STORAGE_BUCKET'),
    measurementId: dotenv.get('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_ANDROID_API_KEY'),
    appId: dotenv.get('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_ANDROID_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_ANDROID_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_ANDROID_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_IOS_API_KEY'),
    appId: dotenv.get('FIREBASE_IOS_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_IOS_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_IOS_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_IOS_STORAGE_BUCKET'),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_IOS_API_KEY'),
    appId: dotenv.get('FIREBASE_IOS_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_IOS_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_IOS_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_IOS_STORAGE_BUCKET'),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
  );
}
