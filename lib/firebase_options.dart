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
    apiKey: 'AIzaSyDVcHjg-hmDpyMkhZUtRCUzdLlfRM7PTFk',
    appId: '1:11013988788:web:855a860e4d6e7bcb6752e1',
    messagingSenderId: '11013988788',
    projectId: 'lunchvote-dbce0',
    authDomain: 'lunchvote-dbce0.firebaseapp.com',
    storageBucket: 'lunchvote-dbce0.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAnynrEPOQwqT94MgzSkEVseU4mVPqvbBc',
    appId: '1:11013988788:ios:8c3d0c0e5be232c26752e1',
    messagingSenderId: '11013988788',
    projectId: 'lunchvote-dbce0',
    storageBucket: 'lunchvote-dbce0.firebasestorage.app',
    iosBundleId: 'com.example.lunchVote',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAnynrEPOQwqT94MgzSkEVseU4mVPqvbBc',
    appId: '1:11013988788:ios:8c3d0c0e5be232c26752e1',
    messagingSenderId: '11013988788',
    projectId: 'lunchvote-dbce0',
    storageBucket: 'lunchvote-dbce0.firebasestorage.app',
    iosBundleId: 'com.example.lunchVote',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqXHtMMfpj-lQU0diF8W4voKeesYAkO1Q',
    appId: '1:11013988788:android:8e1227239f2f847e6752e1',
    messagingSenderId: '11013988788',
    projectId: 'lunchvote-dbce0',
    storageBucket: 'lunchvote-dbce0.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDVcHjg-hmDpyMkhZUtRCUzdLlfRM7PTFk',
    appId: '1:11013988788:web:6c6becedd26b64476752e1',
    messagingSenderId: '11013988788',
    projectId: 'lunchvote-dbce0',
    authDomain: 'lunchvote-dbce0.firebaseapp.com',
    storageBucket: 'lunchvote-dbce0.firebasestorage.app',
  );

}