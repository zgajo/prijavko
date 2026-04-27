---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
  - _bmad-output/planning-artifacts/figma-code-contract.md
---

# prijavko - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for prijavko, decomposing the requirements from the PRD, UX Design Specification, Figma Code Contract, and Architecture Decision Document into implementable stories.

## Requirements Inventory

### Functional Requirements

**Onboarding & Consent**

FR1: Host can launch the app and be guided through first-run consent, permissions, and credential capture in a single linear flow.
FR2: App can present an EU-consent surface for ad personalization before any ads are requested.
FR3: App can present a sensitive-data disclosure explaining passport/MRZ processing, 3-day retention, and a link to the Privacy Policy before camera permission is requested.
FR4: Host can grant or deny camera permission; manual entry remains fully functional if camera is denied.
FR5: Host can enter and store eVisitor credentials (username, password, apikey) for subsequent sessions without re-entering.
FR6: App can verify eVisitor credentials by performing a live login against the eVisitor authentication endpoint during onboarding.
FR7: Host can replace or re-enter credentials at any time from the Settings surface.

**Authentication & Session Lifecycle**

FR8: App can maintain an eVisitor session across process restarts, device reboots, and periods of background inactivity.
FR9: App can detect an expired or invalid session from eVisitor responses (regardless of HTTP status code) and classify the cause (session-dead, lockout, credentials-invalid, network, or server error).
FR10: App can re-authenticate automatically using stored credentials when a dead session is detected, without duplicate concurrent login attempts.
FR11: App can surface a non-blocking credential banner to the host when session-dead or credentials-invalid is detected, with a single-tap recovery action.
FR12: App can refuse further login attempts after a configurable threshold of consecutive failures within a rolling window, and communicate the remaining wait to the host in Croatian.
FR13: App can perform an opportunistic authentication check on app foregrounding without blocking the UI.
FR14: Host can view current session state (authenticated, reauth-needed, locked-out) at a glance in the Settings surface.
FR14.5: App can detect missing credentials on launch (Keystore returns no value for an existing facility profile) and surface a non-blocking "credentials missing — re-enter to continue" state with facility names pre-populated, without losing facility context or forcing full re-onboarding.

**Facility Management**

FR15: App can fetch and cache the list of facilities available to the host's eVisitor account on first successful login.
FR16: Host can select exactly one facility at the start of each registration session.
FR17: App can surface the last-used facility as a hint during facility selection, but not pre-select it as a default.
FR18: Host can see the currently active facility on the home surface during an active registration session.
FR19: App can refresh the facility list when the host explicitly requests it, without forcing a full re-login.

**Guest Capture**

FR20: Host can capture guest identity data by holding a passport or ID card in front of the camera; the app detects and parses a valid MRZ automatically.
FR21: Host can tap a static capture control to capture a document image when live MRZ detection does not succeed within a bounded time.
FR22: Host can enter guest data manually as a fallback when neither live nor static capture succeeds.
FR23: App can validate captured or entered guest data against semantic sanity rules (date plausibility, document expiry, valid country codes, realistic birth years) before accepting it into the queue.
FR24: Host can review and correct captured guest data before it is committed to the queue.
FR25: App can reject a capture or entry inline with a Croatian-language explanation when sanity validation fails, without committing it to the queue.
FR26: App can support future fields required by the May-2026 apartment registration-number mandate, gated by a feature flag, without breaking the existing capture flow.

**Queue & Local Persistence**

FR27: App can persist every captured guest to encrypted local storage with a client-generated unique identifier, synchronously, before surfacing any success indication to the host.
FR28: App can preserve unsent guests across app kills, device reboots, and offline periods indefinitely until either submission succeeds or the host deletes them.
FR29: Host can view the unsent queue with a per-guest status and initiate per-guest edit or delete actions.
FR30: App can automatically delete successfully submitted guests after a 3-day soft-undo retention window, regardless of host action.
FR31: Host can manually delete individual unsent or recently-submitted guests from the queue at any time.
FR31.5: Host can replace the active OIB from the Settings surface via a destructive, typed-OIB-guarded confirmation that wipes all facility profiles, queue entries, credentials, and cookie jar, then re-launches onboarding.

**Submission (Send All)**

FR32: Host can trigger a batch submission of all unsent guests for the active facility via an explicit action (no automatic submission, no background retry).
FR33: App can perform a pre-flight check for authentication and network reachability immediately before submitting and block the submission with a clear message if either check fails.
FR34: App can submit guests individually to eVisitor such that a rejection of one guest does not cause rejection of other guests in the same batch.
FR35: App can report per-guest success or failure outcomes to the host after a submission batch completes.
FR36: Host can edit a failed guest inline and retry only the failed guests without re-submitting already-successful ones.
FR36.5: App can distinguish a rate-limited response (HTTP 429 or equivalent eVisitor throttling) from a submission failure and surface a non-blocking "eVisitor is busy — retrying..." message with exponential backoff, without counting the rate-limit as a per-guest failure outcome.
FR36.6: App can track an `in_flight` queue state between `ready-to-send` and `accepted/rejected`; on app resume after process kill or crash, any `in_flight` entries are re-queried against eVisitor before any retry is attempted (or held for host review if a lookup endpoint is unavailable) — preventing silent double-submits.

**Post-Submission Closure**

FR37: App can present a closure summary after every submission batch, containing the facility name, number of guests registered, and the local submission timestamp — and containing no guest names, document numbers, or other PII.
FR38: Host can share or screenshot the closure summary for their own records.

**Privacy & Data Lifecycle**

FR39: Host can view a "Your Data" surface listing what is currently stored on the device (unsent queue count, recently-submitted count within retention), with links to the Privacy Policy and Terms of Service.
FR40: Host can trigger a complete wipe of all local data (queue, cached facilities, cookie jar, credentials) in a single action.

**Observability & Compliance Signals**

FR41: App can emit zero-PII telemetry events that allow the operator to measure submission success rate, session-dead-recovery rate, queue-stuck-over-24h count, and crash-free session rate — without transmitting any guest or credential data.
FR42: App can present a forced-update banner when a remote minimum-supported-version signal indicates the current client is incompatible with eVisitor, and block submissions while the banner is active.

### NonFunctional Requirements

**Performance**

NFR-P1: Live MRZ auto-shutter fires within 1.5s (p95) from camera-open on a well-lit, flat, in-date machine-readable document.
NFR-P2: Static-tap fallback surfaces no later than 3s of failed live detection.
NFR-P3: A scanned guest is persisted to the encrypted local queue and reflected in the unsent-row UI within 300ms (p95) of successful capture, with synchronous DB commit before the success haptic fires.
NFR-P4: Semantic sanity validation completes within 50ms (p95) of capture submission.
NFR-P5: Send All pre-flight (auth + network) completes within 1s (p95) and either blocks with a clear message or proceeds.
NFR-P6: Per-guest submission latency is bounded by network/eVisitor; the UI per-guest progress indicator updates within 200ms of each eVisitor response.
NFR-P7: Post-submit closure summary renders within 200ms of the last guest's response.
NFR-P8: Cold start (process kill → home screen ready) completes within 2.5s (p95) on the target device baseline (mid-range Android, 2023+ hardware).
NFR-P9: Warm resume (app foregrounded after background) and opportunistic auth check complete within 1s (p95), non-blocking.
NFR-P10: App is capable of holding at least 40 unsent guests in a single registration session without UI degradation (60fps scroll, edit/delete within 200ms). Verified by integration test.

**Security**

NFR-S1: All data in transit uses HTTPS with TLS 1.2+; cleartext traffic is rejected at platform level (`network_security_config.xml`).
NFR-S2: All calls to `www.evisitor.hr` are pinned via SHA-256 certificate pins (leaf + intermediate); a pin mismatch aborts the request without retry.
NFR-S3: Credentials (`userName`, `password`, `apikey`) are stored in flutter_secure_storage with Android Keystore-backed AES/GCM; hardware-backed keys used where available.
NFR-S4: The session cookie jar (`authentication`, `affinity`, `language`) is encrypted at rest via AES-GCM; the encryption key lives in flutter_secure_storage.
NFR-S5: Passport/MRZ data in the Drift queue is AES-GCM-encrypted at the column level for guest-identifying fields.
NFR-S6: Android `allowBackup="false"` and `fullBackupContent="false"` — no cloud backup path for any app data.
NFR-S7: No PII field value appears in any log line or any telemetry event. Enforced at two layers: (a) PII-bearing types override `toString()` to `[REDACTED]`, (b) build-blocking CI grep guard fails merges that reference forbidden log patterns.
NFR-S8: Crashlytics stack traces are symbolicated but carry zero free-text from guest records; custom events carry counts, facility IDs, error codes only.
NFR-S9: App passes the OWASP MASVS L1 verification level as a build-time self-audit (documented checklist checked pre-submission).
NFR-S10: 3-day auto-purge of submitted guests is enforced regardless of host action or app state; documented in Privacy Policy and in-app "Your Data" surface.
NFR-S11: Release builds disable verbose Dio request/response logging; Crashlytics uses an allowlist of custom-key names; transitive dependency default logging reviewed pre-submission; staging acceptance test triggers intentional crash in PII-carrying code path and Firebase Console output manually inspected to verify zero leakage via third-party SDKs.

**Reliability**

NFR-R1: Crash-free session rate ≥ 99.5% (measured via Crashlytics).
NFR-R2: `scan_to_submit` first-time success rate ≥ 90% without field corrections.
NFR-R3: Silent-failure rate (confirmed auth-classifier false negatives in production) = 0 during peak season (2026-06-01 → 2026-09-30).
NFR-R4: Queue-stuck count (unsent guests > 24h old) = 0 on every host's device at every app open (telemetry emits an event when non-zero).
NFR-R5: No submission to eVisitor is lost as a result of process kill, device reboot, network drop, or storage pressure — the queue always either shows the guest as pending or as submitted, never as "gone."
NFR-R6: The app recovers from an expired session automatically on next action, without requiring the host to re-enter credentials (unless credentials themselves are invalid).
NFR-R7: Re-auth under concurrent auth-triggering requests produces exactly one login call (not N); serialized via a QueuedInterceptor-equivalent mechanism.
NFR-R8: Client-side circuit breaker opens after 3 consecutive login failures for 6 minutes, strictly more conservative than the Rhetos server-side 5 / 5-minute lockout.
NFR-R9: App operates offline for all capture, queue, and facility-picker flows; only Send All and the opportunistic auth check require network.

**Integration**

NFR-I1: All eVisitor requests use JSON envelopes; `ImportTourists` uses XML-as-string inside a JSON body; dates are `/Date(ms+offset)/` format.
NFR-I2: Error classifier correctly identifies session-dead across HTTP 401, HTTP 403, HTTP 400-with-`SystemMessage`, and HTTP 200-with-error-envelope-at-non-Login-endpoint cases.
NFR-I3: Error classifier matches Croatian-language error text (`/locked|zaključan/i`, `/invalid|nevažeć|neispra/i`, `/session|prijava|auth/i`) as well as English; regex set refined via Week-1 spike.
NFR-I4: Integration contract with eVisitor is verified by a permanent in-repo Dio fake that runs on every CI build, plus a nightly CI run against the real eVisitor testApi with a minimal-data canary account.
NFR-I5: Drift from the fake contract to the real eVisitor behavior triggers a CI failure; drift is resolved before merging.
NFR-I6: No guest data (PII) is transmitted to AdMob, Crashlytics, Firebase, Google Play, or any third party — only to eVisitor.
NFR-I7: Forced-update mechanism: the app polls a static `prijavko.hr/min-version.json`-style URL on cold start; if current build < `minSupportedVersion`, the app surfaces a forced-update banner and blocks Send All.

**Compatibility**

NFR-C1: App runs on Android 7.0 (API 24) or higher; target SDK is the latest mandated by Play Store at submission time.
NFR-C2: App supports arm64-v8a and armeabi-v7a ABIs; no x86 support.
NFR-C3: App renders correctly in phone portrait on screen sizes from 4.7" to 6.9"; landscape and tablet portrait render without layout breakage but are not design-optimized.
NFR-C4: Camera access works on devices supporting CameraX requirements (effectively all API-24+ devices with a rear camera).
NFR-C5: App does not require Google Play Services beyond ML Kit MRZ (on-device) and Firebase Crashlytics.

**Localization**

NFR-L1: All host-facing copy is available in Croatian (primary) and English (secondary); active language follows Android system locale, with Croatian as fallback.
NFR-L2: Date, time, and number formats follow the active locale conventions.
NFR-L3: Error messages surfaced to the host include both the Croatian eVisitor `UserMessage` (when present) and a prijavko-provided Croatian explanation safe for UI display.
NFR-L4: No user-facing string is English-only; missing translations block release.

**Accessibility**

NFR-A1: All interactive targets meet a minimum 48×48 dp touch target size (Android accessibility guideline).
NFR-A2: Text contrast meets WCAG 2.1 AA (≥ 4.5:1 body, ≥ 3:1 large text) in both light and dark themes.
NFR-A3: Every actionable control exposes a content description for Android TalkBack; scan, Send All, credential banner, and closure summary are fully screen-reader navigable.
NFR-A4: Manual-entry keyboard interactions respect system font scaling up to 200% without layout breakage.

**Maintainability**

NFR-M1: Dart analyzer runs with `--fatal-warnings --fatal-infos` on CI; zero warnings in merged code.
NFR-M2: No production code uses `dynamic` except in boundary deserialization paths that immediately coerce to typed models.
NFR-M3: Public classes and functions carry a doc comment explaining *why* (business context, non-obvious constraints) — not *what*.
NFR-M4: Commit messages explain the *why*; atomic commits preferred over batched.
NFR-M5: Test coverage is measured but not gated on a percentage; the capability contract (FRs) + integration-test harness (NFR-I4) must cover every MVP capability. Deliberate coverage ≥ 70% meaningful on auth + queue + classifier subsystems.
NFR-M6: Pre-peak code freeze is 2026-06-15; post-freeze merges are bugs only until the 2026-09-30 kill-criteria checkpoint.
NFR-M7: The PRD, product brief, distillate, and eVisitor auth-lifecycle research are the authoritative context artifacts; scope changes update the PRD first, then the code.

### Additional Requirements

**Starter & Project Bootstrap (Architecture §2):**
- Use vanilla `flutter create --org hr.prijavko --project-name prijavko --platforms=android --empty -a kotlin .` — no third-party starter, no Very Good CLI, no flavors.
- Single-env toggle via `--dart-define=EVISITOR_ENV=<prod|test|fake>` (no Gradle buildTypes for env).
- Commit generated `*.g.dart` and `*.freezed.dart` to repo; `build_runner watch` for development only.

**CI Pipeline (Architecture §5):**
- GitHub Actions workflows: `analyze` (`dart analyze --fatal-warnings --fatal-infos`), `pii-guard` (build-blocking grep for forbidden log patterns referencing `documentNumber|firstName|lastName|dateOfBirth|nationality|documentExpiry|mrzLine1|mrzLine2`), `test` (unit + widget), `integration-fake` (Dio fake harness), `testapi-canary` (nightly against real eVisitor testApi), `build-aab` (on `v*` git tag with `--obfuscate --split-debug-info`).
- Drift between fake contract and real eVisitor triggers CI failure.

**Android Platform Hardening:**
- `android/app/src/main/res/xml/network_security_config.xml` declaring `cleartextTrafficPermitted="false"` and cert-pinning declaration.
- `AndroidManifest.xml` with `allowBackup="false"`, `fullBackupContent="false"`, only 3 permissions (`CAMERA`, `INTERNET`, `ACCESS_NETWORK_STATE`), Play Store-justifiable camera purpose string.
- `android/app/proguard-rules.pro` with keep rules for Drift, Riverpod, Freezed, Dio.
- `analysis_options.yaml`: `flutter_lints` + `avoid_print`, `prefer_const_constructors`, `always_use_package_imports`, `directives_ordering`, `unnecessary_null_checks`.

**Architectural Patterns & Chokepoints (Architecture §3–4):**
- Dart 3 `sealed class AuthState` — 6 variants (`Initial | Unauthenticated | Authenticating | Authenticated | Reauth | LockedOut | AuthFailure`); no Freezed on FSM.
- `QueuedInterceptor` subclass (`AuthInterceptor`) instantiated via Dio provider; closes over `Ref`; serializes re-auth.
- Circuit breaker: 3 consecutive login failures → 6-minute open (`consecutiveFailures` + `lockedUntil` fields on `AuthNotifier`).
- DIY certificate pinning via `DefaultHttpClientAdapter.onHttpClientCreate`; `CertPins.validFingerprints` as `const`; documented in `docs/security/cert-pins.md` with validity dates and rotation trigger.
- `EvisitorErrorClassifier` — pure function `classify(DioException) → EvisitorErrorClass` (enum variants: `sessionDead | lockedOut | credentialsInvalid | throttled | network | serverError | contractBreak | validationError`).
- Permanent in-repo Dio fake harness at `test/fakes/evisitor_fake_adapter.dart` as first-class artifact (not dev-only).
- `Result<T, AppError>` sealed class for all fallible service/repository methods — never throw across feature boundaries.
- `AppError` sealed class: `AuthError | NetworkError | ValidationError | ServerError | ContractBreakError`.
- `EvisitorDateCodec.encode/decode` — single source for `/Date(ms+offset)/` encoding; never inline.
- `ImportTouristsBuilder` — single source for XML-as-JSON-string payload construction.
- `EvisitorApiClient` — single Dio wrapper for Login, ImportTourists, Hello-check, lookup endpoints.
- `InFlightReconciler` — Path A (lookup endpoint exists) / Path B (host review) behind Week-1 spike outcome.
- `MinVersionChecker` polls `prijavko.hr/min-version.json` on cold start; `ForceUpdateBanner` is a `ShellRoute` overlay that blocks Send All when active.
- `FeatureFlags` — `const bool` class, compile-time. No remote config.

**Observability (Architecture §4):**
- `TelemetryService` singleton is the only class calling `FirebaseCrashlytics.instance`; exposes typed methods: `scanToSubmit`, `authStateTransition`, `sendAllResult`, `queuePurge`, `classifierMismatch`, `queueStuck24h`. No method accepts free text from guest records.
- `systemMessageHash` is SHA-256 of raw message, never raw message.
- `AppLogger` wraps `dart:developer`'s `log()`; `String`-only methods; no `Object` overload.

**State Management Topology (Architecture §4):**
- Riverpod 3 only (no `StateNotifier`, no `ChangeNotifier`): `authNotifierProvider`, `dioProvider`, `facilityNotifierProvider`, `queueNotifierProvider`, `activeFacilityProvider` (session-scoped), `sendAllNotifierProvider` (auto-disposed).
- `go_router` v14+ with `redirect` reading `authNotifierProvider` synchronously.

**Drift / SQLite Schema (Architecture §3):**
- `AppDatabase` with exactly two tables: `GuestEntriesTable` (columns: `id` UUID PK, `facilityId` FK, `encryptedPayload`, `state` enum, `clientCreatedAt`, `submittedAt` nullable, `purgeAfter` nullable indexed) and `FacilitiesTable` (columns: `id`, `oib`, `name`, `lastUsedAt`).
- Never store auth state in Drift.
- 3-day auto-purge runs on app open via `dart:async Timer` on main isolate.

**Compliance & Store Readiness:**
- `docs/security/masvs-l1-checklist.md` OWASP MASVS L1 self-audit checklist, reviewed pre-submission (NFR-S9).
- Privacy Policy published at `prijavko.hr/privacy` (static HTML).
- Terms of Service with liability disclaimer published at `prijavko.hr/terms` (static HTML).
- `prijavko.hr/min-version.json` static endpoint serving `{ "minSupportedVersion": N }`.
- Play Store Data Safety declaration completed pre-submission.
- 6 Croatian-language Play Store screenshots for scan → queue → Send All → closure summary flow.
- Google Play Console tracks used in sequence: Internal testing → Closed testing (2026-05-13 target) → Production (2026-05-27 staged rollout 20→50→100% over 7 days).

**AdMob + UMP/CMP:**
- `google_mobile_ads` + UMP SDK; EU consent on first launch; re-prompt on policy updates.
- Ads never rendered during camera/scan, Send All progress, or while `CredentialBanner` is active.
- Banner-only on Home; no interstitials in v1.0 (deliberate deviation from PRD permission — preserves Closure Summary emotional payoff).

**Week-1 Spike Blockers (must resolve before Epic 4/6):**
- FR26 May-2026 apartment registration-number mandate exact payload shape against testApi.
- eVisitor idempotency key support (affects UUID usage in ImportTourists).
- FR36.6 lookup-by-client-UUID endpoint existence — determines `InFlightReconciler` Path A vs Path B at runtime.
- eVisitor API key scope: vendor-wide (embedded build-time) vs per-account (returns to login UI).

### UX Design Requirements

**Design System & Tokens**

UX-DR1: Create `lib/design/tokens.dart` mirroring Figma `color` (17 dark-mode vars), `spacing` (`space4, 8, 12, 16, 24, 32, 48, 64`), `radii` (`radiusButton=12, radiusCard=16, radiusSheet=24`), and `sizing` (`buttonMinHeight=56`) collections 1:1. Pure `const` values only.
UX-DR2: Adriatic Teal seed color `primarySeed = Color(0xFF0D4F52)`; derive both light and dark themes via `ColorScheme.fromSeed(seedColor: primarySeed, brightness: ...)` in `lib/design/theme.dart`.
UX-DR3: Expose Material-3-missing semantic colors via `ThemeExtension<SemanticColors>` in `lib/design/extensions.dart`: `warning`, `warningContainer`, `onWarningContainer`, `success`, `onSuccess`, `closureAccent`, `surfaceContainerHigh`, `outlineVariant`.
UX-DR4: Bundle Manrope typeface via `google_fonts`, weights 400/500/600/700/800; Noto Sans fallback. Implement 12 typescale slots matching the Figma-code contract (displayLarge 57/800/64 down to labelMedium 12/600/16).
UX-DR5: Use Material Symbols rounded exclusively (`Symbols.xxx`, not `Icons.xxx`) — register once; mixing forbidden.
UX-DR6: Dark mode is the primary design target; every screen designed and validated in dark first, then verified in light. `MaterialApp.themeMode: ThemeMode.system`.

**Custom Widgets (10 total)**

UX-DR7: Implement `GuestStatusGlyph` widget with sealed-enum state (`queued ○`, `sending ↑`, `sent ✓`, `failed ✗`, `in_flight_unresolved ⋯`); three size variants (24/56/64dp); shape + color redundancy for colorblind safety; Croatian TalkBack semantics per state.
UX-DR8: Implement `QueueRow` — Card with 12dp padding, 12dp radius, `surfaceContainerHigh` background; leading `GuestStatusGlyph(small)`; states `queued | sending | sent | failed | in_flight_unresolved`; variants `compact | review`; PII always masked (e.g., "HR2184…"); name never shown; swipe-to-dismiss with SnackBar undo for `queued`-only rows.
UX-DR9: Implement `QueueHero` — Home at-a-glance count with states `empty_recent_success | empty_no_recent | non_empty | auth_dead`; `displayMedium` weight 800 count; compound TalkBack utterance.
UX-DR10: Implement `CredentialBanner` — `MaterialBanner` subclass with warning amber (never red); states `session_expired | credentials_missing | network_unreachable | partial_send_pending`; announced via `SemanticsService.announce`; 48dp action button; never appears simultaneously with `AdBanner`.
UX-DR11: Implement `FacilityPickerSheet` — `showModalBottomSheet` with 20dp top radius; last-used row gets 1.5px primary border + "Zadnji" pill (never auto-selected); tap-outside = cancel (Neutral App poka-yoke); states `loaded_1_auto | loaded_2_plus | loading | error | empty`.
UX-DR12: Implement `MRZViewfinder` — full-screen stack over camera preview; center 200×130 reticle with primary-color corner accents; dark overlay outside; top-left close; top-right `ScanCounterChip`; bottom hint; states `scanning | mrz_detected_validating | static_tap_available | capture_confirmed`.
UX-DR13: Implement `CaptureConfirmation` — full-bleed success overlay; 72×72 success circle with checkmark; "Gost N dodan" / "Skeniram sljedećeg…"; 200ms fade-in / 400ms hold / 200ms fade-out (800ms total); haptic fires BEFORE render.
UX-DR14: Implement `ClosureSummary` — full-screen scaffold with linear gradient (`primaryContainer → surface` at 55%); gold `closureAccent` count in `displayLarge`; facility name + Europe/Zagreb timestamp + count only (zero PII); native Android ShareSheet with text-only payload (no screenshot export in v1.0); auto-focused on appearance; `closureAccent` gold used ONLY on this screen.
UX-DR15: Implement `TypedConfirmationDialog` — `AlertDialog` with `TextField` requiring literal word match (`ZAMIJENI` for replaceOib, `OBRIŠI` for deleteAllData); destructive button enabled ONLY on exact case-insensitive diacritic-aware match; Cancel default; tap-outside does NOT dismiss.
UX-DR16: Implement `AdBanner` — AdMob anchored adaptive banner (50–100dp); UMP consent-gated; Home-only build-time assertion; states `loading | loaded_personalized | loaded_non_personalized | error_collapsed | disabled_auth_dead | disabled_pro_user | collapsed_by_user`; never renders while `CredentialBanner` active.

**Screen Assembly (13 Figma screens → Flutter files per figma-code-contract.md §4)**

UX-DR17: Assemble `welcome_screen.dart` (Welcome + sensitive-data disclosure), `login_screen.dart` (username + password only; apikey embedded build-time subject to Week-1 spike), and UMP consent surface as a pre-onboarding screen (before Welcome).
UX-DR18: Assemble `home_screen.dart` with three states: empty-fresh (single `Scan Guest` CTA + `Ručni unos` secondary), queued-N (inline `QueueRow` list + dual CTAs: Send All primary / Scan + Manual Entry secondary), and auth-dead (credential banner active).
UX-DR19: Assemble `scan_screen.dart` combining `MRZViewfinder`, 3-second static-tap fallback surface, `CaptureConfirmation` overlay, and manual-entry rollup link; `SystemChrome.setPreferredOrientations([portraitUp])` on enter and restored on dispose.
UX-DR20: Assemble `review_screen.dart` (Send All results) with per-guest rows showing `GuestStatusGlyph` progression ○→↑→✓/✗; failed rows highlighted with `Uredi` inline affordance and retry-failed-only CTA.
UX-DR21: Assemble `closure_summary_screen.dart` — portrait-locked; single primary Share + secondary Done; returns to Home on Done; persistent until user taps Done.
UX-DR22: Assemble `settings_screen.dart` with current session state (FR14), `Your Data` link (FR39), "Replace active OIB" (`TypedConfirmationDialog` ZAMIJENI), "Delete all data" (`TypedConfirmationDialog` OBRIŠI), re-enter credentials (FR7).
UX-DR23: Assemble `guest_form_screen.dart` — manual entry + edit-guest states share one file; field structure per §Form Patterns (label above 44dp input, 10dp radius, 1px outlineVariant, 1.5px primary on focus, 1.5px error on validate fail); validate on blur (client) and on submit (server); invalid value stays in field; focus jumps to first invalid field.

**Localization & Copy**

UX-DR24: All user-facing strings go through `AppLocalizations` via ARB files; Croatian (`hr`) is primary, English (`en`) is secondary fallback. Sentence case, imperative CTAs, full Croatian diacritics (č/ć/š/ž/đ — no ASCII approximation). Numbers use HR locale separators (1.234); dates in HR format (3. svibnja 2026).
UX-DR25: eVisitor error surfaces include both the Croatian `UserMessage` (when present) and a prijavko-provided Croatian explanation, in parallel (per NFR-L3).

**Accessibility & Responsive**

UX-DR26: Touch target minimum 48×48 dp everywhere (Android guideline); primary button min-height 56dp (one-handed night-shift). Every `IconButton` has `tooltip`; every custom widget wraps child in `Semantics(label: ...)`; banners announced via `SemanticsService.announce`.
UX-DR27: WCAG 2.1 AA verified — 4.5:1 body, 3:1 large text in both themes; UI components 3:1 non-text contrast; 2dp primary-color focus indicator visible in light and dark; status carries shape AND color redundantly; shape + color checked under deuteranopia/protanopia developer options.
UX-DR28: Content width clamped via `LayoutBuilder` / `ConstrainedBox(maxWidth: 600)` on every scaffold body; `SafeArea` everywhere; `MediaQuery.textScaler` respected with clamp [0.85, 2.0]; portrait lock only on scan + closure (restored on dispose).
UX-DR29: Haptic discipline — `HapticFeedback.mediumImpact()` on scan capture (primary trust signal, fires BEFORE visual); `selectionClick` on per-guest ✓; `heavyImpact` on per-guest ✗ and destructive confirmations; no audio feedback anywhere.

**UX Consistency Hard Rules**

UX-DR30: Button hierarchy enforced — max 2 CTAs per screen; primary rightmost/bottommost; primary button uses `FilledButton` (56dp, primary color, 12dp radius); labels are Croatian verbs in sentence case; icons leading 16–18dp, 6–8dp from text; disabled = 0.38 opacity; no ghost buttons; no primary+primary pairs; no FAB+bottom-CTA conflict.
UX-DR31: No bottom tab bar, no drawer, no navigation stack deeper than 2; Home is the single hub; no confirmation dialogs in primary flows (Send All is single-tap).
UX-DR32: Modal/overlay stack priority enforced — AlertDialog > system perms > BottomSheet > CredentialBanner > SnackBar > micro-toast; only one at a time; AlertDialog tap-outside does NOT dismiss; BottomSheet tap-outside is cancel (not a choice).

**Golden-Test Strategy**

UX-DR33: Every custom widget has golden tests for every named state × light/dark modes; parameterized font-scale goldens at 1.0/1.5/2.0; golden drift blocks merge (Jidoka — stop the line).

### FR Coverage Map

FR1: Epic 1 — First-run linear flow (consent + permissions + credentials)
FR2: Epic 1 — UMP/CMP EU consent surface
FR3: Epic 1 — Sensitive-data disclosure before camera permission
FR4: Epic 1 — Camera permission with manual-entry fallback
FR5: Epic 1 — Credential capture + Keystore storage
FR6: Epic 1 — Live login verification against eVisitor
FR7: Epic 1 — Re-enter credentials from Settings
FR8: Epic 1 — Session persistence across restarts (PersistCookieJar + AES-GCM)
FR9: Epic 2 — Error classifier for session-dead variants (401/403/400+SystemMessage/200+envelope + Croatian regex)
FR10: Epic 2 — Auto re-authentication with serialized concurrent requests
FR11: Epic 2 — CredentialBanner with one-tap recovery
FR12: Epic 2 — Client-side circuit breaker (3/6-min)
FR13: Epic 2 — Opportunistic auth check on foreground
FR14: Epic 2 — Auth-state view in Settings
FR14.5: Epic 2 — Credentials-missing recovery preserving facility context
FR15: Epic 3 — Fetch and cache facilities on first login
FR16: Epic 3 — Explicit per-session facility choice
FR17: Epic 3 — Last-used facility as hint, never default
FR18: Epic 3 — Active facility visible on Home
FR19: Epic 3 — Explicit facility list refresh without re-login
FR20: Epic 4 — Live MRZ auto-shutter capture
FR21: Epic 4 — Static-tap fallback at 3s
FR22: Epic 4 — Manual entry fallback
FR23: Epic 4 — Semantic sanity layer (date plausibility, expiry, ISO, birth year)
FR24: Epic 4 — Review/correct captured data before queue commit
FR25: Epic 4 — Inline Croatian rejection on sanity fail
FR26: Epic 4 — May-2026 mandate field behind feature flag
FR27: Epic 5 — Synchronous encrypted queue commit before success haptic
FR28: Epic 5 — Queue persists across kills/reboots/offline
FR29: Epic 5 — Unsent queue view with per-guest edit/delete
FR30: Epic 5 — 3-day auto-purge of submitted guests
FR31: Epic 5 — Manual per-guest delete
FR31.5: Epic 5 — Replace-Active-OIB typed confirmation
FR32: Epic 6 — Explicit Send All action
FR33: Epic 6 — Pre-flight auth + network check
FR34: Epic 6 — Per-guest submission isolation
FR35: Epic 6 — Per-guest success/failure reporting
FR36: Epic 6 — Edit failed guest and retry-failed-only
FR36.5: Epic 6 — Rate-limit throttling with exponential backoff
FR36.6: Epic 6 — `in_flight` reconciliation on resume
FR37: Epic 7 — Closure Summary (zero-PII, facility + count + time)
FR38: Epic 7 — Share/screenshot Closure Summary
FR39: Epic 8 — "Your Data" surface with live counts + policy links
FR40: Epic 8 — One-action wipe of all local data
FR41: Epic 9 — Zero-PII telemetry events (reliability thesis measurement)
FR42: Epic 9 — Forced-update banner blocking Send All on contract break

## Epic List

### Epic 1: First-Run Onboarding & Credential Trust

**User outcome:** A new host installs the app, consents to data handling, logs into eVisitor once, and lands on Home in under 90 seconds. Credentials and cookies persist securely across restarts so the host never re-authenticates unnecessarily.

**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8

**Implementation notes:** Bundles project bootstrap (`flutter create --empty`), CI workflows (analyze / pii-guard / test / integration-fake / testapi-canary / build-aab), Android platform hardening (`network_security_config.xml`, AndroidManifest `allowBackup=false`, `proguard-rules.pro`, `analysis_options.yaml`), the design-system foundation (`lib/design/tokens.dart` + theme builders + Manrope + Material Symbols rounded + dark-first themes), `SecurityService` + Keystore wiring + AES-GCM cookie-jar helper, DIY certificate pinning against `www.evisitor.hr`, UMP/CMP consent SDK integration, Welcome + Login screens, and the base `EvisitorApiClient` with the Login endpoint only (other endpoints arrive in later epics).

### Epic 2: Resilient Auth Lifecycle (No Door Surprises)

**User outcome:** Session-dead is caught opportunistically and surfaced hours before the door via a non-blocking credential banner. One tap restores the session. A client-side circuit breaker protects the host from Rhetos server-side 5-fail lockout. The host can always see current auth state in Settings.

**FRs covered:** FR9, FR10, FR11, FR12, FR13, FR14, FR14.5

**Implementation notes:** Dart 3 sealed `AuthState` FSM (6 variants), `AuthNotifier` with re-auth trigger and `consecutiveFailures`/`lockedUntil` fields, `QueuedInterceptor` subclass (`AuthInterceptor`) wired via Dio provider, pure-function `EvisitorErrorClassifier` (enum `EvisitorErrorClass` with exhaustive testing for 401/403/400+SystemMessage/200+envelope and Croatian regex `/locked|zaključan/i`, `/invalid|nevažeć|neispra/i`, `/session|prijava|auth/i`), `CredentialBanner` MaterialBanner subclass (4 states) with `SemanticsService.announce`, opportunistic `helloCheck` endpoint on foreground, Settings auth-state chip, LockedOut countdown screen, FR14.5 credentials-missing recovery path preserving facility context.

### Epic 3: Facility Choice (Neutral App Pattern)

**User outcome:** After first successful login the host sees their eVisitor facility list; at the start of every registration session they explicitly pick one facility (last-used is a visible hint, never a default), eliminating wrong-facility submissions.

**FRs covered:** FR15, FR16, FR17, FR18, FR19

**Implementation notes:** `FacilityNotifier` (AsyncNotifier), Drift `FacilitiesTable`, `Facility` Freezed model, `FacilityPickerSheet` custom widget (20dp top radius, "Zadnji" pill for last-used, tap-outside = cancel poka-yoke, 48dp rows, 5 states), Home AppBar facility chip with "change" affordance, `activeFacilityProvider` session-scoped StateProvider, explicit facility-required gate before Scan, manual facility refresh action.

### Epic 4: Confident Capture Pipeline (MRZ → Static-Tap → Manual)

**User outcome:** Host holds passport in front of camera; auto-shutter fires within 1.5s on valid MRZ + sanity; worn docs and non-EU IDs fall back to a 3-second static-tap and then to a fully functional manual-entry form. Expired documents, nonsensical birth years, and invalid ISO country codes are inline-rejected in Croatian before anything reaches the queue.

**FRs covered:** FR20, FR21, FR22, FR23, FR24, FR25, FR26

**Implementation notes:** `MrzCaptureService` (camera + google_mlkit_text_recognition on-device), pure-Dart TD1/TD2/TD3 `MrzParser` with checksum validation, `SemanticSanityLayer` (date plausibility, document expiry, ISO 3166 country codes, realistic birth years), `MRZViewfinder` custom widget (reticle + corner anchors + `ScanCounterChip` + hint), `CaptureConfirmation` overlay (haptic BEFORE render — if felt, Drift commit succeeded), Manual Entry screen as first-class path (FR4 camera-denied flow), FR26 May-2026 mandate field gated by `FeatureFlags.mayMandateField` const, Croatian inline rejection copy.

### Epic 5: Zero-Loss Encrypted Queue

**User outcome:** Every scanned guest is persisted to encrypted local storage with a client UUID, synchronously, before the success haptic fires. The queue survives app kills, device reboots, and offline periods indefinitely. Successful submissions are held 3 days as a soft-undo buffer then auto-purged. Host can delete individual entries or wipe all data via a typed-confirmation poka-yoke.

**FRs covered:** FR27, FR28, FR29, FR30, FR31, FR31.5

**Implementation notes:** `AppDatabase` (Drift) with `GuestEntriesTable` (id UUID PK, facilityId FK, `encryptedPayload` via AES-GCM `TypeConverter`, `state` enum, `clientCreatedAt`, `submittedAt?`, `purgeAfter?` indexed), `QueueNotifier` as single write chokepoint, 3-day auto-purge via `dart:async` `Timer` on app open (main-isolate), Home queue rendering via `GuestStatusGlyph` + `QueueRow` + `QueueHero` custom widgets (WhatsApp-style ○ ↑ ✓ ✗ ⋯), per-row swipe-to-dismiss with SnackBar undo for queued-only rows, PII-masked document numbers in rows, `TypedConfirmationDialog` for Replace-Active-OIB requiring literal "ZAMIJENI" word match (wipes Drift + cookie jar + Keystore + facility profiles and re-launches onboarding).

### Epic 6: Explicit Send All with Per-Guest Isolation

**User outcome:** One tap submits all unsent guests for the active facility; pre-flight blocks on dead auth or offline with a clear Croatian message; per-guest ✓/✗ is rendered inline so one rejected guest never kills the others; failed guests can be edited inline and retried without re-submitting successful ones; rate-limit throttling is handled gracefully with backoff; on crash recovery, `in_flight` entries are reconciled against eVisitor before any retry to prevent silent double-submits.

**FRs covered:** FR32, FR33, FR34, FR35, FR36, FR36.5, FR36.6

**Implementation notes:** `EvisitorApiClient.importTourists`, `ImportTouristsBuilder` (single XML-as-JSON-string source), `EvisitorDateCodec` (single `/Date(ms+offset)/` source), `SendAllNotifier` (AsyncNotifier, auto-disposed) with pre-flight auth + network check, per-guest serial submission loop with per-entry state transitions (`unsent → in_flight → submitted | failed`), `InFlightReconciler` with Path A (lookup-by-UUID — conditional on Week-1 spike) and Path B (host-review fallback) both implemented, retry-failed-only flow, edit failed guest inline (`guest_form_screen.dart` edit state), Send All Results (review) screen with `QueueRow(variant: review)` rendering, rate-limit (HTTP 429) detection with exponential backoff non-blocking message, "eVisitor contract break" classifier variant triggering forced-update check.

### Epic 7: Closure Summary (The Signature Moment)

**User outcome:** After every submission batch the host sees a full-screen Closure Summary — facility name, count (gold), and Europe/Zagreb local timestamp — designed to be screenshotted and shared via native Android share sheet. Zero PII in the payload. The host returns to Home with queue empty (or the failed entries remaining).

**FRs covered:** FR37, FR38

**Implementation notes:** `ClosureSummary` full-screen widget with linear gradient (`primaryContainer → surface` at 55%), `displayLarge` weight-800 count in `closureAccent` gold (color used ONLY on this screen), native Android ShareSheet with text-only payload (no screenshot export in v1.0), portrait-lock via `SystemChrome.setPreferredOrientations` restored on dispose, three states (`all_success | partial_with_failures | single_guest` with singular Croatian grammar), auto-focused on appearance (live region), persistent until user taps Done.

### Epic 8: Privacy Transparency & Data Wipe

**User outcome:** The host sees exactly what is currently stored on their device (unsent queue count + recently-submitted count within 3-day retention), with live links to the Privacy Policy and Terms of Service, and can trigger a complete one-action wipe of every byte of local data via typed-confirmation.

**FRs covered:** FR39, FR40

**Implementation notes:** `YourDataScreen` with live counts from `QueueNotifier`, 3-day purge countdown indicator, external links to `prijavko.hr/privacy` and `prijavko.hr/terms` via `url_launcher`, `TypedConfirmationDialog` requiring literal "OBRIŠI" word match for Delete-All, hard-wipe routine that clears Drift + cookie-jar file + `flutter_secure_storage` entries + cached facilities + credentials and re-launches to UMP/CMP consent + onboarding, Settings-screen integration (gear icon entry point from Home).

### Epic 9: Observability & Forced-Update Safety Net

**User outcome:** Solo-dev (Darko) can measure the reliability thesis in production — submission success rate, session-dead recovery rate, queue-stuck-24h count, crash-free session rate — without any guest or credential data leaving the device. When the eVisitor contract breaks, the host sees a forced-update banner and Send All is blocked until the app is updated (never silent data corruption).

**FRs covered:** FR41, FR42

**Implementation notes:** `TelemetryService` singleton as sole `FirebaseCrashlytics.instance` caller with typed methods (`scanToSubmit`, `authStateTransition`, `sendAllResult`, `queuePurge`, `classifierMismatch`, `queueStuck24h`) and `systemMessageHash` (SHA-256 never raw), Firebase Crashlytics Dart symbolication (`--split-debug-info`), `AppLogger` facade (String-only API, no Object overload) with `dart:developer` backend, CI grep-guard audit pass (forbidden log patterns blocking merges), `MinVersionChecker` polling `prijavko.hr/min-version.json` on cold start via Dio, `ForceUpdateBanner` as `ShellRoute` overlay blocking Send All when `currentBuild < minSupportedVersion`, queue-stuck-24h tripwire emitting `queueStuck24h` event when non-zero at app open, integration of telemetry call-sites into Epics 1–8 completed as part of this epic's acceptance (retroactive wiring where not already in place).

### Epic 10: Monetization & Launch Readiness

**User outcome:** Host installs a Play-Store-listed v1.0 with ad-supported free tier active on Home (never during scan/Send All/credential banner/closure), reliability-thesis copy in the listing, Data Safety declaration accepted by Play Store manual review, all sensitive-data compliance artifacts (Privacy Policy, ToS, MASVS L1) live before the 2026-05-27 submission.

**FRs covered:** none (completes NFR-S9, NFR-I6 verification, and all Play Store compliance surfaces needed for launch)

**Implementation notes:** `AdBanner` custom widget (AdMob anchored adaptive 50–100dp, `google_mobile_ads` + `google_user_messaging_platform`, Home-only build-time assertion, never renders simultaneously with `CredentialBanner`, no interstitials in v1.0), OWASP MASVS L1 self-audit checklist, Privacy Policy + ToS static HTML pages, `prijavko.hr/min-version.json` published, Play Store Data Safety declaration draft, 6 Croatian-language screenshots, Play Store listing copy in Croatian primary, Google Play Console track progression (Internal → Closed 2026-05-13 → Production 2026-05-27 staged 20/50/100% over 7 days), NFR-S11 staging acceptance test (intentional crash + Firebase Console manual inspection).

---

## Epic 1: First-Run Onboarding & Credential Trust

A new host installs the app, consents to data handling, logs into eVisitor once, and lands on Home in under 90 seconds. Credentials and cookies persist securely across restarts. Bundles project bootstrap, design-system foundation, security primitives, and the Welcome/Login flow.

### Story 1.1: Project Bootstrap & CI Foundation

As a solo developer,
I want a strict, production-ready Flutter project scaffold with CI workflows in place from commit #1,
So that every subsequent story lands on a build-blocking foundation that catches analyzer warnings, PII log leaks, test regressions, and contract drift before they reach main.

**Acceptance Criteria:**

**Given** no Flutter project exists in the repo
**When** the bootstrap story is executed
**Then** the repo contains a Flutter project created via `flutter create --org hr.prijavko --project-name prijavko --platforms=android --empty -a kotlin .`
**And** `pubspec.yaml` pins Flutter stable + Dart 3.x
**And** `pubspec.lock` is committed
**And** `analysis_options.yaml` extends `flutter_lints` and enables at minimum `avoid_print`, `prefer_const_constructors`, `always_use_package_imports`, `directives_ordering`, `unnecessary_null_checks`
**And** `dart analyze --fatal-warnings --fatal-infos` exits with zero warnings on the empty scaffold

**Given** the project scaffold exists
**When** a commit is pushed or a PR is opened
**Then** GitHub Actions runs six workflows — `analyze.yml`, `pii_guard.yml`, `test.yml`, `integration_fake.yml`, `testapi_canary.yml` (nightly cron), `build_aab.yml` (on `v*` tag)
**And** the `pii_guard.yml` grep fails the build on any of the patterns `(print|debugPrint|AppLogger\.\w+)\(.*\.(documentNumber|firstName|lastName|dateOfBirth|nationality|documentExpiry|mrzLine1|mrzLine2)` referencing a PII field name
**And** each workflow has a matching README entry explaining its trigger and scope

**Given** the Android app module
**When** the module is inspected
**Then** `android/app/src/main/AndroidManifest.xml` declares `android:allowBackup="false"` and `android:fullBackupContent="false"` and exactly three permissions: `CAMERA`, `INTERNET`, `ACCESS_NETWORK_STATE`
**And** `android/app/src/main/res/xml/network_security_config.xml` declares `cleartextTrafficPermitted="false"` and references the cert-pinning pin set location
**And** `android/app/proguard-rules.pro` contains keep rules for Drift generated code, Riverpod annotations, Freezed `copyWith`, and Dio `HttpClientAdapter`
**And** the build targets min SDK 24 and the latest Play-mandated target SDK

**Given** the project supports environment switching without flavors
**When** a developer runs `flutter run --dart-define=EVISITOR_ENV=<prod|test|fake>`
**Then** `String.fromEnvironment('EVISITOR_ENV', defaultValue: 'prod')` returns the correct value at runtime
**And** no dev/staging/prod Gradle buildTypes have been introduced

**Given** the release build pipeline
**When** a `v*` tag is pushed
**Then** `build_aab.yml` produces a signed AAB via `flutter build appbundle --obfuscate --split-debug-info=build/symbols/`
**And** the workflow uploads the symbols artifact to the workflow run

---

### Story 1.2: Design System Foundation

As a developer implementing any screen,
I want a single source of truth for colors, spacing, radii, typography, and semantic extensions,
So that no widget ever hardcodes a hex value, a magic spacing number, or an inline `TextStyle` and the entire app responds to system dark/light mode with WCAG AA contrast by default.

**Acceptance Criteria:**

**Given** a freshly bootstrapped project
**When** Story 1.2 completes
**Then** `lib/design/tokens.dart` exists with pure `const` values mirroring the Figma `color` / `spacing` / `radii` / `sizing` collections from `figma-code-contract.md` §1 (including `primarySeed = Color(0xFF0D4F52)`, space4..space64, radiusButton=12, radiusCard=16, radiusSheet=24, buttonMinHeight=56)
**And** `tokens.dart` imports nothing beyond `dart:ui` / `flutter/material.dart` for `Color` and `TextStyle` types

**Given** the tokens file exists
**When** `lib/design/theme.dart` is reviewed
**Then** it exports `buildLightTheme()` and `buildDarkTheme()`, both derived from `ColorScheme.fromSeed(seedColor: Tokens.primarySeed, brightness: ...)`
**And** both themes set Manrope via `google_fonts` with weights 400/500/600/700/800, mapping the 12 Figma text styles to Material 3 `TextTheme` slots per `figma-code-contract.md` §2
**And** component defaults (`FilledButton` min-height 56dp, `Card` 16dp radius, `OutlinedButton` 1.5px 48dp, etc.) live in theme component slots — not per-widget overrides

**Given** Material 3 `ColorScheme` does not cover warning/closure semantics
**When** `lib/design/extensions.dart` is reviewed
**Then** it declares `ThemeExtension<SemanticColors>` with required named parameters `warning`, `warningContainer`, `onWarningContainer`, `success`, `onSuccess`, `closureAccent`, `surfaceContainerHigh`, `outlineVariant`
**And** both theme builders register the extension with light- and dark-specific values per UX spec §Color System

**Given** the theming layer exists
**When** `lib/main.dart` boots the app
**Then** `MaterialApp` passes `theme: buildLightTheme()`, `darkTheme: buildDarkTheme()`, `themeMode: ThemeMode.system`
**And** Material Symbols (rounded) are registered once so `Symbols.xxx` is available everywhere; `Icons.xxx` usage is prohibited by a CI-enforced grep rule

**Given** the design-system rules in `.claude/rules/design-system.md`
**When** a widget test covers tokens usage
**Then** a test verifies `FilledButton` minimum height resolves to `Tokens.size.buttonMinHeight` in both themes
**And** a test verifies `ThemeExtension<SemanticColors>` resolves on `Theme.of(context).extension<SemanticColors>()` without null in both light and dark

---

### Story 1.3: Security Primitives, Dio & Cert Pinning

As a host,
I want every network call to eVisitor to be cert-pinned, encrypted at rest, and routed through a single auditable Dio instance,
So that a rogue Wi-Fi, a MITM attempt, or an OS-level backup cannot expose my credentials, cookies, or queued guest data.

**Acceptance Criteria:**

**Given** the security primitives are implemented
**When** `lib/core/security/` is inspected
**Then** `security_service.dart` loads a single AES-GCM key from `flutter_secure_storage` (Keystore-backed) at app start and holds it in memory for the session
**And** `aes_gcm_helper.dart` provides `encrypt(bytes) → ciphertext` and `decrypt(ciphertext) → bytes` using `cryptography_flutter` AES-GCM
**And** `cert_pins.dart` exposes `CertPins.validFingerprints` as `const Set<String>` of SHA-256 hex fingerprints for leaf + intermediate on `www.evisitor.hr`
**And** `docs/security/cert-pins.md` records the pin values, certificate validity windows, and the forced-update trigger date

**Given** the Dio provider wires the HTTP client
**When** a request is dispatched
**Then** the `dioProvider` in `lib/app/providers.dart` constructs Dio with `dio_cookie_manager` + `PersistCookieJar` whose jar file is AES-GCM-encrypted at `path_provider.getApplicationDocumentsDirectory()`
**And** the default `HttpClientAdapter` has `onHttpClientCreate` set so `client.badCertificateCallback` rejects any host other than `www.evisitor.hr` and requires a SHA-256 match against `CertPins.validFingerprints`
**And** connect timeout = 10s, receive timeout = 30s, send timeout = 30s, with an extended 60s receive timeout path reserved for the future `ImportTourists` call

**Given** environment switching is required
**When** Dio is constructed
**Then** its `baseUrl` resolves from `EVISITOR_ENV` — `prod` → `https://www.evisitor.hr/eVisitorRhetos_API/`, `test` → `https://www.evisitor.hr/testApi`, `fake` → in-memory fake adapter bypassing cert pinning entirely
**And** integration tests pass `--dart-define=EVISITOR_ENV=fake` and load `test/fakes/evisitor_fake_adapter.dart` instead of a real HTTP client

**Given** credentials must never leak to backup
**When** `lib/features/settings/credential_store.dart` is reviewed
**Then** it exposes `saveCredentials`, `loadCredentials`, and `wipeCredentials` methods backed by `flutter_secure_storage` with Android Keystore accessibility flag set to `first_unlock_this_device`
**And** unit tests verify that `wipeCredentials` clears every key, not just a subset

**Given** a pin mismatch must abort without retry
**When** `cert_pins_test.dart` runs
**Then** the test simulates a cert fingerprint not in `validFingerprints` and verifies the Dio request fails with a `DioException` of type `badCertificate` and no retry is issued

---

### Story 1.4: UMP/CMP EU Consent Surface

As a host in the EEA,
I want to be asked for ad-personalization consent on first launch before any ads are requested,
So that the app complies with GDPR/EU consent requirements and I control whether ads are personalized.

**Acceptance Criteria:**

**Given** the app is launching for the first time and the user is in an EEA locale
**When** the app cold-starts
**Then** the UMP/CMP consent form renders before any other screen (including Welcome)
**And** the UMP form is driven by the `google_user_messaging_platform` SDK with the AdMob App ID configured in `AndroidManifest.xml`
**And** no ad request is initiated until `ConsentInformation.consentStatus` is either `obtained` or `notRequired`

**Given** the user has completed the UMP form
**When** consent state persists to device
**Then** subsequent cold starts do not re-show the form unless `ConsentInformation.isConsentFormAvailable()` reports a policy update
**And** a Settings entry "Privola za oglase" allows the user to re-open the form on demand

**Given** the user is outside the EEA
**When** the app cold-starts
**Then** the UMP form is skipped and the user proceeds directly to the Welcome screen
**And** ad personalization runs per AdMob defaults (no extra gating)

**Given** UMP determined non-personalized ads only
**When** any subsequent `AdBanner` request is issued
**Then** the request is marked non-personalized via AdMob request parameters
**And** this state is exposed via a Riverpod provider so `AdBanner` (Epic 10) can read it without touching UMP SDK directly

---

### Story 1.5: Welcome & Sensitive-Data Disclosure

As a host on first launch,
I want a clear, Croatian-primary explanation of what passport data the app processes, how long it keeps it, and where the policy lives,
So that I give informed consent before granting camera permission and understand the trust premise before entering credentials.

**Acceptance Criteria:**

**Given** UMP consent has resolved
**When** the Welcome screen renders
**Then** the screen displays a Croatian-primary headline, body text explaining "Prijavko scans passports and sends them to eVisitor. Your data never leaves your phone except to eVisitor. After submission, it is kept 3 days as a safety buffer, then deleted.", and two inline links "Pravila privatnosti" and "Uvjeti korištenja" that open via `url_launcher` to `https://prijavko.hr/privacy` and `https://prijavko.hr/terms`
**And** a single "Nastavi" `FilledButton` is the only CTA
**And** all text uses `AppLocalizations` (no literal strings in the build method)
**And** the screen is assembled per `figma-code-contract.md` §4 row 01 into `lib/features/onboarding/welcome_screen.dart`

**Given** the Welcome screen is visible
**When** the host taps "Nastavi"
**Then** `go_router` navigates to the camera-permission screen (Story 1.6)
**And** no ad requests fire on this screen (per UX spec §Ad Placement — Welcome is always ad-free)

**Given** dark mode is the primary design target
**When** widget tests render the Welcome screen
**Then** golden tests exist for both dark and light variants
**And** contrast meets WCAG 2.1 AA (`4.5:1` body, `3:1` large text)
**And** `Semantics` labels are present so TalkBack reads headline, body, both links, and CTA in visual order

---

### Story 1.6: Camera Permission with Manual-Entry Fallback

As a host,
I want to grant or deny camera access with a clear explanation of why it's needed,
So that if I deny it the app still works — manual entry remains fully functional.

**Acceptance Criteria:**

**Given** the host has completed the Welcome screen
**When** the permission screen is reached
**Then** the screen shows a Croatian-primary rationale ("Kamera je potrebna za skeniranje MRZ koda. Slike se ne pohranjuju ni ne šalju.") and two CTAs: "Dopusti pristup" primary, "Preskoči — ručni unos" secondary
**And** tapping "Dopusti pristup" triggers `permission_handler`'s camera request
**And** tapping "Preskoči — ručni unos" skips the OS prompt and routes forward

**Given** the user granted camera permission
**When** the next screen loads
**Then** the app routes to the eVisitor login screen (Story 1.7)
**And** a local flag `capturePreference = live` is persisted so downstream capture flows default to MRZ-first

**Given** the user denied or skipped camera permission
**When** the next screen loads
**Then** the app still routes to the eVisitor login screen
**And** `capturePreference = manualOnly` is persisted
**And** Epic 4's capture flow reads this flag and surfaces manual entry as the primary path without re-prompting for camera

**Given** the user is on the Settings screen (once it exists)
**When** they tap "Pristup kameri"
**Then** the app re-requests camera permission via `permission_handler`
**And** updates `capturePreference` on grant

---

### Story 1.7: eVisitor Login & Live Credential Verification

As a host with an eVisitor account,
I want to enter my username and password once and have the app verify them against eVisitor,
So that I confirm credentials are correct before relying on them at the door, and subsequent sessions log me in automatically.

**Acceptance Criteria:**

**Given** the host has reached the login screen
**When** `login_screen.dart` renders
**Then** two `TextField`s are shown (username with `autofillHints: [username]`, password with `autofillHints: [password]` and visibility toggle)
**And** the reassurance line "🔒 Podaci se čuvaju šifrirano u Android Keystore-u" is rendered under the fields in `bodySmall`
**And** a single "Prijavi se" `FilledButton` is the only CTA, disabled until both fields are non-empty
**And** the apikey field is NOT rendered in the UI — the key is either embedded at build time as a `String.fromEnvironment('EVISITOR_API_KEY')` const or supplied by the Dio fake in `EVISITOR_ENV=fake`

**Given** the host taps "Prijavi se" with valid credentials
**When** `EvisitorApiClient.login(userName, password, apikey)` POSTs to `/Resources/AspNetFormsAuth/Authentication/Login`
**Then** the expected response is `true` with `Set-Cookie` headers for `authentication`, `affinity`, and `language`
**And** the three cookies are persisted to `PersistCookieJar` (AES-GCM-encrypted file)
**And** credentials are persisted to `flutter_secure_storage` via `CredentialStore.saveCredentials`
**And** the app routes to the facility picker (delivered in Epic 3) or directly to Home if only one facility exists

**Given** the API key is not yet provisioned from HTZ
**When** the developer runs with `--dart-define=EVISITOR_ENV=fake`
**Then** `EvisitorFakeAdapter` returns `HTTP 200 body: true` and three synthetic cookies
**And** the login flow completes end-to-end in integration tests without a real eVisitor call
**And** a README note in `test/fakes/evisitor_fake_adapter.dart` documents how to swap in the real key once obtained

**Given** the host submits incorrect credentials
**When** eVisitor returns HTTP 400 with `{UserMessage, SystemMessage}` or HTTP 200 `false`
**Then** the login button returns to enabled state
**And** the `UserMessage` (if present) is rendered in Croatian below the form
**And** a prijavko-provided Croatian hint "Provjerite korisničko ime i lozinku" is appended per NFR-L3
**And** no credentials or cookies are persisted on failure

**Given** the host submits credentials that trigger a lockout
**When** eVisitor returns a lockout envelope
**Then** the Croatian message "Previše neuspješnih pokušaja — pričekajte 6 minuta." is shown
**And** the login form is disabled for 6 minutes with a visible countdown (actual circuit-breaker logic arrives in Epic 2 Story 2.5; this story renders the UI state correctly when the classifier returns `lockedOut`)

---

### Story 1.8: Session Persistence Across Restarts

As a returning host,
I want the app to remember my login across process kills and device reboots,
So that I don't have to re-authenticate every time I open the app to register guests.

**Acceptance Criteria:**

**Given** the host has previously logged in successfully
**When** the app cold-starts
**Then** `main.dart` awaits `SecurityService.init()` and `CredentialStore.loadCredentials()` before building the widget tree
**And** if credentials are present in Keystore AND the cookie jar file exists with valid ciphertext AND cookies decrypt successfully, the app routes directly to Home via go_router redirect (skipping Welcome / permission / login)
**And** an opportunistic auth check is enqueued for the next frame (actual implementation deferred to Epic 2 Story 2.6)

**Given** credentials exist but cookies are missing or undecryptable
**When** cold-start evaluates routing
**Then** `AuthState` is set to `Reauth` (handover to Epic 2)
**And** the app still routes to Home; the `CredentialBanner` surfaced by Epic 2 handles recovery
**And** no forced re-onboarding occurs

**Given** credentials are missing but a facility profile exists
**When** cold-start evaluates routing
**Then** `AuthState` is set to `AuthFailure(credentialsInvalid)` and the credentials-missing recovery flow (FR14.5, Epic 2 Story 2.7) is invoked
**And** facility context is preserved (facility names visible in the recovery screen)

**Given** neither credentials nor any prior state exist
**When** cold-start evaluates routing
**Then** the app routes to the UMP consent surface → Welcome → permission → login flow per first-run onboarding

**Given** the app has been backgrounded for more than 14 days
**When** the app is foregrounded
**Then** `AuthNotifier` is not preemptively flipped to `Reauth` on Story 1.8's logic alone (14-day sliding-window expiry is a server-side concern surfaced by Epic 2's opportunistic check)
**And** Home renders normally pending that check's result

---

### Story 1.9: Credential Re-Entry from Settings

As a host who changed my eVisitor password,
I want to re-enter my credentials from Settings without losing my facility context or queued guests,
So that I can recover from a password change without starting onboarding from scratch.

**Acceptance Criteria:**

**Given** the host is on the (skeleton) Settings screen
**When** they tap "Zamijeni podatke za prijavu"
**Then** the app routes to a modified login screen with the username field pre-filled from Keystore and the password field empty and focused
**And** a clear banner "Zamjena podataka — stari objekti i nedoslani gosti ostaju." is visible at the top

**Given** the host submits new credentials
**When** login succeeds
**Then** the new username + password overwrite the existing Keystore values via `CredentialStore.saveCredentials`
**And** the cookie jar is replaced with the new session's cookies
**And** `FacilitiesTable` rows are preserved untouched
**And** `GuestEntriesTable` rows (unsent or within 3-day buffer) are preserved untouched
**And** the host returns to the Settings screen with a SnackBar "Podaci ažurirani."

**Given** the host submits incorrect new credentials
**When** login fails
**Then** the old Keystore values are retained (no partial overwrite)
**And** the Croatian error flow from Story 1.7 renders inline
**And** facility and queue data remain untouched

**Given** the host is in the re-entry flow
**When** they tap the system back gesture
**Then** they return to Settings with zero state changes

---

## Epic 2: Resilient Auth Lifecycle (No Door Surprises)

Session-dead is caught opportunistically and surfaced hours before the door via a non-blocking credential banner. One tap restores the session. A client-side circuit breaker protects the host from Rhetos server-side 5-fail lockout. The host can always see current auth state in Settings.

### Story 2.1: AuthState Sealed Class & AuthNotifier Skeleton

As a developer,
I want a single, exhaustively-typed representation of the authentication state machine,
So that every UI surface, every interceptor, and every error path reads from one source of truth and invalid state transitions become compile-time impossible.

**Acceptance Criteria:**

**Given** the auth feature directory is scaffolded
**When** `lib/features/auth/auth_state.dart` is reviewed
**Then** it declares a Dart 3 `sealed class AuthState` with exactly seven final subclasses: `Initial`, `Unauthenticated`, `Authenticating`, `Authenticated({required bool facilitiesLoaded})`, `Reauth`, `LockedOut({required DateTime retryAfter})`, `AuthFailure({required AuthFailureReason reason})`
**And** `auth_failure_reason.dart` declares an enum with `sessionDead | credentialsInvalid | lockedOut | network | contractBreak`
**And** the sealed class enforces exhaustive `switch` at every consumer — a new variant triggers compile errors at every call site

**Given** the `AuthNotifier` class is implemented
**When** `lib/features/auth/auth_notifier.dart` is reviewed
**Then** it extends Riverpod 3 `Notifier<AuthState>` and is exposed via `authNotifierProvider`
**And** the `build()` method consumes `sessionBootstrapProvider` (Story 1.8) and resolves the initial `AuthState` via the exhaustive transition table below
**And** it exposes public methods `handleAuthFailure(EvisitorErrorClass)`, `reauthenticate()`, `login(username, password)`, and `logout()`
**And** `handleAuthFailure` is initially a stub that transitions state based on a hand-coded switch (real classifier wiring arrives in Story 2.3)

**Given** the `SessionBootstrap → AuthState` handoff must be exhaustive — Story 1.8 ships four `SessionBootstrap` variants and Story 2.1 must cover all of them, with no implicit defaults (per Epic 1 retro §6 #2)
**When** `AuthNotifier.build()` resolves the bootstrap future
**Then** the mapping is implemented as an exhaustive `switch` over the sealed `SessionBootstrap`:

| `SessionBootstrap` variant (Story 1.8) | `AuthState` (Story 2.1) | Rationale |
|---|---|---|
| `BootFreshFirstRun` | `Unauthenticated` | No credentials, no facility cache → onboarding flow drives login |
| `BootSessionLive` | `Authenticated(facilitiesLoaded: false)` | Credentials + cookies both viable; facilities load lazily |
| `BootCookiesMissing` | `Reauth` | Credentials viable, cookies expired/undecryptable → silent re-auth (Story 2.4) |
| `BootCredentialsMissing` | `AuthFailure(reason: credentialsInvalid)` | Facility profile exists but Keystore is empty → recovery flow (Story 2.8) |

**And** `Initial` is reserved exclusively for the synchronous pre-bootstrap window (sessionBootstrap future is `AsyncLoading`) and is never produced by the switch — once the future resolves, one of the four mapped variants is emitted
**And** the switch is exhaustive — adding a fifth `SessionBootstrap` variant later breaks compilation in `auth_notifier.dart`, forcing a deliberate update (Poka-yoke)
**And** a unit test in `auth_notifier_bootstrap_test.dart` exercises every `SessionBootstrap` variant and asserts the resulting `AuthState` against the table above; a single missing case fails CI

**Given** state transitions must never skip or corrupt the FSM
**When** unit tests for `AuthNotifier` run
**Then** every transition path is tested: `Initial → Authenticating → Authenticated` (success), `Authenticating → AuthFailure(credentialsInvalid)` (bad creds), `Authenticated → Reauth → Authenticated` (session recovery), `Reauth → LockedOut` (circuit breaker stub), `Authenticated → AuthFailure(network)` (offline)
**And** no test can construct an unreachable transition because the sealed class makes it impossible

**Given** outside code must never mutate state directly
**When** `authNotifier.state = X` / `authNotifierProvider.notifier.state = X` patterns are searched for in the codebase
**Then** a CI grep rule flags any such pattern at build time
**And** the anti-pattern is documented in the Architecture Anti-Pattern Reference table

---

### Story 2.2: Error Classifier (Pure Function with Exhaustive Tests)

As a host,
I want the app to correctly distinguish a dead session from bad credentials, a network blip, a rate-limit, or a server error,
So that the UI surfaces the right recovery affordance and my failed submission never silently looks successful.

**Acceptance Criteria:**

**Given** the error-classification layer exists
**When** `lib/core/errors/evisitor_error_class.dart` is reviewed
**Then** it declares `enum EvisitorErrorClass { sessionDead, lockedOut, credentialsInvalid, throttled, network, serverError, contractBreak, validationError }`
**And** `lib/core/errors/classifier_input.dart` declares a Dart 3 `sealed class ClassifierInput` with exactly two final subclasses:
  - `DioFailure({required DioException exception})` — the request threw (non-2xx response, timeout, connection error, cancellation)
  - `SuccessEnvelope({required Response<dynamic> response, required Uri requestUri})` — HTTP 200 carrying a `{UserMessage, SystemMessage}` error envelope (the Rhetos issue #182 case Story 1.7 documented; status code alone is insufficient per CLAUDE.md eVisitor quirks)
**And** `lib/core/errors/evisitor_error_classifier.dart` exposes a single pure function `EvisitorErrorClass classify(ClassifierInput input)` with zero side effects — one entry point, not two; the unified ADT forces every call site (`AuthInterceptor` from Story 2.3, eVisitor response post-processing in `EvisitorApiClient`) to construct the correct variant and removes the "did you remember to inspect the 200 body?" footgun (per Epic 1 retro §6 #4)
**And** the existing `LoginResponseClassifier.classifyLoginResponse` (Story 1.7) is removed; its six documented response shapes become test cases against `classify(ClassifierInput)` and the `// TODO(story-2.2):` migration marker in 1.7 is closed

**Given** the classifier is called with HTTP 401
**When** processed
**Then** the function returns `sessionDead`

**Given** the classifier is called with HTTP 403
**When** processed
**Then** the function returns `sessionDead`

**Given** the classifier is called with HTTP 400 whose body contains `SystemMessage` matching `/not authenticated|unauthorized|session/i` OR Croatian `/session|prijava|auth/i`
**When** processed
**Then** the function returns `sessionDead` — this is the Rhetos issue #182 case that the naïve Dio interceptor would miss

**Given** the classifier is called via `SuccessEnvelope` on a non-Login endpoint with HTTP 200 + error envelope `{UserMessage, SystemMessage}`
**When** processed
**Then** the function returns `sessionDead` if `SystemMessage` matches any session-dead regex, else `validationError`

**Given** `SystemMessage` matches `/locked|zaključan/i`
**When** processed
**Then** the function returns `lockedOut`

**Given** `SystemMessage` matches `/invalid|nevažeć|neispra/i` on a Login endpoint
**When** processed
**Then** the function returns `credentialsInvalid`

**Given** HTTP 429 or an equivalent throttling envelope
**When** processed
**Then** the function returns `throttled`

**Given** HTTP 5xx
**When** processed
**Then** the function returns `serverError`

**Given** `DioExceptionType.connectionTimeout | sendTimeout | receiveTimeout | connectionError`
**When** processed
**Then** the function returns `network`

**Given** a response shape the classifier does not recognize (no parseable body, no known `SystemMessage` pattern, no matching HTTP status)
**When** processed
**Then** the function returns `contractBreak` — consumed by the forced-update mechanism in Epic 9

**Given** a new variant is added to `EvisitorErrorClass`
**When** `evisitor_error_classifier_test.dart` runs
**Then** the test file has exhaustive coverage via a sealed-enum switch that fails compilation if a variant lacks a test case
**And** the permanent Dio fake in `test/fakes/evisitor_fake_adapter.dart` exposes canned responses for every variant so integration tests can exercise the full matrix

---

### Story 2.3: QueuedInterceptor Wiring with Serialized Re-Auth

As a host,
I want concurrent eVisitor calls that all hit an expired session to trigger exactly one re-login — not one login per in-flight request,
So that I never accidentally burn through the Rhetos 5-failure lockout budget because two requests raced.

**Acceptance Criteria:**

**Given** the `AuthInterceptor` is implemented
**When** `lib/features/auth/auth_interceptor.dart` is reviewed
**Then** it extends `QueuedInterceptor` (NOT `Interceptor` — Dio 5.x's synchronous-exception fix is required per Architecture §3)
**And** it is instantiated inside the `dioProvider` factory, closing over `Ref` so it can call `ref.read(authNotifierProvider.notifier)`

**Given** a Dio request fails
**When** `onError` fires
**Then** the interceptor calls `EvisitorErrorClassifier.classify(err)` and passes the result to `AuthNotifier.handleAuthFailure(classifiedError)`
**And** if classification is `sessionDead`, the interceptor awaits a single internal `Completer<void>` for the re-auth to complete, then re-plays the original request
**And** if classification is anything else, the error is passed through unchanged

**Given** N concurrent requests race with the same `sessionDead` classification
**When** the first one enters `onError`
**Then** the `Completer<void>` is created and held on the `AuthNotifier`
**And** all subsequent concurrent re-auth triggers `await` the same Completer instead of initiating a second login
**And** an integration test against the Dio fake dispatches 10 concurrent requests that all return `sessionDead` and asserts exactly one `POST /Login` call was made (per NFR-R7)

**Given** re-auth completes successfully
**When** the Completer resolves
**Then** every queued request is re-played with the fresh cookie jar
**And** the classifier is re-run on the replayed response
**And** a second consecutive `sessionDead` on the replay does NOT trigger a third login — it transitions to `AuthFailure(credentialsInvalid)` to prevent infinite loops

**Given** re-auth fails due to invalid credentials
**When** the Completer resolves with an error
**Then** every queued request fails with the original `DioException`
**And** `AuthNotifier` state is `AuthFailure(credentialsInvalid)`

---

### Story 2.4: Auto Re-Authentication with Stored Credentials

As a host whose session expired while the app was backgrounded,
I want the app to silently re-authenticate using my stored credentials when I next open it or take an action,
So that I never see the login screen again unless my actual password changed.

**Acceptance Criteria:**

**Given** `AuthNotifier` is in state `Reauth`
**When** `AuthNotifier.reauthenticate()` is called (by the interceptor from Story 2.3 or by the CredentialBanner tap from Story 2.7)
**Then** it loads credentials from `CredentialStore.loadCredentials()`
**And** calls `EvisitorApiClient.login(userName, password, apikey)` with the stored values
**And** on success, `AuthNotifier` transitions to `Authenticated(facilitiesLoaded: false)` and the new cookies are persisted
**And** on classifier `credentialsInvalid` result, `AuthNotifier` transitions to `AuthFailure(credentialsInvalid)`
**And** on classifier `lockedOut` result, `AuthNotifier` transitions to `LockedOut(retryAfter: ...)` (handled by Story 2.5)

**Given** credentials are missing from Keystore when `reauthenticate()` is called
**When** `CredentialStore.loadCredentials()` returns null
**Then** `AuthNotifier` transitions immediately to `AuthFailure(credentialsInvalid)` without making a network call
**And** the credentials-missing recovery flow (Story 2.8) is surfaced

**Given** re-auth is in progress
**When** any other code attempts to call `reauthenticate()` concurrently
**Then** the second call is a no-op — the first call's in-flight operation is awaited (serialization from Story 2.3 applies)
**And** no double-login is ever dispatched

**Given** re-auth succeeds
**When** the new `Authenticated` state is emitted
**Then** the existing facility list and queue remain untouched
**And** TelemetryService (Epic 9) logs an `auth_state_transition` event `from: "reauth"` `to: "authenticated"` when wired

---

### Story 2.5: Circuit Breaker (3 Failures / 6-Minute Open)

As a host,
I want the app to stop hammering eVisitor after three consecutive login failures,
So that I never accidentally trigger the Rhetos 5-fail server-side lockout from a bug or a stale credential.

**Acceptance Criteria:**

**Given** `AuthNotifier` tracks login failure history
**When** a login attempt fails with `credentialsInvalid` or any non-network classifier outcome
**Then** `consecutiveFailures` increments
**And** a successful login resets `consecutiveFailures` to 0

**Given** `consecutiveFailures` reaches 3
**When** the third failure is recorded
**Then** `AuthNotifier` transitions to `LockedOut(retryAfter: DateTime.now().add(Duration(minutes: 6)))`
**And** any login or `reauthenticate` call during the open state returns immediately without hitting the network
**And** the state emits a rebuild so the countdown UI can render

**Given** `AuthNotifier` is in `LockedOut` state
**When** the current time passes `retryAfter`
**Then** the next login/reauth call is allowed
**And** `consecutiveFailures` is reset to 0
**And** the state transitions to `Unauthenticated` (or `Reauth` if triggered from an existing session context)

**Given** lockout state must survive process death — Story 1.7's lockout timer was `autoDispose` and lost on back-gesture / force-quit, which Epic 1 retro §6 #3 flagged as the gap Story 2.5 must close (otherwise a host force-quits and the lockout vanishes, defeating the whole circuit-breaker)
**When** `AuthNotifier` transitions into `LockedOut(retryAfter: ...)`
**Then** `retryAfter` is persisted as `lockedOutUntil: DateTime?` (UTC, ISO-8601) to `flutter_secure_storage` (Android Keystore-backed) via a dedicated `LockoutStore` interface that mirrors the `CredentialStore` seam pattern from Story 1.3 (abstract interface + concrete + `FakeLockoutStore` with constructor-injected error-script function per retro action T6)
**And** `consecutiveFailures` is persisted in the same `LockoutStore` write so a force-quit between failure 2 and failure 3 does not reset the counter
**And** the `LockoutStore` write is the **last** step of the state transition — if it fails, the transition is aborted and `AuthNotifier` emits `AuthFailure(network)` (Jidoka — never enter `LockedOut` without durable backing)

**Given** the app is force-quit while in `LockedOut` and re-launched before `retryAfter`
**When** `AuthNotifier.build()` runs during cold start
**Then** it reads `LockoutStore.load()` **before** consuming `sessionBootstrapProvider`
**And** if `lockedOutUntil != null && DateTime.now().isBefore(lockedOutUntil!)`, the initial state is `LockedOut(retryAfter: lockedOutUntil!)` — overriding any `SessionBootstrap → AuthState` mapping from Story 2.1
**And** if `lockedOutUntil != null && DateTime.now().isAfter(lockedOutUntil!)`, `LockoutStore.clear()` is called and the bootstrap mapping proceeds normally
**And** an integration test simulates: 3 failed logins → `AuthNotifier` reaches `LockedOut` → force-kill app → cold start within the cooldown window → asserts `LockedOut` with the original `retryAfter` and disabled login inputs
**And** a second integration test simulates the same flow but cold-starts **after** `retryAfter` and asserts `Unauthenticated` plus a cleared `LockoutStore`

**Given** the client-side threshold must stay strictly more conservative than Rhetos server-side
**When** a unit test compares the breaker budget to the documented Rhetos policy
**Then** the test asserts `clientMaxFailures < serverMaxFailures` (3 < 5) and `clientCooldown > serverCooldown` (6min > 5min)

**Given** the host reaches `LockedOut`
**When** the UI renders the state
**Then** a dedicated `/locked-out` route (or an inline section on the login screen) shows "Previše neuspješnih pokušaja — pričekajte 6 minuta." with a live countdown timer refreshing every second
**And** all login-form inputs are disabled until the countdown reaches zero

---

### Story 2.6: Opportunistic Auth Check on Foreground

As a host who opens the app hours before guests arrive,
I want the app to silently check whether my eVisitor session is still alive,
So that any session-dead state is surfaced via the credential banner long before I reach the door.

**Acceptance Criteria:**

**Given** `AuthNotifier` observes app lifecycle changes
**When** the app transitions to `AppLifecycleState.resumed`
**Then** a single cheap `EvisitorApiClient.helloCheck()` request is dispatched non-blocking
**And** the check never awaits on the UI thread — it fires and forgets into a Future that updates state when resolved
**And** the warm-resume-to-ready latency stays within 1s p95 (NFR-P9)

**Given** the opportunistic check returns a `sessionDead` classifier result
**When** `AuthNotifier.handleAuthFailure(sessionDead)` processes it
**Then** state transitions to `Reauth`
**And** the `CredentialBanner` surfaces via the ShellRoute overlay (Story 2.7)

**Given** the opportunistic check returns `Authenticated`
**When** state is already `Authenticated`
**Then** the state is not re-emitted (no unnecessary rebuilds) — only transitions that actually change the variant cause emissions

**Given** the opportunistic check fails with a `network` classifier result
**When** processed
**Then** `AuthNotifier` does NOT transition to a failure state — the check is best-effort and a no-network condition is normal
**And** no banner is surfaced on pure network failure; the banner appears only on `sessionDead` or `credentialsInvalid`

**Given** `/Rest/Htz/Hello` (or the chosen cheap authenticated endpoint) is unknown until Week-1 spike
**When** the endpoint path is selected
**Then** the endpoint is defined once as a `const` in `EvisitorApiClient` so a single change swaps the ping target
**And** the Dio fake returns a canned `{status: "ok"}` for this endpoint in `EVISITOR_ENV=fake`

---

### Story 2.7: CredentialBanner (MaterialBanner Subclass)

As a host,
I want a non-blocking amber banner at the top of the screen the moment my session goes dead,
So that I can tap once to reconnect without navigating away from whatever I'm doing, and I never discover the problem at the door.

**Acceptance Criteria:**

**Given** the `CredentialBanner` widget is implemented
**When** `lib/widgets/credential_banner.dart` is reviewed
**Then** it extends `MaterialBanner` (per figma-code-contract §3) and renders with the semantic `warning` ThemeExtension amber — never `error` red
**And** it exposes four state variants: `session_expired | credentials_missing | network_unreachable | partial_send_pending`
**And** each variant renders a distinct Croatian message and single 48dp-min trailing action (e.g., "Ponovi prijavu", "Unesi ponovno", "Odustani", "Pošalji sve")

**Given** the banner is placed in the app shell
**When** the `GoRouter` shell route is configured
**Then** `CredentialBanner` sits above the routed content as a `ShellRoute` overlay
**And** its visibility is driven by watching `authNotifierProvider` — it appears for `Reauth`, `AuthFailure(credentialsInvalid)`, `AuthFailure(network)`
**And** it disappears (dismisses) when state returns to `Authenticated`

**Given** the banner surfaces for the first time
**When** it appears on screen
**Then** `SemanticsService.announce(message, TextDirection.ltr)` fires so TalkBack reads it as a live-region update
**And** the trailing action button is focusable and labeled via `Semantics(button: true, label: ...)`

**Given** the host taps the "Ponovi prijavu" action for `session_expired`
**When** the action fires
**Then** `AuthNotifier.reauthenticate()` is called (Story 2.4 handles the POST)
**And** a subtle inline spinner replaces the action button during the in-flight call
**And** on success, the banner auto-dismisses; on failure, the variant switches to `credentials_missing` with "Unesi ponovno" action routing to Story 2.8 flow

**Given** the banner is visible
**When** an `AdBanner` (Epic 10) would otherwise render
**Then** the `AdBanner` is hidden — the "warning > ads" stack-priority rule from UX spec §Modal and Overlay Patterns is enforced
**And** a widget test verifies that placing both in the same scaffold results in only the credential banner being visible

**Given** dark and light modes ship together
**When** golden tests run
**Then** each of the four banner states has a golden for dark and light + a parameterized font-scale golden at 1.0/1.5/2.0

---

### Story 2.8: Credentials-Missing Recovery Preserving Facility Context

As a host whose credentials were wiped from Keystore (OS reinstall, security policy, corrupted storage) but whose facility cache is intact,
I want to re-enter my credentials without losing my facility selection or unsent queue,
So that a partial state reset doesn't force me through the full onboarding flow or cost me in-progress work.

**Acceptance Criteria:**

**Given** `AuthNotifier` resolves to `AuthFailure(credentialsInvalid)` on cold start AND `FacilitiesTable` has at least one row cached
**When** the router redirect evaluates the state
**Then** the app routes to a dedicated `/credentials-missing` screen (NOT the Welcome flow)
**And** the screen shows "Podaci za prijavu nedostaju" headline, lists the cached facility names so the host sees context is preserved, and presents a single "Unesi ponovno" primary CTA

**Given** the host taps "Unesi ponovno"
**When** the action fires
**Then** the app routes to the login screen (Story 1.7 component) with the username field empty
**And** no destructive confirmation is required — this is recovery, not reset

**Given** the host completes login successfully
**When** `AuthNotifier` transitions to `Authenticated`
**Then** the cached `FacilitiesTable` rows remain untouched
**And** the `GuestEntriesTable` rows remain untouched
**And** the host lands on Home with the facility picker state from before the credential loss

**Given** the host chooses to bail out instead
**When** they tap system back from the credentials-missing screen
**Then** the app stays on the credentials-missing screen — they cannot reach Home without recovering (the router redirect enforces this)
**And** the only escape hatch is via the Settings → Replace-Active-OIB typed-confirmation flow (Epic 5) which wipes facilities + queue + cookies deliberately

---

### Story 2.9: Auth-State View in Settings

As a host who's unsure whether the app is ready for the door,
I want Settings to show my current eVisitor session state at a glance,
So that I can proactively verify everything's live before I need it, without waiting for a banner.

**Acceptance Criteria:**

**Given** the Settings screen skeleton from Story 1.9 is extended
**When** the auth-state section is implemented
**Then** a `ListTile` labeled "eVisitor sesija" displays a status chip reflecting the current `AuthState` variant
**And** the chip uses Croatian-localized labels: `Authenticated` → "Aktivna" (success), `Authenticating` / `Reauth` → "Ponovna prijava…" (warning), `Unauthenticated` → "Odjavljen" (neutral), `LockedOut` → "Zaključano — N min" with live countdown (warning), `AuthFailure` → "Greška — unesi podatke" (warning)
**And** the chip color reads from the `ThemeExtension<SemanticColors>` tokens — never hex

**Given** `AuthState` is `LockedOut`
**When** the host views the Settings chip
**Then** the countdown in minutes updates every second via a `StreamBuilder` or `Timer.periodic` without causing full-screen rebuilds

**Given** the host taps the auth-state row
**When** current state is `Authenticated`
**Then** a `SnackBar` shows "Sve u redu. Sesija je aktivna."
**And** tapping again in any other state routes into the appropriate recovery flow (Story 2.7's reauth or Story 2.8's credentials-missing)

**Given** the Settings screen watches `authNotifierProvider`
**When** a background auth-state change occurs (e.g., opportunistic check finishes)
**Then** the chip re-renders without the host leaving and re-entering the screen

---

## Epic 3: Facility Choice (Neutral App Pattern)

After first successful login the host sees their eVisitor facility list; at the start of every registration session they explicitly pick one facility (last-used is a visible hint, never a default), eliminating wrong-facility submissions.

### Story 3.1: Facility Model & Drift Table

As a developer,
I want a minimal Drift schema and Freezed model for facilities,
So that facility data persists across app kills and is the foundation for the picker and home-screen display without creating tables we don't yet need.

**Acceptance Criteria:**

**Given** the feature directory is scaffolded
**When** `lib/features/facility/facility.dart` is reviewed
**Then** it declares a Freezed `Facility` model with `String id`, `String oib`, `String name`, `DateTime? lastUsedAt`
**And** `facility.g.dart` and `facility.freezed.dart` are committed

**Given** the Drift database is initialized
**When** `lib/features/queue/app_database.dart` is reviewed
**Then** it declares `AppDatabase` with exactly one table so far: `FacilitiesTable` (columns: `id` TEXT PRIMARY KEY, `oib` TEXT NOT NULL, `name` TEXT NOT NULL, `lastUsedAt` DATETIME NULLABLE)
**And** `GuestEntriesTable` is NOT yet created — it will be added in Epic 5 per the JIT principle from Architecture §3
**And** `app_database.g.dart` is committed

**Given** a facility repository is required for separation of concerns
**When** `lib/features/facility/facility_repository.dart` is reviewed
**Then** it exposes `Future<List<Facility>> loadCached()`, `Future<void> upsertAll(List<Facility>)`, `Future<void> updateLastUsed(String id, DateTime at)`, `Future<void> removeById(String id)`
**And** no other file reads or writes `FacilitiesTable` directly (enforced by code review; direct Drift access outside the repository is an Architecture anti-pattern)

**Given** unit tests cover the repository
**When** `facility_repository_test.dart` runs
**Then** tests verify round-trip upsert + load, `updateLastUsed` updates only the target row, `removeById` is idempotent, and the table survives a simulated database re-open

**Given** no PII lives on the facility table
**When** a developer reviews the schema
**Then** no column stores a guest name, passport number, or other sensitive field — facility data is metadata, not personal data, so no encryption is applied (per Architecture §3 data tier table)

---

### Story 3.2: Fetch & Cache Facilities on First Login

As a host who has just logged in,
I want the app to pull my list of eVisitor facilities and keep them available offline,
So that I can pick a facility even when my Wi-Fi drops and I never see an empty picker because of a network blip.

**Acceptance Criteria:**

**Given** `AuthNotifier` transitions to `Authenticated(facilitiesLoaded: false)`
**When** `FacilityNotifier` rebuilds
**Then** it calls `EvisitorApiClient.fetchFacilities()` (endpoint path is a `const` that can be swapped post-Week-1 spike)
**And** on success it writes the result to `FacilityRepository.upsertAll` and emits `AsyncData(List<Facility>)`
**And** `AuthNotifier` state is updated to `Authenticated(facilitiesLoaded: true)` as a side effect of the notifier completing

**Given** the network fetch fails
**When** `FacilityNotifier` receives an error
**Then** it falls back to `FacilityRepository.loadCached()` and emits `AsyncData(cached)` if cached rows exist
**And** if no cached rows exist, emits `AsyncError(error)` with a Croatian-localized message — UI consumers show "Nema objekata. Provjeri internet." with retry CTA

**Given** the app is on cold start with an existing session
**When** `FacilityNotifier.build()` fires
**Then** it serves cached rows first (no network blocking) and enqueues a background refresh
**And** a refresh-result diff is emitted if the server list differs from the cache

**Given** the `EVISITOR_ENV=fake` adapter is in use
**When** `fetchFacilities()` is called
**Then** the Dio fake returns a canned list of 2 facilities (both under a single OIB) to exercise the multi-facility picker path
**And** a second canned fixture returns a list of 1 facility to exercise the auto-select path (Story 3.3 consumes this)

**Given** the classifier returns `sessionDead` during fetch
**When** the interceptor from Epic 2 Story 2.3 processes it
**Then** re-auth is triggered, `fetchFacilities()` is replayed with the fresh cookies, and no duplicate calls are made

---

### Story 3.3: FacilityPickerSheet Custom Widget

As a host starting a registration session,
I want a bottom-sheet facility picker that shows the last-used facility as a hint without pre-selecting it,
So that I make a deliberate choice every time and never accidentally submit to the wrong apartment.

**Acceptance Criteria:**

**Given** the `FacilityPickerSheet` widget is implemented
**When** `lib/widgets/facility_picker_sheet.dart` is reviewed
**Then** it exposes a static method `Future<Facility?> show(BuildContext, {required List<Facility> facilities, Facility? lastUsed})` that wraps `showModalBottomSheet`
**And** the sheet shape uses `Tokens.radius.sheet` (24dp) on the top corners
**And** the sheet renders a drag-handle indicator, a Croatian title (`Odaberi objekt`), a scrollable list of facility rows, and a footer with a close affordance
**And** the file has a top-of-file `why` doc comment explaining the Neutral App constraint that forced a custom wrapper

**Given** a `lastUsed` facility is supplied
**When** the sheet renders
**Then** the row matching `lastUsed.id` has a 1.5px primary-color outline AND a trailing "Zadnji" `Chip`
**And** the row is NOT auto-selected — the host must tap it explicitly to choose it
**And** any other row shows standard surface-container background without accent

**Given** the host taps outside the sheet OR swipes it down
**When** the gesture completes
**Then** `Future<Facility?>` resolves to `null` — tap-outside is cancel, never choice (Neutral App poka-yoke per UX spec §Modal and Overlay Patterns)
**And** no facility is written to `activeFacilityProvider`

**Given** exactly one facility is passed to the sheet
**When** the sheet is invoked via the `show` helper
**Then** the helper short-circuits: it auto-selects the single facility, calls `FacilityRepository.updateLastUsed(id, now)`, and returns it without actually rendering the sheet
**And** the caller sees no modal flash

**Given** 2+ facilities are passed
**When** the host taps a facility row
**Then** `updateLastUsed(id, now)` fires
**And** the `Future<Facility?>` resolves to the chosen facility
**And** the sheet dismisses with the standard Material motion

**Given** states `loaded_1_auto | loaded_2_plus | loading | error | empty`
**When** golden tests run
**Then** each state has a golden for dark and light modes
**And** `loading` renders skeleton rows (the only place skeletons are used per UX spec §Loading States)
**And** `empty` renders "Nema objekata. Provjeri eVisitor Postavke." with an external-link affordance
**And** `error` renders a retry CTA that re-invokes `FacilityNotifier.refresh()`

**Given** rows must be accessible
**When** TalkBack explores the sheet
**Then** each row is a 48dp tap target with a `Semantics` label combining facility name + "Zadnji" marker when applicable
**And** the sheet has `modal: true` focus management (focus does not escape)

---

### Story 3.4: Explicit Per-Session Facility Choice (Neutral App Enforcement)

As a host with multiple facilities,
I want the app to require me to explicitly pick a facility at the start of every registration session,
So that I never catch myself submitting guests to the wrong apartment because the "last used" one stuck around.

**Acceptance Criteria:**

**Given** the session-scoped state is implemented
**When** `lib/app/providers.dart` is reviewed
**Then** it declares `final activeFacilityProvider = StateProvider<Facility?>((ref) => null);`
**And** the provider is auto-disposed so a new app session always starts with `null`
**And** no persistence layer (Drift, Keystore, SharedPreferences) retains the active facility across app kills — a new process means a new choice

**Given** the host is on the Home screen with `activeFacilityProvider == null`
**When** they tap the primary "Skeniraj gosta" CTA
**Then** the tap does NOT open the camera
**And** `FacilityPickerSheet.show(...)` is invoked with the facility list and `lastUsed` derived from `FacilityRepository.loadCached()`'s most-recent `lastUsedAt`
**And** the sheet title is "Odaberi objekt za ovu sesiju" (different from a manual picker-open from the Home chip, which uses "Promijeni objekt")

**Given** the host picks a facility from the sheet
**When** `Future<Facility?>` resolves non-null
**Then** `ref.read(activeFacilityProvider.notifier).state = selected`
**And** the Home screen rebuilds showing the facility chip populated (Story 3.5)
**And** the next "Skeniraj gosta" tap opens the camera directly without re-prompting

**Given** the host dismisses the sheet without choosing
**When** the tap-outside / swipe-down cancel occurs
**Then** `activeFacilityProvider` remains `null`
**And** the Home scan CTA remains locked behind the picker

**Given** the host explicitly changes facility mid-session (tapping the Home chip, Story 3.5)
**When** the picker returns a different facility
**Then** `activeFacilityProvider` is updated
**And** the unsent queue for the previous facility remains intact in Drift (Epic 5 — queues are facility-scoped) — the old queue is simply not visible until the host re-selects that facility

**Given** a widget test covers the Neutral App invariant
**When** the test simulates multi-session scenarios
**Then** it asserts that after an app kill-and-restart the `activeFacilityProvider` is `null` regardless of prior `lastUsedAt`
**And** it asserts that a first-tap-Scan-without-facility path always renders the picker

---

### Story 3.5: Facility Chip on Home AppBar

As a host,
I want to see which facility my scans will be registered to at all times on Home,
So that wrong-facility anxiety is eliminated and I can tap the chip to switch if I've moved to a different property.

**Acceptance Criteria:**

**Given** the Home screen is being assembled (skeleton only for this epic; full states arrive in Epic 5)
**When** the Home `AppBar` is reviewed
**Then** it displays a facility chip on the leading side showing the active facility name in `titleMedium`
**And** when `activeFacilityProvider == null`, the chip shows a placeholder "Odaberi objekt" with an outline style instead of filled
**And** when `activeFacilityProvider != null`, the chip shows the facility name in filled `primaryContainer` color with a trailing caret indicating it's tappable

**Given** the host taps the chip
**When** the chip tap fires
**Then** `FacilityPickerSheet.show(...)` is invoked with sheet title "Promijeni objekt"
**And** the currently-active facility is rendered in the list but NOT highlighted as "Zadnji" (that chip is reserved for `lastUsedAt`-based hint from `FacilityRepository`)
**And** on selection, `activeFacilityProvider` updates and the chip re-renders

**Given** a single-facility account completes first login (Story 3.2 auto-selected it)
**When** the host lands on Home
**Then** the chip is already populated with the single facility name
**And** tapping the chip still opens the picker (even with one row — it's a valid place to confirm) but a single-facility user rarely does

**Given** the chip must be accessible
**When** TalkBack reads the AppBar
**Then** the chip is announced as "Objekt: {name}, dodirni za promjenu" (or "Objekt: nije odabran, dodirni za odabir" when null)
**And** the tap target is ≥48×48dp

**Given** `authNotifierProvider` is in `Reauth` or `AuthFailure(credentialsInvalid)`
**When** the Home screen renders
**Then** the chip stays visible (it's metadata, not auth-dependent) but the scan CTA is disabled per Epic 2 Story 2.7's CredentialBanner overlay

---

### Story 3.6: Explicit Facility List Refresh

As a host who just added a new facility in eVisitor,
I want to refresh my facility list from Settings without having to log out and back in,
So that new apartments appear in the picker the same day I register them with HTZ.

**Acceptance Criteria:**

**Given** the Settings screen has a refresh action
**When** `lib/features/settings/settings_screen.dart` is extended
**Then** a `ListTile` labeled "Osvježi popis objekata" with a refresh icon is visible
**And** the row is disabled while `FacilityNotifier` is already refreshing (to prevent double-dispatch)

**Given** the host taps the refresh action
**When** `FacilityNotifier.refresh()` is called
**Then** it calls `EvisitorApiClient.fetchFacilities()` with no re-login
**And** no cookies, credentials, or auth state are modified
**And** a spinner appears on the tapped row; SnackBar on completion

**Given** the refresh succeeds with a list diff
**When** the repository reconciles against the cache
**Then** new facilities are inserted via `upsertAll`
**And** renamed facilities (same `id`, different `name`) are updated in place
**And** removed facilities (cached but not in fresh response) are deleted via `removeById` ONLY IF no `GuestEntriesTable` rows (from Epic 5) reference them — otherwise they are soft-kept with a `(uklonjen)` suffix until the queue clears
**And** a Croatian SnackBar summarizes the diff: "Dodano N, ažurirano M, uklonjeno K."

**Given** the refresh fails with a `network` classifier result
**When** the failure is processed
**Then** the cached list remains untouched
**And** a Croatian SnackBar "Osvježavanje nije uspjelo — provjeri internet." is shown
**And** no auth state change occurs

**Given** the refresh fails with a `sessionDead` classifier result
**When** the interceptor from Epic 2 Story 2.3 processes it
**Then** re-auth is triggered automatically
**And** `refresh()` is replayed with fresh cookies after re-auth completes
**And** the host sees the final result (success SnackBar or error) without realizing re-auth happened — the whole flow is transparent

**Given** `activeFacilityProvider` holds a facility whose ID is no longer in the fresh server list
**When** the refresh completes
**Then** `activeFacilityProvider` is set to `null`
**And** the Home chip reverts to the "Odaberi objekt" placeholder
**And** a Croatian SnackBar "Objekt '{oldName}' više ne postoji — odaberi drugi." informs the host

---

## Epic 4: Confident Capture Pipeline (MRZ → Static-Tap → Manual)

Host holds passport in front of camera; auto-shutter fires within 1.5s on valid MRZ + sanity; worn docs and non-EU IDs fall back to a 3-second static-tap and then to a fully functional manual-entry form. Expired documents, nonsensical birth years, and invalid ISO country codes are inline-rejected in Croatian before anything reaches the queue.

### Story 4.1: MRZ Parser & Semantic Sanity Layer (Pure Dart)

As a developer,
I want a pure-Dart MRZ parser and a semantic sanity validator that can be tested in isolation without a camera, platform channels, or any Flutter dependency,
So that the most error-prone part of the capture pipeline is provably correct before it meets the camera stream.

**Acceptance Criteria:**

**Given** the MRZ parser is implemented
**When** `lib/features/capture/mrz_parser.dart` is reviewed
**Then** it exposes a pure function `MrzParseResult parse(String rawText)` where `MrzParseResult` is a sealed class with variants `MrzParseSuccess(GuestFields)`, `MrzChecksumFailure(zone)`, `MrzZoneNotFound`, `MrzUnrecognizedFormat`
**And** `GuestFields` is a Freezed model with `String documentNumber`, `String firstName`, `String lastName`, `DateTime dateOfBirth`, `String nationality` (ISO 3166 alpha-3), `String sex`, `DateTime documentExpiry`, `String? personalNumber`, `String documentType` (one of `TD1 | TD2 | TD3`)
**And** `GuestFields.toString()` returns `'[REDACTED type=GuestFields]'` per the PII discipline rule from Architecture §4
**And** the parser file has zero Flutter imports (pure Dart only)

**Given** the parser is called with a valid TD3 passport MRZ (2 lines × 44 chars)
**When** the checksums pass
**Then** the function returns `MrzParseSuccess` with all fields correctly extracted
**And** dates are decoded as `DateTime` in UTC (ISO `YYMMDD` with century resolution: YY ≥ 80 → 19YY, YY < 80 → 20YY, overridable by `documentExpiry > now` rule)

**Given** the parser is called with a valid TD2 ID-card MRZ (2 lines × 36 chars)
**When** the checksums pass
**Then** the function returns `MrzParseSuccess` with the same `GuestFields` shape
**And** `documentType == 'TD2'`

**Given** the parser is called with a valid TD1 ID-card MRZ (3 lines × 30 chars)
**When** the checksums pass
**Then** the function returns `MrzParseSuccess` with the same `GuestFields` shape
**And** `documentType == 'TD1'`

**Given** the parser is called with any MRZ whose composite or line checksum fails
**When** the checksum mismatch is detected
**Then** the function returns `MrzChecksumFailure(zone: ...)`
**And** no partial `GuestFields` is leaked

**Given** the parser is called with text that does not match any MRZ format
**When** zone detection fails
**Then** the function returns `MrzZoneNotFound`

**Given** the semantic sanity layer is implemented
**When** `lib/features/capture/semantic_sanity_layer.dart` is reviewed
**Then** it exposes a pure function `SanityResult check(GuestFields fields, {required DateTime now})` where `SanityResult` is a sealed class with `SanityOk` or `SanityRejected(SanityReason reason, String? detail)`
**And** `SanityReason` is an enum: `documentExpired | unrealisticBirthYear | invalidCountryCode | implausibleDate | implausibleAge`
**And** `documentExpired` is raised when `fields.documentExpiry < now`
**And** `unrealisticBirthYear` is raised when birth year is outside `[1900, now.year]`
**And** `invalidCountryCode` is raised when `fields.nationality` is not in the ISO 3166-1 alpha-3 set (bundled as a `const Set<String>` in a `country_codes.dart` file)
**And** `implausibleDate` is raised if any date (DoB, expiry) fails `DateTime` construction (e.g., Feb 30)
**And** `implausibleAge` is raised if age at `now` is > 120 years

**Given** fixtures of real-world MRZs
**When** `mrz_parser_test.dart` and `semantic_sanity_layer_test.dart` run
**Then** there is at least one fixture per document type (TD1, TD2, TD3)
**And** there is at least one fixture for each checksum-failure path
**And** there is at least one fixture per `SanityReason` variant
**And** Croatian passport, German ID card, US passport, and non-Latin name (Cyrillic transliteration) fixtures are all covered

---

### Story 4.2: Camera + ML Kit Stream Service

As a host,
I want the app to detect my guest's passport MRZ automatically while I hold it in front of the camera,
So that I don't have to tap a shutter — the scan happens the moment a valid code is recognized.

**Acceptance Criteria:**

**Given** the capture service is implemented
**When** `lib/features/capture/mrz_capture_service.dart` is reviewed
**Then** it wraps the `camera` plugin to open a rear-camera preview in portrait orientation
**And** it starts the image stream with a throttled rate (~5 fps, not the native 30 fps) to manage thermal/battery load
**And** each streamed frame is passed to `google_mlkit_text_recognition` on-device (cloud processing forbidden)
**And** the recognized text is handed to `MrzParser.parse` followed by `SemanticSanityLayer.check` in sequence

**Given** a parsed MRZ passes both parser and sanity checks
**When** `MrzCaptureService` emits a success event
**Then** `HapticFeedback.mediumImpact()` fires BEFORE any stream emission to downstream listeners — per UX spec "if the host feels the haptic, the guest is saved"
**And** the camera stream is paused until the consumer acknowledges the success
**And** the success event carries the validated `GuestFields` (not raw text)

**Given** the service sees a checksum failure or zone-not-found
**When** the parser returns `MrzChecksumFailure | MrzZoneNotFound | MrzUnrecognizedFormat`
**Then** no haptic fires, no event is emitted, and the stream continues — the host's reposition is silent retry (per UX spec §Experience Mechanics error table)

**Given** sanity rejects a parsed MRZ (e.g., document expired)
**When** `SemanticSanityLayer.check` returns `SanityRejected`
**Then** `HapticFeedback.heavyImpact()` fires (attention signal)
**And** the service emits a `CaptureResult.sanityRejected(reason, detail)` event
**And** the camera stream is paused until acknowledged

**Given** NFR-P1 requires auto-shutter within 1.5s p95 on a well-lit document
**When** the integration test runs against a canned synthetic MRZ text stream emitted by the Dio fake (not actual camera hardware)
**Then** the service emits success within 1.5 simulated seconds for the happy path
**And** the throttled frame rate does not starve the detection loop under single-CPU stress

**Given** the service must release camera resources cleanly
**When** the consumer disposes the service
**Then** the image stream is stopped, the `CameraController` is disposed, `SystemChrome.setPreferredOrientations(DeviceOrientation.values)` restores default orientation (for Scan screen hand-off — Story 4.3 owns the actual preview widget's lifecycle), and ML Kit recognizer is closed
**And** a second `dispose()` call is a no-op — no double-dispose crashes

**Given** the host denied camera permission in Story 1.6
**When** `MrzCaptureService.start()` is called
**Then** it returns a `CameraUnavailable` result immediately without attempting to open the camera
**And** the consumer routes to manual entry (Story 4.5's fallback wiring)

---

### Story 4.3: MRZViewfinder Custom Widget

As a host,
I want a visual scan frame that tells me where to hold the passport and what the app is doing,
So that the scan experience feels deliberate and I know whether to reposition the document.

**Acceptance Criteria:**

**Given** the widget is implemented
**When** `lib/widgets/mrz_viewfinder.dart` is reviewed
**Then** it is a full-screen `Stack` layered over a `CameraPreview`
**And** the overlay contains: a centered 200×130 rounded-rectangle reticle with primary-color corner anchors, a dimmed overlay outside the reticle (60% opacity surface), a close icon top-left (48dp tap target, Croatian tooltip "Zatvori"), a `ScanCounterChip` top-right showing "N gostiju u redu" (reads the current unsent queue count — wired in Epic 5 via `queueNotifierProvider`; stubbed to "0" for now), a Croatian hint bottom "Približi MRZ kod u okvir"
**And** the file has a top-of-file `why` doc comment explaining the wrap over `CameraPreview`

**Given** the widget receives a `MrzViewfinderState` prop
**When** state is `scanning`
**Then** the reticle corner anchors animate a subtle pulse
**And** the hint reads the default "Približi MRZ kod u okvir"

**Given** state is `mrz_detected_validating`
**When** rendered
**Then** the reticle fills with a subtle primary-container wash for <300ms
**And** the hint reads "Provjeravam…"

**Given** state is `static_tap_available`
**When** rendered
**Then** a "Dodirni za snimku" button surfaces in the bottom action zone above the hint, 56dp min-height, primary-filled
**And** a secondary "Ručni unos" text button sits beside it

**Given** state is `capture_confirmed`
**When** rendered
**Then** the viewfinder hands off to `CaptureConfirmation` overlay (Story 4.4) — the viewfinder's own render continues behind (no teardown) so the camera stays warm for the next guest

**Given** accessibility requirements
**When** TalkBack explores the screen
**Then** the `CameraPreview` is wrapped in `ExcludeSemantics` (visual-only surface, meaningless to screen readers)
**And** the close icon has a `tooltip` and `Semantics(button: true, label: 'Zatvori skeniranje')`
**And** the `ScanCounterChip` has a labeled semantics describing the current count
**And** `static_tap_available` buttons each have Semantics labels

**Given** orientation must lock during scan
**When** the Scan screen (Story 4.5) mounts the viewfinder
**Then** `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` is called on enter
**And** `SystemChrome.setPreferredOrientations(DeviceOrientation.values)` is restored on dispose — tested via widget-lifecycle test

**Given** golden tests cover every state × dark/light
**When** `mrz_viewfinder_test.dart` runs
**Then** goldens exist for `scanning`, `mrz_detected_validating`, `static_tap_available` with a camera placeholder in dark and light modes
**And** a parameterized font-scale golden at 1.0/1.5/2.0 verifies no layout break on the hint text

---

### Story 4.4: CaptureConfirmation Overlay Widget

As a host who just scanned a guest,
I want an instantly-visible confirmation that the guest was saved,
So that I don't wonder "did it actually take?" and I can move on to the next passport without re-checking.

**Acceptance Criteria:**

**Given** the widget is implemented
**When** `lib/widgets/capture_confirmation.dart` is reviewed
**Then** it renders a full-bleed surface-colored scaffold with a centered 72×72dp success circle (`SemanticColors.success`) containing a Material Symbols rounded check
**And** the title `displayMedium` reads "Gost {N} dodan" (Croatian singular, dynamic count)
**And** the subtitle `bodyLarge onSurfaceVariant` reads "Skeniram sljedećeg…"
**And** the file has a top-of-file `why` doc comment explaining the emotional-payoff constraint and the haptic-before-render rule

**Given** the overlay is triggered by a successful capture
**When** rendered
**Then** it fades in over 200ms via `AnimatedOpacity`
**And** holds at full opacity for 400ms
**And** fades out over 200ms returning to the underlying viewfinder
**And** total elapsed time is ≤800ms before the camera is ready for the next scan
**And** the haptic from Story 4.2 has already fired BEFORE this widget first paints — asserted by a widget test that orders the calls via `WidgetsBinding.instance.scheduleFrame` mocks

**Given** TalkBack is active
**When** the overlay appears
**Then** `SemanticsService.announce('Gost $N dodan', TextDirection.ltr)` fires as a live-region update
**And** the visual is marked `Semantics(liveRegion: true)`

**Given** the host taps the overlay before the timed auto-dismiss
**When** an anywhere-tap is detected
**Then** the overlay can be early-dismissed (returns to scanning) — per UX spec §Experience Mechanics Feedback `dismissed_early` state

**Given** the count parameter carries no PII
**When** the widget is reviewed
**Then** no guest name, no document number, no field from `GuestFields` is ever rendered by this widget — only the integer count
**And** a widget test verifies `find.text(documentNumber)` returns zero matches when the widget is rendered with a guest entry having `documentNumber: 'HR1234567'`

**Given** the widget renders in both themes
**When** golden tests run
**Then** dark and light goldens exist
**And** the success circle uses `SemanticColors.success` (not hex), verified by a test reading `Theme.of(context).extension<SemanticColors>()!.success`

---

### Story 4.5: Scan Screen Assembly with 3-Second Static-Tap Fallback

As a host whose passport MRZ is worn and won't auto-detect,
I want the app to surface a "tap to capture" button after 3 seconds of trying,
So that I can take a still photo instead of giving up and retyping everything.

**Acceptance Criteria:**

**Given** the scan screen is assembled
**When** `lib/features/capture/scan_screen.dart` is reviewed
**Then** it is a `ConsumerStatefulWidget` that mounts `MRZViewfinder` + `CaptureConfirmation` + wires `MrzCaptureService`
**And** it is routed at `/scan` via `go_router` with `fullscreenDialog: true`
**And** it reads `activeFacilityProvider` from Epic 3 — if null, it immediately routes back to Home with a toast "Odaberi objekt prije skeniranja"

**Given** the camera is ready and the viewfinder renders in `scanning` state
**When** a 3-second timer expires with no successful parse
**Then** the viewfinder state transitions to `static_tap_available`
**And** a "Ručni unos" text-button rollup is also rendered alongside the static-tap button
**And** NFR-P2 is verified: the timer fires at exactly 3s ±100ms tolerance (widget test with fake async)

**Given** the host taps the static-tap button
**When** the action fires
**Then** `MrzCaptureService.takeStill()` captures a single frame
**And** ML Kit runs on that one frame
**And** parser + sanity run as per Story 4.2
**And** on success → `CaptureConfirmation` overlay → queue commit (Epic 5) → viewfinder returns to `scanning` for the next guest
**And** on parse failure → the viewfinder returns to `static_tap_available` without any timer reset (host can try again or tap manual entry)

**Given** the host taps "Ručni unos"
**When** the action fires
**Then** the scan screen pushes to `/guest-form` (Story 4.6 manual entry)
**And** the camera is paused (not disposed) so return-to-scan resumes quickly
**And** a manual-entry commit hands control back to the scan screen for the next guest

**Given** the host scans 4 consecutive guests successfully
**When** each capture completes
**Then** the camera stays open and warm across all 4 — no re-open delay between guests
**And** the `ScanCounterChip` increments after each queue commit (wired via Epic 5's `queueNotifierProvider`)
**And** the 3-second timer resets on each new guest-scan attempt

**Given** the host dismisses scan with the close button
**When** the action fires
**Then** `MrzCaptureService.dispose()` is called
**And** orientation is restored via `SystemChrome`
**And** the host returns to Home with the updated queue count visible

**Given** `capturePreference == manualOnly` (from Story 1.6's camera-denied path)
**When** the host taps "Skeniraj gosta" on Home
**Then** the scan screen is BYPASSED and the app routes directly to `/guest-form`
**And** no camera open is attempted

---

### Story 4.6: Manual Entry Form (First-Class Path)

As a host whose camera permission is denied, whose guest has a non-EU ID the parser can't read, or who prefers typing,
I want a Croatian-labeled form that accepts all required guest fields with the same sanity validation as MRZ capture,
So that manual entry feels like a graceful path — not a degraded fallback.

**Acceptance Criteria:**

**Given** the form screen is implemented
**When** `lib/features/guest/guest_form_screen.dart` empty state is reviewed
**Then** it renders Croatian-labeled `TextField`s for: document number (text, allowlist validation), first name, last name, date of birth (DatePicker), sex (Radio), nationality (autocomplete from ISO 3166 alpha-3 with Croatian country names), document type (dropdown: passport / ID card / other), document expiry (DatePicker), optional personal number
**And** form layout follows UX spec §Form Patterns: label above 44dp input, 1px `outlineVariant` border, 10dp radius, 1.5px primary on focus, 1.5px error on validate fail, 10dp spacing between fields
**And** all strings go through `AppLocalizations`

**Given** the host edits a field and blurs
**When** blur fires
**Then** client-side sanity runs on that field only — expired doc triggers errorText, unrealistic birth year triggers errorText, invalid ISO code triggers errorText
**And** the invalid value stays in the field (not cleared) so the host can correct it
**And** the submit button remains disabled until the entire form is sanity-valid

**Given** the host taps the primary "Potvrdi" submit
**When** submit fires with all fields valid
**Then** `SemanticSanityLayer.check(fields)` runs one more time as a guard
**And** on success → `QueueNotifier.enqueue(guestEntry)` is called (Epic 5 wiring)
**And** the haptic from Story 4.2 fires via `HapticFeedback.mediumImpact()` BEFORE the queue commit UI settles (same omotenashi contract as live capture)
**And** on sanity failure (rare — already client-side-validated) → Croatian `UserMessage`-style inline rejection per Story 4.7, no queue commit

**Given** the form is reached via the camera-denied path
**When** the host enters the form
**Then** the top AppBar includes a "Omogući kameru" action that re-requests camera permission
**And** re-granting redirects back to the scan screen on the next "Skeniraj gosta" tap

**Given** accessibility requirements
**When** TalkBack reads the form
**Then** every field has a Semantics label, every error message is announced as a live region, focus jumps to the first invalid field on submit
**And** font scaling up to 200% does not break the layout (parameterized widget test)

**Given** the host taps the system back gesture mid-form
**When** the back is triggered
**Then** a Croatian confirmation SnackBar "Podaci neće biti spremljeni" prevents accidental data loss only if the form has uncommitted edits
**And** if the form is empty, back is immediate

**Given** the form screen must be a single file handling both empty and pre-filled states per figma-code-contract §4 row 12–13
**When** the widget is reviewed
**Then** the same file handles Story 4.8 pre-filled-review state via a `GuestFormMode.create | .review | .edit` parameter
**And** tests cover all three modes

---

### Story 4.7: Inline Croatian Sanity Rejection

As a host scanning an expired passport or a document with a clearly-wrong field,
I want an immediate Croatian-language rejection that names the specific problem,
So that I know exactly what to ask the guest for and the queue never accepts trash.

**Acceptance Criteria:**

**Given** `MrzCaptureService` emits `CaptureResult.sanityRejected(reason, detail)`
**When** the scan screen receives it
**Then** an inline banner overlays the bottom third of the scan screen with:
- `SanityReason.documentExpired` → "Isteklo {date} — tražite valjani dokument."
- `SanityReason.unrealisticBirthYear` → "Nerealna godina rođenja — provjeri ili unesi ručno."
- `SanityReason.invalidCountryCode` → "Nepoznat kod države ISO 3166 — unesi ručno."
- `SanityReason.implausibleDate` → "Nemoguć datum — unesi ručno."
- `SanityReason.implausibleAge` → "Nerealna dob — provjeri ili unesi ručno."

**And** the banner uses the `warning` amber ThemeExtension (not error red — UX spec "attention, not panic")
**And** it surfaces for 2.5s auto-dismiss OR dismisses immediately on next scan attempt

**Given** the banner is visible
**When** the host repositions the passport
**Then** the camera stream continues, the parser/sanity state is reset, and the viewfinder returns to `scanning`
**And** no queue commit has occurred and no guest entry exists

**Given** TalkBack is active
**When** the rejection banner appears
**Then** `SemanticsService.announce` fires with the Croatian rejection text
**And** `HapticFeedback.heavyImpact()` fires as a redundant signal (already handled by Story 4.2 for sanity rejection)

**Given** the host instead taps "Ručni unos" from the rejection state
**When** the action fires
**Then** the scan screen pushes `/guest-form` with as much pre-filled context as the parser extracted (Story 4.8's `review` mode) — preserving the host's effort
**And** the sanity-rejected field is marked red with the same Croatian reason so the host corrects it inline

**Given** the same manual-entry form rejects on submit (rare — client-side-validated)
**When** sanity returns `SanityRejected`
**Then** the form shows the same Croatian rejection text as inline `errorText` beneath the offending field
**And** the invalid value stays in the field

---

### Story 4.8: Review & Correct Captured Data Before Commit

As a host who wants to verify a just-scanned passport (especially when the parser had to work hard),
I want an optional review screen before the guest is committed to the queue,
So that I can catch OCR drift on edge cases without blocking the happy path.

**Acceptance Criteria:**

**Given** auto-shutter captured a guest on the happy path
**When** the capture-to-commit flow runs
**Then** the review step is SKIPPED by default — effortlessness wins and `CaptureConfirmation` overlay immediately follows
**And** no regression in NFR-P3 (300ms commit + haptic)

**Given** the host wants to review a captured guest before commit
**When** they long-press the `CaptureConfirmation` overlay OR the overlay exposes a "Uredi prije spremanja" affordance for a configurable 800ms window before auto-dismiss
**Then** the scan flow pushes `/guest-form` in `GuestFormMode.review` with all fields pre-filled from the parsed `GuestFields`
**And** the host can edit any field; blur-validation runs per Story 4.6
**And** "Potvrdi" commits to the queue with the (possibly edited) values
**And** "Odustani" returns to the scan screen with NO queue commit — the scan is discarded

**Given** a manual-entry host wants to review before commit
**When** they tap "Potvrdi" on Story 4.6's form
**Then** behavior depends on a single `const bool kAlwaysReviewManualEntry` feature flag in `FeatureFlags` — default `false` (straight commit per Story 4.6)
**And** if `true`, the form transitions to a read-only summary state before actual commit
**And** the flag is documented in `feature_flags.dart`

**Given** review mode shares a widget with manual entry
**When** `guest_form_screen.dart` is reviewed
**Then** `GuestFormMode.create | .review | .edit` determines the initial state (empty / pre-filled from capture / pre-filled from failed submission in Epic 6)
**And** the AppBar title changes per mode: "Novi gost" / "Pregled prije spremanja" / "Uredi gosta"
**And** the single file contains <400 lines total

**Given** NFR-P4 (sanity validation ≤50ms p95)
**When** the review-mode validate-on-blur fires
**Then** the end-to-end latency from keystroke-blur to errorText render is measured and the test asserts ≤50ms on the sanity call alone

---

### Story 4.9: May-2026 Mandate Field Behind Feature Flag

As a developer,
I want the May-2026 apartment registration-number field scaffolded behind a feature flag but not yet surfaced,
So that once Week-1 spike confirms the exact payload shape and server-side enforcement begins, enabling the feature is a single-line change without migration risk.

**Acceptance Criteria:**

**Given** the feature flag is declared
**When** `lib/core/feature_flags/feature_flags.dart` is reviewed
**Then** it declares `class FeatureFlags { static const bool mayMandateField = false; static const bool kAlwaysReviewManualEntry = false; }`
**And** there is zero remote-config or runtime toggle — the flag is compile-time
**And** a commit-message comment references the PRD FR26 and Architecture §spike-gated-decisions

**Given** `FeatureFlags.mayMandateField == false` (v1.0 default)
**When** the capture flow runs
**Then** no registration-number field is rendered in `guest_form_screen.dart`
**And** no registration-number parsing is attempted on MRZ (it is not on passports)
**And** `GuestEntry` model has the field declared as `String? apartmentRegistrationNumber` (nullable) to avoid a breaking schema change when flipped

**Given** `FeatureFlags.mayMandateField == true` (post-spike, post-regulatory-enforcement)
**When** the capture flow runs
**Then** the `guest_form_screen.dart` renders an additional mandatory field "Registracijski broj apartmana"
**And** the field is sanity-validated (not empty, matches the format HTZ publishes — spike outcome)
**And** the manual-entry submit button stays disabled until the field is populated and sanity-valid
**And** the MRZ auto-shutter path surfaces a mandatory inline post-capture prompt for the field before queue commit

**Given** `ImportTouristsBuilder` (Epic 6 Story 6.2) reads this flag
**When** the flag is true
**Then** the builder includes the `apartmentRegistrationNumber` XML element in the payload
**When** the flag is false
**Then** the builder omits the element entirely (backward compatibility with pre-mandate eVisitor)

**Given** unit tests cover both flag states
**When** `feature_flags_test.dart` runs
**Then** tests verify the form, parser, queue entry shape, and builder behavior under both flag values
**And** a README note documents how to flip the flag and ship a point release

---

## Epic 5: Zero-Loss Encrypted Queue

Every scanned guest is persisted to encrypted local storage with a client UUID, synchronously, before the success haptic fires. The queue survives app kills, device reboots, and offline periods indefinitely. Successful submissions are held 3 days as a soft-undo buffer then auto-purged. Host can delete individual entries or wipe all data via a typed-confirmation poka-yoke.

### Story 5.1: GuestEntry Model, QueueEntryState Enum & Drift Table

As a developer,
I want a single Drift table with an AES-GCM column-level encryption `TypeConverter` and a tight state enum,
So that every queued guest is encrypted at rest by construction and the four legitimate states are exhaustive-switchable.

**Acceptance Criteria:**

**Given** the queue-entry state machine is scoped
**When** `lib/features/queue/queue_entry_state.dart` is reviewed
**Then** it declares `enum QueueEntryState { unsent, in_flight, submitted, failed }`
**And** consumers `switch` on this enum with compile errors on unhandled variants

**Given** the `GuestEntry` model is implemented
**When** `lib/features/queue/guest_entry.dart` is reviewed
**Then** it declares a Freezed immutable model with `String id` (client UUIDv4 generated at scan time), `String facilityId`, `GuestFields fields` (from Epic 4 Story 4.1), `QueueEntryState state`, `DateTime clientCreatedAt` (UTC), `DateTime? submittedAt`, `DateTime? purgeAfter`, `String? lastFailureReason`
**And** `guest_entry.freezed.dart` and `guest_entry.g.dart` are committed
**And** `GuestEntry.toString()` returns `'[REDACTED type=GuestEntry id=$id]'` and equality uses client UUID only (never PII fields) per Architecture §4 PII class discipline

**Given** the Drift table is implemented
**When** `lib/features/queue/guest_entries_table.dart` is reviewed
**Then** it declares `class GuestEntriesTable extends Table` with columns: `id TEXT PRIMARY KEY`, `facilityId TEXT NOT NULL REFERENCES FacilitiesTable(id)`, `encryptedPayload TEXT NOT NULL` (AES-GCM ciphertext of the serialized `GuestFields`), `state TEXT NOT NULL` (textEnum<QueueEntryState>), `clientCreatedAt DATETIME NOT NULL`, `submittedAt DATETIME NULLABLE`, `purgeAfter DATETIME NULLABLE`, `lastFailureReason TEXT NULLABLE`
**And** an index is declared on `purgeAfter` for fast auto-purge scans
**And** a secondary index on `(facilityId, state)` supports per-facility queue reads
**And** `GuestEntriesTable` is registered in `AppDatabase` alongside `FacilitiesTable` from Epic 3 Story 3.1
**And** `app_database.g.dart` is re-run and committed with the schema version bumped

**Given** AES-GCM encryption is applied at the column level
**When** the `TypeConverter<GuestFields, String>` is reviewed
**Then** it uses `aes_gcm_helper.dart` from Epic 1 Story 1.3 with the key loaded once from `SecurityService` and held in memory
**And** `toSql(fields)` serializes `GuestFields` to JSON and encrypts to base64 ciphertext
**And** `fromSql(ciphertext)` decrypts and deserializes back to `GuestFields`
**And** a unit test verifies round-trip encrypt/decrypt for a realistic `GuestFields` fixture returns equal fields
**And** a second test verifies that tampering with the ciphertext (flipping one byte) causes decrypt to throw — AES-GCM integrity is live

**Given** the integration test harness exists from Epic 1
**When** `app_database_test.dart` runs
**Then** a round-trip test inserts a `GuestEntry`, kills the in-memory database, re-opens it, reads the row back, and asserts equality
**And** a test verifies that the `encryptedPayload` column contains ciphertext NOT the plaintext document number (search-in-blob returns zero matches for the original document number string)

---

### Story 5.2: QueueNotifier Single Write Chokepoint with Synchronous Commit

As a developer,
I want all queue state mutations routed through a single notifier whose writes block the caller until Drift has committed,
So that the "haptic fires only if the guest is saved" reliability promise is architecturally enforced and no widget reaches around the chokepoint.

**Acceptance Criteria:**

**Given** the queue notifier is implemented
**When** `lib/features/queue/queue_notifier.dart` is reviewed
**Then** it extends `AsyncNotifier<QueueSnapshot>` and is exposed via `queueNotifierProvider`
**And** the `build()` method reads all rows for `activeFacilityProvider.select((f) => f?.id)` and returns a `QueueSnapshot`
**And** watching `activeFacilityProvider` causes automatic rebuild when the host switches facility
**And** the notifier is watched by `HomeScreen`, `SendAllScreen` (Epic 6), and `YourDataScreen` (Epic 8)

**Given** the public method surface is exhaustive
**When** `QueueNotifier` is reviewed
**Then** it exposes `Future<void> enqueue(GuestFields fields)` (generates UUID + sets `state: unsent` + Drift insert + state refresh)
**And** `Future<void> updateFields(String id, GuestFields fields)` (for edit flow — re-encrypts payload; only permitted on `unsent | failed` entries; throws `Result.Err(InvalidStateError)` for `in_flight | submitted`)
**And** `Future<void> deleteById(String id)` (hard delete)
**And** `Future<void> markInFlight(String id)` (Epic 6 pre-submission)
**And** `Future<void> markSubmitted(String id, {required DateTime purgeAfter})` (Epic 6 post-submission; `purgeAfter = submittedAt + 3d`)
**And** `Future<void> markFailed(String id, {required String reason})` (Epic 6)
**And** `Future<void> runAutoPurge()` (Story 5.7)
**And** no other file in the codebase writes to `GuestEntriesTable` — enforced by code review and a CI grep rule flagging `db.guestEntries.insert|update|delete` outside `queue_notifier.dart`

**Given** `QueueSnapshot` is defined for UI consumers
**When** `lib/features/queue/queue_snapshot.dart` is reviewed
**Then** it is a Freezed model with `List<GuestEntryView> unsent`, `List<GuestEntryView> inFlight`, `List<GuestEntryView> submitted`, `List<GuestEntryView> failed`, `int totalCount`
**And** `GuestEntryView` is a view model carrying ONLY non-PII + masked fields: `id`, `maskedDocNumber` (e.g., "HR2184…"), `state`, `clientCreatedAt`, `purgeAfter`, `lastFailureReason`
**And** `GuestFields` is NOT exposed on `QueueSnapshot` — widgets that need to edit call a dedicated `Future<GuestFields> loadForEdit(String id)` method that returns the decrypted fields only to the caller

**Given** NFR-P3 requires synchronous commit before the success haptic
**When** `enqueue(GuestFields)` is called
**Then** the method awaits Drift's `into(guestEntries).insert(...)` — the returned Future does not complete until the transaction has been committed
**And** an integration test verifies that if the app is killed immediately after `enqueue` returns, the row is present on re-open
**And** widget-level timing asserts that `HapticFeedback.mediumImpact()` (from Epic 4 Story 4.2 capture service) is ordered AFTER `enqueue` resolves — test uses a Completer-based ordering harness

**Given** edge cases
**When** `enqueue` is called with a duplicate UUID (theoretically impossible but defensively handled)
**Then** the method returns `Result.Err(DuplicateUuidError)` without inserting
**And** `deleteById(nonexistent)` is a no-op (not an error — idempotent)
**And** `markInFlight(id)` throws if the entry's current state is not `unsent`
**And** `markSubmitted/markFailed` throw if current state is not `in_flight`

**Given** the anti-pattern is enforced
**When** any widget or non-queue notifier attempts `db.guestEntries.insertOne(...)` directly
**Then** the CI grep rule fails the build
**And** the Architecture Anti-Pattern Reference table lists this as a blocker

---

### Story 5.3: GuestStatusGlyph Custom Widget

As a host scanning the queue,
I want an unmistakable WhatsApp-style status glyph per guest row that reads the same in color AND shape,
So that I know at a glance which guests are queued, sending, accepted, or failed — even in bright sunlight or with deuteranopia.

**Acceptance Criteria:**

**Given** the widget is implemented
**When** `lib/widgets/guest_status_glyph.dart` is reviewed
**Then** it accepts a `GuestStatusGlyphState` enum (`queued | sending | sent | failed | in_flight_unresolved`) and a `GuestStatusGlyphSize` enum (`small` 24dp, `large` 56dp, `hero` 64dp)
**And** the file has a top-of-file `why` doc comment explaining the colorblind-safe redundant encoding and the single-source-of-truth role across queue rendering surfaces
**And** no hex colors appear — all colors read from `ColorScheme` or `ThemeExtension<SemanticColors>`

**Given** each state renders the contract from UX-DR7
**When** the widget is rendered for each state
**Then** `queued` renders a hollow circle (○) with `outline` stroke on transparent background
**And** `sending` renders an up-arrow (↑) with `onPrimaryContainer` stroke on `primaryContainer` fill
**And** `sent` renders a checkmark (✓) in a dark accessible foreground on `SemanticColors.success` fill
**And** `failed` renders a cross (✗) in a dark accessible foreground on `SemanticColors.error` fill (using standard Material 3 error, not warning)
**And** `in_flight_unresolved` renders an ellipsis (⋯) with `onSurfaceVariant` stroke on `surfaceContainer` fill

**Given** shape + color redundancy is a colorblind-safety requirement (UX-DR27)
**When** the widget is rendered
**Then** the state-differentiating glyph (circle / arrow / check / cross / ellipsis) is present regardless of color
**And** a deuteranopia/protanopia simulation widget test verifies visual distinction between all five states when color saturation is collapsed

**Given** TalkBack must announce state correctly
**When** `Semantics` is applied
**Then** the widget's semantics label is Croatian: `queued` → "U redu", `sending` → "Šaljem", `sent` → "Prihvaćeno", `failed` → "Neuspjelo", `in_flight_unresolved` → "Provjeravam"
**And** the glyph itself is non-interactive (`excludeSemantics: false`, `label` provided, but no tap handler)

**Given** the widget must be immutable and efficient
**When** consumers build many rows
**Then** the widget is declared `const` where state is known at compile time
**And** no `setState` is used internally

**Given** comprehensive golden coverage is required
**When** `guest_status_glyph_test.dart` runs
**Then** goldens exist for every combination of 5 states × 3 sizes × 2 themes (30 golden files)
**And** a parameterized font-scale golden at 1.0/1.5/2.0 is not needed (glyph is icon-only, not text)

---

### Story 5.4: QueueRow + QueueHero Custom Widgets

As a host looking at my unsent queue,
I want each guest row to show status + masked document number + a state-appropriate action, and a prominent hero showing the current queue count and system-confidence meta,
So that I can see the state of the world at arm's length without reading every row in detail.

**Acceptance Criteria:**

**Given** `QueueRow` is implemented per UX-DR8
**When** `lib/widgets/queue_row.dart` is reviewed
**Then** it accepts a `GuestEntryView` (view model from Story 5.2) and renders a `Card` with 12dp padding, 12dp radius (`Tokens.radius.card / 1.33` or a dedicated `radiusRow` token), `surfaceContainerHigh` background
**And** the leading slot contains `GuestStatusGlyph(size: small)` mapped from `GuestEntryView.state`
**And** the center shows primary text (Croatian document-type label + `maskedDocNumber` — e.g., "Putovnica HR2184…") and secondary meta (relative time "prije 3 min" or failure reason)
**And** no guest name appears anywhere — mask rule enforced by a widget test that inspects rendered text against a fixture's name fields and asserts zero matches

**Given** per-state behavior differs
**When** `QueueRow` is rendered for a `queued` entry
**Then** the trailing slot is empty (no affordance) but the row is tap-expandable for edit (Story 5.6)
**And** swipe-to-dismiss gesture is enabled on `queued` rows only

**Given** a `failed` entry
**When** rendered
**Then** the row has a 1px `error` border
**And** the primary text uses `error` color for the document-type label
**And** the trailing slot shows a "Uredi" `TextButton` action
**And** the failure reason meta is localized Croatian

**Given** an `in_flight_unresolved` entry
**When** rendered
**Then** the row has a `warning` amber border
**And** the secondary meta shows "Provjeravam…" with a small spinner inline

**Given** variants are available
**When** `QueueRow(variant: .review)` is used on Epic 6's Send All Results screen
**Then** the row renders taller with expanded detail (guest index number, explicit state label, expanded action row)
**And** `compact` is the default for Home

**Given** accessibility
**When** TalkBack explores a row
**Then** the row is a single compound semantics node reading state + masked identifier + time
**And** the tap target is ≥48dp
**And** the "Uredi" affordance is its own accessible button

**Given** `QueueHero` is implemented per UX-DR9
**When** `lib/widgets/queue_hero.dart` is reviewed
**Then** it is a card with `primaryContainer` fill, 14dp radius
**And** its left section shows a small-caps Croatian label ("Red čekanja") above a `displayMedium` weight-800 integer count
**And** its right section shows 2 lines of meta text (`onPrimaryContainer` at 85% opacity)

**Given** four state modes
**When** the hero renders per state
**Then** `empty_recent_success` shows count 0 with meta "Zadnja prijava: prije N min"
**And** `empty_no_recent` shows count 0 with meta "Skeniraj za prvog gosta"
**And** `non_empty` shows the actual count with meta "Dodirni Pošalji sve"
**And** `auth_dead` shows count with meta "Slanje blokirano" and the entire hero uses the `warning` ThemeExtension surface (only state where auth overrides the normal styling)

**Given** compound semantics
**When** TalkBack reads the hero
**Then** a single announcement combines label + count + meta ("Red čekanja: 4 gosta, Dodirni Pošalji sve")
**And** the text scales with system font scale without layout break up to 200%

**Given** golden coverage for both widgets
**When** their tests run
**Then** `queue_row_test.dart` has goldens for every state × variant × dark/light (5 states × 2 variants × 2 themes = 20 goldens)
**And** `queue_hero_test.dart` has goldens for all 4 modes × dark/light (8 goldens)

---

### Story 5.5: Home Screen Assembly (Empty + Non-Empty States)

As a host,
I want Home to show a clean empty state when I have nothing queued and a scannable queue list when I do,
So that I never hunt for the queue — it's right there the second I open the app.

**Acceptance Criteria:**

**Given** Home is assembled
**When** `lib/features/home/home_screen.dart` is reviewed
**Then** it is a `ConsumerWidget` watching `queueNotifierProvider` + `activeFacilityProvider` + `authNotifierProvider`
**And** it uses `LayoutBuilder` + `ConstrainedBox(maxWidth: 600)` for the content body width clamp (UX-DR28)
**And** the AppBar hosts the facility chip from Epic 3 Story 3.5 + a gear icon routing to Settings

**Given** `queueNotifierProvider` resolves to `AsyncData(QueueSnapshot(totalCount: 0))`
**When** Home renders the empty state
**Then** it shows `QueueHero` in `empty_recent_success` or `empty_no_recent` mode depending on last-submission metadata
**And** the primary CTA zone contains a single `FilledButton` "Skeniraj gosta" (56dp min-height) and a secondary `OutlinedButton` "Ručni unos" per UX-DR18
**And** no `QueueRow` list is rendered

**Given** `totalCount > 0`
**When** Home renders the non-empty state
**Then** `QueueHero` renders in `non_empty` mode with the live count
**And** a scrollable list of `QueueRow` instances renders under the hero, sorted: `failed` first, then `unsent`, then `submitted` (soft-undo), then `in_flight_unresolved`
**And** the primary CTA zone shows `FilledButton` "Pošalji sve" (primary) + a row of secondary actions: "Skeniraj" + "Ručni unos"

**Given** `authNotifierProvider` is in `Reauth | AuthFailure(credentialsInvalid)`
**When** Home renders
**Then** the `CredentialBanner` from Epic 2 Story 2.7 is visible via the ShellRoute overlay
**And** the `QueueHero` renders in `auth_dead` mode with "Slanje blokirano"
**And** the "Pošalji sve" CTA is disabled until auth is restored

**Given** the host is the Scan CTA tap
**When** `activeFacilityProvider == null`
**Then** the `FacilityPickerSheet` from Epic 3 Story 3.3 opens with title "Odaberi objekt za ovu sesiju" — Scan does NOT open directly
**And** after the host picks, the sheet dismisses and Scan proceeds

**Given** the host taps "Ručni unos"
**When** the tap fires
**Then** the app routes to `/guest-form` in `GuestFormMode.create` (Epic 4 Story 4.6)
**And** `activeFacilityProvider` is enforced the same way — null triggers the picker first

**Given** accessibility
**When** TalkBack reads Home
**Then** the order is: AppBar (facility chip → gear) → `CredentialBanner` if present → `QueueHero` → queue list → CTAs
**And** each queue row is independently focusable

**Given** responsive behavior
**When** the screen is wider than 600dp (tablet)
**Then** content is centered at max 600dp width, single column, no multi-column layout
**And** the CTA zone remains bottom-anchored full-width within the clamped content area

**Given** the Home screen must include the AdBanner slot (Epic 10 placeholder)
**When** Home renders
**Then** between the queue list and the CTA zone sits a 16dp spacer placeholder where `AdBanner` will mount in Epic 10
**And** no ad content renders until Epic 10 — the slot is reserved, never decorated with theater

---

### Story 5.6: Per-Guest Edit & Delete from Queue

As a host who spotted a typo on a guest row or wants to remove a guest before sending,
I want to edit fields inline or swipe-delete with an undo safety net,
So that mistakes are fixable without re-scanning and accidental deletions are recoverable within a few seconds.

**Acceptance Criteria:**

**Given** the host taps a `QueueRow` in `unsent` or `failed` state
**When** the tap fires
**Then** `QueueNotifier.loadForEdit(id)` returns the decrypted `GuestFields`
**And** the app routes to `/guest-form` in `GuestFormMode.edit` (Epic 4 Story 4.6) pre-filled
**And** the AppBar title is "Uredi gosta"
**And** the primary CTA is "Spremi izmjene"

**Given** the host edits fields and taps "Spremi izmjene"
**When** submit fires
**Then** `SemanticSanityLayer.check` runs
**And** on success → `QueueNotifier.updateFields(id, fields)` re-encrypts and writes to Drift
**And** the row returns to `unsent` state if previously `failed` (giving the entry a fresh retry budget)
**And** `lastFailureReason` is cleared

**Given** the host taps a `submitted` row (within 3-day soft-undo window)
**When** the tap fires
**Then** an informational read-only sheet shows the row's facility + submitted-at timestamp + masked doc number — NO edit affordance (already sent to eVisitor)
**And** only a "Obriši iz sjećanja" destructive action is offered

**Given** the host swipes a `QueueRow` left (dismiss gesture)
**When** the swipe completes past threshold on an `unsent` row
**Then** `QueueNotifier.deleteById(id)` is called
**And** a SnackBar surfaces "Gost obrisan" with a "PONIŠTI" action for 4s
**And** tapping PONIŠTI calls `QueueNotifier.enqueue(fields)` with the original UUID (preserving identity) — an internal-only method `restore(guestEntry)` is exposed on the notifier for this purpose
**And** if 4s passes with no undo, the delete is final (the AES-GCM ciphertext is unrecoverable)

**Given** swipe-to-dismiss must not be enabled on wrong states
**When** the host attempts to swipe a `sending`, `sent`, `failed`, or `in_flight_unresolved` row
**Then** the swipe gesture is not registered — only `unsent` rows respond
**And** for `failed` and `sent` rows, long-press opens an action sheet with Obriši / Uredi (failed only) affordances

**Given** long-press on any row
**When** the gesture fires
**Then** an action bottom sheet opens with state-appropriate options (Uredi for unsent/failed, Obriši for unsent/submitted, Ponovi pokušaj for failed — Epic 6 wiring)

**Given** accessibility
**When** TalkBack is active
**Then** swipe-to-dismiss is inaccessible via gesture but the long-press action sheet is fully navigable
**And** Obriši in the action sheet triggers the same SnackBar+undo flow as the swipe

**Given** NFR-P10 requires 40 guests without UI degradation
**When** an integration test seeds the queue with 40 entries
**Then** the list scrolls at 60fps
**And** edit/delete operations complete within 200ms
**And** the widget tree is built with `ListView.builder` (lazy) not a dumb `ListView` or `Column`

---

### Story 5.7: 3-Day Auto-Purge on App Open

As a host,
I want submitted guests to disappear from my phone automatically 3 days after submission,
So that I never have to clean up and the zero-retention promise is architecturally enforced, not aspirational.

**Acceptance Criteria:**

**Given** the auto-purge is implemented
**When** `QueueNotifier.runAutoPurge()` is called on app cold-start and on `AppLifecycleState.resumed`
**Then** it queries `GuestEntriesTable WHERE purgeAfter < DateTime.now().toUtc()`
**And** hard-deletes matching rows (Drift `delete`) — no soft-delete, no archive, no audit
**And** the AES-GCM ciphertext is unrecoverable once the row is gone

**Given** the purge runs on the main isolate
**When** `runAutoPurge()` is reviewed
**Then** it uses a `dart:async Timer(Duration.zero)` / `Future.microtask` pattern to yield the frame, NOT a `dart:isolate` or WorkManager (Architecture §3: main-isolate because expected row count stays ≤ ~40-60 submitted × 3 days)
**And** the operation does not block the frame — tested with a 100-row fixture and `WidgetTester.binding.framePolicy` set to default

**Given** purge emits telemetry (Epic 9 wiring)
**When** rows are purged
**Then** `TelemetryService.queuePurge(purgedCount: N)` is called (stubbed until Epic 9; story writes the call site)
**And** the telemetry emits zero PII (only the integer count)

**Given** purge must run regardless of host action or network state
**When** the app opens offline
**Then** purge still runs — it is a local operation with no network dependency
**And** the "Your Data" screen (Epic 8) shows updated counts immediately after purge

**Given** the `purgeAfter` column is indexed (Story 5.1)
**When** purge queries the table
**Then** the query plan uses the index and completes in <50ms for 1000 rows (synthetic stress test)

**Given** rows with `state != submitted` never auto-purge
**When** unsent, in-flight-unresolved, or failed rows exist
**Then** those rows are preserved indefinitely until the host explicitly deletes them or Replace-Active-OIB wipes (Story 5.8)
**And** `purgeAfter` is only set by `markSubmitted(id, purgeAfter: submittedAt + Duration(days: 3))` in Epic 6 Story 6.5

**Given** the 3-day window is calibrated
**When** an integration test seeds entries with `purgeAfter = now - 1d` and `purgeAfter = now + 1d`
**Then** the first is purged, the second is preserved

---

### Story 5.8: Replace-Active-OIB via TypedConfirmationDialog

As a host who sold my business to another OIB or who wants to hand the phone off cleanly,
I want a destructive "replace active OIB" action that wipes every byte of local data — but only after I type a specific Croatian confirmation word,
So that accidental taps can't destroy my session and the one-time transition is unmistakable.

**Acceptance Criteria:**

**Given** the generic dialog widget is implemented
**When** `lib/widgets/typed_confirmation_dialog.dart` is reviewed per UX-DR15
**Then** it extends `AlertDialog` and accepts `required String title`, `required String body`, `required String requiredWord`, `required VoidCallback onConfirm`
**And** a `TextField` accepts freeform input; the destructive `FilledButton` (error color) is enabled ONLY when input matches `requiredWord` via case-insensitive + diacritic-aware match
**And** `Cancel` is the default focused action
**And** tap-outside does NOT dismiss (poka-yoke per UX spec §Modal and Overlay Patterns)
**And** the `why` doc comment explains the irreversible-action constraint

**Given** states per UX-DR15
**When** the dialog renders
**Then** `empty_input` disables the destructive button
**And** `partial_match` disables the destructive button
**And** `exact_match` enables the destructive button in error color
**And** `executing` replaces the destructive button with a spinner and disables all inputs (non-dismissible)

**Given** the Settings entry is wired
**When** the host taps "Zamijeni aktivni OIB" in Settings
**Then** `TypedConfirmationDialog` is shown with `requiredWord: 'ZAMIJENI'`, title "Zamijeni aktivni OIB", body "Ovo će obrisati sve objekte, neposlane goste, prijavljene goste u roku od 3 dana, podatke za prijavu i kolačiće. Upiši ZAMIJENI za potvrdu."
**And** Cancel leaves all data intact

**Given** the host types "ZAMIJENI" and taps confirm
**When** the action fires
**Then** the dialog transitions to `executing`
**And** `HapticFeedback.heavyImpact()` fires
**And** the wipe routine runs in this exact order: 1) `GuestEntriesTable.deleteAll()`, 2) `FacilitiesTable.deleteAll()`, 3) cookie-jar file deletion, 4) `CredentialStore.wipeCredentials()`, 5) `SecurityService.rotateKey()` (re-generates Keystore AES-GCM key to invalidate any cached ciphertext), 6) `activeFacilityProvider` reset
**And** each step is awaited sequentially — partial wipe is visible as a failure state, not silently glossed over

**Given** wipe completes
**When** every step succeeded
**Then** the app is force-restarted via `RestartWidget` or equivalent pattern routing to UMP/CMP consent → Welcome → Login flow (Epic 1)
**And** no residual state carries over

**Given** one step fails mid-wipe (e.g., Keystore access denied)
**When** the failure is detected
**Then** the dialog shows a Croatian error "Brisanje nije u potpunosti uspjelo — pokušaj ponovno"
**And** subsequent taps of "Zamijeni" retry from the failed step (idempotent deletes)
**And** telemetry `auth_state_transition` is NOT emitted yet — the state is ambiguous

**Given** the poka-yoke word is case-insensitive + diacritic-aware
**When** a unit test covers input normalization
**Then** "zamijeni", "ZAMIJENI", "Zamijeni", "zámijeni" all match; "ZAMIENI" (missing J) does not match
**And** the Croatian character set includes č/ć/š/ž/đ for future destructive variants that might use them

**Given** the same widget is re-used in Epic 8 for "Delete All Data"
**When** Epic 8 Story 8.3 invokes it
**Then** `requiredWord: 'OBRIŠI'` with different title/body
**And** this story ships the widget and the ZAMIJENI wiring; OBRIŠI is a caller configuration, not a duplicate widget

**Given** golden tests cover both contexts
**When** `typed_confirmation_dialog_test.dart` runs
**Then** goldens exist for `empty_input`, `partial_match`, `exact_match`, `executing` states × dark/light
**And** goldens exist for the ZAMIJENI variant (this story) and are parameterized to also render the OBRIŠI variant

---

## Epic 6: Explicit Send All with Per-Guest Isolation

One tap submits all unsent guests for the active facility; pre-flight blocks on dead auth or offline with a clear Croatian message; per-guest ✓/✗ is rendered inline so one rejected guest never kills the others; failed guests can be edited inline and retried without re-submitting successful ones; rate-limit throttling is handled gracefully with backoff; on crash recovery, `in_flight` entries are reconciled against eVisitor before any retry to prevent silent double-submits.

### Story 6.1: EvisitorDateCodec (Single `/Date(ms+offset)/` Source)

As a developer,
I want one and only one place in the codebase where `/Date(ms+offset)/` strings are constructed and parsed,
So that a single bug fix or DST edge case is resolved in exactly one file and no other file can accidentally hand-roll the format.

**Acceptance Criteria:**

**Given** the codec is implemented
**When** `lib/core/time/evisitor_date_codec.dart` is reviewed
**Then** it declares a `class EvisitorDateCodec` with two static pure methods: `String encode(DateTime dt)` and `DateTime decode(String raw)`
**And** zero Flutter imports — pure Dart only
**And** the file has a top-of-file `why` doc comment explaining the Rhetos `/Date(ms+tz)/` contract and the single-source-of-truth rule

**Given** `encode` is called with a Europe/Zagreb local `DateTime`
**When** encoded
**Then** the output is exactly `/Date(<millisecondsSinceEpoch>+<tzOffset>)/` with the timezone offset formatted `±HHMM` (no colon)
**And** the `millisecondsSinceEpoch` value is UTC-normalized (the ms-since-epoch component does not include the offset — the offset is a display-only annotation per .NET JSON convention)

**Given** a wintertime (CET, UTC+0100) and a summertime (CEST, UTC+0200) date
**When** each is encoded
**Then** the winter output uses `+0100` and the summer output uses `+0200`
**And** a round-trip `decode(encode(dt))` returns a `DateTime` equal to the original after normalizing to UTC (`.toUtc()` comparison)

**Given** `decode` is called with a well-formed `/Date(1234567890+0100)/` string
**When** parsed
**Then** it returns a UTC `DateTime` from `DateTime.fromMillisecondsSinceEpoch(1234567890, isUtc: true)`
**And** the offset portion is parsed and exposed via an optional second return (e.g., via a sealed result `EvisitorDateParsed(utc, offset)`) or as a companion static `parseOffset(String)` method for caller inspection

**Given** malformed input
**When** `decode` is called with `"not a date"`, `"/Date()/"`, `"/Date(abc+0100)/"`, or similar
**Then** it throws `FormatException` with a Croatian message suitable for logging — no silent return of `DateTime.now()` or epoch

**Given** exhaustive test coverage
**When** `evisitor_date_codec_test.dart` runs
**Then** tests include: DST boundary (last Sunday of March and October in Europe/Zagreb), year 2000 boundary, pre-1970 dates (passport issue dates for older guests), fractional-second exclusion (always whole ms), round-trip for 100 synthetic dates spanning 1950–2050
**And** a parametric test verifies `decode(encode(dt)).toUtc() == dt.toUtc()` across the synthetic set

**Given** the CI grep guard enforces the single-source rule
**When** any file outside `evisitor_date_codec.dart` contains the pattern `/\\?/Date\\(`
**Then** the build fails
**And** the Architecture Anti-Pattern Reference table documents "Inline `/Date(...)` string" → "Use `EvisitorDateCodec.encode(dt)`"

---

### Story 6.2: ImportTouristsBuilder (Single XML Builder)

As a developer,
I want one class that produces the exact XML-as-string-inside-JSON payload eVisitor expects for a guest,
So that the payload shape is unit-testable against golden XML fixtures and no other file can construct ImportTourists inline.

**Acceptance Criteria:**

**Given** the builder is implemented
**When** `lib/features/submission/import_tourists_builder.dart` is reviewed
**Then** it declares `class ImportTouristsBuilder` with a method `String build({required GuestEntry entry, required Facility facility})` returning the XML-encoded string suitable to embed as a JSON value
**And** the file has a top-of-file `why` doc comment explaining the XML-inside-JSON constraint and the "single source of XML construction" rule

**Given** the XML structure must match eVisitor's expected schema
**When** `build` is called with a fixture guest + facility
**Then** the output contains an `<ImportTourists>` root, a `<Tourists>` collection, a `<Tourist>` element with child fields populated from `GuestFields` (document number, name, DoB, nationality, sex, document type, document expiry, personal number if present)
**And** all dates inside the XML are encoded via `EvisitorDateCodec.encode` (not inline)
**And** the output is properly XML-encoded (ampersands, angle brackets, quotes — no raw injection risk)

**Given** `FeatureFlags.mayMandateField == true`
**When** `build` is called
**Then** the output includes an `<ApartmentRegistrationNumber>` element populated from `entry.fields.apartmentRegistrationNumber`
**And** if the flag is true but the field is empty, the builder throws `ValidationError` — it does NOT silently omit a mandatory field

**Given** `FeatureFlags.mayMandateField == false`
**When** `build` is called
**Then** the `<ApartmentRegistrationNumber>` element is omitted entirely
**And** the resulting XML is backward-compatible with pre-mandate eVisitor

**Given** the facility context
**When** `build` is called
**Then** `facility.id` is included as the target facility identifier in the XML per the eVisitor schema slot (exact slot TBD per Week-1 spike; one `const String kFacilityIdXmlSlot` documents the mapping)
**And** the `facility.oib` is included if the schema requires it

**Given** the payload must be embeddable as a JSON value
**When** the returned string is inserted into `{"importXml": "..."}` JSON
**Then** no JSON-escaping issues occur
**And** a test round-trips the wrapped JSON through `jsonEncode`/`jsonDecode` and asserts the inner XML is preserved byte-for-byte

**Given** golden XML fixtures exist
**When** `import_tourists_builder_test.dart` runs
**Then** test cases cover: single TD3 passport, single TD2 ID card, single TD1 ID card, entry with optional personal number, entry without, mandate-flag on, mandate-flag off, foreign-key unicode name, Croatian-diacritic guest (čćšžđ)
**And** each case asserts equality against a committed `*.xml` golden file in `test/fixtures/import_tourists/`

**Given** the anti-pattern is enforced
**When** any file outside `import_tourists_builder.dart` contains inline `<ImportTourists>` string construction
**Then** the CI grep rule fails the build
**And** the Anti-Pattern table documents "Inline ImportTourists XML" → "Use ImportTouristsBuilder(...).build()"

---

### Story 6.3: EvisitorApiClient.importTourists Endpoint

As a developer,
I want a typed Dio wrapper for the ImportTourists call that handles the cookie jar, cert pinning, auth interceptor, and error classification by construction,
So that the caller never thinks about cookies, retries, or contract quirks — just a simple `Future<Result<ImportTouristsResponse, AppError>>` call.

**Acceptance Criteria:**

**Given** the API client is extended
**When** `lib/features/submission/evisitor_api_client.dart` is reviewed
**Then** it exposes `Future<Result<ImportTouristsResponse, AppError>> importTourists({required String xmlPayload})`
**And** the method POSTs to the ImportTourists endpoint path (declared as a `const String` in the client; exact path refined via Week-1 spike)
**And** the request body is JSON `{"importXml": "<XML-AS-STRING>"}` (NOT pure XML, NOT pure JSON per Architecture §3)
**And** the method uses the `dioProvider` instance so all Dio-level concerns (cookies, cert pin, auth interceptor) are inherited

**Given** eVisitor accepts the payload
**When** the response is HTTP 200 with a success envelope
**Then** the method returns `Result.Ok(ImportTouristsResponse(...))` — a Freezed model with `DateTime serverTimestamp`, `List<String> acceptedClientUuids`, `List<ImportTouristsRejection> rejections`
**And** `ImportTouristsRejection` carries `String clientUuid`, `String userMessage` (Croatian from eVisitor), `String? systemMessageHash` (SHA-256, never raw per NFR-S8)

**Given** eVisitor returns a validation error per guest
**When** HTTP 200 body contains rejections
**Then** the method returns `Result.Ok` with `rejections` populated
**And** the caller (Story 6.5) pivots each rejection to `QueueNotifier.markFailed`
**And** the classifier is NOT invoked — per-guest validation is a normal outcome, not an error

**Given** eVisitor returns `sessionDead` per classifier (401, 403, 400+SM, 200+envelope@ImportTourists)
**When** the `AuthInterceptor` from Epic 2 Story 2.3 processes it
**Then** re-auth is triggered, the request is replayed with fresh cookies, and the caller receives the final outcome transparently
**And** no duplicate ImportTourists calls are issued — interceptor serialization guarantees once-per-session

**Given** eVisitor returns HTTP 429 or a throttling envelope
**When** the classifier returns `throttled`
**Then** the method returns `Result.Err(ThrottledError(retryAfter: Duration?))` extracted from the response's `Retry-After` header or default `Duration(seconds: 5)`
**And** no retry is attempted inside the client — the caller (Story 6.6) owns backoff policy

**Given** the network fails
**When** the classifier returns `network`
**Then** the method returns `Result.Err(NetworkError)` with the original `DioException` for diagnostics
**And** no retry is attempted — Send All is explicit (no background retry)

**Given** the Dio fake covers all scenarios
**When** `evisitor_fake_adapter.dart` is queried by an integration test
**Then** canned responses exist for: single-guest success, 3-of-5 rejections with Croatian `userMessage`, HTTP 429 with `Retry-After: 3`, HTTP 400+SystemMessage session-dead, connection timeout, contract-break (unrecognized response shape)
**And** the receive timeout for this call is 60s (per Architecture §3 `ImportTourists` extended timeout)

---

### Story 6.4: SendAllNotifier & Pre-Flight Check

As a host about to tap Send All,
I want the app to verify my auth and network are live before it touches a single guest,
So that a dead session or offline state is caught upfront — not silently on guest 3 of 5.

**Acceptance Criteria:**

**Given** the send-all notifier is implemented
**When** `lib/features/submission/send_all_notifier.dart` is reviewed
**Then** it extends `AsyncNotifier<SendAllResult>` and is declared as auto-disposed (its lifetime matches one Send All session — disposed when the user leaves the Review/Closure screens)
**And** it exposes `Future<void> sendAll()` as the entry point
**And** `SendAllResult` is a Freezed model with `int total`, `int succeeded`, `int failed`, `int skipped`, `List<PerGuestOutcome> perGuest`, `SendAllPhase phase` (`preFlight | submitting | throttled | complete | aborted`)

**Given** the host taps "Pošalji sve" on Home or Review screen
**When** `sendAll()` is called
**Then** the pre-flight phase begins with `phase: preFlight`
**And** the notifier reads `authNotifierProvider` state — if not `Authenticated`, transitions to `phase: aborted` with reason `authNotReady` and returns
**And** the notifier queries `connectivity_plus` to verify network availability — if offline, transitions to `phase: aborted` with reason `offline` and returns

**Given** pre-flight aborts due to `authNotReady`
**When** the UI renders the aborted state
**Then** a Croatian message "eVisitor sesija nije aktivna — dodirni traku za ponovnu prijavu" is shown
**And** the `CredentialBanner` is already surfacing (Epic 2 Story 2.7) — no duplicate prompting
**And** no guest state changes in Drift

**Given** pre-flight aborts due to `offline`
**When** the UI renders the aborted state
**Then** a Croatian message "Nema interneta. Poveži se i pokušaj ponovno." is shown
**And** a single "Pokušaj ponovno" affordance re-runs pre-flight (not the full submission)

**Given** pre-flight passes within 1s p95
**When** timing is measured
**Then** from "Pošalji sve" tap to first guest `markInFlight` call is ≤1s p95 on the test baseline device (NFR-P5)
**And** the pre-flight spinner uses the `CircularProgressIndicator` inside the CTA button (not a full-screen modal)

**Given** pre-flight passes
**When** the notifier transitions to `phase: submitting`
**Then** it hands off to the per-guest loop from Story 6.5
**And** the Home CTA disables while a Send All is in progress (prevents double-tap)
**And** no scan/manual-entry is blocked — the host can keep queueing new guests in another facility, but the current-facility queue is frozen for this Send All session

**Given** no ad requests fire during Send All
**When** the notifier is in `phase: submitting | throttled`
**Then** `AdBanner` (Epic 10) is hidden via its consent/state gating — asserted by a widget test

---

### Story 6.5: Per-Guest Serial Submission Loop

As a host watching Send All progress,
I want to see each guest's status transition from ○ queued to ↑ sending to ✓ accepted or ✗ failed in real time,
So that if one guest is rejected I can see exactly which one — and the others continue unaffected.

**Acceptance Criteria:**

**Given** pre-flight has passed
**When** the per-guest loop starts
**Then** for each entry in the unsent queue scoped to `activeFacilityProvider`, the loop runs SERIALLY (not in parallel — avoids Rhetos throttling and preserves per-guest telemetry clarity)
**And** the order is `clientCreatedAt` ascending

**Given** a single guest enters the loop
**When** processing begins
**Then** step 1: `QueueNotifier.markInFlight(id)` — transitions `unsent → in_flight` and emits to UI so `QueueRow` renders ↑ glyph
**And** step 2: `ImportTouristsBuilder.build(entry, facility)` produces the XML payload
**And** step 3: `EvisitorApiClient.importTourists(xmlPayload: payload)` dispatches the call
**And** step 4: outcome is handled per classifier/response

**Given** the response is `Result.Ok(ImportTouristsResponse)` with no rejection for this guest
**When** processing the response
**Then** `QueueNotifier.markSubmitted(id, purgeAfter: response.serverTimestamp + Duration(days: 3))` — transitions `in_flight → submitted`
**And** the UI updates `QueueRow` to ✓ glyph within 200ms (NFR-P6)
**And** `PerGuestOutcome.success` is appended to `SendAllResult.perGuest`

**Given** the response contains a rejection for this guest
**When** processing the response
**Then** `QueueNotifier.markFailed(id, reason: rejection.userMessage)` — transitions `in_flight → failed`
**And** the UI updates `QueueRow` to ✗ glyph within 200ms
**And** `PerGuestOutcome.failure(userMessage, systemMessageHash)` is appended

**Given** the response is `Result.Err(ThrottledError)`
**When** processing
**Then** control passes to Story 6.6's backoff routine (the entry stays `in_flight` during backoff)

**Given** the response is `Result.Err(NetworkError)` or `Result.Err(ServerError)`
**When** processing
**Then** `QueueNotifier.markFailed(id, reason: "Mreža nije dostupna — pokušaj ponovno" | "Greška servera — pokušaj ponovno")`
**And** the loop continues with the next guest — a single network/server error does NOT abort the batch
**And** per NFR-R5 the entry is preserved as `failed` (never `gone`)

**Given** the response is `Result.Err(ContractBreakError)` classified by Epic 2 Story 2.2
**When** processing
**Then** the loop aborts immediately with `phase: aborted` reason `contractBreak`
**And** entries already processed retain their outcome
**And** entries not yet processed remain `unsent`
**And** the forced-update check (Epic 9 Story 9.4) is triggered by the classifier result

**Given** the loop completes all entries
**When** the final guest resolves
**Then** `phase: complete` is emitted
**And** `SendAllScreen` navigates to the Review screen (Story 6.7) if any failures occurred, OR directly to Closure Summary (Epic 7) if 100% success
**And** `TelemetryService.sendAllResult(total, succeeded, failed)` is called (Epic 9 wiring)
**And** `TelemetryService.scanToSubmit(correctionsCount, success)` is emitted per entry

**Given** the host kills the app mid-loop
**When** the app is re-launched
**Then** `in_flight` entries are reconciled per Story 6.8 before any new Send All can start
**And** per NFR-R5 no submission is lost — every entry is either `in_flight_unresolved`, `submitted`, or `failed`

---

### Story 6.6: Rate-Limit Throttling with Exponential Backoff

As a host during a busy hour on eVisitor,
I want the app to handle HTTP 429 throttling by backing off and retrying silently,
So that a temporary server-side rate limit doesn't get counted against my guests as a real failure.

**Acceptance Criteria:**

**Given** the per-guest loop receives `Result.Err(ThrottledError(retryAfter))`
**When** processing the response
**Then** the loop transitions to `phase: throttled`
**And** a non-blocking Croatian message "eVisitor je zauzet — pokušavam ponovno za N s" is rendered as a banner above the Review progress
**And** a countdown of `retryAfter` seconds is shown
**And** the entry remains `in_flight` — no `markFailed` call

**Given** the `retryAfter` duration has elapsed
**When** the loop resumes for the same entry
**Then** `EvisitorApiClient.importTourists` is re-dispatched for that same entry
**And** the attempt counter for that entry is incremented

**Given** throttling persists across retries
**When** the second and third retries also return `throttled`
**Then** exponential backoff applies: retry 1 uses `Retry-After` header or 5s default; retry 2 uses `max(Retry-After, 10s)`; retry 3 uses `max(Retry-After, 20s)`
**And** after 3 consecutive `throttled` outcomes for the SAME entry, the entry is marked `failed` with reason "eVisitor neprestano zauzet — pokušaj ponovno kasnije"
**And** the loop continues with the next entry

**Given** the banner is visible during backoff
**When** the host sees "pokušavam ponovno za N s"
**Then** the countdown updates every second
**And** the host can tap "Prekini" to abort the Send All gracefully — currently-`in_flight` entry is marked `failed` with reason "Otkazano" and the loop exits with `phase: aborted`
**And** already-submitted entries retain their outcomes

**Given** `TelemetryService` tracks throttling
**When** a `throttled` outcome occurs
**Then** no telemetry is emitted per throttle event (noise); only when an entry exceeds 3 retries is `classifierMismatch` NOT emitted (this is not a classifier miss — it's a real server state) but `sendAllResult` at the end includes a `throttleRetries: int` metric for production visibility

**Given** backoff is tested against the Dio fake
**When** the integration test fires a sequence `[throttled, throttled, success]` for one entry
**Then** the test asserts exactly 3 HTTP calls with the correct backoff durations in between
**And** the final outcome is `success`
**And** `SendAllResult.perGuest` for this entry shows `success` (not `failure`)

---

### Story 6.7: Send All Results (Review) Screen with Edit-and-Retry-Failed-Only

As a host who saw one or two guests fail a Send All,
I want a review screen that lets me edit the failed guests inline and retry only those — never re-sending the successful ones,
So that salvage operations take 45 seconds, not 15 minutes, and I never double-submit an accepted guest.

**Acceptance Criteria:**

**Given** Send All completes with at least one failure
**When** the SendAllNotifier reaches `phase: complete`
**Then** the app routes to `/send-all/review` with the `SendAllResult` passed via Riverpod
**And** the screen title is "Rezultati slanja"
**And** a summary header shows "{N} od {M} prijavljeno · {K} neuspjelih"

**Given** the review screen renders per UX-DR20
**When** `lib/features/send/review_screen.dart` is reviewed
**Then** it uses `QueueRow(variant: review)` for each entry
**And** successful entries render with ✓ glyph and meta "Prihvaćeno"
**And** failed entries render with ✗ glyph, 1px error border, red name label, meta showing the Croatian `userMessage`, and a trailing "Uredi" `TextButton`

**Given** the host taps "Uredi" on a failed entry
**When** the action fires
**Then** the app pushes `/guest-form` in `GuestFormMode.edit` pre-filled from the entry's decrypted `GuestFields`
**And** the AppBar shows the failure reason as a warning banner at the top ("Nedostaje reg. broj")
**And** submit runs sanity + returns to Review screen with the entry's state reset to `failed` (ready for retry) and `lastFailureReason` cleared

**Given** the host taps "Pokušaj neuspjele" CTA
**When** the action fires
**Then** a new Send All session is invoked with a filter: only entries in `failed` state are submitted
**And** entries in `submitted` state are NEVER re-sent (poka-yoke — an integration test asserts this)
**And** the per-guest loop from Story 6.5 runs identically, just with a smaller set
**And** the review screen is updated in place (no second push) with new outcomes

**Given** all failures were resolved after retry
**When** the second Send All completes with zero failures
**Then** the app auto-navigates to the Closure Summary (Epic 7) without the review screen re-rendering
**And** the host sees the gold count of total successful submissions (including the previously-successful ones from the first Send All)

**Given** the host taps system back from the review screen with failures still present
**When** the back gesture fires
**Then** a Croatian confirmation "Napusti bez ponovnog pokušaja?" is shown — Prekini / Napusti
**And** Napusti returns to Home with the failed entries still visible in the queue (they stay as `failed` until next Send All)

**Given** accessibility
**When** TalkBack reads the review screen
**Then** the summary header is announced first, then each row with its state + reason + "Uredi" affordance
**And** the "Pokušaj neuspjele" CTA is the final focusable element

**Given** no failures occurred
**When** Send All completed with 100% success
**Then** the review screen is skipped entirely — the app navigates directly from the per-guest loop's last resolution to the Closure Summary (Epic 7)
**And** the Review screen is never a mandatory step, only a corrective one

---

### Story 6.8: InFlightReconciler (Path A / Path B) on App Resume

As a host whose app crashed or whose phone died mid-Send-All,
I want the app on next launch to figure out whether my `in_flight` guests actually reached eVisitor before it retries anything,
So that a crash mid-submission never causes a silent double-submit.

**Acceptance Criteria:**

**Given** the reconciler is implemented
**When** `lib/features/submission/in_flight_reconciler.dart` is reviewed
**Then** it exposes `Future<ReconciliationResult> reconcile()` that queries `GuestEntriesTable WHERE state = 'in_flight'` and returns a summary `{resolved: N, unresolved: M}`
**And** it runs on app cold-start (called from `main.dart` after `SecurityService.init()`) and on `AppLifecycleState.resumed`
**And** it runs BEFORE any new Send All can be initiated — the `SendAllNotifier.sendAll()` pre-flight check blocks if `in_flight` count > 0

**Given** `FeatureFlags.lookupEndpointExists == true` (Path A — post-Week-1-spike confirms endpoint exists)
**When** the reconciler processes each `in_flight` entry
**Then** it calls `EvisitorApiClient.lookupByUuid(entry.id)` per entry
**And** if the lookup returns `found`, transitions entry to `submitted` with `purgeAfter = now + Duration(days: 3)`
**And** if the lookup returns `not_found`, transitions entry back to `unsent` (safe to retry)
**And** if the lookup itself fails (network, sessionDead, etc.), the entry is left `in_flight` and re-tried on next reconcile

**Given** `FeatureFlags.lookupEndpointExists == false` (Path B — v1.0 default, pre-spike)
**When** the reconciler processes each `in_flight` entry
**Then** it transitions entries to `in_flight_unresolved` state
**And** the Home screen surfaces a `CredentialBanner` in `partial_send_pending` variant from Epic 2 Story 2.7 with Croatian message "Neprovjerene prijave — provjeri u eVisitor portalu"
**And** the banner action "U redu" routes to a dedicated advisory screen listing the unresolved entries with their masked doc numbers + `clientCreatedAt` timestamp + a "Označi kao poslano" manual override and a "Pokušaj ponovno" retry override

**Given** the host uses "Označi kao poslano" manual override (Path B)
**When** the action fires
**Then** the entry transitions to `submitted` with `purgeAfter = now + 3d`
**And** no ImportTourists call is made
**And** the host is reminded via SnackBar "Provjeri u eVisitor portalu unutar 24 sata"

**Given** the host uses "Pokušaj ponovno" retry override (Path B)
**When** the action fires
**Then** the entry transitions back to `unsent`
**And** the next Send All will attempt submission — this is the explicit double-submit acceptance (host knowingly chose)
**And** a SnackBar confirms "Označeno za ponovno slanje"

**Given** the reconciler runs without any `in_flight` entries
**When** `reconcile()` completes
**Then** it returns `ReconciliationResult(resolved: 0, unresolved: 0)` in <50ms
**And** no network calls are made (early-return)

**Given** telemetry (Epic 9 wiring)
**When** the reconciler resolves or defers entries
**Then** a `classifierMismatch` event is NOT emitted — this is not a classifier concern
**And** a `queueStuck24h` event IS emitted if any `in_flight_unresolved` entry's `clientCreatedAt` is > 24h old (NFR-R4)

**Given** unit tests cover both paths exhaustively
**When** `in_flight_reconciler_test.dart` runs
**Then** Path A tests: `[found, not_found, network_error]` → respective state transitions
**And** Path B tests: seed 3 `in_flight` entries → all become `in_flight_unresolved` → banner surfaces → host uses overrides → final states correct
**And** architecture.md's "D8 Path A/B design decouples Week-1 spike outcome from structural architecture" is realized

---

## Epic 7: Closure Summary (The Signature Moment)

After every submission batch the host sees a full-screen Closure Summary — facility name, count (gold), and Europe/Zagreb local timestamp — designed to be screenshotted and shared via native Android share sheet. Zero PII in the payload. The host returns to Home with queue empty (or the failed entries remaining).

### Story 7.1: ClosureSummary Custom Widget

As a host who just successfully registered guests at the door,
I want a full-screen moment that feels like an accomplishment — gold accent, generous typography, zero clutter,
So that the relief of "it actually sent" is unmistakable, shareable, and memorable enough to become word-of-mouth marketing for the app.

**Acceptance Criteria:**

**Given** the widget is implemented
**When** `lib/widgets/closure_summary.dart` is reviewed per UX-DR14
**Then** it is a `StatelessWidget` accepting `required int guestCount`, `required String facilityName`, `required DateTime submittedAt`, `required ClosureVariant variant`
**And** `ClosureVariant` is a sealed class: `AllSuccess`, `PartialWithFailures({required int failedCount})`, `SingleGuest`
**And** the file has a top-of-file `why` doc comment explaining the emotional-payoff constraint (this is the product's signature moment — not a confirmation dialog)
**And** no hex colors — all colors via `ColorScheme` or `ThemeExtension<SemanticColors>`

**Given** the visual contract from UX-DR14
**When** the widget renders
**Then** the background is a linear gradient from `primaryContainer` (top) to `surface` (bottom) with the transition at 55% vertical
**And** the top third centers a 56dp success circle (Material Symbols rounded check on `SemanticColors.success` fill) and below it renders the guest count in `textTheme.displayLarge` with weight 800 in `SemanticColors.closureAccent` gold — this gold is the ONLY appearance of `closureAccent` in the entire app (a CI grep rule flags any other file referencing this token)
**And** below the count, a secondary label in `headlineSmall onPrimaryContainer` reads "gost" / "gosta" / "gostiju" per Croatian plural rules for the count value
**And** a sub-label in `bodyLarge onSurfaceVariant` reads "{facilityName} · {HH:mm}" in Europe/Zagreb local time formatted via the active locale

**Given** the `AllSuccess` variant
**When** rendered
**Then** the success circle is full-saturation `SemanticColors.success` fill
**And** no warning/error styling appears anywhere

**Given** the `PartialWithFailures(failedCount: N)` variant
**When** rendered
**Then** an additional `Chip` beneath the sub-label reads "{N} neuspjelih" in `SemanticColors.warning` amber (not error red — per UX spec "attention, not panic")
**And** the gold count + success circle STILL reflect only the successful count (the failure chip is additive metadata, not a hijacking of the emotional payoff)

**Given** the `SingleGuest` variant
**When** rendered
**Then** the label reads "gost" (singular)
**And** no special layout treatment — the same hero layout scales naturally

**Given** the widget must carry ZERO PII
**When** a widget test inspects the rendered text
**Then** `find.text(docNumber)`, `find.text(firstName)`, `find.text(lastName)` all return zero matches for any fixture `GuestEntry`
**And** only the integer count, facility name, and time are rendered
**And** a code-review checklist item documents "ClosureSummary receives `int guestCount`, never `List<GuestEntry>` or `List<GuestFields>` — PII must not traverse this boundary"

**Given** portrait lock is enforced by the screen assembly (Story 7.2)
**When** this widget is rendered in landscape by mistake
**Then** the layout does NOT break (defensive) but the screen assembly's portrait-lock is the primary contract

**Given** accessibility
**When** TalkBack explores the widget
**Then** a single compound semantics announcement reads "Prijavljeno {count} gostiju u objektu {facilityName} u {HH:mm}" (plural correct) with `liveRegion: true` so it auto-announces on appearance
**And** font scaling up to 200% does not break the layout (the gold count uses `FittedBox` inside its container to scale down gracefully)
**And** the success circle has `ExcludeSemantics` (decorative, redundant to the announcement)

**Given** golden tests cover variants × themes
**When** `closure_summary_test.dart` runs
**Then** goldens exist for `AllSuccess(count: 4)`, `PartialWithFailures(count: 4, failedCount: 1)`, `SingleGuest(count: 1)` × dark/light (6 goldens total)
**And** a font-scale golden at 1.5x verifies the gold count still fits on a 360dp-wide screen without overflow

---

### Story 7.2: ClosureSummary Screen Assembly with Share Affordance

As a host who just completed a successful Send All,
I want a full-screen closure page with Share and Done buttons,
So that I can screenshot or text "✅ done" to my spouse in two taps, then return to Home with a clean queue.

**Acceptance Criteria:**

**Given** the screen is assembled per UX-DR21
**When** `lib/features/closure/closure_summary_screen.dart` is reviewed
**Then** it is a `ConsumerWidget` routed at `/closure-summary` with `fullscreenDialog: true`
**And** the body wraps the `ClosureSummary` widget from Story 7.1
**And** the bottom action zone contains two CTAs: `FilledButton` "Podijeli" (primary, leading Material Symbols rounded share icon) and `OutlinedButton` "Gotovo" (secondary)
**And** the CTA zone follows the standard screen skeleton from UX spec (56dp buttons, 16dp horizontal padding, 24dp gesture inset)

**Given** portrait lock is a UX contract
**When** the screen mounts (`initState`)
**Then** `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` is called
**And** on `dispose`, `SystemChrome.setPreferredOrientations(DeviceOrientation.values)` restores default
**And** a widget-lifecycle test verifies both calls in order

**Given** the host taps "Podijeli"
**When** the share action fires
**Then** `share_plus`'s `Share.share(text)` is invoked with a Croatian payload formatted as:
`"Prijavljeno {count} gostiju u objektu {facilityName} u {HH:mm}. #prijavko"`
**And** the payload is TEXT-ONLY — no screenshot generation in v1.0 (UX-DR14: "no screenshot export in v1.0 — user screens natively")
**And** the payload contains ZERO PII — asserted by a unit test that generates payloads for 10 fixture outcomes and verifies no guest name/doc-number strings appear

**Given** the host taps "Gotovo"
**When** the action fires
**Then** the app navigates to `/home` via `go_router.goNamed('home')`
**And** the `SendAllNotifier` is disposed (it was auto-disposed anyway)
**And** the queue on Home reflects the post-submission state: submitted entries now in the 3-day soft-undo buffer, failed entries still visible as `failed` rows (if any)

**Given** the screen is persistent until dismissed
**When** the host taps system back
**Then** the back gesture is equivalent to "Gotovo" — routes to `/home`
**And** a transient screenshot overlay does NOT auto-dismiss (some competitor apps flash a "success" toast for 2s; prijavko's closure is a full-screen moment until the host chooses to leave)

**Given** no ads appear on this screen
**When** Epic 10's `AdBanner` is queried
**Then** `AdBanner` route-context assertion rejects this screen
**And** no ad request fires (this is the "sacred" screen per UX-DR16 and UX spec §Ad Placement)

**Given** the haptic on arrival
**When** the screen first renders
**Then** `HapticFeedback.selectionClick()` fires (subtle — the arrival is the reward, not a heavy impact)
**And** TalkBack's live-region announcement from Story 7.1 is the primary feedback

**Given** dark and light modes ship together
**When** golden tests run
**Then** the screen renders correctly in both modes with the gold `closureAccent` visible in both
**And** contrast is WCAG 2.1 AA on the gold-on-gradient label combination (verified by a contrast test reading actual rendered pixel values from the golden)

---

### Story 7.3: Closure Summary Navigation Wiring

As a host,
I want the Closure Summary to appear automatically after every Send All that finished its work — whether 100% successful on first try or recovered via retry-failed-only,
So that the emotional payoff lands reliably and the transition from stress to relief is the consistent end-of-session experience.

**Acceptance Criteria:**

**Given** the `SendAllNotifier` from Epic 6 reaches `phase: complete`
**When** the notifier evaluates the result
**Then** if `succeeded > 0 && failed == 0` → navigate to `/closure-summary` with `ClosureVariant.AllSuccess` (or `.SingleGuest` if `succeeded == 1`)
**And** if `succeeded > 0 && failed > 0` → navigate to `/send-all/review` (Epic 6 Story 6.7) — NOT directly to Closure
**And** if `succeeded == 0 && failed > 0` → navigate to `/send-all/review` (review-first for salvage)
**And** `phase: aborted` (pre-flight abort or `contractBreak`) → NO navigation, stay on current surface with the appropriate Croatian error

**Given** the host completes Epic 6 Story 6.7's retry-failed-only flow with all remaining failures resolved
**When** the second Send All session reports zero failures
**Then** the navigation from review → closure fires with `ClosureVariant.AllSuccess` and the count includes both the first-pass successes AND the retry successes
**And** the facility name is read from `activeFacilityProvider` at the moment of closure render (no stale state)

**Given** the host resolved some but not all failures on retry
**When** the second Send All leaves `failed > 0` OR the host abandoned retry (Epic 6 Story 6.7 "Napusti bez ponovnog pokušaja")
**Then** the Closure Summary is shown with `ClosureVariant.PartialWithFailures(failedCount: N)`
**And** the gold count reflects only successful submissions (failed entries are the amber chip, not the hero)
**And** when the host taps Done, they return to Home where the remaining `failed` entries are still visible in the queue for a later retry

**Given** telemetry is emitted at closure time (Epic 9 wiring)
**When** `/closure-summary` route is entered
**Then** `TelemetryService.sendAllResult(total: N, succeeded: S, failed: F)` is called once
**And** the event body carries only integers — no facility name, no timestamps, no guest data
**And** `TelemetryService.scanToSubmit(correctionsCount: C, success: true)` is emitted per successful entry (already wired in Story 6.5; Closure screen does NOT re-emit)

**Given** the Closure screen must not be reachable by direct navigation manipulation
**When** `go_router`'s redirect is evaluated
**Then** entering `/closure-summary` without a valid `SendAllResult` in Riverpod state (e.g., a deep-link or a route manipulation) redirects to `/home`
**And** no "empty closure" placeholder is rendered

**Given** the host receives a phone call or backgrounds the app on the Closure screen
**When** they foreground later
**Then** the Closure screen is still visible (state persists)
**And** the opportunistic auth check from Epic 2 Story 2.6 runs silently in the background
**And** "Gotovo" still returns to Home cleanly

**Given** integration tests cover the full path
**When** a Send All test fires with 4 unsent guests, all succeeding
**Then** the final scene assertion is the Closure screen with `guestCount: 4`, `facilityName: <fixture>`, variant `AllSuccess`
**And** the test also verifies the navigation skipped the review screen

**Given** an integration test covers 4 guests, 1 failure, host retries and fixes it
**When** the full flow runs
**Then** the scene transitions are: Home → SendAll loop → Review (1 failure) → edit → retry → Closure (4 success, AllSuccess variant)
**And** the Closure count is `4`, not `3 + 1` — it reflects the final state

---

## Epic 8: Privacy Transparency & Data Wipe

The host sees exactly what is currently stored on their device (unsent queue count + recently-submitted count within 3-day retention), with live links to the Privacy Policy and Terms of Service, and can trigger a complete one-action wipe of every byte of local data via typed-confirmation.

### Story 8.1: "Your Data" Screen with Live Counts & Policy Links

As a host handing my phone to a guest, spouse, or tax inspector,
I want to see at a glance exactly what passport data — if any — is currently on the device and when it will self-delete,
So that the zero-retention promise is not a marketing claim but a screen I can show people.

**Acceptance Criteria:**

**Given** the "Your Data" screen is implemented
**When** `lib/features/settings/your_data_screen.dart` is reviewed per UX-DR22
**Then** it is a `ConsumerWidget` routed at `/your-data` reachable from the Settings screen via a `ListTile` labeled "Tvoji podaci"
**And** it watches `queueNotifierProvider` so counts update live

**Given** the header explains the zero-retention promise
**When** the screen renders
**Then** a top section shows the Croatian explanation: "Tvoji podaci ostaju samo na ovom telefonu i šalju se isključivo eVisitoru. 3 dana nakon prijave sve se automatski briše."
**And** the text uses `AppLocalizations` (no literal strings)

**Given** live counts from `QueueSnapshot`
**When** rendered
**Then** a card shows "Neposlani gosti: {count}" with icon `Symbols.outbox` (or similar Material Symbols rounded)
**And** a second card shows "Poslani (unutar 3 dana): {count}" with icon `Symbols.schedule`
**And** if `submitted > 0`, a third line shows "Najstariji će biti obrisan za {N}h" with `N` computed from the minimum `purgeAfter` across submitted entries
**And** counts refresh without navigation — watching the provider drives the rebuild

**Given** the host taps either count card
**When** the action fires
**Then** it routes to Home where the queue list already shows entries — no separate listing screen is built for Your Data (single source of truth)
**And** the cards are accessible with TalkBack announcing count + meta

**Given** policy links are first-class
**When** rendered
**Then** two `ListTile`s at the bottom show "Pravila privatnosti" and "Uvjeti korištenja" with a leading external-link icon
**And** tapping either opens `https://prijavko.hr/privacy` or `https://prijavko.hr/terms` via `url_launcher` in the system browser (external — not an in-app WebView)
**And** if `url_launcher` fails (rare on Android), a SnackBar shows "Ne mogu otvoriti preglednik — provjeri vezu"

**Given** the screen must not leak PII
**When** rendered
**Then** no guest name, document number, or any `GuestFields` value appears — only integer counts and aggregate purge countdown
**And** a widget test seeds the queue with fixtures containing known PII strings and asserts `find.text(doc)`, `find.text(firstName)` return zero matches

**Given** the Delete-All affordance from Story 8.2
**When** rendered
**Then** a destructive `FilledButton` in error color with label "Obriši sve podatke" sits at the bottom action zone
**And** the button uses the standard 56dp min-height and is visually separated from the informational cards above

**Given** accessibility
**When** TalkBack navigates the screen
**Then** order is: header explanation → count cards → policy links → destructive button
**And** each count card announces "Neposlani gosti: {count}, dodirni za detalje"
**And** the destructive button is clearly announced as destructive with Croatian semantics label "Obriši sve podatke, destruktivna akcija"

**Given** dark and light mode goldens
**When** golden tests run
**Then** goldens exist for empty-queue state (both counts 0), mid-range state (3 unsent, 5 submitted), full-saturation state (40 unsent, 20 submitted), and the aggregate-purge-countdown edge case
**And** tests × dark/light themes

---

### Story 8.2: One-Action Delete-All via TypedConfirmationDialog

As a host selling my phone, handing it off, or resolving a privacy complaint,
I want to erase every byte of guest data, cookies, and credentials from the device in a single confirmed action,
So that GDPR's right-to-erasure is trivially satisfied and I can verify clean state post-wipe.

**Acceptance Criteria:**

**Given** the Delete-All entry points are wired
**When** the host taps "Obriši sve podatke" from `your_data_screen.dart` (Story 8.1) OR from the Settings root screen
**Then** `TypedConfirmationDialog` from Epic 5 Story 5.8 is invoked with `requiredWord: 'OBRIŠI'`, `title: "Obriši sve podatke"`, `body: "Ovo će obrisati sve neposlane goste, prijavljene goste u roku od 3 dana, podatke za prijavu i kolačiće. Objekti će biti obrisani, ali ne i tvoj eVisitor račun. Upiši OBRIŠI za potvrdu."`
**And** Cancel leaves all data intact

**Given** the host types "OBRIŠI" and taps confirm
**When** the action fires
**Then** the dialog transitions to `executing`
**And** `HapticFeedback.heavyImpact()` fires
**And** the same hard-wipe routine from Epic 5 Story 5.8 runs in the exact same order: 1) `GuestEntriesTable.deleteAll()`, 2) `FacilitiesTable.deleteAll()`, 3) cookie-jar file deletion, 4) `CredentialStore.wipeCredentials()`, 5) `SecurityService.rotateKey()`, 6) `activeFacilityProvider` reset
**And** each step is awaited sequentially — partial wipe is visible as a failure state, not silently glossed over
**And** code is shared with Story 5.8 — the only difference is the `requiredWord` and the dialog copy

**Given** the wipe completes
**When** every step succeeded
**Then** the app force-restarts routing to UMP/CMP consent → Welcome → Login (same as Replace-Active-OIB)
**And** the `your_data_screen.dart` is never re-visible to the pre-wipe user until they complete onboarding again
**And** the Play Store Data Safety declaration "user can request data deletion" requirement is fulfilled by this flow

**Given** the wipe fails partway (e.g., Keystore access denied)
**When** the failure is detected
**Then** the dialog shows Croatian error "Brisanje nije u potpunosti uspjelo — pokušaj ponovno"
**And** subsequent taps of "Obriši sve podatke" retry from the failed step (idempotent deletes — deleting an already-empty table is a no-op, re-wiping Keystore is a no-op)
**And** no forced restart occurs until the wipe is fully successful

**Given** diacritic-aware match (shared with Story 5.8)
**When** a unit test covers input normalization
**Then** "obriši", "OBRIŠI", "Obriši", "obrisi", "OBRISI" all match (case-insensitive + diacritic-aware); "OBRI" (too short) and "OBRIŠII" (extra) do not match

**Given** telemetry at wipe time
**When** the wipe completes
**Then** NO telemetry event is emitted — the app cannot emit after wiping since Crashlytics `installationId` remains but all host-context is gone
**And** Crashlytics installation remains (Firebase generates a new one post-restart) — there is no way to "rewind" to pre-wipe and no need to (the whole point is erasure)

**Given** Settings has a clear information architecture
**When** the Settings root screen is reviewed
**Then** the destructive actions are grouped at the bottom in a red-header "Opasna zona" section containing: Zamijeni aktivni OIB (Epic 5 Story 5.8) + Obriši sve podatke (this story)
**And** the two actions use the same `TypedConfirmationDialog` widget with different `requiredWord`s
**And** a widget test verifies neither action can be invoked with a simple button tap — both require typed confirmation

**Given** accessibility
**When** TalkBack explores the destructive section
**Then** the "Opasna zona" header is announced as such
**And** each destructive action's Semantics label includes the word "destruktivna"
**And** the TypedConfirmationDialog's input field announces "Upiši OBRIŠI za potvrdu, trenutno onemogućeno" until exact match

**Given** integration test covers the full flow
**When** a seeded app state (credentials + 3 facilities + 5 unsent + 2 submitted) runs Delete-All
**Then** post-wipe the app is on UMP consent screen
**And** Drift queries return empty tables
**And** Keystore reads return null
**And** cookie-jar file does not exist on disk
**And** a second launch re-initializes all primitives from scratch — no residual state carries over

---

## Epic 9: Observability & Forced-Update Safety Net

Solo-dev (Darko) can measure the reliability thesis in production — submission success rate, session-dead recovery rate, queue-stuck-24h count, crash-free session rate — without any guest or credential data leaving the device. When the eVisitor contract breaks, the host sees a forced-update banner and Send All is blocked until the app is updated (never silent data corruption).

### Story 9.1: AppLogger Facade & Type-Level PII Discipline

As a developer,
I want a log facade that makes it impossible to accidentally log a guest object or PII field at compile time,
So that the zero-PII promise is architecturally enforced — not a runtime vigilance task that will drift as the codebase grows.

**Acceptance Criteria:**

**Given** the log facade is implemented
**When** `lib/core/logging/app_logger.dart` is reviewed
**Then** it declares `class AppLogger` with static methods: `static void debug(String message, {String? tag})`, `static void info(String message, {String? tag})`, `static void warn(String message, {String? tag})`, `static void error(String message, {String? tag, Object? error, StackTrace? stackTrace})`
**And** every `message` parameter is typed `String` — there is NO `Object` overload that would silently call `.toString()` on a PII object
**And** `error.error` accepts `Object?` only for exception chaining; the error's `toString` is only logged if the error is a known safe type (e.g., `DioException` summary without response body), otherwise it is logged as `'[REDACTED error type=${e.runtimeType}]'`

**Given** the file has a top-of-file `why` doc comment
**When** reviewed
**Then** the comment explains the Poka-yoke constraint: "Any `Object` param would defeat compile-time PII safety; strings must be constructed explicitly at call sites — never from `.toString()` on a model"

**Given** every PII-bearing model overrides `toString`
**When** Epic 4 `GuestFields`, Epic 5 `GuestEntry`, and any future model carrying document/identity fields is reviewed
**Then** `toString()` returns `'[REDACTED type=${runtimeType} id=${identity}]'` where `identity` is a non-PII surrogate (UUID for `GuestEntry`, no identity for `GuestFields` which gets `'[REDACTED type=GuestFields]'`)
**And** equality (`==`) never compares PII field values — only the client UUID
**And** a code-review checklist item enforces this rule for any new model added

**Given** the CI grep guard from Epic 1 Story 1.1
**When** this story audits the pattern
**Then** the regex pattern is verified to catch: `(print|debugPrint|AppLogger\.\w+)\(.*\.(documentNumber|firstName|lastName|dateOfBirth|nationality|documentExpiry|mrzLine1|mrzLine2|personalNumber|apartmentRegistrationNumber)`
**And** the regex is tested against a `test/fixtures/pii_guard_violations.dart` file containing intentionally-bad patterns that the CI must catch
**And** the regex is tested against a `test/fixtures/pii_guard_pass.dart` file containing acceptable patterns (e.g., `AppLogger.debug('Guest count: $count')`) that must NOT false-positive

**Given** transitive dependency logging is a compliance risk
**When** NFR-S11 is executed as part of this story
**Then** release builds disable verbose Dio request/response logging (verified by inspecting `dioProvider` factory — no `LogInterceptor` is added in release)
**And** a pre-submission checklist item "NFR-S11 staging acceptance test" is added to `docs/security/masvs-l1-checklist.md` — this story ships the checklist item; Epic 10 Story 10.X executes it pre-submission

**Given** `flutter_secure_storage`, `dio`, `drift`, `cryptography_flutter` have their own logging
**When** each dependency's verbose output is audited
**Then** a note in `docs/security/transitive-logging-audit.md` documents whether each emits PII under any configuration and how to silence it in release (e.g., `dio_cookie_manager` does not log cookies by default — documented)

**Given** integration tests cover the facade
**When** `app_logger_test.dart` runs
**Then** tests verify: an error with a `GuestEntry` passed as `error.error` is logged as `'[REDACTED error type=GuestEntry]'`, not the full toString; `AppLogger.error('Classifier miss', error: classifierMissErr)` serializes correctly; a `null` tag is handled without concatenation errors

---

### Story 9.2: TelemetryService Singleton (Sole FirebaseCrashlytics Entry Point)

As a solo developer measuring the reliability thesis,
I want a typed, singleton telemetry service that is the ONLY caller of `FirebaseCrashlytics.instance`,
So that every emitted event is compile-time guaranteed zero-PII and a future change to the observability backend is a one-file edit.

**Acceptance Criteria:**

**Given** the telemetry service is implemented
**When** `lib/core/telemetry/telemetry_service.dart` is reviewed
**Then** it declares `class TelemetryService` as a singleton (`TelemetryService.instance`) with a plain-Dart initializer (not a Riverpod provider per Architecture §4)
**And** it holds the only reference to `FirebaseCrashlytics.instance` in the codebase
**And** it exposes exactly these typed methods per Architecture §4:
  - `void scanToSubmit({required int correctionsCount, required bool success})`
  - `void authStateTransition({required String from, required String to})`
  - `void sendAllResult({required int total, required int succeeded, required int failed, int throttleRetries = 0})`
  - `void queuePurge({required int purgedCount})`
  - `void classifierMismatch({required int httpStatus, required String systemMessageHash})`
  - `void queueStuck24h({required int count})`
**And** no method accepts a `String` parameter that could carry free-text from guest records — all are either enums-as-strings for known states or hashes/integers

**Given** `systemMessageHash` is SHA-256
**When** `classifierMismatch` is called
**Then** the caller passes the SHA-256 hex digest of the raw `SystemMessage` computed at call site (the service does NOT accept a raw message)
**And** a helper `TelemetryService.hashSystemMessage(String raw)` is exposed for callers to use consistently
**And** the hash is stable across devices for the same input — enabling Crashlytics aggregation of "same unknown error across N hosts"

**Given** Firebase Crashlytics is initialized per app launch
**When** `main.dart` calls `TelemetryService.instance.init()`
**Then** `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode)` is called (debug builds don't pollute production dashboards)
**And** Dart symbolication is configured per the `--split-debug-info=build/symbols/` build flag from Epic 1 Story 1.1
**And** a `customKey` allowlist is documented in the telemetry service's doc comment: `ci_build_number`, `evisitor_env`, `min_version_at_launch` — no other keys are set

**Given** the anti-pattern is enforced
**When** any other file references `FirebaseCrashlytics.instance` directly
**Then** the CI grep rule fails the build
**And** the Anti-Pattern Reference table documents "FirebaseCrashlytics.instance outside TelemetryService" → "TelemetryService.instance.methodName(...)"

**Given** each typed method has unit tests
**When** `telemetry_service_test.dart` runs
**Then** each method is called with fixtures and the mocked `FirebaseCrashlytics` records the custom event with expected shape
**And** a test seeds a `SystemMessage` string, calls `hashSystemMessage`, and asserts the hash matches a committed expected value
**And** a test verifies that NO method signature exposes a `String` parameter for free-text content

**Given** telemetry is non-blocking
**When** any method is called
**Then** the method does not await Crashlytics (Crashlytics events are fire-and-forget)
**And** a slow Crashlytics network does not block any UI thread

**Given** release-build observability
**When** the release AAB is built from Epic 1's `build_aab.yml` workflow
**Then** the symbols artifact is uploaded as part of the same workflow so Crashlytics can symbolicate Dart stacks
**And** a README note documents the manual step (if any) to upload symbols to Firebase post-build — if automated via `firebase-tools`, it's in the workflow

---

### Story 9.3: Telemetry Call-Site Wiring Across Epics 1–8

As a developer,
I want every relevant call site across the app wired to emit the correct `TelemetryService` event with zero-PII payloads,
So that the reliability thesis is actually measured in production — not just "planned for."

**Acceptance Criteria:**

**Given** this is a retroactive wiring sweep across prior epics
**When** the story is executed
**Then** no new product features are introduced
**And** every call site added references an existing event method from Story 9.2

**Given** Epic 2 auth transitions
**When** `AuthNotifier` transitions between any two states
**Then** `TelemetryService.instance.authStateTransition(from: ..., to: ...)` is called with the variant names as `String` (e.g., `'reauth'`, `'authenticated'`, `'lockedOut'`)
**And** NO `AuthState` payload or `DioException` body accompanies the event — variant name only

**Given** Epic 4 capture → Epic 5 queue commit
**When** a guest successfully lands in the queue
**Then** `scanToSubmit` is emitted at the START of the scan (capture service) with `correctionsCount: 0` and `success: true` (the "submit to queue" success)
**And** the `correctionsCount` represents the count of manual field corrections made via edit before queue commit (Epic 4 Story 4.8 review mode or Epic 5 Story 5.6 edit flow) — tracked in a per-entry counter on the notifier state
**And** a separate `scan_to_submit` with `success: false` is emitted if the guest is deleted from queue before Send All (per NFR-R2 "first-time submission success rate without corrections")

**Given** Epic 5 auto-purge
**When** `QueueNotifier.runAutoPurge()` deletes rows
**Then** `queuePurge(purgedCount: N)` is emitted once per purge run (even if N == 0, for production visibility of purge-runs)

**Given** Epic 6 Send All completion
**When** `SendAllNotifier` reaches `phase: complete` or `phase: aborted`
**Then** `sendAllResult(total: N, succeeded: S, failed: F, throttleRetries: T)` is emitted
**And** the event fires once per Send All session, never per guest

**Given** Epic 2 classifier encounters `contractBreak`
**When** the classifier returns `contractBreak`
**Then** `classifierMismatch(httpStatus: code, systemMessageHash: hash)` is emitted
**And** this feeds into Story 9.4's forced-update decision (the event is the canary signal)

**Given** the wiring is complete
**When** an integration test exercises the full happy path (install → login → scan 4 guests → Send All → Closure)
**Then** Crashlytics (mocked) receives: 1× `authStateTransition(initial→authenticated)`, 4× `scanToSubmit(0, true)`, 1× `sendAllResult(4, 4, 0, 0)`, 0× `classifierMismatch`, 0× `queueStuck24h`
**And** an integration test exercising the auth-dead recovery path (Journey 3) additionally fires `authStateTransition(authenticated→reauth)`, `authStateTransition(reauth→authenticated)`

**Given** NFR-R3 peak-season silent-failure rate = 0
**When** the classifier's exhaustive coverage is audited
**Then** every `classifierMismatch` event in production gets manually triaged by the solo-dev within 48h during peak season
**And** a manual-triage checklist in `docs/operations/classifier-triage.md` documents the runbook (inspect hash in Crashlytics → investigate request → patch classifier if needed → ship point release)

---

### Story 9.4: MinVersionChecker & ForceUpdateBanner (Contract-Break Safety Net)

As a host whose app version is incompatible with a breaking eVisitor change,
I want the app to block Send All and tell me to update before I discover the problem the hard way,
So that a silent API-contract break never causes a lost or double-submitted guest.

**Acceptance Criteria:**

**Given** the checker is implemented
**When** `lib/features/version_gate/min_version_checker.dart` is reviewed
**Then** it exposes `Future<MinVersionResult> check()` that polls `https://prijavko.hr/min-version.json` via Dio
**And** the response is expected as `{ "minSupportedVersion": <int> }` matching the `versionCode` strategy from Architecture §5 (`v1.0.0 → 10000`, `v1.0.1 → 10001`)
**And** the check runs on cold start from `main.dart` after `SecurityService.init()` but before any UI render
**And** timeout is 3s; on failure, the check is treated as a no-op (benefit of the doubt — offline launches must still work)

**Given** cert pinning is extended to cover `prijavko.hr`
**When** Dio is constructed
**Then** `CertPins.validFingerprints` includes the SHA-256 leaf + intermediate for `prijavko.hr`
**And** the `badCertificateCallback` accepts both `www.evisitor.hr` and `prijavko.hr` (explicit allowlist, not a wildcard)
**And** `docs/security/cert-pins.md` documents both sets

**Given** the check returns `currentBuild < minSupportedVersion`
**When** the result is evaluated
**Then** `ForceUpdateState.required` is emitted via a `forceUpdateProvider`
**And** `ForceUpdateBanner` surfaces as a `ShellRoute` overlay at the TOP priority (above `CredentialBanner`)
**And** Send All is blocked — `SendAllNotifier.sendAll()` pre-flight (Epic 6 Story 6.4) checks `forceUpdateProvider` and aborts with `phase: aborted, reason: forceUpdateRequired` if active

**Given** the check returns `currentBuild >= minSupportedVersion`
**When** the result is evaluated
**Then** `ForceUpdateState.notRequired` is emitted
**And** no banner surfaces; Send All proceeds normally

**Given** the banner is implemented
**When** `lib/widgets/force_update_banner.dart` is reviewed
**Then** it extends `MaterialBanner` (like `CredentialBanner` in Epic 2) but uses `error` red (not warning amber — this is a hard block, not a soft warning)
**And** the message reads "Verzija aplikacije je zastarjela. Ažuriraj u Trgovini Play kako bi nastavio slati prijave."
**And** the trailing action "Ažuriraj" opens the Play Store listing via `url_launcher` (`market://details?id=hr.prijavko.prijavko`)
**And** the banner is NON-dismissible (no secondary dismiss action — unlike `CredentialBanner`)
**And** scan / queue / settings / "Your Data" flows remain accessible — ONLY Send All is blocked

**Given** stack priority per UX spec §Modal and Overlay Patterns
**When** both `ForceUpdateBanner` and `CredentialBanner` would be visible simultaneously
**Then** only `ForceUpdateBanner` renders (hide-other-banner rule)
**And** `AdBanner` is also hidden — force-update is top priority
**And** a widget test verifies this simultaneity constraint

**Given** `classifierMismatch` events from Story 9.3 are the solo-dev's signal
**When** the Crashlytics dashboard shows a spike in `classifierMismatch` events with the same `systemMessageHash`
**Then** the solo-dev inspects, patches the classifier, and ships a point release
**AND** once enough hosts have upgraded, the solo-dev manually pushes an updated `min-version.json` to `prijavko.hr` bumping `minSupportedVersion` — forcing laggards to update before they can submit
**And** this manual workflow is documented in `docs/operations/contract-break-response.md`

**Given** the host has no network on cold start
**When** the MinVersionChecker fails to reach `prijavko.hr`
**Then** the check is skipped silently (no banner, no error)
**And** Send All remains available (benefit of the doubt — blocking on offline would kill the offline-first promise)
**And** the check retries on the next cold start

**Given** integration tests cover the force-update path
**When** the Dio fake serves a `min-version.json` with `minSupportedVersion: 99999`
**Then** the banner surfaces, Send All is blocked, and tapping "Ažuriraj" invokes `url_launcher` with the correct Play Store intent
**And** when the fake serves `minSupportedVersion: 1`, the banner does not surface

---

### Story 9.5: queue_stuck_24h Tripwire Emission on App Open

As a solo developer monitoring production,
I want the app to emit a telemetry event whenever any queued guest has been waiting more than 24 hours,
So that I can see — in aggregate, zero-PII — whether hosts are missing the 24-hour legal registration window and fix the cause before fines accumulate.

**Acceptance Criteria:**

**Given** the tripwire runs at app entry
**When** the app cold-starts OR transitions to `AppLifecycleState.resumed`
**Then** a background check queries `GuestEntriesTable WHERE state IN ('unsent', 'in_flight_unresolved') AND clientCreatedAt < now() - Duration(hours: 24)`
**And** if `count > 0`, `TelemetryService.instance.queueStuck24h(count: N)` is emitted
**And** if `count == 0`, no event is emitted

**Given** the tripwire is telemetry-only per PRD §Observability
**When** the result is non-zero
**Then** NO user-facing local notification, push, or in-app banner is shown
**And** no foreground service is started (violates explicit-Send-All and no-background-worker principles)
**And** the event goes only to Crashlytics aggregate dashboards

**Given** NFR-R4 targets `queue-stuck count = 0 on every host's device at every app open`
**When** production data shows persistent non-zero events from a specific `installationId` pattern
**Then** the solo-dev investigates via the classifier-triage runbook
**And** common root causes to investigate are documented: perpetual credential-invalid state, contractBreak blocking Send All, forgotten unsent entries during off-season storage

**Given** the tripwire runs on the main isolate (like auto-purge from Epic 5 Story 5.7)
**When** the stuck-check query executes
**Then** the query uses the `(facilityId, state)` composite index from Story 5.1 for fast filtering
**And** the query completes in <20ms on a 1000-row fixture

**Given** the tripwire is idempotent
**When** the app foregrounds multiple times in a 24h window with the same stuck count
**Then** the event may emit multiple times (that is acceptable — aggregate view sees the trend, not per-device counts)
**And** a comment in the code documents that de-duplication is NOT performed locally (Crashlytics handles aggregation)

**Given** integration tests cover the tripwire
**When** a test seeds 3 unsent entries with `clientCreatedAt: now - 25h` and 1 entry with `clientCreatedAt: now - 23h`
**Then** `queueStuck24h(count: 3)` is emitted (only the 3 truly stuck ones, not the 1 recent)
**And** when all are purged or submitted, the next app-open emits nothing

**Given** the tripwire does not interfere with auto-purge
**When** the app foregrounds with some stuck entries AND some ready-to-purge entries
**Then** Epic 5 Story 5.7's auto-purge runs first, Story 9.5's tripwire runs after (sequential on main isolate)
**And** both complete within the warm-resume 1s p95 budget (NFR-P9)

---

## Epic 10: Monetization & Launch Readiness

Host installs a Play-Store-listed v1.0 with ad-supported free tier active on Home (never during scan/Send All/credential banner/closure), reliability-thesis copy in the listing, Data Safety declaration accepted by Play Store manual review, all sensitive-data compliance artifacts (Privacy Policy, ToS, MASVS L1) live before the 2026-05-27 submission.

### Story 10.1: AdBanner Custom Widget

As a solo dev relying on AdMob for v1.0 revenue validation,
I want a single, surgically-placed ad widget that respects every trust-preserving rule in the UX spec,
So that AdMob revenue exists without ever undermining the reliability thesis or intruding on the Closure moment.

**Acceptance Criteria:**

**Given** the widget is implemented per UX-DR16
**When** `lib/widgets/ad_banner.dart` is reviewed
**Then** it is a `ConsumerStatefulWidget` that wraps `google_mobile_ads`'s `BannerAd` using anchored adaptive size (50–100dp, device-responsive)
**And** the file has a top-of-file `why` doc comment explaining the Home-only constraint, no-interstitials decision, and stack-priority rule
**And** it accepts `required AdBannerSlot slot` where `AdBannerSlot` is currently an enum with a single variant `home` — any other variant is a compile error in v1.0

**Given** Home-only placement is a build-time assertion
**When** the widget is mounted in any route other than `/home`
**Then** a `assert(currentRoute == '/home')` fires in debug builds
**And** release builds defensively render nothing (no ad request) if the assertion would have fired
**And** a widget test verifies mounting on `/send-all/review` returns a zero-sized shrink

**Given** the 7 states from UX-DR16
**When** the widget renders per state
**Then** `loading` renders a 50dp transparent container (no spinner — the UX spec prohibits ad skeleton loading to avoid "ads in face" perception)
**And** `loaded_personalized` renders the AdMob-provided banner
**And** `loaded_non_personalized` renders the AdMob-provided banner with `nonPersonalized: true` request extras
**And** `error_collapsed` renders a zero-sized container (fill failure silently collapses)
**And** `disabled_auth_dead` hidden entirely — no request, no render
**And** `disabled_pro_user` hidden entirely (v1.1 placeholder; currently unreachable in v1.0 but the state exists)
**And** `collapsed_by_user` hidden for the current session after the host taps a small "×" dismiss affordance; restores on next cold start

**Given** UMP consent state from Epic 1 Story 1.4 gates personalization
**When** the banner prepares its ad request
**Then** it reads the UMP consent provider (exposed by Story 1.4) and marks the request `nonPersonalized: true` if consent is not granted
**And** no ad request fires if UMP consent has not yet resolved (e.g., a host still on the consent surface)

**Given** stack priority from UX spec §Modal and Overlay Patterns
**When** `CredentialBanner` (Epic 2) OR `ForceUpdateBanner` (Epic 9) is active
**Then** `AdBanner` transitions to `disabled_auth_dead` state and renders nothing
**And** when the blocking banner clears, `AdBanner` returns to `loading` → `loaded_*` on next rebuild
**And** a widget test places both `AdBanner` and `CredentialBanner` in the same scaffold and verifies only `CredentialBanner` is visible

**Given** no ads during Send All flows
**When** `SendAllNotifier.phase` is `preFlight | submitting | throttled`
**Then** `AdBanner` is hidden (watches `sendAllNotifierProvider`)
**And** the widget restores on `phase: complete` (after Closure Summary is dismissed back to Home)

**Given** a small collapse affordance
**When** the host taps the "×" on the banner
**Then** a session-scoped `adBannerCollapsedProvider` flips true
**And** no ad renders for the remainder of this app session
**And** the collapse is NOT persisted across cold starts (fresh chance on each launch per UX spec §8 — "collapsed_by_user" restores on cold start)

**Given** accessibility
**When** TalkBack explores the widget
**Then** the dismiss affordance has a Croatian `Semantics` label "Sakrij oglas"
**And** the ad content itself is managed by AdMob (we don't override its internal semantics)

**Given** no interstitials in v1.0 (UX-DR16 deliberate deviation from PRD permission)
**When** the codebase is searched for `InterstitialAd`, `FullScreenContent`, `RewardedAd`, or any full-screen AdMob format
**Then** no occurrences exist
**And** a PR-review checklist item blocks any future introduction without explicit PRD change

---

### Story 10.2: AdBanner Integration on Home Screen

As a host opening Home,
I want a subtle ad slot between my queue and my CTAs — far from scan/send/closure flows,
So that the app can earn a few cents per session without ever feeling intrusive.

**Acceptance Criteria:**

**Given** the Home screen slot from Epic 5 Story 5.5 is extended
**When** `home_screen.dart` is reviewed post-Story 10.1
**Then** the 16dp spacer placeholder between the queue list and CTA zone is replaced by `AdBanner(slot: AdBannerSlot.home)`
**And** a 16dp `SizedBox` on both sides of the banner preserves gap from queue rows and CTA buttons per UX-DR16

**Given** the content width clamp from Story 5.5
**When** Home renders
**Then** `AdBanner` sits within the 600dp-max content width
**And** the banner is horizontally centered on screens wider than 600dp (tablet)

**Given** widget tests cover ad-placement invariants
**When** `home_screen_test.dart` is extended
**Then** a test scaffolds Home with a `credentialBannerActive` fixture and asserts `find.byType(AdBanner)` finds widget but `find.byType(BannerAd)` finds nothing (Ad is in `disabled_auth_dead` state)
**And** a test scaffolds Home with `sendAllInProgress` fixture and asserts same
**And** a test scaffolds clean Home and asserts the banner renders (in `loading` state — real AdMob instantiation is out-of-scope for widget tests; real-device validation is manual)

**Given** the ad placement is visually separated from primary actions
**When** a golden test renders Home with a populated queue + ad banner in `loading` state
**Then** the vertical stack is: AppBar → `CredentialBanner` slot (empty) → `QueueHero` → `QueueRow` list → 16dp gap → `AdBanner` placeholder → 16dp gap → CTA zone
**And** the golden asserts pixel-perfect spacing

**Given** the host backgrounds the app during `AdBanner.loading`
**When** they resume
**Then** the banner restarts its load cycle (per AdMob SDK default)
**And** no stale ad is shown

**Given** the host taps an ad
**When** the AdMob SDK opens the advertiser's landing
**Then** the app is backgrounded (system default behavior)
**And** when the host returns, Home is in the same state (queue preserved, facility still active)

---

### Story 10.3: OWASP MASVS L1 Self-Audit Checklist

As a solo dev preparing for Play Store sensitive-data manual review,
I want a documented OWASP MASVS L1 checklist that I work through before submission,
So that I can defend the security posture to a manual reviewer with a live, signed artifact.

**Acceptance Criteria:**

**Given** the checklist is drafted per NFR-S9
**When** `docs/security/masvs-l1-checklist.md` is reviewed
**Then** it covers all 8 MASVS categories: V1 Architecture, V2 Data Storage & Privacy, V3 Cryptography, V4 Authentication & Session Management, V5 Network Communication, V6 Platform Interaction, V7 Code Quality, V8 Resilience
**And** each category has explicit `[ ]` checkboxes per requirement with a reference to the prijavko story/file that satisfies it

**Given** specific high-risk items
**When** each is documented
**Then** V2 Data Storage references: Drift AES-GCM column encryption (Story 5.1), Keystore-backed credentials (Story 1.3), AES-GCM cookie jar (Story 1.3), `allowBackup=false` (Story 1.1), zero-PII logs (Story 9.1)
**And** V3 Cryptography references: AES-GCM via `cryptography_flutter`, Keystore-wrapped keys, `SecurityService.rotateKey()` on Replace-Active-OIB
**And** V4 Authentication references: sealed-class FSM (Story 2.1), `QueuedInterceptor` serialization (Story 2.3), circuit breaker (Story 2.5), cert pinning (Story 1.3)
**And** V5 Network references: HTTPS-only via `network_security_config.xml` (Story 1.1), SHA-256 cert pinning for `www.evisitor.hr` and `prijavko.hr` (Stories 1.3 + 9.4)

**Given** NFR-S11 staging acceptance test is part of this checklist
**When** the test is executed pre-submission
**Then** a debug build in staging triggers an intentional crash in a code path that handles a fixture `GuestEntry` (e.g., via a hidden dev-menu "Trigger Test Crash" action compiled only in debug)
**And** the Firebase Crashlytics Console output is manually inspected for any appearance of: document numbers, names, raw `SystemMessage`, cookies, credentials, Keystore keys
**And** if any leakage is found, the build is blocked until fixed; if none, the checklist item is checked
**And** a screenshot of the cleaned Crashlytics event is committed to `docs/security/nfr-s11-evidence/` as submission evidence

**Given** transitive-dependency logging audit from Story 9.1
**When** the checklist references it
**Then** `docs/security/transitive-logging-audit.md` is listed as a required-before-submit artifact
**And** each dependency's logging posture is verified for release builds (Dio logs disabled, Drift logs suppressed, cryptography_flutter default, flutter_secure_storage no verbose logging)

**Given** the checklist must be actually executed, not just authored
**When** pre-submission readiness is assessed
**Then** every `[ ]` has been flipped to `[x]` with an inline note of evidence location (file path or screenshot ref)
**And** the completed checklist is a blocker for Story 10.6 (Play Store submission)
**And** the Git commit that completes the checklist has message `feat: OWASP MASVS L1 self-audit passed — ready for sensitive-data review`

---

### Story 10.4: Privacy Policy & ToS Static Pages Published

As a host reading the app's onboarding,
I want to click "Pravila privatnosti" or "Uvjeti korištenja" and reach an actual, readable Croatian-primary page that matches what the app does,
So that my informed consent is real and the Play Store sensitive-data review has a URL it can verify.

**Acceptance Criteria:**

**Given** the static pages are drafted
**When** `prijavko.hr/privacy` (Croatian primary, English section below) is reviewed
**Then** it covers in plain Croatian: what data is collected (passport/MRZ, camera frames, eVisitor credentials), where each data flows (device → eVisitor only; no third-party except Crashlytics for zero-PII telemetry + AdMob for ads with UMP-gated personalization), retention (3-day soft-undo buffer post-submission then hard-delete), lawful basis (GDPR Art. 6(1)(c) legal obligation under Croatian tourism law — host is the controller, prijavko is a data processor only for the transient moment of transport to eVisitor), host rights (access/rectification trivially via eVisitor portal; erasure via Delete-All in Settings within 3 days), cross-border (none — all traffic is device → eVisitor HR; Crashlytics US is covered by Firebase SCCs), DPIA posture (not controller for guest data; each host is)
**And** the page is a single static HTML file hosted on whatever static-hosting stack `prijavko.hr` uses (GitHub Pages, Netlify, Vercel, or equivalent — zero backend)
**And** the page is publicly accessible with no login, no tracking scripts, no analytics

**Given** the ToS is drafted
**When** `prijavko.hr/terms` is reviewed
**Then** it includes: the liability disclaimer (host is sole legal data controller; fines from app failure are not prijavko's liability per Croatian tourism law); service availability disclaimer (prijavko-the-app is a client; eVisitor outages are not prijavko's fault); ad revenue notice (v1.0 is ad-supported; v1.1 Pro IAP will be optional); governing law (Croatian law, Zagreb jurisdiction); change-of-terms process (in-app notification on next policy update)
**And** the ToS is Croatian-primary with an English section

**Given** onboarding + "Your Data" link to these pages
**When** `welcome_screen.dart` (Story 1.5) and `your_data_screen.dart` (Story 8.1) render their policy/ToS links
**Then** both link to the live URLs via `url_launcher`
**And** an integration test hits both URLs via `http.get` and asserts 200 status with reasonable content length (>1KB — sanity check that the static page isn't empty)

**Given** the pages must exist before Play Store submission
**When** Story 10.6 prepares the Data Safety declaration
**Then** it references the live Privacy Policy URL
**And** the Play Store listing form requires a Privacy Policy URL — this story satisfies that prerequisite
**And** the pages are live and indexed by at least a manual Google search for site verification

**Given** changes to the app's data handling require policy updates
**When** a material change ships (e.g., a new SDK, a new permission)
**Then** the policy pages are updated BEFORE the app ships
**And** a Git-managed history of policy changes lives in the `prijavko.hr` repo (or wherever the static pages are versioned)
**And** the app's in-app UMP/CMP re-prompt is triggered via UMP form-version bump when needed

---

### Story 10.5: prijavko.hr/min-version.json Initial Publish

As the forced-update mechanism from Epic 9 Story 9.4,
I want a live `min-version.json` endpoint to poll from v1.0.0 onward,
So that the mechanism is tested in production from day one and can be bumped at any time to block outdated clients.

**Acceptance Criteria:**

**Given** the endpoint is published
**When** `https://prijavko.hr/min-version.json` is fetched via HTTPS
**Then** the response is `Content-Type: application/json` with body exactly `{"minSupportedVersion": 10000}` (matching v1.0.0's `versionCode` per Architecture §5)
**And** the response has sensible cache headers: `Cache-Control: public, max-age=300` (5-minute edge cache balances cost and responsiveness during a contract-break incident)
**And** the endpoint is served over the same SHA-256 cert set documented in `docs/security/cert-pins.md`

**Given** the MinVersionChecker from Story 9.4 is validated
**When** a staging build runs with `minSupportedVersion: 10000` vs. the app's `versionCode: 10000`
**Then** `MinVersionResult.notRequired` is emitted and no banner surfaces
**And** when staging `min-version.json` is manually bumped to `99999`, the banner surfaces and Send All is blocked
**And** the test is documented in `docs/operations/min-version-test-harness.md`

**Given** the bump workflow for contract-break response
**When** the solo-dev needs to force an update
**Then** `docs/operations/contract-break-response.md` documents the exact steps: 1) investigate classifier-mismatch spike in Crashlytics, 2) identify affected versionCode range, 3) ship a patched AAB to Play Console with bumped versionCode, 4) wait for staged rollout to reach >50% of users on the new version, 5) edit `min-version.json` to the new `minSupportedVersion`, 6) commit + deploy the static file, 7) monitor for forced-update banner impressions in Crashlytics
**And** the workflow is rehearsed once in staging before v1.0 submission

**Given** edge cases
**When** the file serves malformed JSON
**Then** `MinVersionChecker` catches the parse error and skips the check (benefit of the doubt)
**And** a `classifierMismatch` event is NOT emitted (this is a self-inflicted bug, not a contract break)
**And** a comment in the checker notes "static file — verify JSON validity on every commit before publish"

---

### Story 10.6: Play Store Data Safety Declaration & Listing Assets

As the solo dev submitting to Play Store,
I want a complete, accurate Data Safety declaration and a Croatian-primary listing with reliability-thesis copy and 6 screenshots,
So that manual review passes on the first try and the listing converts browsing Croatian hosts into installs.

**Acceptance Criteria:**

**Given** the Data Safety declaration is prepared
**When** the Play Console form is completed per PRD §Store Compliance
**Then** it declares: data types collected — camera images (not retained, processed on-device only) + passport data (collected, transmitted to eVisitor only, retained ≤3 days) + host credentials (collected, encrypted at rest in Keystore, not transmitted to third parties)
**And** data sharing — NONE with third parties (eVisitor submission is the service's core purpose, not "sharing"); AdMob receives no guest data; Crashlytics receives no PII
**And** security practices — data encrypted in transit (HTTPS + cert pinning), data encrypted at rest (AES-GCM with Keystore-backed key), user can request data deletion (Delete-All in Settings)
**And** the declaration is saved as a draft in Play Console and reviewed against the Privacy Policy for consistency

**Given** 6 Croatian-language screenshots are produced
**When** the screenshots are reviewed
**Then** they depict: (1) Home screen with queue + facility chip, (2) Scan screen with MRZViewfinder reticle, (3) CaptureConfirmation overlay with "Gost dodan", (4) Send All per-guest progress with glyph transitions, (5) Closure Summary with gold count + share CTA, (6) Your Data screen showing counts + policy links
**And** each screenshot is 1080×1920 or higher per Play Store specs
**And** no real guest PII appears — all screenshots use synthetic fixture names or masked-data renderings
**And** Croatian captions overlay each screenshot with the reliability-thesis messaging per PRD §Executive Summary

**Given** the Play Store listing copy is drafted
**When** the Croatian-primary title, short description, and full description are reviewed
**Then** the title is "Prijavko — eVisitor za iznajmljivače"
**And** the short description emphasizes reliability ("Nikad izgubljena prijava. Nikad tiha greška.") in ≤80 chars
**And** the full description covers: the core promise, the 3-tier capture fallback, the per-guest isolation story, the zero-retention 3-day auto-purge, the offline-first capture, Android-only + Croatian-language scope
**And** category is set to Business (not Travel per PRD §Store Compliance)
**And** content rating is 3+
**And** an English section is included below Croatian for Play Store international surfacing

**Given** the prerequisites from Stories 10.3 + 10.4 + 10.5 are met
**When** the first submission is prepared
**Then** the MASVS L1 checklist from Story 10.3 is `[x]` complete
**And** Privacy Policy + ToS URLs from Story 10.4 are live and verified
**And** `min-version.json` from Story 10.5 is published
**And** the submission package includes all three as references

**Given** the submission is filed
**When** Google Play completes sensitive-data manual review (1–3 weeks expected)
**Then** if rejected, the rejection reason is triaged per `docs/operations/play-review-response.md` runbook (to be drafted as part of this story) and a fix-and-resubmit ships within 48h
**And** if accepted, the build enters the staged rollout per Story 10.8

---

### Story 10.7: Closed Beta Track Setup (2026-05-13 Target)

As the solo dev validating v1.0 with real Croatian hosts,
I want a Closed Testing track with 10 hosts invited and a feedback channel,
So that real peak-season-adjacent feedback shapes the production submission instead of landing after launch.

**Acceptance Criteria:**

**Given** the Closed Testing track is configured in Play Console
**When** the configuration is reviewed
**Then** a Closed Testing track exists with tester email list populated (up to 10 hosts recruited per PRD §Resource Requirements)
**And** the track is promoted-from via the same `build_aab.yml` workflow on the `v1.0.0-beta.1` tag (Epic 1 Story 1.1)
**And** the Play Store opt-in link is generated and ready to share with recruited beta testers

**Given** beta testers must be briefed
**When** the recruitment message is drafted
**Then** it explains: what prijavko does (reliability thesis, not feature list), what to test (their real peak-season guest check-ins when they happen), how to report issues (direct message or email — no in-app feedback surface in v1.0 per PRD), the 3-day auto-purge (so they know data will self-clean), the ad-supported posture (banners on Home only)
**And** the brief is documented in `docs/operations/closed-beta-recruitment.md`

**Given** the beta runbook exists
**When** `docs/operations/closed-beta-triage.md` is reviewed
**Then** it documents: the solo-dev's daily check of Crashlytics for beta-cohort events; response SLA (within 24h of reported issue); the decision tree for fix-and-ship vs. acceptable-known-issue; the rollback procedure if the beta surfaces a critical bug

**Given** beta metrics are distinct from production
**When** telemetry is inspected during beta
**Then** Crashlytics events are tagged with a `build_type: beta` custom key (per TelemetryService allowlist from Story 9.2)
**And** the tag does NOT persist to production builds (different versionCode, no manual intervention needed)

**Given** the beta target date is 2026-05-13 per PRD
**When** Epic 10 execution is sequenced
**Then** Stories 10.1 → 10.5 are complete by 2026-05-13
**And** Story 10.6's Data Safety declaration is drafted (not yet submitted)
**And** beta runs for ~2 weeks before 2026-05-27 production submission

---

### Story 10.8: Production Submission with Staged Rollout

As the solo dev launching v1.0,
I want a staged production rollout with pre-agreed rollback triggers,
So that a real-device issue affects at most 20% of users before I can stop it, and the kill-criteria checkpoint has a clear decision frame.

**Acceptance Criteria:**

**Given** the production submission is prepared per PRD §Scope Commitments
**When** the 2026-05-27 target date is reached
**Then** the `v1.0.0` Git tag is pushed and `build_aab.yml` produces the signed AAB
**And** the AAB is uploaded to the Play Console Production track with staged rollout enabled
**And** the rollout starts at 20%

**Given** the staged rollout schedule
**When** post-launch monitoring is executed
**Then** day 1–2: 20% rollout — monitor Crashlytics crash-free session rate (target ≥99.5%) and inspect every new crash
**And** day 3–4: if no rollback trigger fired, increase to 50%
**And** day 5–7: if no rollback trigger fired, increase to 100%
**And** each manual rollout increase is gated on a solo-dev review of: crash-free rate, Play Store 1★ review incidence, `classifierMismatch` event volume, beta-tester feedback summary

**Given** rollback triggers are pre-agreed
**When** any of the following is true during the rollout
**Then** the rollout is paused and rolled back:
  - Crash-free session rate < 98%
  - `classifierMismatch` event volume > 5 per 1000 sessions
  - Play Store rating drops below 4.0★ in the first 48h
  - A reproducible PII leak is detected in Crashlytics output (regression of NFR-S11)
**And** rollback is performed via Play Console's halt-rollout action; a fix-and-resubmit ships within 48h

**Given** the kill-criteria checkpoint at 2026-09-30 per PRD §Success Criteria
**When** `docs/operations/kill-criteria.md` is reviewed
**Then** it documents the three triggers: <1,000 installs, OR <3.5 Play Store rating, OR <10% retention at month 3
**And** the runbook for a kill decision covers: announcing sunset via policy page update, pushing a final Play Store update with in-app "Sunset Notice" banner, keeping `min-version.json` stable so existing users can continue using v1.0 until eVisitor changes force an upgrade, eventually unpublishing from Play Store
**And** the kill-criteria review is scheduled in the solo-dev's calendar for 2026-09-30

**Given** success criteria from PRD §Business Success are tracked
**When** monthly post-launch reviews are executed (July, August, September 2026)
**Then** the following are measured: Weekly Active Hosts (target 500 in July), Play Store rating (target 4.5), crash-free rate (target 99.5%), `scan_to_submit` success rate (target 90%)
**And** measurements are recorded in `docs/operations/monthly-metrics.md` with month-over-month diffs
**And** the reviews inform the go/no-go decision at 2026-09-30

**Given** the pre-peak code freeze from PRD is honored
**When** 2026-06-15 is reached
**Then** no new features merge until 2026-09-30 kill-criteria checkpoint
**And** only bug fixes and critical security patches merge during peak season (per PRD §Solo-Dev Operational Posture)
**And** a CI check on the `main` branch enforces the freeze by rejecting non-`fix:` / non-`security:` commits between those dates (via commit-message convention check in a GitHub Action)

---

## Story-to-Requirements Traceability Matrix

_Bidirectional traceability between stories and the requirements inventory. Each story implements one or more FRs, satisfies one or more NFRs, and/or delivers one or more UX-DRs._

### By Story

| Story | Implements FRs | Satisfies NFRs | Delivers UX-DRs |
|---|---|---|---|
| 1.1 Project Bootstrap & CI Foundation | — | NFR-S1, NFR-S6, NFR-C1, NFR-C2, NFR-M1, NFR-I6, NFR-S7 (CI guard) | — |
| 1.2 Design System Foundation | — | NFR-A2, NFR-L1 | UX-DR1, UX-DR2, UX-DR3, UX-DR4, UX-DR5, UX-DR6 |
| 1.3 Security Primitives, Dio & Cert Pinning | — | NFR-S1, NFR-S2, NFR-S3, NFR-S4 | — |
| 1.4 UMP/CMP EU Consent Surface | FR2 | NFR-I6 | — |
| 1.5 Welcome & Sensitive-Data Disclosure | FR3 | NFR-L1, NFR-A2, NFR-A3 | UX-DR17 (Welcome), UX-DR24 |
| 1.6 Camera Permission with Manual-Entry Fallback | FR4 | NFR-L1 | — |
| 1.7 eVisitor Login & Live Credential Verification | FR5, FR6 | NFR-S3, NFR-L3, NFR-I4 | UX-DR17 (Login) |
| 1.8 Session Persistence Across Restarts | FR8 | NFR-R5, NFR-R6 | — |
| 1.9 Credential Re-Entry from Settings | FR7 | NFR-L1 | UX-DR22 (Settings skeleton) |
| 2.1 AuthState Sealed Class & AuthNotifier Skeleton | — | NFR-M2 (no `dynamic`), NFR-R7 | — |
| 2.2 Error Classifier (Pure Function) | FR9 | NFR-I2, NFR-I3, NFR-I4 | — |
| 2.3 QueuedInterceptor with Serialized Re-Auth | FR10 | NFR-R7 | — |
| 2.4 Auto Re-Authentication with Stored Credentials | FR10 | NFR-R6 | — |
| 2.5 Circuit Breaker (3/6-min) | FR12 | NFR-R8 | — |
| 2.6 Opportunistic Auth Check on Foreground | FR13 | NFR-P9, NFR-R3 | — |
| 2.7 CredentialBanner (MaterialBanner Subclass) | FR11 | NFR-A2, NFR-A3, NFR-L1 | UX-DR10, UX-DR32 (stack priority) |
| 2.8 Credentials-Missing Recovery | FR14.5 | NFR-R5 | — |
| 2.9 Auth-State View in Settings | FR14 | NFR-L1, NFR-A3 | UX-DR22 |
| 3.1 Facility Model & Drift Table | — | NFR-S5 (negative — no PII stored), NFR-M5 | — |
| 3.2 Fetch & Cache Facilities on First Login | FR15 | NFR-R9, NFR-I2 | — |
| 3.3 FacilityPickerSheet Custom Widget | — | NFR-A1, NFR-A2, NFR-A3, NFR-L1 | UX-DR11, UX-DR32 (BottomSheet tap-outside = cancel) |
| 3.4 Explicit Per-Session Facility Choice | FR16, FR17 | — | UX-DR11 |
| 3.5 Facility Chip on Home AppBar | FR18 | NFR-A1, NFR-A3 | UX-DR18 (home AppBar) |
| 3.6 Explicit Facility List Refresh | FR19 | NFR-L1 | — |
| 4.1 MRZ Parser & Semantic Sanity Layer (Pure Dart) | FR23 | NFR-P4, NFR-S7 (PII redaction), NFR-M3 | — |
| 4.2 Camera + ML Kit Stream Service | FR20 | NFR-P1, NFR-C4, NFR-C5, NFR-S7 (on-device only, NFR-I6) | — |
| 4.3 MRZViewfinder Custom Widget | — | NFR-A1, NFR-A3 | UX-DR12, UX-DR19 (scan orientation lock), UX-DR28 |
| 4.4 CaptureConfirmation Overlay Widget | — | NFR-A3, NFR-S7 (zero-PII in overlay), NFR-P3 (haptic-before-render ordering) | UX-DR13, UX-DR29 (haptic discipline) |
| 4.5 Scan Screen Assembly with Static-Tap Fallback | FR21 | NFR-P2 | UX-DR19 |
| 4.6 Manual Entry Form (First-Class Path) | FR22 | NFR-A1, NFR-A2, NFR-A3, NFR-A4, NFR-L1 | UX-DR23 |
| 4.7 Inline Croatian Sanity Rejection | FR25 | NFR-L1, NFR-L3, NFR-A3 | UX-DR25 |
| 4.8 Review & Correct Captured Data Before Commit | FR24 | NFR-P4 | UX-DR23 |
| 4.9 May-2026 Mandate Field Behind Feature Flag | FR26 | NFR-I1 (forward-compatible payload) | — |
| 5.1 GuestEntry Model, QueueEntryState Enum & Drift Table | — | NFR-S5, NFR-S7, NFR-S10 | — |
| 5.2 QueueNotifier Single Write Chokepoint | FR27 | NFR-P3, NFR-R5 | — |
| 5.3 GuestStatusGlyph Custom Widget | — | NFR-A2, NFR-A3 (shape + color redundancy) | UX-DR7, UX-DR27 (colorblind safety) |
| 5.4 QueueRow + QueueHero Custom Widgets | — | NFR-A1, NFR-A2, NFR-A3, NFR-A4 | UX-DR8, UX-DR9 |
| 5.5 Home Screen Assembly (Empty + Non-Empty States) | FR28 | NFR-R5, NFR-A1, NFR-C3 | UX-DR18, UX-DR28 (600dp clamp) |
| 5.6 Per-Guest Edit & Delete from Queue | FR29, FR31 | NFR-P10 | UX-DR32 (modal/overlay priority) |
| 5.7 3-Day Auto-Purge on App Open | FR30 | NFR-S10, NFR-R9 | — |
| 5.8 Replace-Active-OIB via TypedConfirmationDialog | FR31.5 | NFR-S7, NFR-L1 | UX-DR15, UX-DR29 (heavy-impact haptic on destructive) |
| 6.1 EvisitorDateCodec | — | NFR-I1, NFR-M5 | — |
| 6.2 ImportTouristsBuilder | — | NFR-I1, NFR-I5 | — |
| 6.3 EvisitorApiClient.importTourists | — | NFR-I1, NFR-I4, NFR-S2 | — |
| 6.4 SendAllNotifier & Pre-Flight Check | FR32, FR33 | NFR-P5, NFR-R9 | — |
| 6.5 Per-Guest Serial Submission Loop | FR34, FR35 | NFR-P6, NFR-R5, NFR-R6 | UX-DR7 (glyph transitions) |
| 6.6 Rate-Limit Throttling with Exponential Backoff | FR36.5 | NFR-I1, NFR-L1 | — |
| 6.7 Send All Results (Review) Screen | FR36 | NFR-A3, NFR-L1 | UX-DR20 |
| 6.8 InFlightReconciler (Path A / Path B) | FR36.6 | NFR-R4, NFR-R5 | — |
| 7.1 ClosureSummary Custom Widget | FR37 | NFR-S7 (zero-PII), NFR-A2, NFR-A4 | UX-DR14 |
| 7.2 ClosureSummary Screen Assembly with Share | FR38 | NFR-L1, NFR-A3 | UX-DR14, UX-DR21, UX-DR29 (selection-click haptic) |
| 7.3 Closure Summary Navigation Wiring | FR37, FR38 | NFR-P7 | — |
| 8.1 "Your Data" Screen | FR39 | NFR-S7, NFR-L1, NFR-A3, NFR-S10 | UX-DR22 |
| 8.2 One-Action Delete-All via TypedConfirmationDialog | FR40 | NFR-S7, NFR-S10, NFR-L1 | UX-DR15 |
| 9.1 AppLogger Facade & PII Discipline | — | NFR-S7, NFR-S8, NFR-S11 | — |
| 9.2 TelemetryService Singleton | FR41 | NFR-S7, NFR-S8, NFR-I6 | — |
| 9.3 Telemetry Call-Site Wiring Across Epics 1–8 | FR41 | NFR-R1, NFR-R2, NFR-R3 | — |
| 9.4 MinVersionChecker & ForceUpdateBanner | FR42 | NFR-I7, NFR-R9, NFR-S2 | UX-DR32 (stack priority: force-update > credential > ad) |
| 9.5 queue_stuck_24h Tripwire Emission | — | NFR-R4, NFR-P9 | — |
| 10.1 AdBanner Custom Widget | — | NFR-A3, NFR-L1 | UX-DR16, UX-DR32 |
| 10.2 AdBanner Integration on Home Screen | — | NFR-C3 | UX-DR16, UX-DR18 |
| 10.3 OWASP MASVS L1 Self-Audit Checklist | — | NFR-S9, NFR-S11 | — |
| 10.4 Privacy Policy & ToS Static Pages Published | — | NFR-S10 (disclosed), NFR-I6 | — |
| 10.5 prijavko.hr/min-version.json Initial Publish | FR42 (operational) | NFR-I7 | — |
| 10.6 Play Store Data Safety Declaration & Listing | — | NFR-S10, NFR-L1, NFR-C3 | — |
| 10.7 Closed Beta Track Setup | — | NFR-R1, NFR-R2 (validation) | — |
| 10.8 Production Submission with Staged Rollout | — | NFR-R1, NFR-M6 | — |

### FR-to-Story Inverse Map (every FR traced to ≥1 story)

| FR | Stories |
|---|---|
| FR1 (linear onboarding flow) | 1.4, 1.5, 1.6, 1.7 (together compose the linear flow) |
| FR2 | 1.4 |
| FR3 | 1.5 |
| FR4 | 1.6 |
| FR5 | 1.7 |
| FR6 | 1.7 |
| FR7 | 1.9 |
| FR8 | 1.8 |
| FR9 | 2.2 |
| FR10 | 2.3, 2.4 |
| FR11 | 2.7 |
| FR12 | 2.5 |
| FR13 | 2.6 |
| FR14 | 2.9 |
| FR14.5 | 2.8 |
| FR15 | 3.2 |
| FR16 | 3.4 |
| FR17 | 3.4 |
| FR18 | 3.5 |
| FR19 | 3.6 |
| FR20 | 4.2 |
| FR21 | 4.5 |
| FR22 | 4.6 |
| FR23 | 4.1 |
| FR24 | 4.8 |
| FR25 | 4.7 |
| FR26 | 4.9 |
| FR27 | 5.2 |
| FR28 | 5.5 (queue visible on Home; persistence itself is in 5.1 + 5.2) |
| FR29 | 5.6 |
| FR30 | 5.7 |
| FR31 | 5.6 |
| FR31.5 | 5.8 |
| FR32 | 6.4 |
| FR33 | 6.4 |
| FR34 | 6.5 |
| FR35 | 6.5 |
| FR36 | 6.7 |
| FR36.5 | 6.6 |
| FR36.6 | 6.8 |
| FR37 | 7.1, 7.3 |
| FR38 | 7.2 |
| FR39 | 8.1 |
| FR40 | 8.2 |
| FR41 | 9.2, 9.3 |
| FR42 | 9.4, 10.5 |

**Result: All 46 FRs are covered by at least one story.**

### UX-DR-to-Story Inverse Map (every UX-DR delivered by ≥1 story)

| UX-DR | Delivered by |
|---|---|
| UX-DR1 (tokens) | 1.2 |
| UX-DR2 (Adriatic Teal + theme builders) | 1.2 |
| UX-DR3 (ThemeExtension<SemanticColors>) | 1.2 |
| UX-DR4 (Manrope + typescale) | 1.2 |
| UX-DR5 (Material Symbols rounded) | 1.2 |
| UX-DR6 (dark-first) | 1.2 |
| UX-DR7 (GuestStatusGlyph) | 5.3, 6.5 |
| UX-DR8 (QueueRow) | 5.4 |
| UX-DR9 (QueueHero) | 5.4 |
| UX-DR10 (CredentialBanner) | 2.7 |
| UX-DR11 (FacilityPickerSheet) | 3.3, 3.4 |
| UX-DR12 (MRZViewfinder) | 4.3 |
| UX-DR13 (CaptureConfirmation) | 4.4 |
| UX-DR14 (ClosureSummary) | 7.1, 7.2 |
| UX-DR15 (TypedConfirmationDialog) | 5.8, 8.2 |
| UX-DR16 (AdBanner) | 10.1, 10.2 |
| UX-DR17 (welcome + login + UMP consent) | 1.4, 1.5, 1.7 |
| UX-DR18 (home 3-state) | 3.5, 5.5, 10.2 |
| UX-DR19 (scan screen with portrait lock) | 4.3, 4.5 |
| UX-DR20 (Send All review screen) | 6.7 |
| UX-DR21 (closure screen) | 7.2 |
| UX-DR22 (settings screen) | 1.9, 2.9, 8.1 |
| UX-DR23 (guest form create/review/edit) | 4.6, 4.8 |
| UX-DR24 (localization / AppLocalizations) | 1.5 (baseline — reinforced across all UI stories) |
| UX-DR25 (eVisitor UserMessage + prijavko hint pairing) | 4.7 |
| UX-DR26 (touch targets, tooltips, semantics) | cross-cutting — reinforced by every widget story with explicit ACs |
| UX-DR27 (WCAG 2.1 AA + shape+color redundancy) | 5.3, 1.2 |
| UX-DR28 (600dp content clamp, textScaler) | 5.5, 4.3 |
| UX-DR29 (haptic discipline) | 4.2, 4.4, 5.8, 7.2 |
| UX-DR30 (button hierarchy, max 2 CTAs) | 1.2 (component theme defaults) + reinforced in every screen story |
| UX-DR31 (no tabs/drawer; nav stack ≤2) | 5.5, 7.2 (nav architecture is inherited from go_router config in 1.1/2.1 redirect) |
| UX-DR32 (modal/overlay stack priority) | 2.7, 3.3, 5.8, 9.4, 10.1 |
| UX-DR33 (golden-test coverage × states × dark/light) | 2.7, 3.3, 4.3, 4.4, 5.3, 5.4, 5.8, 7.1 |

**Result: All 33 UX-DRs are delivered by at least one story.**

### NFR-to-Story Coverage (selected high-criticality NFRs)

| NFR | Stories addressing it |
|---|---|
| NFR-P1 (MRZ auto-shutter ≤1.5s p95) | 4.2 |
| NFR-P2 (static-tap at 3s) | 4.5 |
| NFR-P3 (queue commit ≤300ms, sync before haptic) | 5.2, 4.4 |
| NFR-P4 (sanity ≤50ms p95) | 4.1, 4.8 |
| NFR-P5 (pre-flight ≤1s p95) | 6.4 |
| NFR-P6 (per-guest UI update ≤200ms) | 6.5 |
| NFR-P7 (closure render ≤200ms) | 7.3 |
| NFR-P9 (warm resume ≤1s p95) | 2.6, 9.5 |
| NFR-P10 (40 unsent guests without UI degradation) | 5.6 |
| NFR-S1 to S11 (all security NFRs) | 1.1, 1.3, 4.4, 5.1, 5.8, 7.1, 8.1, 8.2, 9.1, 9.2, 10.3 |
| NFR-R1 to R9 (all reliability NFRs) | 2.5–2.8, 5.5, 5.7, 6.4–6.8, 9.3, 9.5 |
| NFR-I1 to I7 (integration NFRs) | 1.4, 2.2, 2.3, 4.9, 6.1–6.3, 6.6, 9.4, 10.5 |
| NFR-C1 to C5 (compatibility NFRs) | 1.1, 4.2, 5.5, 10.2 |
| NFR-L1 to L4 (localization NFRs) | 1.5, every UI story uses `AppLocalizations` per UX-DR24 |
| NFR-A1 to A4 (accessibility NFRs) | 1.2, 2.7, 3.3, 4.3, 4.4, 4.6, 5.3, 5.4, 5.5, 7.1, 7.2, 8.1, 10.1 |
| NFR-M1 to M7 (maintainability NFRs) | 1.1 (CI), 2.1 (sealed class), cross-cutting via `.claude/rules/` enforcement + 10.8 (code freeze) |

---

## Validation Results

**✅ FR Coverage Validation** — All 46 FRs are covered by at least one story with testable acceptance criteria.

**✅ Architecture Starter Template Validation** — Architecture §2 specifies `flutter create --empty`. Epic 1 Story 1.1 implements this exact command with all flag rationale documented.

**✅ Database/Entity JIT Principle** — `FacilitiesTable` created in Story 3.1 (first story needing facilities); `GuestEntriesTable` created in Story 5.1 (first story needing queue entries). No upfront schema creation.

**✅ Story Quality** — Each story has ACs in Given/When/Then format, is sized for single-dev-session completion, and includes specific acceptance criteria.

**✅ Epic Structure** — All 10 epics deliver user value (Epic 10 is a monetization/launch-readiness epic that while lacking direct FRs still delivers the "ad-supported free tier on Play Store" user outcome).

**✅ Dependency Validation** — Within-epic story dependencies flow forward only (no forward dependencies). Cross-epic dependencies respect the graph: Epic 1 → Epic 2 → Epic 3 → Epic 4 → Epic 5 → Epic 6 → Epic 7; Epic 8/9/10 layer on top. Epic 9 Story 9.3 (telemetry wiring) is explicitly retroactive and depends on Epics 1–8 being implemented first — this is by design, not a violation.

**✅ UX-DR Coverage** — All 33 UX Design Requirements are delivered by at least one story.

**All validations complete!** [C] Complete Workflow
