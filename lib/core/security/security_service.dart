import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prijavko/core/security/aes_gcm_helper.dart';

class SecurityService {
  SecurityService();

  static const _keyName = 'prijavko_aes_gcm_key_v1';

  // WHY: The AES-GCM key is in `flutter_secure_storage` (Keystore-backed), not
  // Drift or SharedPreferences. `allowBackup=false` in AndroidManifest prevents
  // it leaving the device. The cookie jar and future Drift PII columns all derive
  // from this single key — one Keystore entry, one audit point.
  // WHY: Explicit AndroidOptions without encryptedSharedPreferences to ensure
  // Keystore-backed storage (not EncryptedSharedPreferences). The
  // encryptedSharedPreferences param was removed in v10 — the default path
  // uses Keystore-backed custom ciphers.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AesGcmHelper? _helper;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      throw StateError('SecurityService already initialized');
    }
    // WHY: Key is loaded once at startup — not lazily on first use — so any
    // flutter_secure_storage failure (Keystore unavailable, corrupt entry)
    // crashes visibly at launch rather than silently during a guest submission
    // at 2 AM. Jidoka: stop the line early.
    String? encoded = await _storage.read(key: _keyName);
    if (encoded == null) {
      // Hoist the SecureRandom instance — `Random.secure()` instantiates a
      // platform-channel SecureRandom (JNI on Android) per call. One instance
      // for all 32 bytes keeps the JNI hop count to 1.
      final secureRandom = Random.secure();
      final keyBytes = Uint8List.fromList(
        List.generate(32, (_) => secureRandom.nextInt(256)),
      );
      encoded = base64Encode(keyBytes);
      await _storage.write(key: _keyName, value: encoded);
    }
    final keyBytes = base64Decode(encoded);
    _helper = AesGcmHelper(keyBytes);
    _initialized = true;
  }

  AesGcmHelper get encryptionHelper {
    if (!_initialized || _helper == null) {
      throw StateError('SecurityService not initialized — call init() first');
    }
    return _helper!;
  }
}
