// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyCGF6dFVrs8S776f4IVVz6FMcPsVr1RiN4',
    appId: '1:28449054287:web:90866f08e32e437a16143a',
    messagingSenderId: '28449054287',
    projectId: 'courtly-949ac',
    authDomain: 'courtly-949ac.firebaseapp.com',
    storageBucket: 'courtly-949ac.firebasestorage.app',
    measurementId: 'G-9LELVJEHNR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWe1VBzhxNb5ljn-LVX52d4hXLiWXu3jw',
    appId: '1:28449054287:android:fc52b9cc513abe1316143a',
    messagingSenderId: '28449054287',
    projectId: 'courtly-949ac',
    storageBucket: 'courtly-949ac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDf-9MTqknV6KMLnu4zr010BqGlZ3XUx5o',
    appId: '1:28449054287:ios:b09d647165725da216143a',
    messagingSenderId: '28449054287',
    projectId: 'courtly-949ac',
    storageBucket: 'courtly-949ac.firebasestorage.app',
    iosBundleId: 'com.example.courtly',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDf-9MTqknV6KMLnu4zr010BqGlZ3XUx5o',
    appId: '1:28449054287:ios:b09d647165725da216143a',
    messagingSenderId: '28449054287',
    projectId: 'courtly-949ac',
    storageBucket: 'courtly-949ac.firebasestorage.app',
    iosBundleId: 'com.example.courtly',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCGF6dFVrs8S776f4IVVz6FMcPsVr1RiN4',
    appId: '1:28449054287:web:4ce3c258b53964dd16143a',
    messagingSenderId: '28449054287',
    projectId: 'courtly-949ac',
    authDomain: 'courtly-949ac.firebaseapp.com',
    storageBucket: 'courtly-949ac.firebasestorage.app',
    measurementId: 'G-RS9BSEGK26',
  );
}
