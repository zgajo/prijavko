---
stepsCompleted:
  - 1
  - 2
  - 3
  - 4
  - 5
  - 6
  - 7
  - 8
lastStep: 8
status: 'complete'
completedAt: '2026-04-14'
inputDocuments:
  - "prd.md"
  - "product-brief-prijavko.md"
  - "product-brief-prijavko-distillate.md"
  - "ux-design-specification.md"
  - "research/technical-android-evisitor-mrz-queue-evisitor-api-research-2026-04-13.md"
  - "research/market-mobile-evisitor-guest-check-in-hr-research-2026-04-13.md"
workflowType: 'architecture'
project_name: 'prijavko'
user_name: 'Darko'
date: '2026-04-14'
appName: 'Prijavko'
stateManagement: 'Riverpod 3.0'
buildFlavors: ['dev', 'prod']
---

# Architecture Decision Document — Prijavko

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (39 total, 9 groups):**

| Group | FRs | Architectural Weight |
|-------|-----|---------------------|
| **Document Capture & Recognition** | FR1–FR5 | Camera pipeline, ML Kit integration, tiered extraction (MRZ/OCR/manual), metadata tracking |
| **Guest Data Review & Editing** | FR6–FR10 | Submission snapshot card (read-only/editable), client-side validation against eVisitor field rules, queue entry deletion |
| **Facility Management** | FR11–FR15 | Multi-profile CRUD, Keystore-encrypted credential storage, session-scoped facility selection, per-facility defaults |
| **Guest Queue & Batch Workflow** | FR16–FR22 | Offline-first local queue, explicit state machine lifecycle, batch send, per-guest retry, 7-day stale purge |
| **eVisitor API Integration** | FR23–FR29 | Cookie-based Forms Auth, XML payload construction, GUID generation for idempotency, transparent re-auth, Croatian error passthrough, conditional fields (non-EU) |
| **Submission History** | FR30–FR32 | 30-day local history with auto-purge, status/timestamp per entry |
| **Consent & Monetization** | FR33–FR35 | AdMob + UMP/CMP for EEA, consent preference management |
| **Onboarding** | FR36 | First-launch detection, guided facility setup |
| **Feedback & Error Communication** | FR37–FR39 | Audio/haptic feedback, Croatian field-level validation, duplicate scan warning (24h) |

**Non-Functional Requirements (31 total, 4 categories):**

| Category | NFRs | Count | Key Constraints |
|----------|------|-------|-----------------|
| **Performance** | NFR1a, NFR1b, NFR2–NFR8 | 10 | MRZ parse <3s, OCR <5s, cold start <5s, 50-guest queue smooth, 15s API timeout, no UI thread blocking |
| **Security** | NFR9–NFR18 | 10 | Keystore encryption, app-private storage, Auto Backup disabled, HTTPS only, image discard after extraction, 30-day purge, FLAG_SECURE, no PII in logs |
| **Integration** | NFR19–NFR24 | 6 | Cookie session management with transparent re-auth, queue survives API errors/crashes, exponential backoff with jitter, ML Kit on-device only, ads non-blocking |
| **Reliability** | NFR25–NFR29 | 5 | ≥99.5% crash-free, state machine recovery after process death, session context restoration, update-safe queue, duplicate submission prevention |

**Scale & Complexity:**

- Primary domain: **Mobile — Android, Flutter, camera + local DB + government REST**
- Complexity level: **Medium-High**
- Estimated architectural components: **~12 major** (capture pipeline, MRZ parser, OCR engine, review/validation, facility manager, credential vault, queue/state machine, eVisitor transport, error mapper, history store, ad/consent manager, onboarding)

### Technical Constraints & Dependencies

| Constraint | Source | Architectural Impact |
|------------|--------|---------------------|
| **eVisitor Forms Auth (cookies)** | API wiki | Persistent cookie jar (Dio + PersistCookieJar), re-auth on 401/redirect, cookies survive process death |
| **XML payloads in JSON wrapper** | API spec | XML builder for `ImportTourists`/`CheckInTourist`; not standard REST — custom serialization layer |
| **ICAO MRZ TD1/TD2/TD3** | Document standards | Parser library (mrz_parser), checksum validation, field extraction limits (no city of birth/residence in MRZ) |
| **ML Kit on-device** | Privacy + offline | No network dependency for capture; bundled model; Text Recognition v2 |
| **Android Keystore** | Security NFRs | Direct Keystore + cipher (not deprecated security-crypto); hardware-backed keys |
| **Flutter framework** | PRD decision | Platform channels for native APIs (camera, Keystore); Dart ecosystem for MRZ parser, Dio, Drift |
| **eVisitor date format** | API spec | `YYYYMMDD` — custom formatting, not ISO 8601 |
| **MUP field length limits** | API spec | Document ≤16, name/surname ≤64 — client-side validation before send |
| **Non-EU conditional fields** | API spec | BorderCrossing + PassageDate mandatory for non-EU guests — conditional form logic |

### Cross-Cutting Concerns Identified

| Concern | Affected Components | Resolution Strategy Needed |
|---------|--------------------|-----------------------------|
| **Process death safety** | Queue, session state, facility context, auth state | Persistent DB for all mutable state; no in-memory-only data on critical path |
| **Credential security** | Facility profiles, eVisitor login, credential display | Keystore encryption, FLAG_SECURE, no autocomplete, backup exclusion |
| **PII handling** | Capture, review, queue, history, crash reporting | Image discard, log scrubbing, 30-day purge, app-private storage |
| **Error mapping (Croatian)** | eVisitor submit, client validation, review card | Centralized error mapper: API `UserMessage` passthrough + client-side Croatian strings |
| **Offline/online transitions** | Queue, send, ads, auth | Queue operational offline; send gates on connectivity; ads load async; auth deferred |
| **State machine consistency** | Queue lifecycle, batch send, crash recovery | Explicit states in DB; transient states (`sending`) recover to last stable on restart |
| **Idempotency** | Guest submission, crash recovery, retry | GUID per guest persisted locally; dedup check before re-send |

## Starter Template Evaluation

### Primary Technology Domain

**Flutter mobile app (Android-only v1)** — camera + on-device ML + local SQLite/Drift + government REST (cookie auth) + ad monetization.

### App Identity

- **User-facing name:** Prijavko
- **Internal project name:** prijavko
- **Package identifier:** `hr.prijavko.app` (adjust domain if you own one)

### Starter Options Considered

| Option | Verdict | Reason |
|--------|---------|--------|
| `flutter create` (standard) | **Selected** | Maximum flexibility; no unwanted opinions; Riverpod + flavors added manually |
| `flutter create -t skeleton` | Rejected | Provider/ChangeNotifier-based (legacy); sample list/detail pattern doesn't map to camera/queue domain |
| Very Good CLI (`very_good_core`) | Rejected | Locks into Bloc; Riverpod chosen as state management; flavor and i18n setup achievable manually |

### Selected Starter: `flutter create` + Manual Architecture

**Rationale:** No existing starter covers the project's domain-specific needs (camera pipeline, MRZ parsing, cookie-based government API, Keystore encryption). The architectural value comes from how custom code is organized, not from a template. Riverpod is the chosen state management — incompatible with VGC's Bloc scaffolding. Build flavors and i18n are straightforward to add manually.

**Initialization Command:**

```bash
flutter create --org hr.prijavko --platforms android prijavko
```

**Post-initialization setup (first implementation story):**
- Add Riverpod, Drift, Dio, build flavors, i18n, linting, test scaffolding
- Establish feature-based folder structure
- Configure Android min/target SDK, permissions, Keystore, backup exclusion

### State Management Decision: Riverpod 3.0

**Why Riverpod over Bloc:**
- Lower boilerplate for solo dev velocity
- Compile-time provider safety via `riverpod_generator`
- Built-in support for async data (API calls, DB queries) via `AsyncValue`
- No event class ceremony — state transitions handled by notifier methods
- Offline persistence patterns available natively
- Modern Flutter 2026 default for new projects

**Queue state machine with Riverpod:** Guest lifecycle (`captured → confirmed → ready → sending → sent/failed`) modeled as a Drift-persisted enum column. Riverpod providers observe DB state reactively (Drift streams → `.watch()` → provider). State transitions are methods on a notifier, not dispatched events — simpler for solo dev, equally testable.

### Build Flavors: Dev (Test API) / Prod

| Flavor | eVisitor API Base | Purpose |
|--------|-------------------|---------|
| **dev** | `https://www.evisitor.hr/testApi` | Development + testing with snapshot data |
| **prod** | `https://www.evisitor.hr` (production) | Release builds for Play Store |

Flavors configured via `--dart-define` or `--dart-define-from-file` at build time. No staging flavor needed for v1 (solo dev, no team environments).

### Architectural Decisions Provided by Setup

**Language & Runtime:**
- Dart (latest stable), strict analysis options
- Null safety enforced
- Strict custom `analysis_options.yaml`

**Project Structure (feature-based):**

```
lib/
├── core/                     # Shared utilities, theme, constants, extensions
│   ├── config/               # Environment config, flavor, API base URLs
│   ├── theme/                # ThemeData, ColorScheme, ThemeExtension (queue semantics)
│   ├── l10n/                 # Croatian + English ARB files
│   └── utils/                # Date formatting (YYYYMMDD), validators, GUID generator
├── features/
│   ├── capture/              # Camera, ML Kit, MRZ parser, OCR, review card
│   ├── queue/                # Guest state machine, queue list, batch operations
│   ├── facility/             # Facility profiles, credential vault, session picker
│   ├── send/                 # eVisitor transport, cookie auth, error mapper, retry
│   ├── history/              # 30-day submission history, auto-purge
│   ├── onboarding/           # First-launch flow, facility setup guide
│   └── settings/             # Ad consent (UMP), preferences
├── data/
│   ├── database/             # Drift database, tables, DAOs, migrations
│   ├── api/                  # Dio client, cookie jar, eVisitor endpoints
│   └── models/               # Shared domain models (Guest, Facility, etc.)
└── main.dart
```

**Database:**
- Drift 2.32+ with WAL mode for crash safety
- Isolate-based queries (Drift threading support)
- Migration strategy for schema evolution across app updates

**HTTP:**
- Dio 5.x + `dio_cookie_manager` + `PersistCookieJar`
- Cookies persisted to app-private filesystem via `path_provider`
- Single Dio instance per app lifecycle

**ML/Capture:**
- `google_mlkit_text_recognition` (on-device, no network)
- `mrz_parser` for ICAO TD1/TD2/TD3 checksum validation
- `camera` plugin for still capture

**Testing Framework:**
- Unit tests: MRZ parser, state machine transitions, error mapper, validators
- Widget tests: review card, queue list, facility picker
- Integration tests: mock eVisitor server with real error shapes, camera with sample documents

### Post-MVP Architectural Anticipation

**Read registered guests from eVisitor (Phase 2 — see PRD):** Current architecture pre-accounts for this: eVisitor transport layer designed with read operations in mind (not write-only), and the `guests` table includes a `source` discriminator (`local` vs `remote`) to accommodate server-sourced records alongside locally captured ones.

**Note:** Project initialization using this command should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Data architecture: Drift table design, validation strategy, error handling pattern
- Authentication: Keystore credential encryption approach
- API communication: eVisitor transport abstraction, retry policy
- Navigation: routing library
- Code generation: unified pipeline

**Important Decisions (Shape Architecture):**
- Logging/observability with PII scrubbing
- Structured analytics events for north-star metric

**Deferred Decisions (Post-MVP):**
- Biometric-gated credential access (BiometricPrompt)
- Remote config / feature flags
- Read-back of registered guests from eVisitor
- Play Integrity API for abuse reduction
- iOS port considerations

### Data Architecture

**Database: Drift 2.32+ (SQLite with WAL)**

Already decided in Step 3. Additional decisions:

**Table Design:**

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `facilities` | Facility profiles | id (PK), name, facilityCode, defaults (JSON: TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, defaultStayDuration) |
| `credentials` | Encrypted credential blobs per facility | id (PK), facilityId (FK), encryptedUsername, encryptedPassword, createdAt |
| `guests` | Queue + history (unified) | id (PK), guid (UUID), facilityId (FK), sessionId (FK), state (enum), captureTier (MRZ/OCR/manual), all eVisitor fields, eVisitorResponse, errorMessage, isTerminalFailure (bool, nullable), createdAt, confirmedAt, submittedAt, source (local/remote) |
| `scan_sessions` | Session metadata | id (PK), facilityId (FK), startedAt, endedAt, guestCount |

**Design rationale:** Guests table doubles as queue (state < `sent`) and history (state = `sent`/`failed_terminal`). Single table avoids duplication — the `state` column + `submittedAt` timestamp partition the data. 30-day purge runs against `submittedAt` for sent guests. 7-day purge against `createdAt` for unsent stale items. `source` column (`local`/`remote`) anticipates Phase 2 read-back from eVisitor.

**Data Validation Strategy:**

| Layer | Responsibility |
|-------|---------------|
| **Domain model constructors** | Poka-yoke guards: field length limits (doc ≤16, name ≤64), required field presence, date format validation. Invalid state cannot be constructed. |
| **Repository layer** | Business rule validation: non-EU requires BorderCrossing/PassageDate, facility assignment required before queue entry, duplicate scan check (24h). |
| **Presentation layer** | Display errors only — never computes validation. Shows `Result.failure` messages from repository. |

**Error Handling Pattern: `Result<T, Failure>` + `AsyncValue`**

- **Data/domain layers:** `Result<T, Failure>` sealed class — makes every failure path explicit at the call site. No silent exception swallowing. `Failure` is a sealed hierarchy: `NetworkFailure`, `AuthFailure`, `ApiFailure(userMessage)`, `ValidationFailure(fields)`, `StorageFailure`.
- **Presentation layer:** Riverpod `AsyncValue<T>` handles loading/error/data tri-state for UI rendering. Providers map `Result.failure` → `AsyncValue.error` with typed failure info preserved.
- **No raw try/catch** except at the outermost boundary (Dio interceptor, platform channel bridge). All internal code uses explicit Result returns.

**Migration Strategy:**

- Drift schema versioning with `MigrationStrategy`
- Each schema change = numbered migration in `onUpgrade`
- Integration test verifies migration from every prior version to current
- NFR28: queue data survives app updates without data loss

### Authentication & Security

**Credential Encryption: `flutter_secure_storage`**

- Wraps Android Keystore natively — AES encryption with Keystore-backed keys
- Battle-tested, community maintained, simpler than raw platform channels
- Stores encrypted username + password per facility profile
- No plaintext credentials in Drift DB or SharedPreferences
- Post-MVP: add `BiometricPrompt` gate before credential access (optional enhancement)

**Security Hardening:**

| Measure | Implementation |
|---------|---------------|
| **FLAG_SECURE** | Applied to credential entry/display screens and guest PII screens (review card, queue detail). Prevents screenshots and recent-apps thumbnails. |
| **Auto Backup exclusion** | `android:allowBackup="false"` or scoped `backup_rules.xml` excluding credential and guest DB files. No sensitive data restored to another device. |
| **Keyboard autocomplete** | Disabled on credential fields (`enableSuggestions: false`, `autocorrect: false`) per NFR15 |
| **PII log scrubbing** | Crashlytics custom keys strip guest names, doc numbers, MRZ data, credential values. Only anonymized funnel events and crash stacks. |
| **HTTPS only** | Dio `BaseOptions` with no HTTP fallback. Certificate pinning deferred (operational burden for solo dev). |
| **Image discard** | Camera image bytes released immediately after ML Kit processing. Only extracted text fields persisted to Drift. No image file written to disk. |

### API & Communication Patterns

**eVisitor Transport Layer:**

```
EVisitorClient (Dio wrapper)
├── AuthService           → login, re-auth, cookie management
├── GuestSubmitService    → CheckInTourist / ImportTourists
├── ErrorMapper           → API UserMessage → Failure with Croatian text
└── (Phase 2) GuestReadService → fetch registered guests
```

- **Repository pattern:** `EVisitorRepository` wraps client calls, returns `Result<T, Failure>`, handles re-auth transparently on 401/redirect
- **Cookie persistence:** `PersistCookieJar` with file storage under `getApplicationDocumentsDirectory()/.cookies/`. Cookies survive process death.
- **XML payload construction:** Dedicated `XmlPayloadBuilder` for ImportTourists/CheckInTourist — isolated, unit-testable, no XML construction in business logic
- **GUID tracking:** Each guest gets a UUID v4 at creation time, persisted in Drift. Sent as `ID` parameter to eVisitor. Used for idempotency, future checkout/cancellation.

**Retry Policy:**

| Parameter | Value |
|-----------|-------|
| **Max attempts per guest** | 3 per manual send action |
| **Backoff** | Exponential with jitter: 1s, 2s, 4s base + random 0–500ms |
| **Retryable codes** | 429, 503, timeout, network error |
| **Non-retryable codes** | 400 (bad data → edit), 401 (re-auth flow), 404 |
| **Terminal failure** | After max attempts → `failed(isTerminal: true)` state with `errorMessage`. User must edit fields and retry manually. Non-terminal failures (network, timeout) remain retryable via `retryGuest()`. |
| **Re-auth on 401** | Detect 401/redirect-to-login → call `AuthService.reAuth()` → replay failed request once. If re-auth fails → `pausedAuth` state on all pending guests via `pauseForAuth()`. After successful re-auth → `resumeAfterAuth()` resets them to `ready`. |
| **Batch behavior** | Sequential per guest (not concurrent). Failure on one guest does not abort remaining batch. Per-guest result tracked independently. |

**Croatian Error Mapping:**

- eVisitor API returns `{SystemMessage, UserMessage}` — `UserMessage` is the Croatian human-readable string
- `ErrorMapper` passes `UserMessage` through directly for API errors (already Croatian)
- Client-side validation errors use Croatian string constants from l10n ARB files
- `Failure.apiFailure(userMessage: "...")` carries the Croatian text to the UI layer unchanged

#### Mock eVisitor Server Contract

**Purpose:** Project-owned Fastify + TypeScript server mirroring the eVisitor REST surface. Used by both the local dev loop (`local.json` via `10.0.2.2:8080`) and the CI compose pipeline (`test.json` via Docker DNS `mock-evisitor:8080`). Never shipped in the app binary.

**Endpoints mirrored:**

| Endpoint | Method | Notes |
|---|---|---|
| `/Login` | POST | Form-encoded `username` + `password`. Sets `ASP.NET_SessionId` cookie on success. Returns 200 OK with session cookie or 401 on bad credentials. |
| `/CheckInTourist` | POST | XML body. Requires valid session cookie. Returns `{SystemMessage, UserMessage}` JSON envelope. |
| `/ImportTourists` | POST | XML body (batch). Requires valid session cookie. Returns array of per-guest `{ID, SystemMessage, UserMessage}`. |
| `/healthz` | GET | Returns 200 `{"status":"ok"}`. Used by compose healthcheck. |

**Scripted response set (fixtures under `test-infra/mock-evisitor/fixtures/`):**

| Fixture | Trigger | Response |
|---|---|---|
| `submit_success.json` | Default happy path | `{SystemMessage: "", UserMessage: ""}` 200 |
| `submit_error_validation.json` | Guest with doc number matching pattern `ERR_VALIDATION_*` | `{SystemMessage: "...", UserMessage: "Putovnica nije važeća."}` 400 |
| `submit_error_duplicate.json` | Guest with pattern `ERR_DUPLICATE_*` | `{SystemMessage: "...", UserMessage: "Gost je već prijavljen."}` 409 |
| `submit_error_session.json` | Request with expired/absent cookie | 401 (or 302 → login HTML body — both must be handled) |
| `submit_error_unavailable.json` | Triggered via `X-Mock-Scenario: unavailable` header | 503 |
| `login_success` | Valid test credentials | 200 + `Set-Cookie: ASP.NET_SessionId=testsession123` |
| `login_failure` | Invalid credentials | 401 |

**Session semantics:**
- Server issues a short-lived cookie (`maxAge: 300s`) — Patrol E2E tests must exercise the re-auth flow naturally by waiting for expiry or sending an `X-Mock-Scenario: expire-session` header.
- Cookie jar must be `PersistCookieJar` backed — mock validates cookie presence, matching real eVisitor behavior.

**API contract validation:**
- Postman MCP used to validate the mock server's response shapes during mock development.
- Contract tests (`test-infra/mock-evisitor/test/`) assert that each fixture returns the correct status code, headers, and `{SystemMessage, UserMessage}` envelope shape.
- These tests run in CI as a pre-check before the E2E job (if mock contract is broken, no point running Patrol).

**What the mock deliberately does NOT implement:**
- Facility lookup / facility list endpoints (Phase 2, not in v1 scope)
- HTML error bodies for all error cases — only `submit_error_session` 302 redirect needs HTML body (testing the `AuthFailure` non-JSON body path)
- Rate limiting (the real eVisitor test API has this; mock removes the constraint for CI determinism)

### Frontend Architecture

**State Management: Riverpod 3.0**

Already decided in Step 3. Additional architecture:

- **Provider organization:** Feature-scoped. Each feature folder contains its own providers. No god-providers.
- **`riverpod_generator`** for compile-time safety on all providers
- **DB reactivity:** Drift `.watch()` streams → `StreamProvider` or `AsyncNotifierProvider` — UI rebuilds when DB changes
- **Guest state machine:** State transitions are methods on `GuestQueueNotifier` (e.g. `confirmGuest()`, `markReady()`, `markSending()`, `markSent()`, `markFailed()`). Each method writes to Drift. Provider observes Drift stream — **single source of truth is always the DB**, never in-memory state alone.

**Navigation: `go_router`**

- Flutter team maintained, declarative routing
- Route guards: redirect to onboarding if no facility profiles exist
- Shell route for bottom navigation (Home, Queue, History, Settings)
- Stack navigation for camera → review → confirm flow
- Predictive back gesture support (Android 14+)

**Immutable Models: `freezed`**

- Domain models (Guest, Facility, ScanSession) defined with `freezed`
- Provides `copyWith`, `==`, `toString`, pattern matching via sealed unions
- `Failure` hierarchy as `freezed` sealed class
- JSON serialization via `json_serializable` where needed (facility defaults)

**Code Generation Pipeline:**

- `build_runner` as unified code gen orchestrator
- Generators: `drift_dev`, `riverpod_generator`, `freezed`, `json_serializable`
- Single `dart run build_runner build` command generates all artifacts
- Generated files in `.g.dart` / `.freezed.dart` — gitignored or committed per team preference (solo: commit for simpler CI)

### Infrastructure & Deployment

**CI/CD: GitHub Actions**

| Trigger | Job | Steps |
|---|---|---|
| Every push + PR | `base-checks` | `flutter analyze` (zero warnings) + `flutter test` with coverage + `dart run build_runner build --delete-conflicting-outputs` verify |
| Every push + PR | `e2e` (depends on `base-checks`) | Containerized Patrol suite via `docker-compose -f docker-compose.e2e.yml up --abort-on-container-exit`. See `### Test Infrastructure & CI Pipeline`. |
| Push to `main` | `coverage-gate` | Fails if combined Dart + mock-server coverage < 70% meaningful (excluding generated files, fixtures) |
| Tag `v*` | `release-build` | `flutter build appbundle --dart-define-from-file=config/prod.json`; uploads AAB artifact |
| Manual | `play-store-upload` | v1: manual Play Console upload. Automated internal track deferred to v1.1. |

**Environment Configuration:**

```
config/
├── local.json  # { "API_BASE": "http://10.0.2.2:8080", "AD_ENABLED": false }
│               # Android Studio AVD → host-side mock server (pnpm dev on host)
├── test.json   # { "API_BASE": "http://mock-evisitor:8080", "AD_ENABLED": false }
│               # compose test-runner → mock-evisitor container (Docker DNS). Never used outside compose.
└── prod.json   # { "API_BASE": "https://www.evisitor.hr",   "AD_ENABLED": true }
```

- `local.json` — daily local development. Flutter app on Android Studio AVD connects via `10.0.2.2` (AVD loopback to host) to the mock server running on the host (`cd test-infra/mock-evisitor && pnpm dev`). No real eVisitor API access required.
- `test.json` — APK built inside `test-runner` container; resolves `mock-evisitor` via Docker service-name DNS. **Never used outside compose.**
- `prod.json` — Play Store release build only.

Run locally: `flutter run --dart-define-from-file=config/local.json`

**Logging / Observability:**

| Layer | Tool | PII Policy |
|-------|------|------------|
| **Crash reporting** | Firebase Crashlytics | No guest names, doc numbers, MRZ, credentials. Anonymized custom keys only. |
| **Analytics** | Firebase Analytics (or lightweight custom) | Funnel events: `capture_tier`, `edit_after_capture`, `send_result`, `first_time_success`. All anonymized. |
| **Debug logging** | `dart:developer` `log()` | Level-tagged. Stripped in release builds via `kReleaseMode` guard. |

**North-star metric instrumentation:** `first_time_success` event fires when a guest goes `captured → confirmed → sent` without field edits between confirm and send. Tracked per guest, aggregated in analytics.

#### Quality Gates

**Test Coverage (≥70% meaningful):**

| Scope | Tool | Excludes |
|---|---|---|
| Dart (app) | `flutter test --coverage` + `lcov` | `*.g.dart`, `*.freezed.dart`, fixture files, `main.dart` |
| TypeScript (mock server) | `vitest --coverage` | fixture JSON files |
| Combined gate | `coverage-gate` CI job on push to `main` | Fails build if either falls below 70% |

"Meaningful" = business logic, state machine transitions, error mapping, validation, transport layer. Generated code and fixtures are noise in coverage metrics and must be excluded.

**Accessibility (Flutter Semantics):**

| Activity | Tool | Cadence |
|---|---|---|
| Semantics tree assertions | `flutter_test` + `find.bySemanticsLabel` | Every widget test — inline, not a separate audit pass |
| TalkBack audit | Manual: TalkBack enabled on Android Studio AVD | Per-epic, pre-release |
| Screen reader announcement | Assert `$.native.tap(Finder)` triggers correct TalkBack output for queue rows, error surfaces, dynamic non-EU fields | Patrol E2E — 1 dedicated a11y journey |

No Lighthouse / axe-core — those are web tools. Flutter a11y is Semantics-tree-first. Every queue row widget test asserts a single coherent `semanticsLabel` (e.g. "Ana Horvat, Apartment Blue, failed, can retry") not fragmented button/icon/text labels.

**Security Review:**

| Activity | Tool | Cadence |
|---|---|---|
| Static analysis | `dart analyze` (zero warnings), `flutter_lints` custom rules | Every commit (CI gate) |
| Dependency audit | `dart pub audit` | On every `pubspec.lock` change |
| AI-assisted code review | Claude via Claude Code — review against OWASP Mobile Top 10 + project-specific PII rules | Per-epic, documented in AI Integration Log |
| Manual checklist | PII logging, `allowBackup`, FLAG_SECURE, HTTPS-only, Keystore credential storage | Pre-release sign-off |

Security review findings documented as issues; remediations logged in the AI Integration Log artifact.

**AI Integration Log:**

A living markdown document at `_bmad-output/ai-integration-log.md` maintained throughout development. Required training deliverable. Sections:

| Section | What to capture |
|---|---|
| Agent Usage | Which tasks used AI assistance; which prompts produced good output vs required heavy editing |
| MCP Server Usage | Postman MCP for mock server contract validation; Flutter DevTools for performance (not Chrome DevTools — N/A for native Android) |
| Test Generation | How AI assisted in writing test vectors, fixture shapes, Patrol test scaffolding; what it missed |
| Debugging with AI | Cases where AI helped diagnose issues (state machine edge cases, ADB connectivity, cookie replay) |
| Limitations | What AI could not do well; where human judgment was critical |

This log is updated at the end of each story, not in a single retrospective dump.

### Test Infrastructure & CI Pipeline

**Goal:** Deterministic, reproducible E2E pipeline satisfying `docker-compose up` as the canonical path to "build APK → boot emulator → install → run Patrol → assert against mock eVisitor." Decouples test suite from the real eVisitor test API (rate-limited, snapshot-scheduled).

#### Containerized E2E Topology

Three containers on a shared Docker bridge network:

```
┌─────────────────── docker-compose network: prijavko-e2e ────────────────────┐
│                                                                             │
│  ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐     │
│  │  mock-evisitor   │◄────│   test-runner    │────►│  android-emulator│     │
│  │                  │     │                  │     │                  │     │
│  │  Fastify + TS    │     │  Flutter SDK +   │     │ budtmo/          │     │
│  │  :8080 HTTP      │     │  patrol_cli +    │     │ docker-android   │     │
│  │  /healthz        │     │  ADB client      │     │ :5555 ADB        │     │
│  │                  │     │                  │     │ :6080 noVNC      │     │
│  │  scripted resp.  │     │                  │     │ API 34, x86_64   │     │
│  │  - success       │     │ 1. flutter build │     │ KVM-accelerated  │     │
│  │  - 400 validation│     │ 2. adb connect   │     │                  │     │
│  │  - 409 duplicate │     │ 3. adb install   │     │                  │     │
│  │  - 401 session   │     │ 4. patrol test   │     │                  │     │
│  │  - 503 unavail.  │     │                  │     │                  │     │
│  └──────────────────┘     └──────────────────┘     └──────────────────┘     │
│         ▲                          │                        ▲               │
│         │                          │ HTTP (test asserts)    │               │
│         └──────────────────────────┘                        │               │
│                                    └────────────────────────┘               │
│                          ADB over TCP + Patrol native server                │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Container Responsibilities

| Container | Image base | Owns |
|---|---|---|
| `mock-evisitor` | `node:20-alpine` | Fastify mock of eVisitor REST surface (`Login`, `CheckInTourist`, `ImportTourists`), cookie-based session, scripted error envelope (`{SystemMessage, UserMessage}`), `/healthz`. Fixtures under `test-infra/mock-evisitor/fixtures/`. |
| `test-runner` | Multi-stage: `ghcr.io/cirruslabs/flutter:stable` → adds `patrol_cli`, `android-platform-tools` | Builds APK (`flutter build apk --dart-define-from-file=config/test.json`), waits for `android-emulator:5555` readiness, `adb connect`, `adb install`, `patrol test` against the `integration_test/` suite. Emits JUnit + coverage to mounted volume. |
| `android-emulator` | `budtmo/docker-android:emulator_14.0` (API 34, x86_64) | Headless Android emulator booted with KVM (`/dev/kvm` device mount), ADB exposed on `:5555`. Patrol native automation server installed per-test-run by Patrol CLI. |

#### Docker Compose Sketch

File: `docker-compose.e2e.yml` (split from app compose to isolate test concerns)

```yaml
services:
  mock-evisitor:
    build: ./test-infra/mock-evisitor
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/healthz"]
      interval: 5s
      retries: 10

  android-emulator:
    image: budtmo/docker-android:emulator_14.0
    privileged: true              # required for KVM
    devices:
      - /dev/kvm:/dev/kvm         # nested virt acceleration
    environment:
      EMULATOR_DEVICE: "Samsung Galaxy S10"
      WEB_VNC: "false"
    healthcheck:
      test: ["CMD-SHELL", "adb shell getprop sys.boot_completed | grep -q 1"]
      interval: 10s
      retries: 30

  test-runner:
    build: ./test-infra/test-runner
    depends_on:
      mock-evisitor: { condition: service_healthy }
      android-emulator: { condition: service_healthy }
    volumes:
      - ./:/workspace
      - ./test-infra/output:/output   # JUnit + coverage artifacts
    environment:
      EVISITOR_BASE_URL: "http://mock-evisitor:8080"
      ADB_SERVER: "android-emulator:5555"
```

Config file `config/test.json` points `API_BASE` at `http://mock-evisitor:8080` so the APK under test talks to the mock, not the real eVisitor. Ads disabled.

#### Execution Sequence (`docker-compose -f docker-compose.e2e.yml up --abort-on-container-exit`)

1. `mock-evisitor` boots, `/healthz` passes.
2. `android-emulator` boots with KVM, reports `sys.boot_completed=1`.
3. `test-runner` starts: `flutter build apk --flavor test`, then `adb connect android-emulator:5555`, `adb install build/app/outputs/flutter-apk/app-test.apk`, then `patrol test -t integration_test/` with the native automation server handling camera permission, airplane-mode toggle, notification assertions.
4. Test runner emits JUnit XML + coverage to `./test-infra/output/`.
5. Compose exits with test runner's exit code.

#### Local Dev Loop vs CI Loop

| Loop | Emulator | Mock server | Patrol invocation | When to use |
|---|---|---|---|---|
| **Local fast loop (Apple Silicon)** | Native Android Studio AVD (ARM system image, HVF-accelerated) | `cd test-infra/mock-evisitor && pnpm dev` on host | `patrol test` from host shell | Daily dev: watch-compile-test on real hardware speed. ~10s cold, <5s warm. |
| **Local full E2E (optional)** | ❌ Not recommended on Apple Silicon — Docker Desktop doesn't expose KVM/HVF to containers; emulator boots in software emu, 5–10 min and flaky | Inside compose | Inside compose | Rare local verification of the compose pipeline itself. Prefer CI. |
| **CI** | `android-emulator` container on GHA `ubuntu-latest` (KVM-accelerated via `/dev/kvm`) | Inside compose | Inside compose | Every PR + every push to `main`. |

**Explicit decision:** the compose E2E pipeline is **CI-canonical, local-optional**. Dev machines run the fast loop. CI runs the full compose. This honors the training brief's `docker-compose up` contract without sacrificing dev ergonomics on Apple Silicon.

#### APK Build Strategy

- **Inside the `test-runner` container** via multi-stage Dockerfile:
  - Stage 1 (base): `ghcr.io/cirruslabs/flutter:stable` — Flutter SDK + Android SDK + build tools. Heavy layer, cached aggressively.
  - Stage 2 (runner): adds `patrol_cli`, ADB, test entrypoint script.
- Rationale: single self-contained image; `docker-compose up` genuinely does everything; multi-stage caching keeps CI fast after first run.
- **Not chosen:** separate "builder" container producing APK as shared volume. Adds orchestration complexity for no material gain at v1 scale.

#### GitHub Actions Integration

```yaml
# .github/workflows/e2e.yml
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Enable KVM
        run: |
          echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
          sudo udevadm control --reload-rules
          sudo udevadm trigger --name-match=kvm
      - uses: docker/setup-buildx-action@v3
      - name: Cache Docker layers
        uses: actions/cache@v4
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-${{ hashFiles('test-infra/**/Dockerfile') }}
      - run: docker compose -f docker-compose.e2e.yml up --abort-on-container-exit
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-results
          path: test-infra/output/
```

Existing CI workflow (analyze/test/build_runner verify) remains untouched; E2E is an additional job gated on the base checks passing.

#### KVM / Apple Silicon Gotchas (Do-Not-Forget)

- **Apple Silicon cannot run this compose locally with acceptable performance.** Documented as CI-only. Do not spend sprint time debugging `/dev/kvm` absence on M-series.
- **GHA hosted `ubuntu-latest` exposes `/dev/kvm` only since 2023.** Pin the runner image; do not allow GHA to silently drop to a runner without KVM.
- **budtmo/docker-android image is ~4 GB.** Docker layer cache on CI is mandatory; cold pipeline is ~8–10 min, warm is ~3–4 min.
- **Emulator boot race:** the `healthcheck` on `sys.boot_completed` is load-bearing. `test-runner`'s `depends_on: condition: service_healthy` is the only reliable gate; do not `sleep 60` in the entrypoint.
- **ADB over TCP between containers:** `adb connect android-emulator:5555` — Docker DNS resolves the service name. Do not hardcode IPs.
- **Patrol native server version pinning:** `patrol_cli` and `patrol` Dart dep must match; drift causes opaque "native automator not responding" errors. Pin both in `pubspec.yaml` and in the test-runner Dockerfile.

#### What This Section Defers to Other Sections

- Mock eVisitor API contract (fixtures, response shapes, session cookie semantics) — covered in a new `### Mock eVisitor Server Contract` subsection under `### API & Communication Patterns` (separate edit).
- Epic/story breakdown for building the mock, the Dockerfiles, and the CI wiring — covered in the new "Test Infrastructure & Deployment Quality" epic in `epics.md` (separate edit).
- Coverage targets, a11y audit workflow, security review cadence — covered in a new `### Quality Gates` subsection (separate edit).

### Decision Impact Analysis

**Implementation Sequence:**

1. Project init + folder structure + dependencies + build flavors
2. Drift database + freezed models + code gen pipeline
3. Facility CRUD + flutter_secure_storage + credential encryption
4. Dio + cookie persistence + eVisitor auth spike (dev flavor → testApi)
5. Camera + ML Kit + MRZ parser + capture pipeline
6. Review card + validation + guest state machine
7. Queue UI + batch send + retry + error mapper
8. History + auto-purge
9. AdMob + UMP/CMP
10. Onboarding flow
11. Polish (sound/haptic, duplicate warning)

**Cross-Component Dependencies:**

| Decision | Depends On | Blocks |
|----------|-----------|--------|
| Drift schema | freezed models | All features that persist data |
| eVisitor auth | Dio + cookie jar + flutter_secure_storage | Guest submission, batch send |
| Capture pipeline | ML Kit + mrz_parser + camera | Review card, queue entry |
| Queue state machine | Drift schema + Riverpod providers | Batch send, history, retry |
| Error mapper | eVisitor transport + l10n | All user-facing error surfaces |
| Build flavors | config files | Dev vs prod API switching |

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified

**12 areas** where AI agents could make incompatible choices without explicit rules.

### Naming Patterns

**Dart/Flutter Code Naming:**

| Element | Convention | Example |
|---------|-----------|---------|
| **Files** | `snake_case.dart` | `guest_queue_notifier.dart`, `evisitor_client.dart` |
| **Classes** | `PascalCase` | `GuestQueueNotifier`, `EVisitorClient` |
| **Variables / parameters** | `camelCase` | `facilityCode`, `guestState`, `encryptedPassword` |
| **Constants** | `camelCase` (Dart convention, not SCREAMING_CASE) | `defaultStayDuration`, `maxRetryAttempts` |
| **Enums** | `PascalCase` type, `camelCase` values | `GuestState.confirmed`, `CaptureTier.mrz` |
| **Private members** | `_camelCase` | `_cookieJar`, `_authService` |
| **Providers** | `camelCaseProvider` suffix via generator | `guestQueueProvider`, `facilityListProvider` |
| **Freezed unions** | `PascalCase` factory constructors | `Failure.network(message: ...)`, `Failure.api(userMessage: ...)` |

**Drift Database Naming:**

| Element | Convention | Example |
|---------|-----------|---------|
| **Tables** | `PascalCase` Dart class, maps to `snake_case` SQL | `class Guests extends Table` → `guests` |
| **Columns** | `camelCase` Dart, auto-maps to `snake_case` SQL | `TextColumn get facilityCode` → `facility_code` |
| **Foreign keys** | `{referenced_table_singular}Id` | `facilityId`, `sessionId` |
| **Indexes** | `idx_{table}_{columns}` | `idx_guests_facility_id`, `idx_guests_state` |
| **DAOs** | `{Table}Dao` | `GuestsDao`, `FacilitiesDao` |

**Feature Folder Naming:**

| Element | Convention | Example |
|---------|-----------|---------|
| **Feature folder** | `snake_case` (noun) | `capture/`, `queue/`, `facility/`, `send/` |
| **Sub-folders** | `presentation/`, `data/`, `providers/` | `capture/presentation/`, `capture/providers/` |
| **Widget files** | `snake_case` matching widget name | `guest_review_card.dart`, `facility_session_bar.dart` |
| **Screen files** | `{feature}_screen.dart` | `queue_screen.dart`, `capture_screen.dart` |
| **Provider files** | `{concern}_provider.dart` or `{concern}_notifier.dart` | `guest_queue_notifier.dart`, `facility_provider.dart` |

### Structure Patterns

**Feature Folder Internal Structure:**

```
features/{feature_name}/
├── presentation/
│   ├── screens/          # Full-screen widgets (routed)
│   └── widgets/          # Feature-specific reusable widgets
├── providers/            # Riverpod providers + notifiers for this feature
├── data/                 # Feature-specific repositories (if not shared)
└── {feature_name}.dart   # Barrel file exporting public API
```

**Shared vs feature-scoped:**

| Location | What goes here | Rule |
|----------|---------------|------|
| `lib/core/` | Theme, l10n, config, utils used by ≥2 features | Never import feature-specific code |
| `lib/data/` | Drift DB, Dio client, shared models | Shared data layer — features depend on this, never the reverse |
| `lib/features/{x}/` | Everything specific to feature x | May import `core/` and `data/`. **Never import another feature directly.** Cross-feature communication goes through shared providers or data layer. |

**Test File Placement:**

```
test/
├── core/                 # Mirrors lib/core/
├── data/                 # Mirrors lib/data/
├── features/
│   ├── capture/
│   │   ├── providers/    # Unit tests for notifiers
│   │   └── presentation/ # Widget tests
│   └── queue/
└── integration/          # End-to-end flows
```

Rule: **test file mirrors source file path**. `lib/features/queue/providers/guest_queue_notifier.dart` → `test/features/queue/providers/guest_queue_notifier_test.dart`.

### Format Patterns

**eVisitor API Data Formats:**

| Format | Convention | Example |
|--------|-----------|---------|
| **Dates to eVisitor** | `YYYYMMDD` string | `"20260414"` |
| **Times to eVisitor** | `hh:mm` string | `"18:30"` |
| **Dates internal (Drift)** | `DateTime` (UTC) | `DateTime.utc(2026, 4, 14)` |
| **Dates display (UI)** | `dd.MM.yyyy.` (Croatian) | `"14.04.2026."` |
| **GUIDs** | UUID v4, lowercase with hyphens | `"a1b2c3d4-e5f6-7890-abcd-ef1234567890"` |

**JSON / Serialization:**

- Internal Dart models: `camelCase` field names (Dart convention)
- eVisitor payloads: match eVisitor API field names exactly (PascalCase: `TouristName`, `DocumentNumber`, etc.)
- `XmlPayloadBuilder` handles Dart camelCase → eVisitor PascalCase mapping — no manual PascalCase in business logic

**Null Handling:**

- Drift columns: explicitly `nullable()` or not. No implicit nulls.
- Freezed models: required fields have no default. Optional fields use `String?` with `@Default` where a sensible default exists.
- UI: never display `null` — show placeholder text or hide field. No "null" or empty strings rendered.

### Communication Patterns

**Riverpod Provider Patterns:**

| Pattern | Rule |
|---------|------|
| **Provider naming** | Use `riverpod_generator` annotations. Provider name = function name + `Provider` suffix (auto-generated). |
| **State updates** | Always via notifier methods. Never modify state directly from widgets. |
| **Cross-feature data** | Widget reads provider A and provider B independently. No provider importing another feature's provider directly — go through shared data layer. |
| **Async operations** | Always `AsyncValue<T>`. Loading/error/data handled with `.when()` in UI. |
| **Disposal** | `autoDispose` by default. Only keep-alive for app-lifecycle providers (Dio instance, DB instance). |

**Guest State Machine Events:**

| Transition | Method | Side Effects |
|------------|--------|-------------|
| New → `captured` | `createGuest(fields, tier, facilityId)` | Insert into Drift |
| `captured` → `confirmed` | `confirmGuest(guestId)` | Update state in Drift |
| `confirmed` → `ready` | Automatic when facility assigned + validated | Update state in Drift |
| `ready` → `sending` | `beginSend(guestId)` | Update state in Drift |
| `sending` → `sent` | `markSent(guestId, response)` | Update state + submittedAt in Drift |
| `sending` → `failed` | `markFailed(guestId, failure)` | Update state + errorMessage + isTerminal flag in Drift |
| `sending` → `pausedAuth` | `pauseForAuth(batchGuestIds)` | Bulk update all in-flight/pending guests when re-auth fails |
| `pausedAuth` → `ready` | `resumeAfterAuth(batchGuestIds)` | Bulk reset to ready after successful re-authentication |
| `failed` → `ready` | `retryGuest(guestId)` | Clear errorMessage, reset state in Drift (only non-terminal failures) |
| Any → deleted | `removeGuest(guestId)` | Delete from Drift (only pre-send states) |

Rule: **Every state transition writes to Drift first, then the Riverpod provider observing the Drift stream updates the UI.** No optimistic in-memory state.

### Process Patterns

**Error Handling Flow:**

```
Data layer (Dio/Drift)
  → catches exceptions at boundary
  → returns Result<T, Failure>

Repository
  → receives Result
  → adds business context if needed
  → returns Result<T, Failure>

Provider/Notifier
  → receives Result
  → maps to AsyncValue.data or AsyncValue.error
  → Failure object preserved for UI

Widget
  → reads AsyncValue
  → .when(data: ..., error: ..., loading: ...)
  → error handler renders Failure.userMessage (Croatian)
```

No raw try/catch in features. Only at:
1. Dio interceptors (wrap transport errors → `Result.failure`)
2. Platform channel bridge (wrap platform exceptions → `Result.failure`)
3. Main isolate error handler (last resort crash logging)

**Loading State Pattern:**

- **Local loading** (single button/card): `AsyncValue.loading` on the specific provider
- **Screen loading** (initial data fetch): full-screen `CircularProgressIndicator` only on first load, not on refresh
- **Send progress** (batch): `LinearProgressIndicator` with per-guest status tracked in Drift, not ephemeral state
- Rule: never block camera with a loading spinner except during permission flow

**Validation Pattern:**

- **When:** On field blur + on submit (not on every keystroke)
- **Where:** Domain model constructors enforce invariants (Poka-yoke). Repository validates business rules. Widget displays errors.
- **Format:** `ValidationFailure(Map<String, String> fieldErrors)` — key is field name, value is Croatian error message
- **eVisitor errors post-submit:** `ApiFailure(userMessage)` displayed as-is (already Croatian from server)

**Failure Severity Rendering (UX ↔ Architecture alignment):**

UX spec defines two visual failure tiers for queue rows. Architecture maps them as follows:

| UX Token | Architecture State | Determination | UI Treatment |
|---|---|---|---|
| `failed-retryable` | `state == failed` AND `isTerminalFailure == false` | Network error, timeout, 429/503, or max auto-retries exhausted but data is valid | Show retry action, use warning-level color |
| `failed-terminal` | `state == failed` AND `isTerminalFailure == true` | 400 (bad data), 404, or business rule rejection from eVisitor | Show edit action, use error-level color, retry disabled until fields edited |

`isTerminalFailure` is set by `EVisitorRepository` based on HTTP status code and `Failure` type at the time of `markFailed()`. The `QueueGuestRow` widget reads both `state` and `isTerminalFailure` from the Drift-backed model to select the correct `ThemeExtension` token.

### Enforcement Guidelines

**All AI Agents MUST:**

1. Run `dart analyze` with zero warnings before considering code complete
2. Run `dart format` on all modified files
3. Run `dart run build_runner build` after modifying any file that uses code generation (Drift tables, freezed models, Riverpod providers)
4. Place new files in the correct feature folder per structure patterns above
5. Use `Result<T, Failure>` for all data layer returns — no throwing exceptions from repositories
6. Write state transitions through Drift — never hold critical guest/queue state in memory only
7. Use Croatian strings from l10n ARB files for all user-facing text — no hardcoded strings in widgets
8. Never log PII (guest names, document numbers, credentials, MRZ data) at any log level

**Anti-Patterns to Reject:**

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| `try { } catch (e) { print(e); }` | Return `Result.failure(Failure.from(e))` |
| Holding guest state in `StateNotifier` without Drift | Write to Drift first, observe stream |
| `if (mounted) setState(...)` | Use Riverpod — no `setState` |
| Hardcoded `"Greška"` in widget | `context.l10n.errorGeneric` from ARB |
| `Color(0xFFFF0000)` for error | `theme.colorScheme.error` or `ThemeExtension` token |
| `import '../../../features/send/...'` from capture | Go through `data/` layer or shared provider |
| `flutter_secure_storage.read()` in a widget | Read via `FacilityRepository` → provider |

## Project Structure & Boundaries

### Complete Project Directory Structure

```
prijavko/
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── build.yaml                            # build_runner configuration
├── .gitignore
├── .github/
│   └── workflows/
│       └── ci.yml                        # flutter analyze + test + build_runner verify
├── config/
│   ├── dev.json                          # API_BASE: testApi, AD_ENABLED: false
│   └── prod.json                         # API_BASE: production, AD_ENABLED: true
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml       # Camera permission, internet, backup rules
│   │   │   ├── res/
│   │   │   │   └── xml/
│   │   │   │       └── backup_rules.xml  # Exclude credentials + guest DB
│   │   │   └── kotlin/.../
│   │   │       └── MainActivity.kt
│   │   └── build.gradle                  # minSdk, targetSdk, signing configs
│   └── build.gradle
├── assets/
│   ├── l10n/
│   │   ├── app_hr.arb                    # Croatian strings (primary)
│   │   └── app_en.arb                    # English strings (fallback)
│   └── images/                           # App icon, onboarding illustrations
├── lib/
│   ├── main.dart                         # Entry point, ProviderScope, flavor init
│   ├── app.dart                          # MaterialApp.router, theme, go_router
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart           # Environment (apiBase, adEnabled) from dart-define
│   │   │   └── constants.dart            # maxRetryAttempts, stalePurgeDays, historyRetentionDays
│   │   ├── theme/
│   │   │   ├── app_theme.dart            # ThemeData light/dark from teal seed
│   │   │   └── queue_theme_extension.dart # ThemeExtension for queue state colors/icons
│   │   ├── l10n/
│   │   │   └── l10n.dart                 # Generated l10n delegate (from ARB)
│   │   ├── router/
│   │   │   └── app_router.dart           # go_router config, route guards, shell route
│   │   ├── result/
│   │   │   └── result.dart               # Result<T, Failure> sealed class
│   │   └── utils/
│   │       ├── date_formatter.dart       # YYYYMMDD ↔ DateTime, Croatian display format
│   │       ├── uuid_generator.dart       # UUID v4 generation for guest GUIDs
│   │       └── pii_scrubber.dart         # Strip PII from log messages
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart         # Drift database class, includes all tables
│   │   │   ├── app_database.g.dart       # Generated
│   │   │   ├── tables/
│   │   │   │   ├── facilities_table.dart
│   │   │   │   ├── credentials_table.dart
│   │   │   │   ├── guests_table.dart
│   │   │   │   └── scan_sessions_table.dart
│   │   │   ├── daos/
│   │   │   │   ├── facilities_dao.dart
│   │   │   │   ├── guests_dao.dart
│   │   │   │   └── scan_sessions_dao.dart
│   │   │   └── migrations/
│   │   │       └── migration_strategy.dart
│   │   ├── api/
│   │   │   ├── dio_client.dart           # Dio singleton, cookie jar, interceptors
│   │   │   ├── evisitor_auth_service.dart # Login, re-auth, cookie management
│   │   │   ├── evisitor_submit_service.dart # CheckInTourist / ImportTourists
│   │   │   ├── xml_payload_builder.dart  # Dart model → eVisitor XML
│   │   │   └── error_mapper.dart         # API {UserMessage} → Failure, Croatian strings
│   │   ├── repositories/
│   │   │   ├── facility_repository.dart  # CRUD, credential access via secure storage
│   │   │   ├── guest_repository.dart     # Queue ops, state transitions, purge
│   │   │   ├── evisitor_repository.dart  # Auth + submit orchestration, retry logic
│   │   │   └── history_repository.dart   # 30-day query, auto-purge
│   │   └── models/
│   │       ├── guest.dart                # Freezed: Guest model
│   │       ├── guest.freezed.dart        # Generated
│   │       ├── facility.dart             # Freezed: Facility model
│   │       ├── facility.freezed.dart     # Generated
│   │       ├── scan_session.dart         # Freezed: ScanSession model
│   │       ├── guest_state.dart          # Enum: captured, confirmed, ready, sending, sent, failed, pausedAuth
│   │       ├── capture_tier.dart         # Enum: mrz, ocr, manual
│   │       ├── failure.dart              # Freezed sealed: Network, Auth, Api, Validation, Storage
│   │       └── failure.freezed.dart      # Generated
│   ├── features/
│   │   ├── capture/
│   │   │   ├── capture.dart              # Barrel export
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── capture_screen.dart     # Camera viewfinder + doc type selector
│   │   │   │   └── widgets/
│   │   │   │       ├── document_camera_view.dart              # Camera preview + frame + torch
│   │   │   │       ├── guest_submission_snapshot_card.dart     # Submission snapshot (readonly/editable)
│   │   │   │       └── capture_tier_badge.dart                 # MRZ / OCR / Manual indicator
│   │   │   ├── providers/
│   │   │   │   ├── capture_notifier.dart  # Camera state, ML Kit processing
│   │   │   │   └── capture_notifier.g.dart
│   │   │   └── data/
│   │   │       ├── mrz_extraction_service.dart  # ML Kit → mrz_parser → fields
│   │   │       └── ocr_extraction_service.dart  # ML Kit text regions → fields
│   │   ├── queue/
│   │   │   ├── queue.dart
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── queue_screen.dart         # Guest list with state chips
│   │   │   │   └── widgets/
│   │   │   │       ├── queue_guest_row.dart       # Name, facility chip, status
│   │   │   │       ├── batch_send_summary.dart    # Partial batch results
│   │   │   │       └── empty_queue_state.dart     # CTA to start scanning
│   │   │   └── providers/
│   │   │       ├── guest_queue_notifier.dart      # State machine methods
│   │   │       └── guest_queue_notifier.g.dart
│   │   ├── facility/
│   │   │   ├── facility.dart
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── facility_list_screen.dart  # Profile CRUD
│   │   │   │   │   └── facility_form_screen.dart  # Add/edit facility + credentials
│   │   │   │   └── widgets/
│   │   │   │       ├── facility_session_bar.dart   # Always-visible anchor during session
│   │   │   │       └── facility_picker_sheet.dart  # Bottom sheet selector at session start
│   │   │   └── providers/
│   │   │       ├── facility_notifier.dart
│   │   │       ├── facility_notifier.g.dart
│   │   │       ├── active_session_notifier.dart    # Current facility + session state
│   │   │       └── active_session_notifier.g.dart
│   │   ├── send/
│   │   │   ├── send.dart
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── send_progress_screen.dart  # Per-guest results during batch
│   │   │   │   └── widgets/
│   │   │   │       ├── evisitor_message_panel.dart # Croatian error display
│   │   │   │       └── auth_prompt_dialog.dart     # Re-auth on 401
│   │   │   └── providers/
│   │   │       ├── send_notifier.dart              # Batch send orchestration
│   │   │       └── send_notifier.g.dart
│   │   ├── history/
│   │   │   ├── history.dart
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── history_screen.dart         # 30-day submitted guests
│   │   │   │   └── widgets/
│   │   │   │       └── history_guest_row.dart
│   │   │   └── providers/
│   │   │       ├── history_provider.dart
│   │   │       └── history_provider.g.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding.dart
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── onboarding_screen.dart      # First-launch facility setup guide
│   │   └── settings/
│   │       ├── settings.dart
│   │       └── presentation/
│   │           └── screens/
│   │               └── settings_screen.dart        # Ad consent, about, privacy
│   └── shared/
│       └── widgets/
│           ├── prijavko_scaffold.dart              # App scaffold with bottom nav
│           └── connectivity_banner.dart            # Offline status banner
├── test/
│   ├── core/
│   │   └── utils/
│   │       ├── date_formatter_test.dart
│   │       └── uuid_generator_test.dart
│   ├── data/
│   │   ├── database/
│   │   │   ├── daos/
│   │   │   │   ├── guests_dao_test.dart
│   │   │   │   └── facilities_dao_test.dart
│   │   │   └── migrations/
│   │   │       └── migration_test.dart
│   │   ├── api/
│   │   │   ├── evisitor_auth_service_test.dart
│   │   │   ├── evisitor_submit_service_test.dart
│   │   │   ├── xml_payload_builder_test.dart
│   │   │   └── error_mapper_test.dart
│   │   ├── repositories/
│   │   │   ├── guest_repository_test.dart
│   │   │   └── evisitor_repository_test.dart
│   │   └── models/
│   │       └── failure_test.dart
│   ├── features/
│   │   ├── capture/
│   │   │   ├── providers/
│   │   │   │   └── capture_notifier_test.dart
│   │   │   ├── data/
│   │   │   │   └── mrz_extraction_service_test.dart
│   │   │   └── presentation/
│   │   │       └── widgets/
│   │   │           └── guest_submission_snapshot_card_test.dart
│   │   ├── queue/
│   │   │   └── providers/
│   │   │       └── guest_queue_notifier_test.dart
│   │   └── send/
│   │       └── providers/
│   │           └── send_notifier_test.dart
│   ├── fixtures/
│   │   ├── mrz_samples/                  # ICAO TD1/TD3 test vectors
│   │   │   ├── passport_de_valid.txt
│   │   │   ├── passport_at_valid.txt
│   │   │   ├── id_hr_valid.txt
│   │   │   └── passport_checksum_fail.txt
│   │   └── evisitor_responses/           # Mock API response shapes
│   │       ├── login_success.json
│   │       ├── submit_success.json
│   │       ├── submit_error_category.json
│   │       └── submit_error_duplicate.json
│   └── integration/
│       ├── capture_to_queue_test.dart
│       └── queue_to_send_test.dart
└── integration_test/
    └── app_test.dart                     # On-device integration tests
```

### Architectural Boundaries

**Data Layer Boundary:**

```
[Widgets] ──reads──→ [Providers] ──calls──→ [Repositories] ──uses──→ [Drift DB / Dio / SecureStorage]
                                                                         ↕
                                                              [eVisitor API / Android Keystore]
```

- Widgets never import from `data/` directly — always through providers
- Providers never call Dio or Drift directly — always through repositories
- Repositories return `Result<T, Failure>` — never throw exceptions
- Drift DB is the single source of truth for guest/queue state

**Feature Boundaries:**

| Feature | Can Import | Cannot Import |
|---------|-----------|---------------|
| `capture` | `core/`, `data/models/`, `data/repositories/` | `queue/`, `send/`, `history/`, `facility/` internals |
| `queue` | `core/`, `data/models/`, `data/repositories/` | `capture/`, `send/`, `history/` internals |
| `send` | `core/`, `data/models/`, `data/repositories/` | `capture/`, `queue/`, `history/` internals |
| `facility` | `core/`, `data/models/`, `data/repositories/` | `capture/`, `queue/`, `send/` internals |
| `shared/widgets/` | `core/` only | All features |

Cross-feature coordination (e.g. capture adds guest → queue shows it) happens through Drift DB as the shared bus: capture writes to `guests` table → queue provider watches the same table stream.

### Requirements to Structure Mapping

| FR Group | Primary Location | Supporting Files |
|----------|-----------------|------------------|
| **FR1–FR5** (Capture & Recognition) | `features/capture/` | `data/models/guest.dart`, `data/models/capture_tier.dart` |
| **FR6–FR10** (Review & Editing) | `features/capture/presentation/widgets/guest_submission_snapshot_card.dart` | `data/repositories/guest_repository.dart` |
| **FR11–FR15** (Facility Management) | `features/facility/` | `data/database/tables/facilities_table.dart`, `data/database/tables/credentials_table.dart`, `data/repositories/facility_repository.dart` |
| **FR16–FR22** (Queue & Batch) | `features/queue/` | `data/database/daos/guests_dao.dart`, `data/repositories/guest_repository.dart` |
| **FR23–FR29** (eVisitor API) | `data/api/` + `data/repositories/evisitor_repository.dart` | `features/send/` (UI), `data/api/error_mapper.dart` |
| **FR30–FR32** (History) | `features/history/` | `data/repositories/history_repository.dart` |
| **FR33–FR35** (Ads & Consent) | `features/settings/` | `core/config/app_config.dart` |
| **FR36** (Onboarding) | `features/onboarding/` | `core/router/app_router.dart` (route guard) |
| **FR37–FR39** (Feedback & Errors) | `core/theme/` + `data/api/error_mapper.dart` | `core/l10n/` (Croatian strings) |

### Integration Points

**External Integrations:**

| Integration | File | Protocol |
|-------------|------|----------|
| **eVisitor API** | `data/api/evisitor_auth_service.dart`, `evisitor_submit_service.dart` | HTTPS + cookies (Dio), JSON/XML payloads |
| **ML Kit** | `features/capture/data/mrz_extraction_service.dart`, `ocr_extraction_service.dart` | On-device, `google_mlkit_text_recognition` |
| **Android Keystore** | `data/repositories/facility_repository.dart` (via `flutter_secure_storage`) | Platform channel (wrapped by package) |
| **AdMob** | `features/settings/` + ad container widgets | Google Mobile Ads SDK |
| **UMP/CMP** | `features/settings/` (consent surface) | UMP SDK |
| **Firebase Crashlytics** | `main.dart` (init) + `core/utils/pii_scrubber.dart` | Firebase SDK |

**Internal Data Flow:**

```
Camera → ML Kit → MrzExtractionService → Guest model → GuestRepository.create()
  → Drift INSERT → guests table stream → GuestQueueNotifier → Queue UI

Queue UI → "Send All" → SendNotifier → EVisitorRepository.submitBatch()
  → EVisitorAuthService.ensureAuthenticated()
  → EVisitorSubmitService.submit(guest) per guest
  → GuestRepository.markSent() or .markFailed()
  → Drift UPDATE → guests table stream → Queue UI (per-row result)
```

### Development Workflow

**Daily commands:**

```bash
# Run with test API
flutter run --dart-define-from-file=config/dev.json

# Code generation after model/provider/table changes
dart run build_runner build --delete-conflicting-outputs

# Analyze + format
dart analyze && dart format lib/ test/

# Tests
flutter test

# Build release AAB for Play Store
flutter build appbundle --dart-define-from-file=config/prod.json
```

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
- Riverpod 3.0 + Drift 2.32+ + Freezed + go_router + Dio 5.x: fully compatible — common production Flutter stack with no known conflicts
- `build_runner` handles all code generation (Drift, Riverpod, Freezed, json_serializable) in a single pipeline — no conflicting generators
- `flutter_secure_storage` wraps Android Keystore natively — no conflict with Drift (separate storage concerns)
- ML Kit on-device + camera plugin: independent of network/state layer — no coupling issues
- AdMob + UMP: isolated in settings feature — does not touch capture/queue/send path

**Pattern Consistency:**
- Naming conventions follow Dart/Flutter standards throughout (snake_case files, PascalCase classes, camelCase variables)
- `Result<T, Failure>` consistently used across all data layer boundaries — no mixed error handling
- Drift-as-truth pattern consistently applied: every state transition writes DB first, providers observe streams
- Feature isolation rules are symmetric — no feature can import another feature's internals

**Structure Alignment:**
- Feature-based folder structure maps 1:1 to FR groups
- `data/` layer properly centralized — all repositories and DB access in one location
- Test structure mirrors source — no ambiguity about where tests go
- Config files (`dev.json`, `prod.json`) aligned with build flavor decision

No contradictions found.

### Requirements Coverage Validation ✅

**Functional Requirements (39/39 covered):**

| FR | Coverage | Architecture Location |
|----|----------|----------------------|
| FR1–FR5 | ✅ | `features/capture/`, ML Kit, mrz_parser |
| FR6–FR10 | ✅ | `guest_submission_snapshot_card.dart`, `guest_repository.dart`, domain validation |
| FR11–FR15 | ✅ | `features/facility/`, `flutter_secure_storage`, session notifier |
| FR16–FR22 | ✅ | `features/queue/`, Drift state machine, `guests_dao.dart`, purge in repository |
| FR23–FR29 | ✅ | `data/api/`, `evisitor_repository.dart`, `xml_payload_builder.dart`, GUID tracking |
| FR30–FR32 | ✅ | `features/history/`, `history_repository.dart`, 30-day auto-purge |
| FR33–FR35 | ✅ | `features/settings/`, AdMob SDK, UMP SDK, `app_config.dart` |
| FR36 | ✅ | `features/onboarding/`, go_router redirect guard |
| FR37–FR39 | ✅ | `core/theme/`, `core/l10n/`, `error_mapper.dart`, duplicate check via DAO query |

**Non-Functional Requirements (31/31 covered):**

| NFR | Coverage | How Addressed |
|-----|----------|--------------|
| NFR1a–NFR8 (Performance) | ✅ | ML Kit on-device, Drift isolate threading, async Dio, no UI thread blocking, `AsyncValue` loading states |
| NFR9–NFR18 (Security) | ✅ | `flutter_secure_storage`, FLAG_SECURE, `backup_rules.xml`, HTTPS-only Dio, image discard in capture pipeline, 30-day purge, no PII in Crashlytics, no autocomplete on credentials |
| NFR19–NFR24 (Integration) | ✅ | PersistCookieJar, re-auth on 401, Drift WAL durability, exponential backoff + jitter, ML Kit offline, ads async/non-blocking |
| NFR25–NFR29 (Reliability) | ✅ | Crashlytics, `sending` → recover to `ready` on restart, session context in Drift, migration strategy, GUID-based idempotency |

### Implementation Readiness Validation ✅

**Decision Completeness:**
- All critical decisions documented with specific package names and versions
- Implementation patterns cover naming, structure, formats, communication, and process
- Anti-pattern table provides concrete reject-criteria for code review
- State machine transitions fully enumerated with methods and side effects

**Structure Completeness:**
- ~65 files/directories explicitly defined in project tree
- Every FR group mapped to specific file paths
- Integration points listed with protocol and file location

**Pattern Completeness:**
- 8 enforcement rules for AI agents
- 7 anti-patterns with corrections
- Error handling flow diagrammed layer by layer
- Validation pattern (when/where/format) fully specified

### Gap Analysis Results

**Critical Gaps: None**

**Important Gaps (3 — addressable during implementation, not blocking):**

| Gap | Impact | Resolution |
|-----|--------|-----------|
| **Connectivity monitoring** | `connectivity_banner.dart` exists in structure but no provider/package defined | Add `connectivity_plus` package. Create `connectivityProvider` in `core/`. Send feature gates on this provider. |
| **Ad container placement** | UX spec says "neutral containers" but no specific ad widget file mapped | Add `shared/widgets/ad_banner_container.dart`. Place in queue and history screens only (never camera/review/send). |
| **Duplicate scan detection (FR39)** | 24h duplicate warning mentioned but no explicit DAO query defined | `GuestsDao.findDuplicate(facilityId, dateOfBirth, documentNumber, within24h)` → `capture_notifier` checks before adding to queue. Soft warning, not hard block. |

**Nice-to-Have Gaps (deferred):**
- Sound/haptic feedback hooks (FR37) — simple implementation, no architectural impact
- Background retry on send — bounded behavior defined but implementation is Phase 2 polish
- Analytics event catalog — north-star metric defined but full event taxonomy evolves during implementation

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed (39 FRs, 31 NFRs)
- [x] Scale and complexity assessed (Medium-High)
- [x] Technical constraints identified (eVisitor API, MRZ, Keystore, GDPR)
- [x] Cross-cutting concerns mapped (7 concerns with resolution strategies)

**✅ Architectural Decisions**
- [x] Critical decisions documented with versions (Riverpod 3.0, Drift 2.32+, Dio 5.x, go_router, freezed)
- [x] Technology stack fully specified
- [x] Integration patterns defined (cookie auth, XML payloads, retry policy)
- [x] Security architecture specified (Keystore, FLAG_SECURE, PII scrubbing, backup exclusion)

**✅ Implementation Patterns**
- [x] Naming conventions established (Dart, Drift, features)
- [x] Structure patterns defined (feature folders, shared vs scoped)
- [x] Communication patterns specified (Riverpod providers, state machine events)
- [x] Process patterns documented (error handling, loading, validation)

**✅ Project Structure**
- [x] Complete directory structure defined (~65 files)
- [x] Component boundaries established (feature isolation rules)
- [x] Integration points mapped (6 external integrations)
- [x] Requirements to structure mapping complete (all 39 FRs)

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**

**Confidence Level: High**

**Key Strengths:**
- Drift-as-truth pattern eliminates entire class of state consistency bugs (process death, crash recovery)
- Feature isolation prevents spaghetti dependencies — each feature is independently testable
- `Result<T, Failure>` sealed hierarchy makes every failure path explicit and typed
- eVisitor transport abstraction (client → service → repository) isolates the messiest integration behind clean interfaces
- Build flavors enable safe development against test API without risk of touching production

**Areas for Future Enhancement:**
- Biometric-gated credential access (BiometricPrompt) — post-MVP
- Read-back of registered guests from eVisitor — Phase 2, schema pre-prepared with `source` column
- iOS port — Flutter codebase enables this but no iOS-specific decisions made
- Remote config / feature flags — not needed for solo dev v1
- Play Integrity API — abuse reduction for later

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented
- Use implementation patterns consistently across all components
- Respect project structure and feature boundaries — no cross-feature imports
- Refer to this document for all architectural questions
- When in doubt: Drift is truth, Result is the error contract, Croatian is the UI language

**First Implementation Priority:**

```bash
flutter create --org hr.prijavko --platforms android prijavko
```

Then: dependencies + folder structure + build flavors + code gen pipeline + Drift schema + freezed models.
