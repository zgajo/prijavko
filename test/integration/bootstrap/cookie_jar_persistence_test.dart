// WHY this test exists: _hasViableSessionCookies is dead code if
// PersistCookieJar doesn't actually round-trip cookies through
// EncryptedStorage. This test catches any EncryptedStorage refactor
// that silently breaks persistence — the load-bearing assumption of Story 1.8.
//
// WHY flutter test (not integration_test/): no Flutter binding required for
// the cookie jar itself. `dart:io` and the `cookie_jar` package are pure Dart.
import 'dart:io' show Cookie, Directory;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/security/encrypted_storage.dart';

import '../../fakes/fake_security_service.dart';

void main() {
  test(
    'PersistCookieJar round-trips authentication cookie across instances',
    () async {
      // WHY systemTemp + createTemp: avoids /tmp/test_cookies path collision
      // under parallel test workers (Story 1.7 retro lesson).
      final tempDir = await Directory.systemTemp.createTemp('boot_jar_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final security = FakeSecurityService();
      await security.init();

      // Instance #1 — write
      final storage1 = EncryptedStorage(
        tempDir.path,
        security.encryptionHelper,
      );
      final jar1 = PersistCookieJar(
        storage: storage1,
        persistSession: true,
        ignoreExpires: false,
      );
      await jar1.saveFromResponse(
        Uri.parse('https://www.evisitor.hr/eVisitorRhetos_API/'),
        [
          Cookie('authentication', 'session-token')
            ..path = '/eVisitorRhetos_API/'
            ..secure = true
            ..httpOnly = true,
        ],
      );

      // Instance #2 — read from same dir + same key (cross-process-restart sim)
      final storage2 = EncryptedStorage(
        tempDir.path,
        security.encryptionHelper,
      );
      final jar2 = PersistCookieJar(
        storage: storage2,
        persistSession: true,
        ignoreExpires: false,
      );
      final cookies = await jar2.loadForRequest(
        Uri.parse('https://www.evisitor.hr/eVisitorRhetos_API/'),
      );

      expect(cookies.map((c) => c.name).toList(), contains('authentication'));
    },
  );
}
