---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-04-23'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/product-brief-prijavko.md
  - _bmad-output/planning-artifacts/product-brief-prijavko-distillate.md
  - _bmad-output/planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md
  - _bmad-output/brainstorming/brainstorming-session-2026-04-22-2127.md
  - _bmad-output/planning-artifacts/implementation-readiness-report-2026-04-23.md
workflowType: 'architecture'
project_name: 'prijavko'
user_name: 'Darko'
date: '2026-04-23'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional:** 46 FRs across 11 categories — Onboarding & Consent (FR1–FR7), Auth Lifecycle (FR8–FR14.5), Facility Management (FR15–FR19), Guest Capture (FR20–FR26), Queue & Local Persistence (FR27–FR31.5), Submission/Send All (FR32–FR36.6), Post-Submission Closure (FR37–FR38), Privacy & Data Lifecycle (FR39–FR40), Observability & Compliance Signals (FR41–FR42). Verb-prefixed and testable. Every journey capability maps to ≥1 FR.

**Non-Functional:** 58 NFRs across 8 dimensions — Performance (10), Security (11), Reliability (9), Integration (7), Compatibility (5), Localization (4), Accessibility (4), Maintainability (8). Crash-free ≥99.5%, scan_to_submit ≥90% no-correction, silent-failure = 0 in peak season, zero-PII in logs enforced at build time, OWASP MASVS L1 self-audit.

**Scale & Complexity:**
- Primary domain: Android-only Flutter mobile app, single-activity, single user, single external integration (eVisitor Rhetos).
- System topology: LOW — no backend, no multi-tenancy, no sync, no admin.
- Engineering discipline: HIGH — type-level privacy, 6-state auth FSM, HTTP-400-SystemMessage classifier, permanent in-repo Dio fake, CI-gated contract drift detection, circuit breaker more conservative than server lockout.
- Integration complexity: HIGH — undocumented Rhetos, Croatian error envelopes, no refresh token, HTTP 400-masquerading-as-401 (Rhetos issue #182), dates in .NET JSON format, ImportTourists XML-as-string-in-JSON.
- Regulatory complexity: HIGH — Play Store sensitive-data manual review, GDPR Art. 32 rigor, Croatian tourism law, AdMob sensitive-content.
- UI complexity: MEDIUM — ~12–15 screens, 3-tier capture pipeline, non-blocking banners, per-guest progress; no real-time, no collaboration, no gestures.
- Data complexity: LOW — ephemeral queue (~40 guests/session cap), eVisitor is the authoritative store, 3-day soft-undo buffer post-submission.
- Estimated architectural components: ~10 (auth, classifier, queue, submission, capture, facility, settings, privacy, telemetry, version-gate), ~6 shared primitives (security, time, localization, logging facade, error types, feature flags).

### Technical Constraints & Dependencies

**Stack committed (PRD §22, distillate §22):**
Flutter 3.x / Dart 3.x, Dio 5.x + `dio_cookie_manager` + PersistCookieJar, `flutter_secure_storage` (Keystore), Drift/SQLite, Riverpod 3, Freezed + `build_runner`, Firebase Crashlytics, AdMob + UMP/CMP SDK, in-repo Dio fake as permanent first-class artifact, Google Play Console Closed Beta track.

**Rejected (distillate §12 — do not re-propose):** backend/PWA host surface, Sentry, FCM, WorkManager, background auto-retry, geolocation, home-screen widget (v1.0), remote config, iCal import, tax calculator, iOS (v1.0), configurable retention window, single-OIB-per-install.

**Platform:** Android-only, min API 24, target SDK latest per Play mandate at 2026-05-27, arm64-v8a + armeabi-v7a, HTTPS-only (cleartext rejected at platform level), `allowBackup="false"` + `fullBackupContent="false"`.

**External contract quirks (eVisitor research, 2026-04-22):**
- 3 named cookies: `authentication`, `affinity`, `language` (NOT `.ASPXAUTH`)
- HTTP 400 for unauthorized (Rhetos issue #182) — classifier must inspect status code AND body `SystemMessage`
- `ImportTourists` = XML wrapped as a JSON string field (not pure XML or JSON)
- Dates: .NET JSON `/Date(ms+offset)/`, NOT `YYYYMMDD`
- No refresh token — re-auth is always full re-login with stored creds
- Rhetos server-side lockout: 5 failures → 5-minute lock
- Login may return HTTP 200 with error envelope `{UserMessage, SystemMessage}`
- Cookie TTL likely 14 days sliding (ASP.NET Core Identity default, unverified)

**Spike-gated unknowns (Week-1 blockers):**
- FR26 May-2026 mandate payload shape
- eVisitor idempotency key support
- Server-side reported-history endpoint existence (v1.1 Pro blocker)
- FR36.6 lookup-by-client-UUID endpoint for in_flight reconciliation

**Operational constraints:**
- Solo-dev, ~12 effective working days to 2026-05-27 submission
- Pre-peak code freeze 2026-06-15 (bugs-only June–Aug)
- Budget sub-€500 out-of-pocket
- Sensitive-data Play Store review 1–3 weeks expected

### Cross-Cutting Concerns Identified

1. **Error classification** — a first-class type, not a utility. Variants: auth-session-dead, auth-locked-out, auth-creds-invalid, network, validation, throttling (HTTP 429), server-error, contract-break. Consumed by classifier, interceptor, UI banners, telemetry, circuit breaker.

2. **Time** — Europe/Zagreb local for UI; UTC for eVisitor payloads; `/Date(ms+offset)/` on the wire. Single time service, used everywhere.

3. **Localization** — Croatian primary + Android system locale fallback; `UserMessage` surfaces unmodified + prijavko-provided Croatian explanations; no English-only strings (NFR-L4 blocks release on missing translations).

4. **Observability** — zero-PII Crashlytics custom events: `scan_to_submit`, `auth_state_transition`, `send_all_result`, `queue_purge`, `classifier_mismatch`, `queue_stuck_24h`. Every subsystem emits; no subsystem emits free text from guest records. Custom-key allowlist is build-time-checked.

5. **Security primitives** — Keystore-wrapped AES-GCM key, cert pinning set (leaf + intermediate SHA-256), `allowBackup=false`. Shared across auth (cookie jar + creds), queue (PII columns), and key management.

6. **PII redaction as compile-time property** — PII-bearing types override `toString() → [REDACTED type=X]`; log facade rejects raw PII at the type signature; CI grep guard fails builds on forbidden log patterns. Not a runtime guard — a type invariant.

7. **Feature flags** — tiny, local. FR26 May-2026 mandate payload, ad-placement pivot trigger. `const bool` + `enum` is sufficient; no remote config.

8. **Version gating** — static `prijavko.hr/min-version.json` polled on cold start; forced-update banner blocks Send All when current build < minSupportedVersion. Intersects with auth (block send), queue (preserve unsent), settings (visible state).

9. **CI as part of the architecture** — permanent Dio fake + nightly testApi canary + zero-PII grep guard + `dart analyze --fatal-warnings --fatal-infos` + OWASP MASVS L1 checklist + feature-flag audit. These are build-time gates encoded in CI config, not external process.

## Starter Template Evaluation

### Primary Technology Domain

Android-only Flutter 3.x mobile app — stack pre-committed in PRD §22 and distillate §22. This step decides the init command and starter opinions (not framework selection, which is already fixed).

### Starter Options Considered

| Option | Verdict | Rationale |
|---|---|---|
| Vanilla `flutter create --empty` | ✅ Selected | Minimalism wins; Android-only by construction; no speculative scaffolding to delete; craftsmanship rules (Monozukuri, JIT) aligned. |
| Very Good CLI (`very_good create`) | ❌ Rejected | Bloc-opinionated; conflicts with committed Riverpod 3 stack. Flavors are overkill for v1.0 single-env app (prod vs testApi = one `--dart-define`). |
| Community Riverpod quickstarts | ❌ Rejected | Unmaintained, unofficial, no guarantee of Riverpod 3 + Dart 3 + current lint tracking. Copy-from-docs beats forking others' preferences. |
| Clean-architecture templates | ❌ Rejected | Speculative abstraction; violates JIT. Layering is decided in step 06 Structure based on actual subsystems, not pre-imported. |

### Selected Starter: vanilla `flutter create --empty`

**Rationale for Selection:**
- Minimalism — empty main.dart means zero speculative scaffolding; every file earns its place.
- Android-only by construction via `--platforms=android` — no cross-platform directory cruft matching the PRD explicit non-goal of iOS/web abstraction in v1.0.
- Solo-dev economics — a committed stack added one package at a time costs less total time than fighting an opinionated starter.
- Play Store reviewability — clean vanilla project surfaces only what we added, no unused defaults to explain during sensitive-data manual review.
- Craftsmanship alignment — every linter rule, CI workflow, and permission added explicitly, auditable from commit #1.

**Initialization Command:**

```bash
flutter create \
  --org hr.prijavko \
  --project-name prijavko \
  --platforms=android \
  --empty \
  -a kotlin \
  .
```

**Flag Rationale:**

| Flag | Why |
|---|---|
| `--org hr.prijavko` | Android applicationId `hr.prijavko.prijavko`; matches `prijavko.hr` domain (owned before submission). |
| `--project-name prijavko` | Dart package name + Play Store import slug. |
| `--platforms=android` | No iOS/web/desktop directories; matches v1.0 non-goal. |
| `--empty` | Minimal main.dart, no counter-app demo. |
| `-a kotlin` | Explicit default; future platform-channel code is Kotlin. |
| `.` | Generate into current repo root (already a git repo). |

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
Dart 3.x (from stable Flutter channel, currently 3.41.x), null-safety enforced, sound by default.

**Build Tooling:**
`flutter pub` + `build_runner` for codegen (Freezed, Drift, Riverpod generators added in later stories). Gradle 8.x + AGP per Flutter stable defaults. R8 code shrinking + Dart `--obfuscate --split-debug-info` in release builds; ProGuard rules for Drift/Riverpod/Freezed/Dio committed explicitly.

**Testing Framework:**
`flutter_test` (unit + widget) — default. `integration_test` (E2E) — added in story 1.x, needed for Dio fake harness (PRD §Testing, NFR-I4).

**Code Organization:**
Starter produces: `lib/main.dart`, `android/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`. No feature-layer structure imposed — decided in step 06 (Structure) based on the ~10 subsystems identified in step 02.

**Development Experience:**
Hot reload via `flutter run`. `dart format` + `dart analyze` out of the box; `--fatal-warnings --fatal-infos` enabled in CI (NFR-M1). Android Studio / VS Code parity.

### What the Starter Does NOT Provide (added in later stories)

- `analysis_options.yaml` tightened with strict rules + `--fatal-infos` CI gate.
- Dependency set: Riverpod 3, Freezed, Drift, Dio 5.x, `dio_cookie_manager`, PersistCookieJar, `flutter_secure_storage`, `firebase_crashlytics`, `google_mobile_ads`, UMP/CMP SDK.
- GitHub Actions workflows: CI grep guard, `dart analyze --fatal-infos`, `flutter test`, integration test against Dio fake, nightly testApi canary, forbidden-log-pattern check.
- `network_security_config.xml` with cert-pinning declaration and `cleartextTrafficPermitted="false"`.
- `AndroidManifest.xml` edits: `allowBackup="false"`, `fullBackupContent="false"`, camera permission with Play Store justification string, target SDK per Play policy at submission date.
- Permanent in-repo Dio fake harness structure (NFR-I4).

### Environment Switching Strategy (no flavors)

Instead of dev/staging/prod Android flavors, use a single `--dart-define=EVISITOR_ENV=<prod|test>` toggle read at runtime via `String.fromEnvironment('EVISITOR_ENV', defaultValue: 'prod')`. Rationale: v1.0 has exactly two environments (eVisitor prod + testApi) — flavors are overkill. Nightly CI canary uses `EVISITOR_ENV=test`. No Gradle buildType sprawl. JIT escalation to flavors only if v1.1 adds a third environment.

**Note:** Project initialization using the above `flutter create` command is the first implementation story (Epic 1, Story 1.1). All "NOT provided by starter" items are separately-tracked, testable stories.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (block implementation):**
- D1 MRZ capture stack — gates entire Capture Pipeline (Epic 4)
- D3 Auth state machine representation — gates Auth Lifecycle (Epic 2)
- D8 `in_flight` reconciliation design — gates Send All (Epic 6); path conditional on Week-1 spike

**Important Decisions (shape architecture):**
- D2 AES-GCM library — affects cookie jar, Drift column encryption, key management
- D4 Navigation — go_router with auth redirect
- D5 Riverpod 3 topology — how auth state flows to the interceptor + UI
- D6 Log facade — single auditable PII chokepoint
- D7 Cert pinning — DIY, no extra package

**Deferred Decisions (post-MVP):**
- Multi-OIB UI Riverpod topology (schema-ready in v1.0; UI in v1.1)
- NFC chip read camera pipeline (v1.1 — `flutter_nfc_kit`)
- Compliance receipt PDF generation approach (v1.1 Pro IAP)
- Play Store In-App Review API integration (v1.1 post-launch signal)

### Data Architecture

**Drift / SQLite schema design philosophy:**
One `AppDatabase` class with three tables. Tables created only when the epic that owns them is implemented (JIT, not upfront schema creation):
- `GuestEntriesTable` — owned by Epic 5 (Queue). Columns: `id` (UUID String, PK), `facilityId` (String FK), `encryptedPayload` (String — AES-GCM ciphertext of full guest JSON), `state` (enum: `unsent | in_flight | submitted | failed`), `clientCreatedAt` (DateTime), `submittedAt` (DateTime nullable), `purgeAfter` (DateTime nullable — set to `submittedAt + 3 days` on success, null if unsent/failed).
- `FacilitiesTable` — owned by Epic 3. Columns: `id` (String PK), `oib` (String), `name` (String), `lastUsedAt` (DateTime nullable). No PII; no encryption.
- No auth state in Drift — ever. Auth lives only in `flutter_secure_storage` (credentials) + AES-GCM file (cookie jar).

**Queue entry state machine:**
`unsent → in_flight` (Send All triggered) → `submitted | failed` (response received). On app resume: any `in_flight` entries are treated as unresolved — see D8.

**AES-GCM encryption — `cryptography` + `cryptography_flutter`:**

| Data | Storage | Encryption |
|---|---|---|
| Credentials (`userName`, `password`, `apikey`) | `flutter_secure_storage` | Keystore-backed AES/GCM (platform-native) |
| Cookie jar (`authentication`, `affinity`, `language`) | Encrypted file on app-internal storage | AES-GCM via `cryptography_flutter`; key held in `flutter_secure_storage` |
| Guest PII columns in Drift | `GuestEntriesTable.encryptedPayload` | AES-GCM via `cryptography_flutter`; same Keystore-backed key |
| Facility cache | Drift `FacilitiesTable` | None — no PII |

Drift column encryption approach: the entire guest payload is serialized to JSON, encrypted as a single ciphertext string, and stored in `encryptedPayload`. A `TypeConverter<GuestEntry, String>` on the Drift table handles encrypt/decrypt transparently. The encryption key is loaded once at app start from `flutter_secure_storage` and held in memory by the `SecurityService` (not re-fetched per row).

**3-day auto-purge:** Runs in a `dart:async` `Timer` triggered at app open (not an isolate, not WorkManager). Queries `purgeAfter < DateTime.now()` with an index on `purgeAfter`. Expected row count is low (≤40 submitted per session × rolling 3 days), so main-isolate is fine. Confirmed by NFR-P10 (≥40 guests without degradation) and NFR-M6 (no foreground services).

### Authentication & Security

**Auth state machine — Dart 3 `sealed class`:**

```dart
sealed class AuthState { const AuthState(); }
final class Initial           extends AuthState { const Initial(); }
final class Unauthenticated   extends AuthState { const Unauthenticated(); }
final class Authenticating    extends AuthState { const Authenticating(); }
final class Authenticated     extends AuthState {
  const Authenticated({required this.facilitiesLoaded});
  final bool facilitiesLoaded;
}
final class Reauth            extends AuthState { const Reauth(); }
final class LockedOut         extends AuthState {
  const LockedOut({required this.retryAfter});
  final DateTime retryAfter;
}
final class AuthFailure       extends AuthState {
  const AuthFailure({required this.reason});
  final AuthFailureReason reason; // enum: sessionDead | credentialsInvalid | lockedOut | network | contractBreak
}
```

Rationale: Dart 3 native, zero codegen, compile-time exhaustive `switch`. Freezed not used here (no copyWith needed for FSM transitions; variants carry minimal data). NFR-R7 invariant (exactly one concurrent login) enforced by the `QueuedInterceptor` holding a reference to `AuthNotifier` via the Dio provider factory.

**QueuedInterceptor topology:**
`QueuedInterceptor` subclass (`AuthInterceptor`) is instantiated inside the Dio provider factory, which closes over the `Ref`. On `onError`: calls `ref.read(authNotifierProvider.notifier).handleAuthFailure(classifiedError)` which (a) classifies the error, (b) triggers re-login if `sessionDead`, (c) enforces circuit breaker, (d) transitions state machine. Concurrent 401/400s queue behind the single re-auth operation.

**Circuit breaker:** 3 consecutive login failures → 6-minute open (stricter than Rhetos 5/5-min). Implemented as `consecutiveFailures` + `lockedUntil` fields on `AuthNotifier` state; not a separate class.

**Certificate pinning — DIY:**
```dart
// Inside Dio factory:
(adapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  client.badCertificateCallback = (cert, host, port) {
    if (host != 'www.evisitor.hr') return false;
    final fingerprint = _sha256Fingerprint(cert.der);
    return CertPins.validFingerprints.contains(fingerprint);
  };
  return client;
};
```
`CertPins` is a dedicated `const` file documenting: pin values, cert validity dates, forced-update trigger date (when pins must rotate). No pinning package dependency.

**OWASP MASVS L1 self-audit:** Documented checklist committed to `docs/security/masvs-l1-checklist.md`, reviewed pre-submission (NFR-S9).

### API & Communication

**MRZ capture stack — `google_mlkit_text_recognition` + `camera` + inline parser:**

Rationale: precise ownership of the auto-shutter timing (NFR-P1 ≤1.5s p95), static-tap fallback surface (NFR-P2 at exactly 3s), and 3-tier pipeline. Wrapper packages black-box the camera loop and make fallback timing non-deterministic.

| Package | Role |
|---|---|
| `camera` (Flutter official, CameraX-backed) | Camera preview, image stream, static capture |
| `google_mlkit_text_recognition` | On-device MRZ text detection (no cloud, no PII transmission) |
| Inline MRZ parser (pure Dart) | TD1/TD2/TD3 zone parsing, checksum validation, semantic sanity layer |

**Capture pipeline flow:**
1. Camera stream → ML Kit frame analysis loop.
2. On valid MRZ checksum: fire haptic, commit to Drift synchronously, emit `scan_to_submit` event start.
3. 3-second timer running since camera open: if no valid MRZ → surface static-tap control (NFR-P2).
4. Static-tap → single image capture → ML Kit on still image. If still no valid MRZ → surface manual-entry screen.
5. Semantic sanity layer runs in all three paths before queue commit (NFR-P4 ≤50ms).

**Permanent Dio fake harness:**
An `HttpClientAdapter` implementation that serves pre-canned responses matching eVisitor's known response shapes. Stored at `test/fakes/evisitor_fake_adapter.dart`. Selected via `--dart-define=EVISITOR_ENV=fake` in integration tests. Covers: login success/failure, HTTP 401/403/400+SystemMessage, Croatian error envelope variants, `ImportTourists` XML-in-JSON round-trip, `/Date(ms+offset)/` parsing.

**Error classifier — first-class type:**
```dart
enum EvisitorErrorClass {
  sessionDead,    // 401 | 403 | 400+SystemMessage | 200+errorEnvelope@non-Login
  lockedOut,      // SystemMessage matches /locked|zaključan/i
  credentialsInvalid, // SystemMessage matches /invalid|nevažeć|neispra/i
  throttled,      // HTTP 429 or equivalent
  network,        // connection timeout, no-internet
  serverError,    // 5xx
  contractBreak,  // response shape unrecognizable → triggers forced-update check
  validationError // guest field rejected by eVisitor
}
```
Classifier is a pure function `classify(DioException) → EvisitorErrorClass`. Tested exhaustively by integration test harness.

### App Architecture (Frontend)

**Navigation — `go_router` v14+ with auth-conditional redirect:**
- `redirect` callback reads `authNotifierProvider` state synchronously.
- `Unauthenticated | AuthFailure` → `/onboarding`
- `LockedOut` → `/locked-out` (countdown screen)
- `Authenticated` → `/home` (or current route if already valid)
- Forced-update banner is a `ShellRoute` overlay, not a separate route — it sits above all routes and blocks interaction when active.

**Riverpod 3 topology:**

| Provider | Type | Scope | Owns |
|---|---|---|---|
| `authNotifierProvider` | `Notifier<AuthState>` | Global (root) | Six-state FSM, circuit breaker, re-auth trigger |
| `dioProvider` | `Provider<Dio>` | Global | Dio instance with `AuthInterceptor` wired to `authNotifierProvider` |
| `facilityNotifierProvider` | `AsyncNotifier<List<Facility>>` | Global | Facility fetch + cache; invalidated on logout |
| `queueNotifierProvider` | `AsyncNotifier<QueueSnapshot>` | Global | Queue read + state for home screen |
| `activeFacilityProvider` | `StateProvider<Facility?>` | Session-scoped | Current session's explicit facility selection (null = none chosen yet) |
| `sendAllNotifierProvider` | `AsyncNotifier<SendAllResult>` | Auto-disposed | Per-Send-All lifecycle; disposed after closure summary shown |

No `StateNotifier` (deprecated). No `ChangeNotifier`. `Notifier`/`AsyncNotifier`/`StateProvider` only.

**Log facade — custom `AppLogger`:**
Wraps `dart:developer`'s `log()`. Methods accept `String message` only — no `Object` overload, preventing accidental `.toString()` leakage. CI grep guard updated to target `AppLogger` call sites. All transitive SDK default logging reviewed pre-submission per NFR-S11.

**TelemetryService — centralized Crashlytics chokepoint:**
Singleton (plain Dart class, not a Riverpod provider). Exposes typed methods for each event:
```dart
void scanToSubmit({required int correctionsCount, required bool success});
void authStateTransition({required String from, required String to});
void sendAllResult({required int total, required int succeeded, required int failed});
void queuePurge({required int purgedCount});
void classifierMismatch({required int httpStatus, required String systemMessageHash}); // hash, not raw
void queueStuck24h({required int count});
```
No method accepts free text from guest records. `systemMessageHash` is SHA-256 of the raw message — loggable without PII exposure.

### Infrastructure & Deployment

**CI pipeline (GitHub Actions):**

| Job | Trigger | What it checks |
|---|---|---|
| `analyze` | Every push/PR | `dart analyze --fatal-warnings --fatal-infos` |
| `pii-guard` | Every push/PR | Grep for forbidden log patterns (documentNumber, firstName, etc. in log calls) |
| `test` | Every push/PR | `flutter test` (unit + widget) |
| `integration-fake` | Every push/PR | Integration tests against Dio fake harness |
| `testapi-canary` | Nightly (cron) | Integration tests against real eVisitor testApi with canary account; contract-drift detection |
| `build-aab` | Tag push (`v*`) | `flutter build appbundle --obfuscate --split-debug-info` |

**Version code strategy:** `v1.0.0` → versionCode `10000`, `v1.0.1` → `10001`. Git tag → CI build.

**Min-version forced-update:** Cold start polls `prijavko.hr/min-version.json`. Static file, zero backend. If `currentBuild < minSupportedVersion` → `ForceUpdateBanner` overlay activates, Send All blocked. Updated manually when breaking eVisitor contract change detected.

### Decision Impact Analysis

**Implementation sequence (respects epic dependency order from readiness report):**
1. Bootstrap + CI infrastructure (starter command, analysis options, GitHub Actions, grep guard)
2. Auth lifecycle (D3 sealed class, D5 AuthNotifier, D7 cert pinning, QueuedInterceptor, circuit breaker)
3. Facility management (Drift FacilitiesTable, go_router D4 redirect, activeFacilityProvider)
4. Capture pipeline (D1 ML Kit + camera + inline parser, semantic sanity layer)
5. Queue & Drift persistence (GuestEntriesTable, D2 AES-GCM column encryption, auto-purge)
6. Send All + submission (QueueNotifier, SendAllNotifier, D8 `in_flight` reconciliation, error classifier)
7. Closure, privacy surface, data wipe
8. Observability, forced-update, compliance readiness

**Cross-component dependencies:**
- `dioProvider` depends on `authNotifierProvider` — both initialized at app start before any route.
- `queueNotifierProvider` depends on `activeFacilityProvider` — queue is always facility-scoped.
- `sendAllNotifierProvider` depends on both queue state and auth state (pre-flight).
- `TelemetryService` is called by all notifiers — no Riverpod dependency, injected via constructor.
- D8 `in_flight` reconciliation path (A vs B) is a Week-1 spike outcome; architecture supports both without structural change.

**Spike-gated decisions (Week-1, must resolve before Epic 4/6):**
- FR26 May-2026 mandate payload shape → affects `ImportTourists` XML builder + semantic sanity layer
- eVisitor idempotency key support → affects queue UUID usage in ImportTourists payload
- FR36.6 lookup endpoint existence → determines D8 Path A vs Path B at runtime

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified

9 areas where AI story agents could make different choices that would conflict: file naming, Drift column naming, provider naming, date encoding, Result type usage, PII class handling, error routing, loading state expression, and import/export structure.

### Naming Patterns

**Dart file naming — always `snake_case.dart`:**
```
auth_notifier.dart         ✅
AuthNotifier.dart          ❌
authNotifier.dart          ❌
```

**Dart class naming — always `PascalCase`.**

**Drift table class naming — `PascalCase` + `Table` suffix; column getters camelCase:**
```dart
class GuestEntriesTable extends Table {    // ✅
  TextColumn get id => text()();
  TextColumn get encryptedPayload => text()();
  TextColumn get state => textEnum<QueueEntryState>()();
  DateTimeColumn get purgeAfter => dateTime().nullable()();
}
// ❌ class guestEntriesTable / class GuestEntries
```

**Riverpod provider naming — `camelCase` + `Provider` suffix:**
```dart
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(...);  // ✅
// ❌ AuthNotifierProvider, authProvider
```

**Crashlytics / TelemetryService event names — always `snake_case` matching PRD exactly:**
`scan_to_submit`, `auth_state_transition`, `send_all_result`, `queue_purge`, `classifier_mismatch`, `queue_stuck_24h`

**go_router route paths — kebab-case; route names — lowercase:**
```dart
GoRoute(path: '/send-all', name: 'send-all', ...)   // ✅
GoRoute(path: '/sendAll', name: 'sendAll', ...)       // ❌
```

**AppLogger calls — message is always a `String` literal or safe interpolation, never a PII object:**
```dart
AppLogger.debug('Auth state: $from → $to');         // ✅
AppLogger.debug('Guest: $guestEntry');               // ❌ toString() leaks PII
```

### Structure Patterns

**Feature-first directory layout under `lib/`:**
```
lib/
  core/
    security/          — SecurityService, CertPins, AES-GCM helpers
    time/              — EvisitorDateCodec, timezone utils
    logging/           — AppLogger
    telemetry/         — TelemetryService
    errors/            — EvisitorErrorClass, AppError, EvisitorErrorClassifier
    result/            — Result<T, E> sealed class
    feature_flags/     — FeatureFlags const class
  features/
    auth/              — AuthState, AuthNotifier, AuthInterceptor
    facility/          — Facility model, FacilityNotifier, FacilitiesTable
    capture/           — MrzCaptureService, SemanticSanityLayer, MrzParser
    queue/             — GuestEntry, QueueNotifier, GuestEntriesTable, AppDatabase
    submission/        — SendAllNotifier, ImportTouristsBuilder, EvisitorApiClient
    closure/           — ClosureSummary widget
    settings/          — CredentialStore, SettingsNotifier, YourDataScreen
    onboarding/        — OnboardingFlow, ConsentScreen, CredentialCaptureScreen
    version_gate/      — MinVersionChecker, ForceUpdateBanner
  app/
    router.dart        — GoRouter definition, redirect logic
    app.dart           — MaterialApp, ProviderScope root
    providers.dart     — top-level provider declarations
  main.dart
```

**Test directory structure:**
```
test/
  unit/                — pure Dart, no Flutter framework
  widget/              — flutter_test widget tests
  fakes/
    evisitor_fake_adapter.dart   — permanent Dio fake (first-class artifact)
    fake_security_service.dart
integration_test/
  app_test.dart        — E2E against Dio fake
  canary_test.dart     — nightly testApi canary (env-gated)
```

**Drift database ownership:** `lib/features/queue/` owns `AppDatabase` + all table definitions. Generated `*.g.dart` files are committed (not gitignored).

**Freezed / codegen files:** `*.freezed.dart` and `*.g.dart` committed to repo. `build_runner watch` for development only.

### Format Patterns

**Result type — `Result<T, AppError>` for all fallible service/repository methods; never throw across feature boundaries:**
```dart
// ✅
Future<Result<List<Facility>, AppError>> fetchFacilities();
// ❌
Future<List<Facility>> fetchFacilities() async { throw EvisitorException(...); }
```

`AppError` is a sealed class: `AuthError | NetworkError | ValidationError | ServerError | ContractBreakError`.

**Date / time — two contexts, never confused:**

| Context | API | Output |
|---|---|---|
| eVisitor payload | `EvisitorDateCodec.encode(dateTime)` | `/Date(ms+tz)/` String |
| UI display | `dateTime.toLocal()` + locale formatter | locale String |
| Internal Dart | `DateTime.now().toUtc()` | `DateTime` |

```dart
// ✅
final encoded = EvisitorDateCodec.encode(dateOfBirth);
// ❌ inline — forbidden everywhere except inside EvisitorDateCodec itself
final encoded = '\/Date(${dateOfBirth.millisecondsSinceEpoch}+0100)\/';
```

**ImportTourists XML — always through `ImportTouristsBuilder`; no inline XML string construction anywhere else.**

**Riverpod async state — always `AsyncValue<T>` + `.when()` in widgets; no bespoke `isLoading` booleans.**

### Communication Patterns

**Auth error routing — single entry point:**
```dart
// ✅ only valid call site (inside AuthInterceptor)
ref.read(authNotifierProvider.notifier).handleAuthFailure(classified);
// ❌ inline auth handling anywhere else
if (error is SessionDeadError) { _login(); }
```

**Queue writes — always through `QueueNotifier`:**
```dart
// ✅
await ref.read(queueNotifierProvider.notifier).enqueue(guestEntry);
// ❌ direct Drift access from widget or other notifier
await db.guestEntries.insertOne(row);
```

**State transitions — only via notifier methods; never `notifier.state = X` from outside the notifier.**

**Telemetry — only via `TelemetryService` typed methods; never `FirebaseCrashlytics.instance` directly.**

### Process Patterns

**PII class discipline — every class containing guest document fields MUST:**
1. Override `toString()` → `'[REDACTED type=${runtimeType} id=$id]'`
2. Not implement `==` on PII field values — use client UUID only

**CI grep guard forbidden pattern targets:**
```
(print|debugPrint|AppLogger\.\w+)\(.*\.(documentNumber|firstName|lastName|
dateOfBirth|nationality|documentExpiry|mrzLine1|mrzLine2)
```

**Loading state — `AsyncNotifier` pattern:**
```dart
// ✅
state = const AsyncLoading();
final result = await operation();
state = AsyncData(result);
// ❌
bool isLoading = false; isLoading = true; notifyListeners();
```

**`BuildContext` across async gaps — always check `mounted`:**
```dart
// ✅
await op(); if (!context.mounted) return; Navigator.of(context).pop();
// ❌
await op(); Navigator.of(context).pop();
```

**Widget extraction — extract at >50 lines or when the subtree has a meaningful name.**

**Null safety — no `!` in production paths; prefer null-check + early return.**

**`async`/`await` over `.then()` everywhere.**

### Enforcement Guidelines

**All AI story agents MUST:**

1. Place files in the feature directory that owns them.
2. Route all auth errors through `AuthNotifier.handleAuthFailure()`.
3. Write all queue state changes through `QueueNotifier` methods.
4. Use `EvisitorDateCodec.encode()` for all `/Date(ms+offset)/` values.
5. Use `ImportTouristsBuilder` for all XML payload construction.
6. Override `toString()` → `[REDACTED ...]` on every guest-document-field class.
7. Emit telemetry only via `TelemetryService` typed methods.
8. Return `Result<T, AppError>` from service/repository methods.
9. Check `context.mounted` after every `await` preceding context use.
10. Use `AsyncValue<T>` + `.when()` for loading state in widgets.

**Pattern enforcement:** CI `dart analyze --fatal-warnings` + build-blocking grep guard. Story acceptance criteria must reference relevant patterns above. Violations found during AI coverage review (NFR-M8) are remediated in the same week.

### Anti-Pattern Reference

| Anti-pattern | Correct pattern |
|---|---|
| Inline `/Date(...)` string | `EvisitorDateCodec.encode(dt)` |
| Inline ImportTourists XML | `ImportTouristsBuilder(...).build()` |
| `FirebaseCrashlytics.instance` outside TelemetryService | `TelemetryService.instance.methodName(...)` |
| Direct Drift write from widget/non-queue notifier | `QueueNotifier.enqueue(entry)` |
| Auth error handling outside `AuthNotifier` | `authNotifier.handleAuthFailure(error)` |
| PII object in any log call | `'[REDACTED type=GuestEntry id=${e.id}]'` |
| `notifier.state = X` from outside the notifier | Call an `AuthNotifier` method |
| `.then()` chaining | `async`/`await` |
| `!` null assertion in production paths | Null-check + early return |
| Anonymous `Builder` with >50 lines | Extract named `StatelessWidget` |

## Project Structure & Boundaries

### Complete Project Directory Structure

```
prijavko/
├── .github/
│   └── workflows/
│       ├── analyze.yml              — dart analyze --fatal-warnings --fatal-infos
│       ├── pii_guard.yml            — grep guard for forbidden log patterns (build-blocking)
│       ├── test.yml                 — flutter test (unit + widget)
│       ├── integration_fake.yml     — integration_test against Dio fake harness
│       ├── testapi_canary.yml       — nightly: real eVisitor testApi + canary account
│       └── build_aab.yml            — release AAB on git tag v*
├── android/
│   └── app/
│       ├── src/main/
│       │   ├── kotlin/hr/prijavko/prijavko/
│       │   │   └── MainActivity.kt
│       │   ├── res/xml/
│       │   │   └── network_security_config.xml  — cert pinning + cleartextTrafficPermitted=false
│       │   └── AndroidManifest.xml              — allowBackup=false, camera permission
│       └── build.gradle
├── docs/
│   └── security/
│       ├── masvs-l1-checklist.md    — OWASP MASVS L1 self-audit (NFR-S9)
│       └── cert-pins.md             — pin values, cert validity dates, forced-update trigger date
├── integration_test/
│   ├── app_test.dart                — E2E against Dio fake harness
│   └── canary_test.dart             — nightly testApi canary (env-gated: EVISITOR_ENV=test)
├── lib/
│   ├── core/
│   │   ├── errors/
│   │   │   ├── app_error.dart               — sealed class AppError (AuthError|NetworkError|...)
│   │   │   ├── evisitor_error_class.dart    — enum EvisitorErrorClass
│   │   │   └── evisitor_error_classifier.dart — pure fn: classify(DioException)→EvisitorErrorClass
│   │   ├── feature_flags/
│   │   │   └── feature_flags.dart           — const class FeatureFlags (mandate field, ad pivot)
│   │   ├── logging/
│   │   │   └── app_logger.dart              — thin wrapper over dart:developer log()
│   │   ├── result/
│   │   │   └── result.dart                  — sealed class Result<T, E> (Ok | Err)
│   │   ├── security/
│   │   │   ├── aes_gcm_helper.dart          — AES-GCM encrypt/decrypt via cryptography_flutter
│   │   │   ├── cert_pins.dart               — const CertPins.validFingerprints
│   │   │   └── security_service.dart        — key loading from flutter_secure_storage
│   │   ├── telemetry/
│   │   │   └── telemetry_service.dart       — singleton; typed methods; FirebaseCrashlytics chokepoint
│   │   └── time/
│   │       ├── evisitor_date_codec.dart     — encode/decode /Date(ms+offset)/ ↔ DateTime
│   │       └── time_service.dart            — DateTime.now().toUtc(); Europe/Zagreb helpers
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_failure_reason.dart     — enum AuthFailureReason
│   │   │   ├── auth_interceptor.dart        — QueuedInterceptor subclass; 401/403/400+SM handling
│   │   │   ├── auth_notifier.dart           — Notifier<AuthState>; circuit breaker; re-auth
│   │   │   └── auth_state.dart              — sealed class AuthState (6 states, Dart 3 native)
│   │   ├── capture/
│   │   │   ├── capture_result.dart          — sealed class CaptureResult (success|failed|timeout)
│   │   │   ├── capture_screen.dart          — live MRZ + 3s timer + static-tap fallback surface
│   │   │   ├── manual_entry_screen.dart     — ManualEntryScreen (3rd-tier fallback)
│   │   │   ├── mrz_capture_service.dart     — camera stream + google_mlkit_text_recognition
│   │   │   ├── mrz_parser.dart              — pure Dart TD1/TD2/TD3 zone parser + checksum
│   │   │   └── semantic_sanity_layer.dart   — date plausibility, expiry, ISO country, birth year
│   │   ├── closure/
│   │   │   ├── closure_summary.dart         — Freezed model (zero-PII: facility + count + time)
│   │   │   ├── closure_summary.freezed.dart
│   │   │   └── closure_summary_screen.dart  — shareable; ad interstitial post-success
│   │   ├── facility/
│   │   │   ├── facilities_table.dart        — Drift table: id, oib, name, lastUsedAt
│   │   │   ├── facility.dart                — Freezed model
│   │   │   ├── facility.freezed.dart
│   │   │   ├── facility.g.dart
│   │   │   ├── facility_notifier.dart       — AsyncNotifier<List<Facility>>; cache post-login
│   │   │   └── facility_screen.dart         — FacilityPickerScreen (Neutral App pattern)
│   │   ├── onboarding/
│   │   │   ├── consent_screen.dart          — UMP/CMP EU consent + sensitive-data disclosure
│   │   │   ├── credential_capture_screen.dart — userName/password/apikey entry + live login verify
│   │   │   └── onboarding_flow.dart         — linear first-run flow (FR1–FR6)
│   │   ├── queue/
│   │   │   ├── app_database.dart            — AppDatabase: GuestEntriesTable + FacilitiesTable
│   │   │   ├── app_database.g.dart
│   │   │   ├── guest_entries_table.dart     — Drift table + AES-GCM TypeConverter
│   │   │   ├── guest_entry.dart             — Freezed model; toString()→[REDACTED type=GuestEntry id=...]
│   │   │   ├── guest_entry.freezed.dart
│   │   │   ├── guest_entry.g.dart
│   │   │   ├── queue_entry_state.dart       — enum QueueEntryState (unsent|in_flight|submitted|failed)
│   │   │   ├── queue_notifier.dart          — AsyncNotifier<QueueSnapshot>; enqueue/delete/purge
│   │   │   ├── queue_screen.dart            — UnsendQueueScreen (per-guest status, edit, delete)
│   │   │   └── queue_snapshot.dart          — Freezed model (non-PII counts + summaries for UI)
│   │   ├── settings/
│   │   │   ├── credential_store.dart        — flutter_secure_storage wrapper
│   │   │   ├── settings_notifier.dart       — session state, Replace-Active-OIB (FR31.5)
│   │   │   ├── settings_screen.dart         — auth state + replace OIB + Your Data link
│   │   │   └── your_data_screen.dart        — FR39: queue counts + policy URLs + Delete All (FR40)
│   │   ├── submission/
│   │   │   ├── evisitor_api_client.dart     — typed Dio wrapper: Login, ImportTourists, Hello-check
│   │   │   ├── import_tourists_builder.dart — ImportTourists XML-in-JSON builder (single source)
│   │   │   ├── in_flight_reconciler.dart    — FR36.6 Path A (lookup) / Path B (host review)
│   │   │   ├── send_all_notifier.dart       — AsyncNotifier<SendAllResult>; pre-flight; per-guest loop
│   │   │   ├── send_all_result.dart         — Freezed model: per-guest outcomes
│   │   │   └── send_all_screen.dart         — per-guest ✓/✗ rendering; edit-and-retry-failed-only
│   │   └── version_gate/
│   │       ├── force_update_banner.dart     — ShellRoute overlay; blocks Send All when active
│   │       └── min_version_checker.dart     — polls prijavko.hr/min-version.json on cold start
│   ├── app/
│   │   ├── app.dart                         — MaterialApp.router + ProviderScope root
│   │   ├── providers.dart                   — dioProvider, appDatabaseProvider, top-level declarations
│   │   └── router.dart                      — GoRouter: routes + redirect(authNotifierProvider)
│   └── main.dart
├── test/
│   ├── fakes/
│   │   ├── evisitor_fake_adapter.dart       — permanent Dio fake (all eVisitor response shapes)
│   │   └── fake_security_service.dart       — in-memory SecurityService for unit tests
│   ├── unit/
│   │   ├── auth/
│   │   │   ├── auth_notifier_test.dart
│   │   │   ├── auth_interceptor_test.dart
│   │   │   └── evisitor_error_classifier_test.dart — all 3 session-dead variants + Croatian regex
│   │   ├── capture/
│   │   │   ├── mrz_parser_test.dart
│   │   │   └── semantic_sanity_layer_test.dart
│   │   ├── core/
│   │   │   ├── evisitor_date_codec_test.dart — /Date(ms+offset)/ encode/decode round-trip
│   │   │   └── result_test.dart
│   │   ├── queue/
│   │   │   ├── auto_purge_test.dart
│   │   │   ├── in_flight_reconciler_test.dart — Path A + Path B scenarios
│   │   │   └── queue_notifier_test.dart
│   │   └── submission/
│   │       └── import_tourists_builder_test.dart — XML structure, date encoding, field mapping
│   └── widget/
│       └── features/
│           ├── capture_screen_test.dart
│           ├── closure_summary_screen_test.dart
│           ├── queue_screen_test.dart
│           └── send_all_screen_test.dart
├── analysis_options.yaml
├── pubspec.lock                     — committed
├── pubspec.yaml
└── .gitignore                       — excludes build/, .dart_tool/ but NOT *.g.dart / *.freezed.dart
```

### Architectural Boundaries

**External API boundary — single entry point per external service:**

| External Service | Entry Point | Notes |
|---|---|---|
| eVisitor Rhetos API | `features/submission/evisitor_api_client.dart` | All HTTP; cert-pinned, cookie-managed, auth-intercepted Dio |
| Firebase Crashlytics | `core/telemetry/telemetry_service.dart` | Only class calling `FirebaseCrashlytics.instance` |
| Google AdMob + UMP/CMP | `features/onboarding/consent_screen.dart` (consent) + ad widgets in `closure/` + home | Ad requests gated on UMP consent state; never during scan/Send All |
| ML Kit Text Recognition | `features/capture/mrz_capture_service.dart` | On-device; no cloud; no PII transmitted |
| `prijavko.hr/min-version.json` | `features/version_gate/min_version_checker.dart` | Cold-start GET via Dio |

**Internal layer boundary — `core/` is consumed by `features/`; never the reverse.**

**Feature dependency graph (strict, no cycles):**

```
onboarding ──► auth ──► facility ──► (home / router)
                │                          │
                ▼                          ▼
             capture ──────────────► queue ──► submission ──► closure
                                              │
                                              ▼
                                           settings
```

**Data boundary — storage tier ownership:**

| Tier | Owner | Contents |
|---|---|---|
| `flutter_secure_storage` | `core/security/security_service.dart` + `features/settings/credential_store.dart` | Credentials + AES-GCM cookie-jar encryption key |
| AES-GCM encrypted file | `features/auth/auth_interceptor.dart` (via PersistCookieJar) | Cookies (`authentication`, `affinity`, `language`) |
| Drift / SQLite | `features/queue/app_database.dart` | Queue entries (AES-GCM column) + facility cache (plaintext) — never auth state |
| In-memory (Riverpod) | Notifiers | Live session state — not persisted directly |

### Requirements to Structure Mapping

| FR Category | Primary location | Supporting |
|---|---|---|
| Onboarding & Consent (FR1–FR7, FR14.5) | `features/onboarding/` | `features/auth/`, `core/security/` |
| Auth Lifecycle (FR8–FR14) | `features/auth/` | `core/errors/`, `core/security/` |
| Facility Management (FR15–FR19) | `features/facility/` | `features/queue/app_database.dart` |
| Guest Capture (FR20–FR26) | `features/capture/` | `core/time/`, `core/feature_flags/` (FR26) |
| Queue & Persistence (FR27–FR31.5) | `features/queue/` | `core/security/` (AES-GCM), `core/time/` (purgeAfter) |
| Send All (FR32–FR36.6) | `features/submission/` | `features/auth/` (pre-flight), `features/queue/` |
| Closure (FR37–FR38) | `features/closure/` | |
| Privacy & Data Lifecycle (FR39–FR40) | `features/settings/` | `features/queue/`, `core/security/` |
| Observability (FR41) | `core/telemetry/` | Called from all features |
| Forced-update (FR42) | `features/version_gate/` | `app/router.dart` (ShellRoute overlay) |

**Cross-cutting concerns mapped:**

| Concern | Location | Mechanism |
|---|---|---|
| PII type-level redaction | Every PII model in `features/*/` | `toString()` override |
| Zero-PII logs CI guard | `.github/workflows/pii_guard.yml` | Grep, build-blocking |
| AES-GCM key management | `core/security/security_service.dart` | Key loaded once at start, held in memory |
| Error classification | `core/errors/evisitor_error_classifier.dart` | Pure function; fully tested |
| Date encoding | `core/time/evisitor_date_codec.dart` | Only place `/Date(ms+offset)/` is constructed |
| Feature flags | `core/feature_flags/feature_flags.dart` | `const bool` — compile-time |

### Integration Points & Data Flow

**Primary journey data flow (J2 — door check-in):**

```
CaptureScreen → MrzCaptureService (ML Kit) → SemanticSanityLayer
  → QueueNotifier.enqueue(GuestEntry)
    → GuestEntriesTable.insert (AES-GCM, state=unsent, synchronous)
    → haptic + UI update

[Host taps Send All]
SendAllNotifier.sendAll()
  → AuthNotifier.preFlightCheck() → OK | block
  → connectivity check → OK | block
  → per entry: QueueNotifier.markInFlight(id)
      → EvisitorApiClient.importTourists(entry, facility)
          → ImportTouristsBuilder.build() + EvisitorDateCodec.encode()
          → Dio POST (cert-pinned, cookie-managed, AuthInterceptor)
          → EvisitorErrorClassifier → success | error class
      → QueueNotifier.markSubmitted(id) [purgeAfter=now+3d]
      OR QueueNotifier.markFailed(id, error)
      → TelemetryService.sendAllResult(...)
  → ClosureSummaryScreen (zero-PII)
```

**Auth recovery flow (J3 — silent session death):**

```
App foreground → AuthNotifier.opportunisticCheck()
  → EvisitorApiClient.helloCheck() → 400+SystemMessage
  → AuthInterceptor → EvisitorErrorClassifier → sessionDead
  → AuthNotifier.handleAuthFailure() → state = Reauth
  → CredentialBanner surfaces
  → Host taps reconnect → AuthNotifier.reauthenticate()
    → EvisitorApiClient.login(storedCredentials) → OK
    → state = Authenticated; banner dismisses
```

**In-flight reconciliation on resume (FR36.6):**

```
App launch → query GuestEntriesTable WHERE state = in_flight
  → if empty: normal startup
  → if non-empty:
      Path A (Week-1 spike: lookup endpoint found):
        EvisitorApiClient.lookupByUuid(id) → markSubmitted | markFailed | hold
      Path B (v1.0 default — no lookup endpoint):
        Surface "Unconfirmed submissions" warning
        → Host: verify in eVisitor portal OR retry
```

### Development Workflow Integration

**Development commands:**
```bash
flutter run --dart-define=EVISITOR_ENV=test       # against real testApi
flutter run --dart-define=EVISITOR_ENV=fake        # against Dio fake
flutter test                                        # unit + widget
flutter test integration_test/ --dart-define=EVISITOR_ENV=fake
dart run build_runner build --delete-conflicting-outputs
```

**Release build:**
```bash
flutter build appbundle \
  --dart-define=EVISITOR_ENV=prod \
  --obfuscate \
  --split-debug-info=build/symbols/
```

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
All 8 decisions work together without conflict. D3 sealed `AuthState` + D5 `Notifier<AuthState>` + D4 go_router redirect form a clean tripartite: FSM, reactive state, navigation guard. D2 `cryptography_flutter` + D3 (auth state never in Drift) ensures no PII/key mixing across storage tiers. D1 camera loop ownership + synchronous Drift commit + D8 `in_flight` state make the capture→queue→submission chain airtight. D7 DIY cert pinning uses `DefaultHttpClientAdapter.onHttpClientCreate` — a valid Dio 5.x hook with no package conflict. D6 log facade's `String`-only API blocks `AuthInterceptor` from accidentally logging DioException bodies containing raw `SystemMessage`.

**Version Compatibility:**
Flutter 3.x / Dart 3.x / Dio 5.x / go_router v14+ / Riverpod 3 / Drift / Freezed / `cryptography_flutter` / ML Kit — no known version conflicts. `QueuedInterceptor` confirmed active and maintained in Dio 5.x (bug fix for synchronous exception hang shipped 2024).

**Pattern Consistency:**
Naming conventions, Result type, async state, date encoding, and PII redaction are internally consistent. Anti-pattern table directly mirrors the 10 mandatory enforcement rules — no agent guidance conflicts.

**Structure Alignment:**
Feature-first layout maps 1:1 onto the 10 subsystems identified in Project Context Analysis. `core/` → `features/` dependency direction is cycle-free. All external APIs have single entry points.

### Requirements Coverage Validation ✅

**Functional Requirements Coverage:**
All 46 FRs across 11 categories are architecturally supported. Every FR category maps to a primary feature directory and supporting cross-cutting concerns (see Requirements to Structure Mapping in §5). FR26 (May-2026 mandate) is spike-gated and handled via `FeatureFlags` without structural change. FR36.6 (`in_flight` reconciliation) has both Path A and Path B implemented in `InFlightReconciler` without schema divergence.

**Non-Functional Requirements Coverage:**
7 of 8 NFR dimensions are explicitly addressed by architectural patterns. Accessibility (NFR-A1–A4) has baseline Flutter Material defaults but no explicit per-screen pattern — see Gap Analysis and Addendum below.

### Implementation Readiness Validation ✅

**Decision Completeness:**
All 8 critical decisions include: exact package names, code-level examples (sealed class, cert pinning, error classifier enum, Result type, TelemetryService method signatures), and rationale. Story 1.1 (bootstrap) can begin immediately from the `flutter create` command in §2. Story 2.1 (auth FSM) has paste-ready sealed class and QueuedInterceptor topology.

**Structure Completeness:**
Complete directory tree with file-level granularity. Every file named, co-located with its feature, and annotated with responsibility. Test directory mirrors `lib/` structure. CI workflows enumerated with triggers and descriptions.

**Pattern Completeness:**
10 mandatory rules + 10 anti-patterns with correctives. Named Riverpod provider topology with types and scopes. Auth error routing, queue write routing, telemetry routing — all have single named entry points enforced by the 10 rules.

### Gap Analysis Results

**Critical gaps: None** — all decisions blocking implementation are resolved.

**Important gaps (addressed in addendum below):**

1. **Accessibility patterns** — NFR-A1–A4 mentioned in Requirements Overview but absent from Implementation Patterns. Risk: AI story agents implement `Semantics` and touch targets inconsistently. Addressed in Accessibility Addendum.

2. **AdMob placement policy** — Architecture prohibits ads during scan/Send All but does not specify positive placement rules per screen. Risk: agent divergence on closure and home screen ad placement. Addressed in AdMob Addendum.

3. **`android/app/proguard-rules.pro` missing from directory tree** — Release build with `--obfuscate` requires R8 keep rules for Drift, Riverpod, Freezed, Dio. Story 1.x must include this file. Added to structure below.

**Nice-to-have gaps:**

4. **`analysis_options.yaml` lint rule set** — file is listed but contents unspecified. Story 1.1 should pin: `flutter_lints`, plus `avoid_print`, `prefer_const_constructors`, `always_use_package_imports`, `directives_ordering`, `unnecessary_null_checks`.

### Architectural Addenda (resolving validation gaps)

#### Accessibility Addendum

All interactive widgets: minimum touch target 48×48dp (enforce via `SizedBox` or `InkWell` constraints, not wrapping). `Semantics` label required on icon-only buttons, progress indicators, and status badges. `ExcludeSemantics` on decorative dividers and background imagery. Screen reader ordering = visual top-to-bottom reading order (do not reorder with `Semantics.sortKey` unless broken layout requires it). MRZ capture screen: camera preview excluded from semantics (`ExcludeSemantics`); accessible controls (static-tap button, manual-entry fallback) fully labeled.

#### AdMob Placement Policy

| Screen | Ad type | Condition |
|---|---|---|
| Home (queue list) | Banner, bottom | Always; gated on UMP consent |
| Closure summary | Interstitial | Post-success only; gated on UMP consent |
| All other screens | None | No ads on: onboarding, capture, send-all progress, locked-out, settings, your-data |

Ad requests: never initiated while `SendAllNotifier` state is in-progress. UMP consent state checked before every ad request via AdMob SDK `ConsentInformation`.

#### ProGuard/R8 File Addition

Add `android/app/proguard-rules.pro` to the project structure (alongside `build.gradle`). Story 1.x acceptance criteria: file must contain keep rules for Drift generated code, Riverpod annotations, Freezed `copyWith` methods, and Dio `HttpClientAdapter`. Reference: package-specific ProGuard docs for each dependency.

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed (46 FRs, 58 NFRs, 5 user journeys)
- [x] Scale and complexity assessed (LOW topology, HIGH discipline, HIGH integration complexity)
- [x] Technical constraints identified (eVisitor quirks, solo-dev, pre-peak freeze, Play Store review)
- [x] Cross-cutting concerns mapped (9 concerns, each with owner and mechanism)

**✅ Architectural Decisions**
- [x] All 8 critical decisions documented with package names, versions, and rationale
- [x] Technology stack fully specified — no ambiguous "TBD" choices remaining
- [x] Integration patterns defined (QueuedInterceptor, error classifier, cert pinning)
- [x] Performance considerations addressed (D1 camera loop ownership, sync Drift commit, main-isolate purge)
- [x] Spike-gated unknowns documented with both structural paths (D8)

**✅ Implementation Patterns**
- [x] Naming conventions for files, classes, providers, routes, events
- [x] Structure patterns (feature-first, 10 mandatory rules)
- [x] Communication patterns (auth error routing, queue write routing, telemetry routing)
- [x] Process patterns (Result type, async state, PII discipline, context.mounted)
- [x] Anti-pattern reference table

**✅ Project Structure**
- [x] Complete file-level directory structure defined
- [x] Component boundaries established (external API entry points, storage tier ownership)
- [x] Integration points mapped (primary J2 journey flow, auth recovery J3 flow, FR36.6 in-flight reconciliation)
- [x] Requirements-to-structure mapping complete (all 11 FR categories + 6 cross-cutting concerns)

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**

**Confidence Level: HIGH**

The architecture resolves every eVisitor quirk at a named structural location (HTTP 400 → `EvisitorErrorClassifier`; XML-in-JSON → `ImportTouristsBuilder`; `/Date(ms+offset)/` → `EvisitorDateCodec`; 3 named cookies → `PersistCookieJar` + AES-GCM file; no refresh token → full re-login in `AuthNotifier`). PII zero-leakage is enforced at three independent layers (type system, log facade, CI grep guard) — each sufficient alone, redundant together. The Explicit-Send-All + synchronous Drift commit combination guarantees the PRD's "never fails silently" invariant without background services.

**Key Strengths:**
1. Every eVisitor API quirk has a named architectural owner — no surprise behaviors at implementation time
2. Triple-layer PII protection (type → facade → CI) makes the zero-PII guarantee verifiable, not aspirational
3. QueuedInterceptor + 3/6-min circuit breaker is strictly more conservative than Rhetos server lockout — prevents thundering-herd at a host's door
4. Permanent Dio fake as first-class artifact means CI always runs integration tests regardless of testApi availability
5. D8 Path A/B design decouples Week-1 spike outcome from structural architecture — spike result is a configuration choice, not a refactor

**Areas for Future Enhancement (post-v1.0):**
- Accessibility: per-screen `Semantics` audit + automated a11y test coverage
- AdMob: frequency cap and backoff strategy for hosts who submit frequently during peak season
- ProGuard: pin specific keep-rule versions as package versions are bumped
- Multi-OIB UI: Riverpod topology is schema-ready; UI topology (v1.1) will extend `activeFacilityProvider` to be OIB-scoped

### Implementation Handoff

**AI Agent Guidelines:**
1. Follow all 10 mandatory rules in Implementation Patterns & Consistency Rules — these are acceptance criteria, not suggestions
2. Place files in the feature directory that owns them — the directory structure is a contract, not a suggestion
3. Never open a second entry point to eVisitor, Crashlytics, ML Kit, or Drift outside the defined gateway files
4. For all Week-1 spike-gated items (FR26 payload shape, idempotency key, FR36.6 lookup endpoint): implement Path B as the default; upgrade to Path A only after spike confirms the endpoint exists
5. Run `dart analyze --fatal-warnings --fatal-infos` locally before committing — CI will block if you don't

**First Implementation Priority:**
```bash
flutter create \
  --org hr.prijavko \
  --project-name prijavko \
  --platforms=android \
  --empty \
  -a kotlin \
  .
```
Follow with: `analysis_options.yaml` (strict lint rules), GitHub Actions workflows (analyze, pii-guard, test, integration-fake, testapi-canary), `network_security_config.xml`, `AndroidManifest.xml` edits, and `proguard-rules.pro`.

