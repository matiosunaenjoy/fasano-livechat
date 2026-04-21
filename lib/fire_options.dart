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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('Plataforma no soportada');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBRSWTEWcOK07e_6LaX8RpjwAhyZMUrj2M',
    appId: '1:278029831412:web:3ddd732fd4726dfb3f62a1',
    messagingSenderId: '278029831412',
    projectId: 'empresa-chat-2b2a7',
    authDomain: 'empresa-chat-2b2a7.firebaseapp.com',
    storageBucket: 'empresa-chat-2b2a7.firebasestorage.app',
    measurementId: 'G-TLDWC5DS9G',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_ANDROID',
    appId: 'TU_APP_ID_ANDROID',
    messagingSenderId: '278029831412',
    projectId: 'empresa-chat-2b2a7',
    storageBucket: 'empresa-chat-2b2a7.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'TU_API_KEY_WINDOWS',
    appId: 'TU_APP_ID_WINDOWS',
    messagingSenderId: '278029831412',
    projectId: 'empresa-chat-2b2a7',
    storageBucket: 'empresa-chat-2b2a7.firebasestorage.app',
  );
}
