// WHY SharedPreferences (not flutter_secure_storage): CapturePreference is a
// UX convenience flag, not a secret. Keystore-backed storage would add
// unnecessary init latency and platform-channel complexity for a boolean-
// equivalent value. SharedPreferences is Flutter-team first-party; already
// available. Same reasoning as CredentialStore's decision to use Keystore
// for actual credentials — inverse of it.
//
// WHY versioned key: mirrors CredentialStore pattern. If the enum shape ever
// changes (adding a third variant), a new key prefix forces a clean migration
// rather than silently mis-reading a stale integer.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'capture_preference.dart';

part 'capture_preference_store.g.dart';

const _kKey = 'prijavko_capture_preference_v1';

class CapturePreferenceStore {
  Future<void> save(CapturePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, preference.name);
  }

  // Defaults to manualOnly — safe fallback that never requires camera.
  Future<CapturePreference> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return CapturePreference.manualOnly;
    return CapturePreference.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CapturePreference.manualOnly,
    );
  }
}

@riverpod
CapturePreferenceStore capturePreferenceStore(Ref ref) =>
    CapturePreferenceStore();
