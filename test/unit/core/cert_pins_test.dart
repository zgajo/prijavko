// guards AC1.3, AC1.4, AC11.2 (positive path)
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/security/cert_pins.dart';

void main() {
  group('CertPins', () {
    // Fake DER bytes whose SHA-256 is NOT in validFingerprints.
    final fakeDer = Uint8List(64)..fillRange(0, 64, 0xFF);

    tearDown(() {
      CertPins.debugOverrideFingerprints = null;
    });

    test('isTrustedCertificate returns false for non-target host', () {
      expect(CertPins.isTrustedCertificate(fakeDer, 'evil.com'), isFalse);
      expect(CertPins.isTrustedCertificate(fakeDer, 'evisitor.hr'), isFalse);
      expect(
        CertPins.isTrustedCertificate(fakeDer, 'sub.www.evisitor.hr'),
        isFalse,
      );
    });

    test('isTrustedCertificate normalizes host casing and trailing dots', () {
      // Lowercase + trailing-dot stripping must route to the fingerprint
      // check, which then fails closed because fakeDer's hash isn't pinned.
      // The point of this test is to verify host normalization happens; if
      // the host check rejected upper-case or FQDN form, the regression here
      // would still return false but for the wrong reason. Pin a fingerprint
      // that DOES match fakeDer so a trip through the fingerprint check
      // returns true — proving the normalizer routed past the host guard.
      CertPins.debugOverrideFingerprints = {
        CertPins.computeFingerprint(fakeDer),
      };
      expect(CertPins.isTrustedCertificate(fakeDer, 'WWW.EVISITOR.HR'), isTrue);
      expect(
        CertPins.isTrustedCertificate(fakeDer, 'www.evisitor.hr.'),
        isTrue,
      );
      expect(
        CertPins.isTrustedCertificate(fakeDer, 'Www.Evisitor.Hr...'),
        isTrue,
      );
    });

    test(
      'isTrustedCertificate returns false for www.evisitor.hr with unknown fingerprint',
      () {
        expect(
          CertPins.isTrustedCertificate(fakeDer, 'www.evisitor.hr'),
          isFalse,
        );
      },
    );

    test('computeFingerprint returns lowercase hex SHA-256 with no colons', () {
      final bytes = Uint8List.fromList(utf8.encode('test'));
      final result = CertPins.computeFingerprint(bytes);
      expect(result, sha256.convert(bytes).toString());
      expect(result, isNot(contains(':')));
      expect(result, equals(result.toLowerCase()));
      expect(result.length, 64); // 32 bytes × 2 hex chars
    });

    test('production fingerprint set is non-empty and well-formed', () {
      // Structural guard against accidentally clearing the production pins.
      expect(CertPins.validFingerprints, isNotEmpty);
      for (final fp in CertPins.validFingerprints) {
        expect(fp.length, 64, reason: 'fingerprint must be 64 hex chars');
        expect(
          RegExp(r'^[0-9a-f]+$').hasMatch(fp),
          isTrue,
          reason: 'fingerprint must be lowercase hex',
        );
      }
    });

    test(
      'isTrustedCertificate returns true for matching fingerprint (positive path)',
      () {
        // Inject a test-only fingerprint computed from the fixture bytes.
        // This proves: (a) the contains() check actually fires positive when
        // fingerprints match; (b) computeFingerprint feeds the lookup
        // correctly. A regression that flipped `==` to `!=` would fail this
        // test, which is what AC11.2 requires.
        final fixtureBytes = Uint8List.fromList(utf8.encode('fixture-cert'));
        final fixtureFingerprint = CertPins.computeFingerprint(fixtureBytes);
        CertPins.debugOverrideFingerprints = {fixtureFingerprint};

        expect(
          CertPins.isTrustedCertificate(fixtureBytes, 'www.evisitor.hr'),
          isTrue,
        );
      },
    );

    test('debugOverrideFingerprints scopes to the test that set it', () {
      // Sanity that the override slot resets between tests via tearDown.
      // (If this test ran without tearDown and the previous test left an
      // override, validFingerprints would not equal the production set.)
      expect(CertPins.debugOverrideFingerprints, isNull);
      expect(CertPins.validFingerprints.length, greaterThanOrEqualTo(2));
    });
  });
}
