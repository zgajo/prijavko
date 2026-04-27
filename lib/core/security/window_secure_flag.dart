// WHY: FLAG_SECURE prevents screenshots and app-switcher previews on
// screens displaying credentials, MRZ content, or guest PII (CLAUDE.md
// §Security & Privacy, NFR-S1). Exposed as a MethodChannel bridge so
// Flutter can toggle the flag at screen lifecycle boundaries.
//
// Reused by: LoginScreen (Story 1.7), scan/review screens (Story 4.x).

import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show immutable;

@immutable
class WindowSecureFlag {
  static const _channel = MethodChannel('hr.prijavko.window_secure');

  static Future<void> enable() => _channel.invokeMethod<void>('enable');
  static Future<void> disable() => _channel.invokeMethod<void>('disable');
}
