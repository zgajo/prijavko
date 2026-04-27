// Unit tests for CapturePreferenceStore (AC7.4).
// Uses SharedPreferences.setMockInitialValues to avoid platform channels
// in the test VM — standard Flutter test pattern for shared_preferences.
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/capture/capture_preference.dart';
import 'package:prijavko/core/capture/capture_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences state between tests.
    SharedPreferences.setMockInitialValues({});
  });

  group('CapturePreferenceStore', () {
    test('default load returns manualOnly when no value is stored', () async {
      final store = CapturePreferenceStore();
      expect(await store.load(), CapturePreference.manualOnly);
    });

    test('save live then load returns live', () async {
      final store = CapturePreferenceStore();
      await store.save(CapturePreference.live);
      expect(await store.load(), CapturePreference.live);
    });

    test('save manualOnly then load returns manualOnly', () async {
      final store = CapturePreferenceStore();
      await store.save(CapturePreference.manualOnly);
      expect(await store.load(), CapturePreference.manualOnly);
    });
  });
}
