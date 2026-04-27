// WHY: Certificate fingerprints for www.evisitor.hr (leaf + intermediate).
// The duplicate layer — Dart `badCertificateCallback` here AND `<pin-set>` in
// network_security_config.xml (AC12) — is intentional defense-in-depth:
// platform-level pinning catches cert failures even if Dart code regresses;
// Dart-level pinning provides richer failure surfacing and easier testability.
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class CertPins {
  // Poka-yoke: abstract final class with no constructor — instantiation impossible.
  CertPins._();

  // SHA-256 hex fingerprints (lowercase, no colons) of the leaf AND intermediate
  // certs for www.evisitor.hr. Both are required so rotation safety is preserved:
  // if the leaf rotates, the intermediate remains valid.
  //
  // Leaf:         valid Oct 20 2025 – Oct 19 2026
  // Intermediate: valid Mar 30 2021 – Mar 29 2031
  //
  // Rotate cert pins 30 days before the leaf cert's Not After date (2026-09-19).
  // See docs/security/cert-pins.md for the full rotation procedure.
  static const Set<String> validFingerprints = {
    '87b5a19bce04a9be8ca9e8aee798e032b64c68fe7f23c6d8a476a73f261112a7',
    'c8025f9fc65fdfc95b3ca8cc7867b9a587b5277973957917463fc813d0b625a9',
  };

  static bool isTrustedCertificate(Uint8List derBytes, String host) {
    if (host != 'www.evisitor.hr') {
      return false;
    }
    return validFingerprints.contains(computeFingerprint(derBytes));
  }

  // Synchronous SHA-256 of DER-encoded cert bytes.
  // Must be synchronous because `badCertificateCallback` is synchronous.
  static String computeFingerprint(Uint8List derBytes) =>
      sha256.convert(derBytes).toString();
}
