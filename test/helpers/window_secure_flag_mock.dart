// Shared MethodChannel mock for `hr.prijavko.window_secure`. LoginScreen
// triggers FLAG_SECURE on init via the platform channel; widget tests must
// mock it or every test that mounts LoginScreen throws MissingPluginException.
//
// WHY one helper instead of duplicating in each test file: forgetting the
// tearDown in any one file leaks the mock into every subsequent test in the
// same isolate — the kind of cross-file flake that costs hours to debug.
// Centralising the contract makes the leak impossible (Poka-yoke).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('hr.prijavko.window_secure');

/// Installs a no-op mock handler for the FLAG_SECURE method channel. Call
/// from `setUp`. The matching `tearDownWindowSecureFlagMock` MUST run from
/// `tearDown` to avoid bleeding the mock into other test files.
void setUpWindowSecureFlagMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async => null);
}

void tearDownWindowSecureFlagMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, null);
}
