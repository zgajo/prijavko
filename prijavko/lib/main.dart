import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e, stack) {
    debugPrint('Firebase.initializeApp failed: $e\n$stack');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'App failed to initialize. Check Firebase configuration '
              '(google-services.json).',
            ),
          ),
        ),
      ),
    );
    return;
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Analytics SDK without setting user identifiers or PII.
  FirebaseAnalytics.instance;

  runApp(const ProviderScope(child: PrijavkoApp()));
}
