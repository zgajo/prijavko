# Story 1.3: Security Primitives, Dio & Cert Pinning

Status: done

## Story

As a host,
I want every network call to eVisitor to be cert-pinned, encrypted at rest, and routed through a single auditable Dio instance,
so that a rogue Wi-Fi, a MITM attempt, or an OS-level backup cannot expose my credentials, cookies, or queued guest data.

## Acceptance Criteria

### AC1 — `lib/core/security/cert_pins.dart`

1. `abstract final class CertPins` with private unnamed constructor (instantiation impossible — Poka-yoke).
2. `static const Set<String> validFingerprints` — SHA-256 hex fingerprints (lowercase, no colons) of the **leaf AND intermediate** certs for `www.evisitor.hr`. Both are required so rotation safety is preserved (if leaf rotates, the intermediate remains valid).
3. Static method `isTrustedCertificate(Uint8List derBytes, String host) → bool`:
   - Returns `false` for any host other than `www.evisitor.hr` (first guard, zero-overhead reject for non-target traffic).
   - Returns `false` if `computeFingerprint(derBytes)` is not in `validFingerprints`.
4. Static method `computeFingerprint(Uint8List derBytes) → String` — synchronous SHA-256 of the DER-encoded cert bytes, using `package:crypto` (`sha256.convert(derBytes).toString()`). Must be synchronous because `badCertificateCallback` is synchronous.
5. **IMPLEMENTER ACTION REQUIRED — obtain real fingerprints:** Run at dev time (not CI):
   ```bash
   # Leaf cert fingerprint:
   echo | openssl s_client -connect www.evisitor.hr:443 2>/dev/null \
     | openssl x509 -noout -fingerprint -sha256 \
     | sed 's/://g' | awk -F= '{print tolower($2)}'

   # Intermediate cert fingerprint:
   echo | openssl s_client -connect www.evisitor.hr:443 -showcerts 2>/dev/null \
     | awk '/-----BEGIN CERTIFICATE-----/{p=1; c++} c==2{print} /-----END CERTIFICATE-----/{p=0}' \
     | openssl x509 -noout -fingerprint -sha256 \
     | sed 's/://g' | awk -F= '{print tolower($2)}'
   ```
   Record both values in `docs/security/cert-pins.md` (AC8) and in the `validFingerprints` set. Do NOT commit placeholder values — they either block production TLS or are inert (neither serves the guard-rail intent). The test in `cert_pins_test.dart` must use the real fingerprints once they are known.
6. Top-of-file `// WHY:` comment: "Certificate fingerprints for www.evisitor.hr (leaf + intermediate). The duplicate layer — Dart `badCertificateCallback` here AND `<pin-set>` in network_security_config.xml (AC12) — is intentional defense-in-depth: platform-level pinning catches cert failures even if Dart code regresses; Dart-level pinning provides richer failure surfacing and easier testability."

### AC2 — `lib/core/security/aes_gcm_helper.dart`

1. `class AesGcmHelper` — final, non-const (holds mutable `cryptography` algorithm reference).
2. Constructor `AesGcmHelper(Uint8List keyBytes)` — key must be exactly 32 bytes (AES-256-GCM). Guard: throw `ArgumentError` if `keyBytes.length != 32` (Poka-yoke; prevents key truncation bugs).
3. `Future<Uint8List> encrypt(Uint8List plaintext) → Uint8List` — produces `[nonce (12 bytes)] ++ [ciphertext] ++ [mac (16 bytes)]`. Nonce must be randomly generated per call (use `SecureRandom(12)` or equivalent from `package:cryptography`). The 12-byte prefix convention lets `decrypt` locate the nonce without a side-channel.
4. `Future<Uint8List> decrypt(Uint8List ciphertext) → Uint8List` — splits the blob as `nonce = first 12 bytes`, `encrypted = remainder`, decrypts with AES-256-GCM. Throws `SecretBoxAuthenticationError` on MAC mismatch (from `package:cryptography` — do not catch it; callers handle the `Err` variant). Do not swallow authentication failures silently.
5. Uses `package:cryptography_flutter`'s `AesGcm.with256bits()` — this delegates to Android Keystore or hardware crypto when available.
6. `// WHY:` inline on nonce generation: "A fresh random nonce per encrypt call is non-negotiable for AES-GCM security — reusing a (key, nonce) pair leaks the key stream."

### AC3 — `lib/core/security/security_service.dart`

1. `class SecurityService` — concrete class; constructor is `SecurityService()` (no params; dependency inversion via override in tests).
2. `Future<void> init()` — called exactly once in `main()` before `runApp()`. Loads the AES-GCM key from `flutter_secure_storage` key `'prijavko_aes_gcm_key_v1'`. If no key exists (first run), generates a new 32-byte cryptographically random key (`List.generate(32, (_) => Random.secure().nextInt(256))`), stores it as `base64Encode(keyBytes)`, then loads it. Calling `init()` twice (accidental) is guarded: throw `StateError('SecurityService already initialized')`.
3. `AesGcmHelper get encryptionHelper` — throws `StateError('SecurityService not initialized — call init() first')` if accessed before `init()` completes.
4. `flutter_secure_storage` options: `AndroidOptions(encryptedSharedPreferences: false)` — we want Keystore-backed storage, not `EncryptedSharedPreferences` (the latter has a weaker threat model). Accessibility: `KeychainAccessibility.first_unlock_this_device` (the Android equivalent — verify the `flutter_secure_storage` API at install time; on Android it maps to `KeyProperties.PURPOSE_DECRYPT`). On Android, `FlutterSecureStorage` uses Android Keystore by default — verify with `FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: false))`.
5. `// WHY:` comment on key storage: "The AES-GCM key is in `flutter_secure_storage` (Keystore-backed), not Drift or SharedPreferences. `allowBackup=false` in AndroidManifest prevents it leaving the device. The cookie jar and future Drift PII columns all derive from this single key — one Keystore entry, one audit point."
6. `test/fakes/fake_security_service.dart` provides `FakeSecurityService` that extends or wraps `SecurityService` with an in-memory key (fixed 32-byte value) so unit tests never touch `flutter_secure_storage`. See AC10.

### AC4 — `lib/core/security/encrypted_storage.dart`

1. `class EncryptedStorage implements Storage` (where `Storage` is from `package:cookie_jar`). Verify the exact import path at install time: `import 'package:cookie_jar/src/storage.dart'` or the public export.
2. Constructor `EncryptedStorage(String directory, AesGcmHelper helper)`.
3. `init(bool persistSession, bool ignoreExpires)` — creates the directory (`Directory(directory).create(recursive: true)`), stores the flags for later reference.
4. `read(String key)` — reads file `$directory/$key`, base64-decodes the contents, AES-GCM-decrypts via `helper.decrypt()`, UTF-8-decodes to String. Returns `null` if file does not exist.
5. `write(String key, String value)` — UTF-8-encodes the value, AES-GCM-encrypts via `helper.encrypt()`, base64-encodes, writes to file `$directory/$key`.
6. `delete(String key)` — deletes the file `$directory/$key` if it exists; no-op if absent.
7. `deleteAll(List<String> keys)` — iterates and deletes each; also deletes any file not in `keys` that exists in the directory (full wipe semantics when `keys` is the full set of stored keys — verify `PersistCookieJar`'s contract for `deleteAll` at install time).
8. `readAll()` — returns a list of all filenames in `directory` (the "keys" side) — not the values. Used by `PersistCookieJar` to enumerate stored cookies.
9. **Encoding note:** Use `base64Encode` / `base64Decode` from `dart:convert` for the file bytes. Do NOT use `base64Url` — the file key names may contain `/` characters (cookie domains), which are invalid in file names. Sanitize keys with `.replaceAll('/', '_')` before using as file names; unsanitize the reverse when returning from `readAll()`.
10. `// WHY:` at class level: "eVisitor uses 3 named cookies (authentication, affinity, language). AES-GCM-encrypted files provide the same threat model as the credentials in flutter_secure_storage. The Android Keystore key (loaded by SecurityService) encrypts both — one key, two storage surfaces."

### AC5 — `lib/core/result/result.dart`

1. Dart 3 native sealed class (no Freezed, no codegen — JIT; `Result` has exactly 2 variants and needs no `copyWith`):
   ```dart
   sealed class Result<T, E> { const Result(); }
   final class Ok<T, E> extends Result<T, E> {
     const Ok(this.value);
     final T value;
   }
   final class Err<T, E> extends Result<T, E> {
     const Err(this.error);
     final E error;
   }
   ```
2. No extensions, helpers, or `when`/`map` methods — callers use Dart 3 exhaustive `switch`. Adding convenience methods is a future Kaizen; do not pre-build them.
3. `// WHY:` at class level: "All repository and data-layer functions return Result<T, E> instead of throwing. Pattern-matching on Result at call sites makes the error path structurally impossible to forget (Poka-yoke). Dart 3 sealed exhaustive switch replaces the need for a Freezed union here."

### AC6 — `lib/core/errors/app_error.dart`

1. Dart 3 sealed class (no Freezed — same rationale as AC5):
   ```dart
   sealed class AppError { const AppError(); }
   ```
2. **Only one variant ships in this story** (JIT):
   ```dart
   final class StorageError extends AppError {
     const StorageError(this.message, {this.cause});
     final String message;
     final Object? cause; // original PlatformException or similar; NOT logged as-is (see AC below)
   }
   ```
3. `cause` is typed `Object?` (not `dynamic`) and is **only for internal crash triage** — never passed to AppLogger, Crashlytics, or the UI verbatim. The caller wraps it in `Err(StorageError('Credential write failed'))` without leaking the raw platform exception message. `// WHY:` inline: "PlatformException messages from flutter_secure_storage may contain OS-level detail that includes key metadata — not PII, but still auditable surface. Callers extract only the safe message string."
4. Additional variants (`NetworkError`, `AuthError`, `ValidationError`, `ParseError`) are not created in this story — they arrive with their owning stories (2.x, 4.x, 6.x). A `// TODO(story-2.1): NetworkError` comment is NOT added — the architecture doc is the authoritative reference; inline TODOs for future variants create noise.

### AC7 — `lib/features/settings/credential_store.dart`

1. `class CredentialStore` — concrete, non-const. Constructor `CredentialStore({FlutterSecureStorage? storage})` — accepts an optional storage parameter so tests can inject a fake without platform channels. Default: `FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: false))`.
2. Storage key constants (private, top-of-file `const`):
   ```dart
   static const _keyUsername = 'prijavko_cred_username_v1';
   static const _keyPassword = 'prijavko_cred_password_v1';
   static const _keyApiKey   = 'prijavko_cred_apikey_v1';
   ```
   Key versioning (`_v1`) allows future key migration without data loss — a comment explains the convention.
3. `Future<Result<void, StorageError>> saveCredentials({required String username, required String password, required String apiKey})` — writes all three keys. If any write throws, wraps in `Err(StorageError(...))` and does NOT attempt partial rollback (partial state is tolerable; the next `saveCredentials` overwrites). Does NOT log the values.
4. `Future<Result<Credentials, StorageError>> loadCredentials()` — reads all three keys. If all are present, returns `Ok(Credentials(username, password, apiKey))`. If ANY key is missing (e.g. first run or after `wipeCredentials`), returns `Err(StorageError('Credentials not found'))` — NOT a partial result. `Credentials` is a simple `final class Credentials { ... }` in this same file (three `final String` fields, no Freezed needed — Poka-yoke via required named params, no codegen overhead).
5. `Future<Result<void, StorageError>> wipeCredentials()` — calls `storage.delete(key:)` for ALL THREE keys individually. Does NOT call `storage.deleteAll()` (that would wipe unrelated keys stored by other plugins). Unit test must verify all three keys are deleted (AC9).
6. `// WHY:` at class level: "Credentials never touch Drift, SharedPreferences, or the cookie jar. They live only in flutter_secure_storage (Android Keystore). The `allowBackup=false` manifest declaration (Story 1.1 AC4) prevents them leaving the device. `CredentialStore` is the single entry point — no feature may read credentials from any other surface."

### AC8 — `lib/app/providers.dart` — dioProvider

1. **Riverpod introduction**: This is the first story to use Riverpod providers. Add `flutter_riverpod`, `riverpod_annotation` to `dependencies`; add `riverpod_generator`, `build_runner` to `dev_dependencies`. Use `@riverpod` codegen exclusively (per CLAUDE.md — "No manual `Provider(...)` calls in new code").
2. Three providers declared in `lib/app/providers.dart`:

   **a) `securityServiceProvider`** — `@Riverpod(keepAlive: true)`:
   ```dart
   @Riverpod(keepAlive: true)
   SecurityService securityService(SecurityServiceRef ref) {
     // Must be overridden in ProviderScope before use.
     // Throwing here is deliberate Poka-yoke: forgetting the override crashes loudly at startup.
     throw UnimplementedError(
       'securityServiceProvider must be overridden with an initialized SecurityService '
       'before ProviderScope is created. Call SecurityService().init() in main().',
     );
   }
   ```

   **b) `cookieJarDirectoryProvider`** — `@Riverpod(keepAlive: true)`:
   ```dart
   @Riverpod(keepAlive: true)
   String cookieJarDirectory(CookieJarDirectoryRef ref) {
     throw UnimplementedError(
       'cookieJarDirectoryProvider must be overridden with the resolved app documents path. '
       'Call path_provider.getApplicationDocumentsDirectory() in main().',
     );
   }
   ```

   **c) `dioProvider`** — `@Riverpod(keepAlive: true)`:
   - Reads `securityServiceProvider` and `cookieJarDirectoryProvider` via `ref.watch(...)`.
   - `BaseOptions`: `baseUrl = _resolveBaseUrl()`, `connectTimeout = Duration(seconds: 10)`, `receiveTimeout = Duration(seconds: 30)`, `sendTimeout = Duration(seconds: 30)`.
   - `// WHY:` comment on 60s receive path: "ImportTourists batches can be slow — a 60s extended receive path is reserved for that call (Story 6.3) which will override the per-request timeout on that specific Dio request via `Options(receiveTimeout: ...)`. The provider sets the default; the call site overrides."
   - When `evisitorEnv != EvisitorEnv.fake`: creates `EncryptedStorage` → `PersistCookieJar(storage: ...)` → `dio.interceptors.add(CookieManager(cookieJar))`. Then applies cert-pinned `IOHttpClientAdapter` (see below).
   - When `evisitorEnv == EvisitorEnv.fake`: no cookie jar, no cert pinning (no real TLS). The Dio instance is ready to accept an adapter override in integration tests. `baseUrl = 'http://localhost/'` (unreachable; never used — fake adapter intercepts all requests before they leave the process).
   - `IOHttpClientAdapter` (Dio 5.x — `package:dio/io.dart`):
     ```dart
     // Verify exact Dio 5.x API at install time — IOHttpClientAdapter is the 5.x name
     // (was DefaultHttpClientAdapter in 4.x).
     dio.httpClientAdapter = IOHttpClientAdapter(
       createHttpClient: () => HttpClient()
         ..badCertificateCallback = (X509Certificate cert, String host, int port) =>
             CertPins.isTrustedCertificate(cert.der, host),
     );
     ```
     Import: `import 'dart:io' show HttpClient, X509Certificate;` + `import 'package:dio/io.dart';`.
   - **`_resolveBaseUrl()`** private top-level function:
     ```dart
     String _resolveBaseUrl() => switch (evisitorEnv) {
       EvisitorEnv.prod => 'https://www.evisitor.hr/eVisitorRhetos_API/',
       EvisitorEnv.test => 'https://www.evisitor.hr/testApi/',
       EvisitorEnv.fake => 'http://localhost/', // intercepted by test adapter
     };
     ```

3. **`lib/app/providers.g.dart`** is generated by `dart run build_runner build --delete-conflicting-outputs` and committed. This is the only generated file in `lib/app/`.

4. **No `lib/app/app.dart` or `lib/app/router.dart` in this story** — both wait for go_router in Story 1.5. `providers.dart` is the only file in `lib/app/` right now. `// TODO(story-1.5): app.dart (MaterialApp.router + ProviderScope) lands here.` — add this comment at the top of `providers.dart`.

### AC9 — `lib/main.dart` — ProviderScope wiring

1. `main()` becomes `async`:
   ```dart
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     applyMainAppFontConfig();               // Story 1.2 — existing

     final securityService = SecurityService();
     await securityService.init();           // Keystore key loaded here, once

     final appDocDir = await getApplicationDocumentsDirectory();
     final cookieJarDir = '${appDocDir.path}/.evisitor_cookie_jar';

     runApp(
       ProviderScope(
         overrides: [
           securityServiceProvider.overrideWithValue(securityService),
           cookieJarDirectoryProvider.overrideWithValue(cookieJarDir),
         ],
         child: const MainApp(),
       ),
     );
   }
   ```
2. `MainApp` (the existing `StatelessWidget`) is unchanged — it stays inside `ProviderScope`.
3. The `_DesignSystemPreview` widget inside `MainApp` is unchanged (it will be replaced by `WelcomeScreen` in Story 1.5 per the existing TODO).
4. `// WHY:` inline on pre-`runApp` init: "SecurityService loads the AES-GCM key once at startup — not lazily on first use — so any `flutter_secure_storage` failure (Keystore unavailable, corrupt entry) crashes visibly at launch rather than silently during a guest submission at 2 AM. Jidoka: stop the line early."
5. `integration_test/app_test.dart` — update to wrap the pump in a `ProviderScope` with fake overrides so the cold-start probe (NFR-P8) still passes. The existing `binding.firstFrameRasterized` assertion remains; do not remove it.

### AC10 — `test/fakes/` — test infrastructure

1. `test/fakes/evisitor_fake_adapter.dart`:
   - `class EvisitorFakeAdapter implements HttpClientAdapter` (Dio 5.x — from `package:dio`).
   - Story 1.3 skeleton: a single `fetch` implementation that returns `ResponseBody.fromString('', 200, headers: {})` for any request. This is enough to verify `dioProvider` wires correctly.
   - Future stories add endpoint routing to this file (login → Story 1.7, ImportTourists → Story 6.3). A `// TODO(story-1.7): wire login endpoint` comment marks the extension point.
   - `close({bool force = false})` → no-op.
   - The adapter is imported **only from test code** (`test/` or `integration_test/`). It is never imported from `lib/`. The `dioProvider`'s fake-env path creates a default Dio without a real adapter; integration tests then override `dioProvider` entirely.
2. `test/fakes/fake_security_service.dart`:
   - `class FakeSecurityService extends SecurityService` with a fixed deterministic 32-byte key (e.g. `Uint8List.fromList(List.filled(32, 0x42))`).
   - Overrides `init()` to be a no-op (no Keystore access).
   - Overrides `encryptionHelper` to return an `AesGcmHelper` constructed from the fixed key.
   - Allows unit tests for `CredentialStore`, `EncryptedStorage`, `dioProvider` to run without Android platform channels.

### AC11 — Tests

Tests live under `test/unit/` (pure Dart) — no integration tests required for this story's primitives (they're pure/unit-testable).

1. **`test/unit/core/result_test.dart`**:
   - `Ok` carries its value; `Err` carries its error.
   - Dart 3 exhaustive `switch` over `Result` compiles without a default case (static proof of exhaustiveness).
   - `Ok` and `Err` are const-constructible with const inner values.
   - Guards `// guards AC5.1 — sealed exhaustiveness`.

2. **`test/unit/core/cert_pins_test.dart`**:
   - `isTrustedCertificate(fakeDer, 'www.evisitor.hr')` returns `false` for bytes whose SHA-256 is not in `validFingerprints`. (`fakeDer = Uint8List(64)..fillRange(0, 64, 0xFF)`)
   - `isTrustedCertificate(anyDer, 'evil.com')` returns `false` regardless of fingerprint.
   - `computeFingerprint(bytes)` returns lowercase hex of SHA-256 with no colons.
   - If `validFingerprints` is **non-empty** at test time (real pins installed), add a positive test: create a `derBytes` whose SHA-256 matches a known-good fingerprint string, verify `isTrustedCertificate` returns `true`. (This test is conditional — add a `skip` annotation if `validFingerprints` is empty, with message "Obtain real fingerprints — AC1 AC11 task 5".)
   - Guards `// guards AC1.3, AC1.4`.

3. **`test/unit/core/aes_gcm_helper_test.dart`**:
   - `encrypt` then `decrypt` round-trip returns the original plaintext.
   - Two `encrypt` calls on the same plaintext produce different ciphertexts (random nonce — deterministic output would be a security bug).
   - `decrypt` of a tampered ciphertext (flip one byte in the MAC area) throws (authentication failure — `SecretBoxAuthenticationError` or similar from the `cryptography` package).
   - Constructor with 31-byte key throws `ArgumentError`.
   - Guards `// guards AC2.2, AC2.3, AC2.4`.

4. **`test/unit/settings/credential_store_test.dart`**:
   - Uses `MockFlutterSecureStorage` or an in-memory `FakeFlutterSecureStorage` (a `Map<String, String>` implementation of the `FlutterSecureStorage` read/write/delete interface). Do NOT use `flutter_test`'s `MockPlatformChannel` — keep it pure Dart.
   - `saveCredentials` writes all three keys.
   - `loadCredentials` returns `Ok(Credentials(...))` when all three keys exist.
   - `loadCredentials` returns `Err(StorageError('Credentials not found'))` when any key is absent.
   - `wipeCredentials` calls `delete` for all three keys; verify via the fake storage's internal map that ALL three keys are absent post-wipe (test cannot just call `loadCredentials` — it must directly inspect the storage to confirm no partial-wipe bug).
   - `wipeCredentials` does NOT delete any key not owned by `CredentialStore` (inject a pre-seeded fake storage with an extra key; verify it survives the wipe).
   - Guards `// guards AC7.5`.

5. **`integration_test/app_test.dart`** — updated: wraps the pump in `ProviderScope` with `securityServiceProvider.overrideWithValue(FakeSecurityService())`, `cookieJarDirectoryProvider.overrideWithValue(Directory.systemTemp.path)`, and `dioProvider.overrideWithValue(Dio()..httpClientAdapter = EvisitorFakeAdapter())`. The existing cold-start probe assertion (`binding.firstFrameRasterized` / NFR-P8 ≤ 2.5s) is preserved.

### AC12 — `android/app/src/main/res/xml/network_security_config.xml` — `<pin-set>`

1. Add `<pin-set>` inside the existing `<domain-config>` for `www.evisitor.hr`:
   ```xml
   <domain-config>
     <domain includeSubdomains="true">www.evisitor.hr</domain>
     <pin-set expiration="YYYY-MM-DD">
       <!-- Leaf cert SHA-256 SPKI fingerprint — base64 encoded -->
       <pin digest="SHA-256">BASE64_LEAF_FINGERPRINT==</pin>
       <!-- Intermediate CA SHA-256 SPKI fingerprint — base64 encoded -->
       <pin digest="SHA-256">BASE64_INTERMEDIATE_FINGERPRINT==</pin>
     </pin-set>
   </domain-config>
   ```
2. **IMPORTANT: Android `<pin-set>` uses base64-encoded SPKI (Subject Public Key Info) hash, NOT the DER certificate hash.** This is DIFFERENT from the hex fingerprint in `CertPins.validFingerprints` (which is the full cert DER SHA-256). The two values will differ. Compute the SPKI fingerprint:
   ```bash
   echo | openssl s_client -connect www.evisitor.hr:443 2>/dev/null \
     | openssl x509 -pubkey -noout \
     | openssl pkey -pubin -outform DER \
     | openssl dgst -sha256 -binary \
     | openssl base64
   ```
3. Set `expiration` to the leaf cert's `Not After` date minus 30 days (so the OS warns before the pin expires). Without `expiration`, a stale pin silently allows all certs post-expiry — worse than useless. Document the expiry in `docs/security/cert-pins.md`.
4. `// WHY:` update in the existing file header comment: "Story 1.3 adds the <pin-set>. Both Dart-level (badCertificateCallback) and platform-level (this pin-set) pinning are active simultaneously. Dart-level fails requests with a DioException; platform-level fails at the OS socket layer before Dart even sees the connection."

### AC13 — ProGuard keep rules

Add per-plugin keep rules to `android/app/proguard-rules.pro` for the packages introduced in this story:
```proguard
# flutter_secure_storage — Story 1.3
-keep class com.it_nomads.fluttersecurestorage.** { *; }
# path_provider — Story 1.3
-keep class io.flutter.plugins.pathprovider.** { *; }
# cryptography_flutter uses BouncyCastle / system provider — no custom classes to keep
# dio, cookie_jar — pure Dart, no native code, no keep rules needed
```
The blanket `-keep class io.flutter.plugins.** { *; }` from Story 1.1 is NOT removed (deferred to a later Kaizen pass when all plugins are known) — just add the explicit rules above it.

### AC14 — `docs/security/cert-pins.md`

Must contain:
1. SHA-256 hex fingerprints for leaf + intermediate (same values as `CertPins.validFingerprints`), base64 SPKI fingerprints for leaf + intermediate (same values as `network_security_config.xml`'s `<pin-set>`).
2. Certificate `Not After` dates for both certs.
3. Date fingerprints were verified (manual inspection date).
4. Forced-update trigger date recommendation: "Rotate cert pins 30 days before the leaf cert's `Not After` date. This is also the trigger condition for the min-version check (Story 9.4) — when cert pins rotate, the app must be force-updated because old installs will hard-fail TLS."
5. Command used to obtain each fingerprint (so a future developer can reproduce the process without tribal knowledge).
6. `// WHY: both cert AND SPKI formats are documented — Dart pinning uses cert SHA-256 (DER), Android NSC uses SPKI SHA-256 (base64). They are not interchangeable.`

### AC15 — `pubspec.yaml` dependency additions

New `dependencies` (confirm latest stable versions on `pub.dev` at dev time — use caret `^` ranges):
- `flutter_riverpod: ^<latest>` — `ProviderScope`, `ConsumerWidget`, `ref.watch`
- `riverpod_annotation: ^<latest>` — `@riverpod`, `@Riverpod(keepAlive: true)` annotations
- `dio: ^5.x` — HTTP client (pinned to major 5; check `pub.dev`)
- `dio_cookie_manager: ^<latest>` — `CookieManager` interceptor for Dio
- `cookie_jar: ^4.x` — `PersistCookieJar`, `Storage` interface
- `path_provider: ^<latest>` — `getApplicationDocumentsDirectory()`
- `flutter_secure_storage: ^<latest>` — Android Keystore-backed credential storage
- `cryptography_flutter: ^<latest>` — AES-256-GCM (hardware-accelerated on Android)
- `crypto: ^3.x` — synchronous SHA-256 for `badCertificateCallback`

New `dev_dependencies`:
- `riverpod_generator: ^<latest>` — `build_runner` codegen target for `@riverpod`
- `build_runner: ^<latest>` — codegen runner

Run `dart run build_runner build --delete-conflicting-outputs` after `flutter pub get`. Commit `pubspec.yaml`, `pubspec.lock`, and `lib/app/providers.g.dart` (per architecture — generated files are committed, not gitignored). Record exact resolved versions in the Change Log.

**IMPORTANT — `build_runner` runs in dev, NOT in CI.** The generated `*.g.dart` files are committed, so CI (`test.yml`, `integration_fake.yml`) never needs to run `build_runner`. If CI currently does not include a `build_runner` step, do NOT add one.

---

## Tasks / Subtasks

- [x] Task 1 — Add dependencies and run codegen (AC: #15)
  - [x] Subtask 1.1 — Add all `dependencies` and `dev_dependencies` listed in AC15 to `pubspec.yaml`. Annotate each with a comment referencing its story AC (matching the pattern already established for `google_fonts` and `material_symbols_icons`).
  - [x] Subtask 1.2 — Run `flutter pub get`. Record exact resolved versions in the Change Log.
  - [x] Subtask 1.3 — After `lib/app/providers.dart` is written (Task 8), run `dart run build_runner build --delete-conflicting-outputs` to generate `lib/app/providers.g.dart`. Commit `pubspec.yaml`, `pubspec.lock`, and `providers.g.dart`.
  - [x] Subtask 1.4 — Update ProGuard rules per AC13.

- [x] Task 2 — `lib/core/result/result.dart` + `lib/core/errors/app_error.dart` (AC: #5, #6)
  - [x] Subtask 2.1 — Create `lib/core/result/result.dart` with `sealed class Result<T, E>`, `Ok`, `Err` per AC5.
  - [x] Subtask 2.2 — Create `lib/core/errors/app_error.dart` with `sealed class AppError`, `StorageError` per AC6.
  - [x] Subtask 2.3 — Add `test/unit/core/result_test.dart` per AC11.1. Run `flutter test test/unit/core/result_test.dart` — green before proceeding.

- [x] Task 3 — `lib/core/security/cert_pins.dart` + `docs/security/cert-pins.md` (AC: #1, #14)
  - [x] Subtask 3.1 — **Obtain real cert fingerprints** using the `openssl` commands in AC1.5. Record in `docs/security/cert-pins.md`.
  - [x] Subtask 3.2 — Create `lib/core/security/cert_pins.dart` with the real fingerprints, `isTrustedCertificate`, and `computeFingerprint` per AC1.
  - [x] Subtask 3.3 — Add `test/unit/core/cert_pins_test.dart` per AC11.2. Run and verify green.

- [x] Task 4 — `lib/core/security/aes_gcm_helper.dart` (AC: #2)
  - [x] Subtask 4.1 — Create `lib/core/security/aes_gcm_helper.dart` per AC2.
  - [x] Subtask 4.2 — Add `test/unit/core/aes_gcm_helper_test.dart` per AC11.3. Run and verify green (including the tampered-ciphertext authentication failure test).

- [x] Task 5 — `lib/core/security/security_service.dart` (AC: #3)
  - [x] Subtask 5.1 — Create `lib/core/security/security_service.dart` per AC3.
  - [x] Subtask 5.2 — Create `test/fakes/fake_security_service.dart` per AC10.2.

- [x] Task 6 — `lib/core/security/encrypted_storage.dart` (AC: #4)
  - [x] Subtask 6.1 — Create `lib/core/security/encrypted_storage.dart` per AC4. Verify `Storage` interface import path from `cookie_jar` package at install time; document the import in a `// WHY:` note if it's from a private (`src/`) path.
  - [x] Subtask 6.2 — Verify key-sanitisation for file names (AC4.9) with a quick manual test against `'www.evisitor.hr'` → filename-safe string.

- [x] Task 7 — `lib/features/settings/credential_store.dart` (AC: #7)
  - [x] Subtask 7.1 — Create `lib/features/settings/credential_store.dart` (also defines `Credentials` value class) per AC7.
  - [x] Subtask 7.2 — Add `test/unit/settings/credential_store_test.dart` per AC11.4. The in-memory `FakeFlutterSecureStorage` is declared inside this test file (not a separate fake file — it's only used here). Run and verify green, especially the three-key wipe test.

- [x] Task 8 — `lib/app/providers.dart` — dioProvider (AC: #8)
  - [x] Subtask 8.1 — Create `lib/app/providers.dart` with `securityServiceProvider`, `cookieJarDirectoryProvider`, and `dioProvider` per AC8. Verify the Dio 5.x `IOHttpClientAdapter` API against the package README at install time.
  - [x] Subtask 8.2 — Run `dart run build_runner build --delete-conflicting-outputs`. Verify `lib/app/providers.g.dart` is generated cleanly. Commit it.
  - [x] Subtask 8.3 — Create `test/fakes/evisitor_fake_adapter.dart` skeleton per AC10.1.

- [x] Task 9 — Wire ProviderScope in `lib/main.dart` (AC: #9)
  - [x] Subtask 9.1 — Make `main()` async. Add `SecurityService().init()` and `getApplicationDocumentsDirectory()` before `runApp()`. Wrap `MainApp` in `ProviderScope` with the two overrides per AC9.
  - [x] Subtask 9.2 — Update `integration_test/app_test.dart` with fake provider overrides per AC11.5. Ensure the NFR-P8 cold-start probe assertion is preserved.

- [x] Task 10 — `android/app/src/main/res/xml/network_security_config.xml` — `<pin-set>` (AC: #12)
  - [x] Subtask 10.1 — Compute the SPKI SHA-256 base64 fingerprints (different from the DER SHA-256 hex in AC1 — use the `openssl pkey` command from AC12.2).
  - [x] Subtask 10.2 — Add `<pin-set expiration="...">` with leaf + intermediate to the existing `<domain-config>` shell per AC12.1.
  - [x] Subtask 10.3 — Update `docs/security/cert-pins.md` with the SPKI values and expiration date per AC14.

- [x] Task 11 — Validation gate
  - [x] Subtask 11.1 — `flutter test` — all tests green.
  - [x] Subtask 11.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [x] Subtask 11.3 — `dart format --set-exit-if-changed lib test integration_test` — clean.
  - [x] Subtask 11.4 — PII grep guard and icons guard — both `rc=1` (no match) against the working tree.
  - [x] Subtask 11.5 — Build release AAB (`flutter build appbundle --release`) and verify no R8/ProGuard errors related to new packages.

---

## Dev Notes

### Why this story is third

Stories 1.1 and 1.2 created the scaffold and design system. Every subsequent story that touches a screen, persists data, or makes a network call depends on these security primitives. Story 1.7 (eVisitor login) needs `CredentialStore` + `dioProvider`. Story 2.x (auth lifecycle) needs the `AuthInterceptor` wired to `dioProvider`. Story 5.x (queue) needs `SecurityService.encryptionHelper` for Drift PII column encryption. All roads lead through Story 1.3.

### Architecture mandates (non-negotiable)

- **Single Dio instance via `dioProvider`.** No feature may instantiate `Dio()` directly. Every HTTP call goes through the provider — that is the audit point for cert pinning, cookie management, and future auth interceptor wiring.
- **No auth interceptor in this story.** `QueuedInterceptor`/`AuthInterceptor` lands in Epic 2.3. Story 1.3's `dioProvider` wires only the transport and cookie layers. A `// TODO(story-2.3): AuthInterceptor wires here` comment in `providers.dart` marks the extension point.
- **`@riverpod` only — no manual Provider/Notifier calls.** The `securityServiceProvider`, `cookieJarDirectoryProvider`, and `dioProvider` all use the `@Riverpod(keepAlive: true)` annotation. Generated code lives in `providers.g.dart` — committed.
- **`autoDispose` default does NOT apply to these providers.** The architecture (CLAUDE.md) says "default to `autoDispose`" but adds "If you need `keepAlive`, add a comment explaining why." These three providers are infrastructure — they must never be disposed for the app's lifetime. `keepAlive: true` + `// WHY: lifetime matches the app process; disposing would force TLS + Keystore re-init on every navigation`.
- **Credentials only in `flutter_secure_storage`.** Not Drift, not `shared_preferences`, not anywhere else. `CredentialStore` is the only class that reads or writes credential keys.
- **`EVISITOR_ENV=fake` does not import test code.** `dioProvider` when `fake` returns a plain Dio without cert pinning or cookies. Test code overrides the entire `dioProvider` with a Dio using `EvisitorFakeAdapter`. The `lib/` tree never imports `test/fakes/`.
- **AES-GCM nonce must be random per call.** `AesGcmHelper.encrypt()` generates a fresh nonce on every invocation. The same-plaintext-different-ciphertext property is asserted in `aes_gcm_helper_test.dart`.
- **No direct `dart:crypto` — use `package:crypto` for SHA-256.** Dart stdlib has no SHA-256; `package:crypto` is the Dart team's official package. `package:cryptography_flutter` provides AES-GCM. They serve different roles and are not interchangeable.

### eVisitor API quirks relevant to Story 1.3 (carry-forward)

- **3 cookies, not 1:** `authentication`, `affinity`, `language`. `PersistCookieJar` persists all three automatically — the `dio_cookie_manager` interceptor handles the Set-Cookie / Cookie header round-trip.
- **HTTP 400 = unauthorized (Rhetos server bug #182):** The `badCertificateCallback` is only about TLS cert validation, not about HTTP auth errors. HTTP 400-based auth handling is Epic 2 territory.
- **baseUrl trailing slash:** eVisitor's Rhetos-based API requires the trailing `/` in the base URL. Omitting it causes 301 redirects that `dio` may follow incorrectly. `'https://www.evisitor.hr/eVisitorRhetos_API/'` — the slash is intentional.
- **Auth flow is deferred.** `dioProvider` has no `Authorization` header, no login interceptor, no cookie pre-seeding. First actual login call is Story 1.7. `PersistCookieJar` will be empty until then — that is correct and expected.

### Previous story intelligence (Stories 1.1 + 1.2)

- `lib/core/env/evisitor_env.dart` **already exists** with `EvisitorEnv` enum and top-level `final evisitorEnv` global. `dioProvider` imports and reads this — do NOT re-declare.
- `lib/design/`, `lib/widgets/`, `lib/main.dart` (DesignSystemPreview), `lib/core/env/` are the only content in `lib/` right now.
- Story 1.1 deferred: "proguard-rules.pro uses blanket `-keep class io.flutter.plugins.** { *; }` — refine to per-plugin rules when the plugin actually imports (Stories 1.3+)." Add per-plugin rules in AC13.
- Story 1.1 deferred: "`EVISITOR_ENV=fake` has no consumer branching in `lib/` yet. Consumer lands with Dio fake transport (Story 1.3+)." Story 1.3 is that consumer — close the deferred item.
- Story 1.1 deferred: "`network_security_config.xml` shell exists — `<pin-set>` owned entirely by Story 1.3." Story 1.3 adds the `<pin-set>` in AC12.
- `dart format` scope: `dart format --set-exit-if-changed lib test integration_test` (not `.`). Established in Story 1.1 review.
- `build_runner` output: `*.g.dart` and `*.freezed.dart` are **committed** (per architecture). Do NOT add them to `.gitignore`. Riverpod generator output goes into the same file as the source with `.g.dart` extension (e.g. `providers.dart` → `providers.g.dart`).

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| `final secProvider = Provider<SecurityService>((_) => SecurityService())` | `@Riverpod(keepAlive: true) SecurityService securityService(...)` — codegen only |
| Call `securityService.init()` inside `securityServiceProvider`'s build | Init in `main()`, inject via `overrideWithValue` |
| Store credentials in `drift` or `shared_preferences` | `flutter_secure_storage` only (`CredentialStore`) |
| Use `DefaultHttpClientAdapter` (Dio 4.x API) | `IOHttpClientAdapter` from `package:dio/io.dart` (Dio 5.x) |
| Use `sha256` from `package:cryptography` (async) in `badCertificateCallback` | `sha256.convert()` from `package:crypto` (synchronous) |
| Reuse the same nonce across `encrypt` calls | Generate a fresh `SecureRandom` nonce per call |
| Add `AuthInterceptor` or login logic | That is Story 2.3. Leave a `// TODO(story-2.3)` comment and stop. |
| Create `lib/app/app.dart` or `lib/app/router.dart` | Those wait for go_router in Story 1.5. `lib/app/providers.dart` only. |
| Import `test/fakes/evisitor_fake_adapter.dart` from `lib/` | Never. Test fakes stay in `test/`. `dioProvider` fake-path returns a plain Dio; tests inject the adapter via provider override. |
| Call `dart run build_runner build` in CI scripts | Generated files are committed. CI never runs `build_runner`. |
| Use `Dio()` directly in any feature class | Always read `ref.watch(dioProvider)` — single audit point. |
| Mix DER SHA-256 fingerprints with SPKI SHA-256 fingerprints | Dart `CertPins`: DER SHA-256 hex. Android NSC `<pin-set>`: SPKI SHA-256 base64. Document both. They differ. |
| Omit the `expiration` attribute in `<pin-set>` | `expiration` is required to prevent a stale-pin silent-bypass after cert rotation. |
| Add `evisitor_fake_adapter.dart` to `dependencies` | It's in `test/`, not `lib/`. Tests import it; production never does. |
| Call `flutter_secure_storage.deleteAll()` in `wipeCredentials` | Deletes ALL keys including other plugins'. Delete only the 3 named keys. |

### Project Structure Notes

**Directories created by this story:**
- `lib/core/result/`
- `lib/core/errors/`
- `lib/core/security/`
- `lib/features/settings/`
- `lib/app/`
- `test/fakes/`
- `test/unit/core/`
- `test/unit/settings/`
- `docs/security/`

**This story does NOT create:**
- `lib/core/logging/` — Story 9.1 (`AppLogger`)
- `lib/core/telemetry/` — Story 9.2
- `lib/core/time/` — Story 6.1
- `lib/core/feature_flags/` — arrives with Story 4.9 (mandate field flag)
- `lib/features/auth/` — Epic 2
- `lib/app/app.dart`, `lib/app/router.dart` — Story 1.5
- Any Freezed models — first Freezed model arrives with Story 3.1 or 5.1
- Any Drift tables — Story 5.1

**Providers in this story (all in `lib/app/providers.dart`):**
- `securityServiceProvider` — `@Riverpod(keepAlive: true)` → throws if not overridden
- `cookieJarDirectoryProvider` — `@Riverpod(keepAlive: true)` → throws if not overridden
- `dioProvider` — `@Riverpod(keepAlive: true)` → depends on above two

### References

- [Architecture §Security Architecture, §HTTP/Networking Stack, §File/Folder Structure, §Riverpod Topology, §Dependency Table](../planning-artifacts/architecture.md)
- [Architecture §Directory Layout — `lib/core/security/`, `lib/features/settings/`, `lib/app/providers.dart`](../planning-artifacts/architecture.md)
- [CLAUDE.md §Tech Stack — Riverpod 3, Dio 5.x, dio_cookie_manager, flutter_secure_storage, Result contract](../../CLAUDE.md)
- [CLAUDE.md §Architecture — Result contract, Drift-as-truth, Riverpod patterns](../../CLAUDE.md)
- [eVisitor API reference in project memory — 3 cookies (authentication/affinity/language), NOT .ASPXAUTH; Rhetos HTTP 400 quirk; baseUrl trailing slash](../../../.claude/projects/-Users-darko-Documents-Projects-private-prijavko/memory/reference_evisitor.md)
- [Story 1.1 — ProGuard deferred, network_security_config.xml shell, EVISITOR_ENV=fake deferred](./1-1-project-bootstrap-and-ci-foundation.md)
- [Story 1.2 — `lib/design/`, `lib/widgets/`, `lib/main.dart` current shape, dependency pattern](./1-2-design-system-foundation.md)
- [Deferred work — EVISITOR_ENV=fake consumer, network_security_config.xml pin-set, ProGuard per-plugin rules](./deferred-work.md)
- [PRD NFR-S1 (HTTPS-only), NFR-S2 (Keystore credentials), NFR-S5 (FLAG_SECURE), NFR-S6 (no backup), NFR-S7 (PII discipline)](../planning-artifacts/prd.md)
- [`flutter_riverpod` + `riverpod_generator` — pub.dev (verify @Riverpod codegen API at install time)](https://pub.dev/packages/flutter_riverpod)
- [`dio` 5.x — pub.dev (verify IOHttpClientAdapter API; was DefaultHttpClientAdapter in 4.x)](https://pub.dev/packages/dio)
- [`cryptography_flutter` — pub.dev (AES-256-GCM, hardware-accelerated on Android)](https://pub.dev/packages/cryptography_flutter)
- [`flutter_secure_storage` — pub.dev (AndroidOptions, first_unlock_this_device accessibility)](https://pub.dev/packages/flutter_secure_storage)
- [`cookie_jar` 4.x — pub.dev (Storage interface, PersistCookieJar, FileStorage export status)](https://pub.dev/packages/cookie_jar)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Riverpod ecosystem pinned to 2.6.x stable (flutter_riverpod, riverpod_annotation, riverpod_generator) — Riverpod 3.x was incompatible with Dart SDK 3.10.7 at the time of implementation.
- `flutter_secure_storage` v10 API: `encryptedSharedPreferences` parameter is deprecated; `IOSOptions`/`MacOsOptions` renamed to `AppleOptions`. Removed the deprecated parameter; used default constructor.
- `ProviderRef<T>` deprecated in Riverpod 2.6.x — replaced with `Ref` (from `flutter_riverpod`, not re-exported by `riverpod_annotation`).
- `cryptography` added as explicit direct dependency (was only a transitive dep but imported directly in `aes_gcm_helper.dart`).
- Real cert fingerprints obtained via `openssl s_client` at 2026-04-27. Leaf cert expires 2026-10-19; `<pin-set expiration>` set to 2026-09-19 (30-day buffer). Rotate trigger = 2026-09-19.

### Completion Notes List

- All 11 tasks completed; 67/67 unit tests pass.
- `dart analyze --fatal-warnings --fatal-infos` — clean.
- `dart format` — clean.
- Release AAB built successfully (40.1MB) with no R8/ProGuard errors.
- PII grep guard and icons guard both rc=1 (no matches).
- `providers.g.dart` committed; CI must NOT run `build_runner`.
- `EVISITOR_ENV=fake` branch in `dioProvider` creates a plain Dio with no cert pinning or cookies; integration tests override `dioProvider` entirely with `EvisitorFakeAdapter`.
- `dioProvider` `// TODO(story-2.3): AuthInterceptor wires here` comment in place.

### File List

**New files:**
- `lib/core/result/result.dart`
- `lib/core/errors/app_error.dart`
- `lib/core/security/cert_pins.dart`
- `lib/core/security/aes_gcm_helper.dart`
- `lib/core/security/security_service.dart`
- `lib/core/security/encrypted_storage.dart`
- `lib/features/settings/credential_store.dart`
- `lib/app/providers.dart`
- `lib/app/providers.g.dart`
- `test/fakes/fake_security_service.dart`
- `test/fakes/evisitor_fake_adapter.dart`
- `test/unit/core/result_test.dart`
- `test/unit/core/cert_pins_test.dart`
- `test/unit/core/aes_gcm_helper_test.dart`
- `test/unit/settings/credential_store_test.dart`
- `docs/security/cert-pins.md`

**Modified files:**
- `pubspec.yaml` — added 9 prod deps + 2 dev deps
- `pubspec.lock` — updated
- `android/app/proguard-rules.pro` — per-plugin keep rules for flutter_secure_storage + path_provider
- `android/app/src/main/res/xml/network_security_config.xml` — `<pin-set>` added
- `lib/main.dart` — async main, SecurityService.init(), ProviderScope wiring
- `integration_test/app_test.dart` — ProviderScope with fake overrides

### Review Findings

_Code review on 2026-04-27. 5 decision-needed, 10 patch, 8 deferred, 14 dismissed as noise._

**Decision-needed (resolve before patches):**

- [x] [Review][Decision] **EncryptedStorage.deleteAll wipes whole directory and breaks subsequent writes** — Current impl `dir.delete(recursive: true)` ignores the `keys` arg AND leaves the dir nonexistent, so the next `write()` throws `FileSystemException`. Spec AC4.7 said "iterate keys + sweep extras". Options: (a) restore literal spec — iterate per-key, then sweep files not in keys; (b) keep full-wipe semantics but recreate the directory afterward; (c) accept current behavior. [lib/core/security/encrypted_storage.dart:60-66]
- [x] [Review][Decision] **PersistCookieJar `persistSession` not set** — `PersistCookieJar(storage: storage)` defaults to `persistSession: false, ignoreExpires: false`. eVisitor's `authentication` cookie may be issued without `max-age` (session cookie); project memory mandates "cookie must persist across process death". Options: (a) `persistSession: true, ignoreExpires: false`; (b) accept default and let Story 1.7 decide; (c) defer until login lands. [lib/app/providers.dart PersistCookieJar construction]
- [x] [Review][Decision] **CertPins positive-path test does not test the positive path** — Test admits SHA-256 inversion is impossible and only validates fingerprints are 64-char hex. Spec AC11.2 explicitly required `derBytes whose SHA-256 matches → returns true`. A regression that flipped `==` to `!=` in `validFingerprints.contains` would still pass. Options: (a) refactor `CertPins` to allow injectable fingerprint set + add fixture-bytes round-trip test; (b) commit a known fixture DER and add its fingerprint to `validFingerprints` permanently for testing; (c) accept current structural-only test. [test/unit/core/cert_pins_test.dart:62-93]
- [x] [Review][Decision] **EncryptedStorage.init creates `${baseDir}ie<flag>_ps<flag>/` subpath** — Spec AC4.3 said `Directory(directory).create(recursive: true)` literally; code mimics FileStorage's flag-encoded sub-path. Silent scope expansion not noted in code comments. Options: (a) revert to literal directory; (b) keep + add `// WHY:` explaining FileStorage compat. [lib/core/security/encrypted_storage.dart:22-30]
- [x] [Review][Decision] **`<pin-set>` lacks a backup pin** — Only leaf + intermediate pinned. If both rotate together (CA migration, force re-issuance), all installs hard-fail TLS with no fallback. Industry guidance: leaf + intermediate + backup root/CA. Spec AC1.2 specified leaf+intermediate only. Options: (a) add a backup pin (e.g., DigiCert/Sectigo root) + document expiry; (b) accept current per spec and rely on the force-update path (Story 9.4). [android/app/src/main/res/xml/network_security_config.xml]

**Patch:**

- [x] [Review][Patch] **EncryptedStorage.read should swallow corruption gracefully** [lib/core/security/encrypted_storage.dart:33-39] — wrap base64Decode + decrypt in try/catch; on `FormatException`/`RangeError`/`SecretBoxAuthenticationError` return `null` and best-effort delete the bad file. A single corrupt cookie file currently kills every subsequent request because `PersistCookieJar.loadForRequest` doesn't wrap in `Result`.
- [x] [Review][Patch] **AesGcmHelper.decrypt must validate length ≥ 28 upfront** [lib/core/security/aes_gcm_helper.dart:60-77] — guard `if (ciphertext.length < 28) throw ArgumentError(...)` before sublist, else short input throws opaque `RangeError` instead of the documented `SecretBoxAuthenticationError`.
- [x] [Review][Patch] **`_sanitizeKey` collisions** [lib/core/security/encrypted_storage.dart:_sanitizeKey] — `key.replaceAll('/', '_')` makes `a/b` and `a_b` collide on the same file. Use `base64Url.encode(utf8.encode(key))` (no padding stripped) — collision-free + reversible for `readAll`-style enumerations.
- [x] [Review][Patch] **CredentialStore: narrow `catch` and reject empty creds** [lib/features/settings/credential_store.dart] — (a) replace `catch (e)` with `catch (PlatformException e)` so programming errors (StateError, OOM) aren't swallowed into `StorageError`; (b) reject empty `username`/`password`/`apiKey` in `saveCredentials` (return `Err`) — empty creds currently round-trip through `loadCredentials` as `Ok(Credentials('', '', ''))`, breaking the Poka-yoke claim.
- [x] [Review][Patch] **AES-GCM tampered tests should also flip nonce + ciphertext bytes** [test/unit/core/aes_gcm_helper_test.dart] — current test only flips a MAC byte. Add: flip byte at offset 0 (nonce), flip byte between offset 12 and length-16 (ciphertext body). AES-GCM authenticates `nonce || ciphertext || aad` — all three regions must trip MAC verification.
- [x] [Review][Patch] **AES-GCM empty-plaintext round-trip test missing** [test/unit/core/aes_gcm_helper_test.dart] — add `encrypt(Uint8List(0))` → `decrypt(...)` returns empty bytes. PersistCookieJar may write empty cookie values.
- [x] [Review][Patch] **integration_test missing tearDown** [integration_test/app_test.dart] — encrypted cookie files leak in `Directory.systemTemp.path` between runs (no `tearDown`). On parallel test runs, instances collide. Add tearDown to delete the override directory.
- [x] [Review][Patch] **SecurityService — single Random.secure() instance** [lib/core/security/security_service.dart:42-44] — `List.generate(32, (_) => Random.secure().nextInt(256))` constructs 32 separate `SecureRandom` instances (each a JNI call on Android). Hoist `final r = Random.secure();` and call `r.nextInt(256)` 32 times.
- [x] [Review][Patch] **StorageError.toString() override** [lib/core/errors/app_error.dart] — `cause` (`Object?`) may leak via interpolation `'$err'` if a developer ever interpolates the object. Override `toString() => 'StorageError($message)'` so PII never reaches Crashlytics by accident — Poka-yoke per AC6.3.
- [x] [Review][Patch] **CertPins host normalization** [lib/core/security/cert_pins.dart:isTrustedCertificate] — `host != 'www.evisitor.hr'` is case-sensitive and rejects FQDN trailing dot. Use `host.toLowerCase().replaceAll(RegExp(r'\.+$'), '') != 'www.evisitor.hr'` so `WWW.EVISITOR.HR` and `www.evisitor.hr.` route to the fingerprint check instead of failing closed silently.

**Deferred:**

- [x] [Review][Defer] **EncryptedStorage methods before init guard** [lib/core/security/encrypted_storage.dart] — `late _currentDirectory` throws unhelpful `LateInitializationError` if `read/write/delete` runs before `init`. PersistCookieJar always calls init first today; harden when a second caller appears.
- [x] [Review][Defer] **SecurityService.init re-entrancy on hot-restart** [lib/core/security/security_service.dart:32-51] — concurrent `init()` calls can pass the `_initialized` guard during the await window, generating two keys. Hot-restart edge case; revisit when AuthNotifier (Story 2.x) starts touching `init`.
- [x] [Review][Defer] **EvisitorFakeAdapter returns 200 for any path** [test/fakes/evisitor_fake_adapter.dart] — flesh out endpoint routing in Story 1.7 (login) and Story 6.3 (ImportTourists) per the existing TODO comment.
- [x] [Review][Defer] **fake env compile-time guard for prod builds** [lib/app/providers.dart] — assert `evisitorEnv != fake` in `kReleaseMode`; prevents misconfigured release shipping plaintext localhost + no pinning. Wire when Story 10.x release-readiness lands.
- [x] [Review][Defer] **`cryptography_flutter` unmaintained — track for replacement** [pubspec.yaml] — last release > 2 years; evaluate replacement before Epic 5 (Drift PII column encryption) hardens dependence.
- [x] [Review][Defer] **FakeFlutterSecureStorage incomplete coverage** [test/unit/settings/credential_store_test.dart] — overrides only `read/write/delete`; future tests calling `containsKey/readAll/deleteAll` will throw `MissingPluginException` from the unoverridden methods. Extend when needed.
- [x] [Review][Defer] **integration_test dioProvider override is dead code today** [integration_test/app_test.dart] — no widget consumes `dioProvider` until first network-call screen lands (Story 1.7). The override is harmless prep; revisit when WelcomeScreen (Story 1.5) or LoginScreen (Story 1.7) actually triggers the path.
- [x] [Review][Defer] **SecurityService corrupt stored value handling** [lib/core/security/security_service.dart:40-49] — Jidoka by AC9.4 WHY ("crashes visibly at launch rather than silently"). Re-evaluate if real-world corrupt-state reports come in (backup restore to new device, OS upgrade quirks).
