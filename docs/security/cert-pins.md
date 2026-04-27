# Certificate Pin Documentation — www.evisitor.hr

// WHY: both cert AND SPKI formats are documented — Dart pinning uses cert
// SHA-256 (DER), Android NSC uses SPKI SHA-256 (base64). They are not
// interchangeable.

Fingerprints verified: **2026-04-27**

---

## Leaf Certificate

- **Not Before:** Oct 20 00:00:00 2025 GMT
- **Not After:** Oct 19 23:59:59 2026 GMT
- **DER SHA-256 (hex, lowercase, no colons)** — used in `CertPins.validFingerprints` (Dart `badCertificateCallback`):
  ```
  87b5a19bce04a9be8ca9e8aee798e032b64c68fe7f23c6d8a476a73f261112a7
  ```
- **SPKI SHA-256 (base64)** — used in `network_security_config.xml` `<pin-set>`:
  ```
  auwWkCCvoXUIBsH0t4Db36v2pfKdQXHwPoQWRdbiIag=
  ```

## Intermediate Certificate

- **Not Before:** Mar 30 00:00:00 2021 GMT
- **Not After:** Mar 29 23:59:59 2031 GMT
- **DER SHA-256 (hex, lowercase, no colons)** — used in `CertPins.validFingerprints`:
  ```
  c8025f9fc65fdfc95b3ca8cc7867b9a587b5277973957917463fc813d0b625a9
  ```
- **SPKI SHA-256 (base64)** — used in `network_security_config.xml` `<pin-set>`:
  ```
  Wec45nQiFwKvHtuHxSAMGkt19k+uPSw9JlEkxhvYPHk=
  ```

---

## Rotation Trigger

Rotate cert pins **30 days before the leaf cert's Not After date**: **2026-09-19**.

This is also the trigger condition for the min-version check (Story 9.4) — when
cert pins rotate, the app must be force-updated because old installs will hard-fail
TLS.

The `<pin-set expiration>` in `network_security_config.xml` is set to the rotation
trigger date (2026-09-19) so the OS warns before the pin expires.

---

## Commands Used to Obtain Fingerprints

```bash
# Leaf cert DER SHA-256:
echo | openssl s_client -connect www.evisitor.hr:443 2>/dev/null \
  | openssl x509 -noout -fingerprint -sha256 \
  | sed 's/://g' | awk -F= '{print tolower($2)}'

# Intermediate cert DER SHA-256:
echo | openssl s_client -connect www.evisitor.hr:443 -showcerts 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/{p=1; c++} c==2{print} /-----END CERTIFICATE-----/{p=0}' \
  | openssl x509 -noout -fingerprint -sha256 \
  | sed 's/://g' | awk -F= '{print tolower($2)}'

# Leaf cert SPKI SHA-256 base64 (for Android NSC pin-set):
echo | openssl s_client -connect www.evisitor.hr:443 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl base64

# Intermediate cert SPKI SHA-256 base64 (for Android NSC pin-set):
echo | openssl s_client -connect www.evisitor.hr:443 -showcerts 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/{p=1; c++} c==2{print} /-----END CERTIFICATE-----/{p=0}' \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl base64

# Cert validity dates:
echo | openssl s_client -connect www.evisitor.hr:443 2>/dev/null \
  | openssl x509 -noout -dates
```
