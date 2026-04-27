// WHY: eVisitor uses 3 named cookies (authentication, affinity, language).
// AES-GCM-encrypted files provide the same threat model as the credentials
// in flutter_secure_storage. The Android Keystore key (loaded by SecurityService)
// encrypts both — one key, two storage surfaces.
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:prijavko/core/security/aes_gcm_helper.dart';

class EncryptedStorage implements Storage {
  EncryptedStorage(this._directory, this._helper);

  final String _directory;
  final AesGcmHelper _helper;

  // Set during init — appended by PersistCookieJar with ie/ps flags (same
  // pattern as FileStorage to stay compatible with PersistCookieJar internals).
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
    final encoded = await file.readAsString();
    final cipherBytes = base64Decode(encoded);
    final plainBytes = await _helper.decrypt(cipherBytes);
    return utf8.decode(plainBytes);
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
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  // Cookie keys can contain '/' (domain separators), which are invalid in file
  // names on most operating systems.
  String _sanitizeKey(String key) => key.replaceAll('/', '_');
}
