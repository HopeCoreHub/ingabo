// File: firebase_options.dart
// Generated file for Firebase configuration

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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCTFtdjSnbAS7p1ZhWho0jrs80ToTgJnZw',
    appId: '1:73148402495:web:b3cfb82ee2c63ad8b2a18a',
    messagingSenderId: '73148402495',
    projectId: 'hopecore-hub',
    authDomain: 'hopecore-hub.firebaseapp.com',
    storageBucket: 'hopecore-hub.firebasestorage.app',
    databaseURL: 'https://hopecore-hub-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApTPIWlPLbsvzbPqdCsJRvrvjZFIVqTho',
    appId: '1:73148402495:android:47dde8627289a6dab2a18a',
    messagingSenderId: '73148402495',
    projectId: 'hopecore-hub',
    storageBucket: 'hopecore-hub.firebasestorage.app',
    databaseURL: 'https://hopecore-hub-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCik3Gp9FomhtdZgVlcgfJeyKEGevtRFoM',
    appId: '1:73148402495:ios:9db65c6487d5620db2a18a',
    messagingSenderId: '73148402495',
    projectId: 'hopecore-hub',
    storageBucket: 'hopecore-hub.firebasestorage.app',
    iosBundleId: 'com.ingabohopecore.hopecorehub',
    databaseURL: 'https://hopecore-hub-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCik3Gp9FomhtdZgVlcgfJeyKEGevtRFoM',
    appId: '1:73148402495:ios:9db65c6487d5620db2a18a',
    messagingSenderId: '73148402495',
    projectId: 'hopecore-hub',
    storageBucket: 'hopecore-hub.firebasestorage.app',
    iosBundleId: 'com.ingabohopecore.hopecorehub',
    databaseURL: 'https://hopecore-hub-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCTFtdjSnbAS7p1ZhWho0jrs80ToTgJnZw',
    appId: '1:73148402495:web:593fcec965fd1711b2a18a',
    messagingSenderId: '73148402495',
    projectId: 'hopecore-hub',
    authDomain: 'hopecore-hub.firebaseapp.com',
    storageBucket: 'hopecore-hub.firebasestorage.app',
    databaseURL: 'https://hopecore-hub-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCTFtdjSnbAS7p1ZhWho0jrs80ToTgJnZw',
    appId: '1:73148402495:web:593fcec965fd1711b2a18a',
    messagingSenderId: '73148402495',
    projectId: 'hopecore-hub',
    authDomain: 'hopecore-hub.firebaseapp.com',
    storageBucket: 'hopecore-hub.firebasestorage.app',
    databaseURL: 'https://hopecore-hub-default-rtdb.firebaseio.com',
  );
}
