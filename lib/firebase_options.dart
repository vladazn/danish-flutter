import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Helper method to get environment variables for web
  static String _getWebEnvVar(String key) {
    if (kIsWeb) {
      // Try to get from JavaScript environment variables
      try {
        // This will be available after web/env.js is loaded
        if (js.context.hasProperty('env') && js.context['env'].hasProperty(key)) {
          return js.context['env'][key] as String;
        }
      } catch (e) {
        // Fallback to placeholder if JavaScript env is not available
      }
    }
    // Fallback to dotenv for mobile or if web env is not available
    return dotenv.env[key] ?? 'placeholder';
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _getWebEnvVar('FIREBASE_API_KEY'),
    appId: _getWebEnvVar('FIREBASE_APP_ID'),
    messagingSenderId: _getWebEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _getWebEnvVar('FIREBASE_PROJECT_ID'),
    storageBucket: _getWebEnvVar('FIREBASE_STORAGE_BUCKET'),
    authDomain: _getWebEnvVar('FIREBASE_AUTH_DOMAIN'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'placeholder',
    appId: dotenv.env['FIREBASE_APP_ID'] ?? 'placeholder',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'placeholder',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'placeholder',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'placeholder',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'placeholder',
    appId: dotenv.env['FIREBASE_APP_ID'] ?? 'placeholder',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'placeholder',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'placeholder',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'placeholder',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'placeholder',
  );
}
