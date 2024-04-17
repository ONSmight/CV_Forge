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
    apiKey: 'AIzaSyCaxnPjuGpPL6n6YKBG5zoEDOjuSI72KMo',
    appId: '1:419872690422:web:639363ec2055cfdb25dcd7',
    messagingSenderId: '419872690422',
    projectId: 'cv-forge',
    authDomain: 'cv-forge.firebaseapp.com',
    storageBucket: 'cv-forge.appspot.com',
    measurementId: 'G-WQGQFNGNQJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCli3hVS-h7WbrdpiUpA86mFxLtLyPiDRg',
    appId: '1:419872690422:android:11396b18a1ecf37625dcd7',
    messagingSenderId: '419872690422',
    projectId: 'cv-forge',
    storageBucket: 'cv-forge.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCVWcG21t4_8xlsPS7-BVg4W6qvDCYwWHc',
    appId: '1:419872690422:ios:ccfed9dcba3ae36525dcd7',
    messagingSenderId: '419872690422',
    projectId: 'cv-forge',
    storageBucket: 'cv-forge.appspot.com',
    iosBundleId: 'com.example.loginSignup',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCVWcG21t4_8xlsPS7-BVg4W6qvDCYwWHc',
    appId: '1:419872690422:ios:3867be2b3d2a820925dcd7',
    messagingSenderId: '419872690422',
    projectId: 'cv-forge',
    storageBucket: 'cv-forge.appspot.com',
    iosBundleId: 'com.example.authFirebase',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCaxnPjuGpPL6n6YKBG5zoEDOjuSI72KMo',
    appId: '1:419872690422:web:d02054f8969033ff25dcd7',
    messagingSenderId: '419872690422',
    projectId: 'cv-forge',
    authDomain: 'cv-forge.firebaseapp.com',
    storageBucket: 'cv-forge.appspot.com',
    measurementId: 'G-FP977NB9VV',
  );
}
