// WHY: eVisitor uses 3 named cookies (authentication, affinity, language).
// AES-GCM-encrypted files provide the same threat model as the credentials
// in flutter_secure_storage. The Android Keystore key (loaded by SecurityService)
// encrypts both — one key, two storage surfaces.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:prijavko/core/security/aes_gcm_helper.dart';

class EncryptedStorage implements Storage {
  EncryptedStorage(this._directory, this._helper);

  final String _directory;
  final AesGcmHelper _helper;

  // WHY: PersistCookieJar's internals (cookie_jar 4.x) expect FileStorage-style
  // sub-paths keyed by the persistSession/ignoreExpires flags so cookies stored
  // under different flag combinations don't collide. Mimicking that layout
  // keeps EncryptedStorage drop-in compatible with PersistCookieJar even
  // though the spec showed a flat `directory.create()` — the flag-encoded
  // sub-path is the same convention FileStorage uses upstream.
  late String _currentDirectory;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    String baseDir = _directory.replaceAll('\\', '/');
    if (!baseDir.endsWith('/')) {
      baseDir += '/';
    }
    _currentDirectory =
        '${baseDir}ie${ignoreExpires ? 1 : 0}_ps${persistSession ? 1 : 0}/';
    await Directory(_currentDirectory).create(recursive: true);
  }

  @override
  Future<String?> read(String key) async {
    final file = File('$_currentDirectory${_sanitizeKey(key)}');
    if (!file.existsSync()) {
      return null;
    }
    try {
      final encoded = await file.readAsString();
      final cipherBytes = base64Decode(encoded);
      final plainBytes = await _helper.decrypt(cipherBytes);
      return utf8.decode(plainBytes);
    } on FormatException {
      // Corrupt base64 — treat as missing, drop the bad file.
      await _bestEffortDelete(file);
      return null;
    } on ArgumentError {
      // AES-GCM length guard tripped — truncated file, drop it.
      await _bestEffortDelete(file);
      return null;
    } on SecretBoxAuthenticationError {
      // MAC mismatch — file was tampered with or written under a different
      // key. Drop it; PersistCookieJar will treat the cookie as absent and
      // re-fetch on next round-trip.
      await _bestEffortDelete(file);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final plainBytes = utf8.encode(value);
    final cipherBytes = await _helper.encrypt(plainBytes);
    final encoded = base64Encode(cipherBytes);
    await File('$_currentDirectory${_sanitizeKey(key)}').writeAsString(encoded);
  }

  @override
  Future<void> delete(String key) async {
    final file = File('$_currentDirectory${_sanitizeKey(key)}');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    final dir = Directory(_currentDirectory);
    if (!dir.existsSync()) {
      return;
    }
    // AC4.7: iterate per-key delete, then sweep any file not in keys. The
    // directory itself stays — recreating it would regress ordering with
    // concurrent reads on PersistCookieJar; keeping it empty is the literal
    // "Storage" contract.
    final keepNames = <String>{};
    for (final key in keys) {
      final name = _sanitizeKey(key);
      final file = File('$_currentDirectory$name');
      if (file.existsSync()) {
        await file.delete();
      }
      keepNames.add(name);
    }
    await for (final entity in dir.list()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (!keepNames.contains(name)) {
          await _bestEffortDelete(entity);
        }
      }
    }
  }

  Future<void> _bestEffortDelete(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on FileSystemException {
      // Caller cannot meaningfully recover; swallow.
    }
  }

  // Cookie keys can contain '/' (domain separators) and other characters
  // invalid in file names. base64Url is reversible, padding-preserving, and
  // collision-free across keys that differ only in separator characters
  // (e.g. `a/b` vs `a_b`).
  String _sanitizeKey(String key) => base64Url.encode(utf8.encode(key));
}
