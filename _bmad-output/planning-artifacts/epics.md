---
stepsCompleted:
  - "step-01-validate-prerequisites"
  - "step-02-design-epics"
  - "step-03-create-stories"
  - "step-04-final-validation"
inputDocuments:
  - "prd.md"
  - "architecture.md"
  - "ux-design-specification.md"
---

# Prijavko - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Prijavko, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Host can capture a guest's identity document using the device camera
FR2: System can extract guest data from the MRZ zone of a captured document with checksum validation (TD1, TD2, TD3 formats)
FR3: System can fall back to OCR text extraction when MRZ parsing fails or MRZ is absent
FR4: Host can manually enter or correct all guest data fields when automated extraction is insufficient
FR5: System can determine the capture method used (MRZ, OCR, manual) and carry it as metadata
FR6: Host can review extracted guest data on a read-only confirmation card before submission
FR7: Host can switch a review card to editable mode to correct any field
FR8: Host can add data not extractable from documents (e.g., arrival date, departure date, facility assignment)
FR9: System can validate guest data against eVisitor field requirements before allowing submission
FR10: Host can delete a guest from the queue before submission
FR11: Host can add a facility profile with credentials (eVisitor username, password, facility ID) and per-facility defaults (TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, default stay duration)
FR12: Host can manage multiple facility profiles (edit, delete)
FR13: Host can select a session-scoped active facility that applies to all subsequent captures
FR14: Host can change the active facility between capture sessions
FR15: System can store facility credentials and defaults encrypted on-device using hardware-backed keystore
FR16: System can maintain a local queue of captured guests associated with the active facility
FR17: Host can view all guests in the current queue
FR18: Host can submit all ready guests in a single batch action
FR19: Host can submit an individual guest from the queue
FR20: System can track each guest's status through a defined state lifecycle (captured → confirmed → ready → sending → sent / failed)
FR21: Host can retry submission for failed guests
FR22: System can automatically purge unsent queue items older than 7 days to prevent stale data accumulation
FR23: System can authenticate with the eVisitor API using host credentials (ASP.NET Forms Authentication with cookie session)
FR24: System can submit guest check-in data to eVisitor (CheckInTourist or ImportTourists endpoint)
FR25: System can generate a unique GUID per guest submission and persist it locally for idempotency, future checkout, and cancellation
FR26: System can detect session expiry or authentication failure and re-authenticate transparently
FR27: System can parse eVisitor API error responses and present them as human-readable Croatian messages
FR28: System can handle eVisitor API unavailability without losing queued guest data
FR29: System can require BorderCrossing and PassageDate fields for non-EU guests before submission (conditional mandatory fields per eVisitor API rules)
FR30: Host can view a history of submitted guests for the past 30 days
FR31: Host can see the submission status and timestamp for each historical entry
FR32: System can automatically purge history entries older than 30 days
FR33: System can display ads within the app (AdMob integration)
FR34: System can present a consent dialog for ad personalization compliant with EEA/UK requirements (UMP/CMP)
FR35: Host can manage their ad consent preferences
FR36: System can detect first launch and guide the host through initial facility profile setup before scanning
FR37: System can provide audible and/or haptic feedback on successful capture events
FR38: System can display field-level validation errors in Croatian before submission
FR39: System can warn the host when a duplicate guest scan is detected within 24 hours

### NonFunctional Requirements

NFR1a: MRZ capture-to-parsed-data display must complete within 3 seconds on mid-range Android devices (Snapdragon 600-series or equivalent, 2022+, release build)
NFR1b: OCR fallback capture-to-parsed-data display must complete within 5 seconds on the same device class
NFR2: Time-to-first-feedback after capture (e.g., "Reading document…") must be under 1 second — perceived progress reduces wait anxiety
NFR3: Guest queue list rendering must remain smooth (no sustained jank) with up to 50 guests in a single session
NFR4: App cold start to camera-ready state must complete within 5 seconds on mid-range devices (release build, subsequent launches — first install may be slower)
NFR5: Warm resume (app backgrounded → foregrounded) to camera-ready must complete within 2 seconds
NFR6: eVisitor API submission per guest: client-side timeout of 15 seconds; user-visible progress indicator during submission; retry available immediately on timeout
NFR7: Review card field editing must have no perceptible input lag relative to system keyboard
NFR8: App must remain responsive during background API submission — UI thread never blocked by network operations
NFR9: Facility credentials must be encrypted at rest using Android Keystore hardware-backed keys
NFR10: Guest identity data stored locally must not be accessible to other apps (app-private storage, no external storage)
NFR11: Android Auto Backup must be disabled or scoped to exclude credential and guest data — no restoration of sensitive data to another device
NFR12: eVisitor API communication must use HTTPS exclusively — no fallback to HTTP
NFR13: Captured document images must not be persisted after data extraction — only extracted text fields are stored
NFR14: Local guest history must be automatically purged after 30 days (device-local clock, UTC-normalized) with no manual recovery possible
NFR15: Credential entry fields must not allow system keyboard autocomplete/suggestions to prevent credential leakage
NFR16: Credential and guest identity screens must use FLAG_SECURE to prevent capture in screenshots and recent app thumbnails
NFR17: App must comply with Google Play data safety declaration requirements (no data shared with third parties except ad networks per consent)
NFR18: Observability (Crashlytics, analytics) must never capture MRZ data, document images, guest names, or credential values in logs or crash reports — anonymized funnel events and crash stacks only
NFR19: eVisitor API session management must handle cookie expiry (401, redirect-to-login, empty session) transparently — re-authenticate and replay failed request without user intervention or data loss
NFR20: eVisitor API failures must never result in loss of queued guest data — queue persists through API errors, app crashes, and process death (SQLite/Drift with WAL)
NFR21: eVisitor API retry policy must use exponential backoff with jitter on 429/503/timeout responses — no retry storms
NFR22: App must gracefully degrade when eVisitor API is unreachable — all capture, review, and queue functions remain operational offline
NFR23: ML Kit text recognition must function without network connectivity (on-device bundled model, no cloud API dependency)
NFR24: AdMob integration must not block or delay core app functionality — ads load asynchronously, never interrupt capture or submission flows, and no full-screen interstitials during capture or submission sequences
NFR25: Crash-free session rate must be ≥ 99.5% as measured by Firebase Crashlytics over trailing 28 days (target applies after first public release stabilization)
NFR26: Guest state machine must be recoverable after process death — no guest stuck in transient state (sending) after app restart; resume or roll back to last stable state
NFR27: After crash or process death, app must restore the user's session context (active facility, queue position) — not just data survival but continuity of workflow
NFR28: Queue data must survive app updates without data loss
NFR29: Duplicate submission prevention — system must not submit the same guest twice to eVisitor even after crash recovery or retry (idempotency key or server-side dedup check)

### Additional Requirements

- Architecture specifies `flutter create --org hr.prijavko --platforms android prijavko` as the starter template — this defines Epic 1 Story 1 (project initialization)
- Post-init setup includes: Riverpod 3.0, Drift 2.32+, Dio 5.x, freezed, go_router, build flavors (dev/prod), i18n (Croatian + English ARB), linting, test scaffolding, feature-based folder structure
- Drift database schema: 4 tables (facilities, credentials, guests, scan_sessions) with explicit column types, foreign keys, and indexes
- Unified code generation pipeline via `build_runner` (Drift + Riverpod + Freezed + json_serializable)
- `Result<T, Failure>` sealed class pattern for all data layer error handling — no raw exceptions from repositories
- `Failure` sealed hierarchy: NetworkFailure, AuthFailure, ApiFailure(userMessage), ValidationFailure(fields), StorageFailure
- eVisitor transport layer: AuthService (login, re-auth, cookie management), GuestSubmitService (CheckInTourist/ImportTourists), ErrorMapper (UserMessage → Failure), XmlPayloadBuilder
- Cookie persistence via PersistCookieJar surviving process death
- Retry policy: max 3 attempts per guest per manual send, exponential backoff with jitter (1s/2s/4s + 0–500ms), terminal vs retryable failure classification
- State machine: 7 states (captured, confirmed, ready, sending, sent, failed, pausedAuth) with explicit transition methods and Drift-first persistence
- Build flavors: dev (testApi, ads disabled) / prod (production, ads enabled) via --dart-define-from-file
- CI: GitHub Actions — flutter analyze + flutter test + build_runner verify on push to main; release AAB on tag
- Environment config files: config/dev.json, config/prod.json
- Logging: Firebase Crashlytics (no PII), Firebase Analytics (anonymized funnel events), dart:developer log() stripped in release
- North-star metric instrumentation: `first_time_success` event when guest goes captured → confirmed → sent without field edits
- Connectivity monitoring: `connectivity_plus` package + `connectivityProvider` (identified as gap in architecture validation)
- Ad container widget: `shared/widgets/ad_banner_container.dart` — queue and history screens only, never camera/review/send (identified as gap)
- Duplicate scan detection: `GuestsDao.findDuplicate()` query for 24h window — soft warning, not hard block (identified as gap)

### UX Design Requirements

UX-DR1: Implement Material 3 design system with teal seed ColorScheme (`ColorScheme.fromSeed`), light + dark theme pair, and `ThemeData(useMaterial3: true)` — Direction A as primary
UX-DR2: Create `ThemeExtension` (AppQueueTheme) with semantic tokens for all queue states: queued, sending, failed-retryable, failed-terminal, paused-auth, sent — each with color + icon + label
UX-DR3: Implement `FacilitySessionBar` custom widget — always-visible facility anchor during scan session with facility name, session affordance (change/finish), states: none/active/disabled
UX-DR4: Implement `DocumentCameraView` custom widget — full-screen still capture with alignment frame, document type hint, torch toggle, states: permission-denied/initializing/ready/capturing/processing
UX-DR5: Implement `GuestSubmissionSnapshotCard` custom widget — review step showing "what will be sent" with tier badge (MRZ/OCR/manual), identity fields, conditional eVisitor fields, states: readonly_ok/editable/validation_error
UX-DR6: Implement `QueueGuestRow` custom widget — guest list row with name, doc hint, facility chip, status chip mapped to ThemeExtension queue tokens, actions: open detail/retry/remove
UX-DR7: Implement `BatchSendSummary` custom widget — partial batch and auth pause clarity with per-row result, aggregate progress, Croatian messages, states: in_progress/paused_auth/completed_partial/completed_all
UX-DR8: Implement `EVisitorMessagePanel` custom widget — display eVisitor UserMessage (Croatian) with optional collapsed system detail, primary fix action (focus field)
UX-DR9: Implement button hierarchy per M3: FilledButton (Confirm/Send/Retry), FilledTonalButton/OutlinedButton (Edit/Change facility), TextButton (Cancel/Dismiss), FAB (Scan only — never Send), destructive TextButton with error color + AlertDialog confirmation
UX-DR10: Implement feedback patterns: SnackBar for local success, summary screen for batch results, MaterialBanner/inline for recoverable errors, modal for auth re-prompt, Banner for offline status, LinearProgressIndicator for send progress
UX-DR11: Implement bottom NavigationBar with 4 destinations: Home, Queue (with Badge count), History, Settings — plus go_router shell route
UX-DR12: Implement form patterns: single-column layout, inline validation on blur + submit, progressive disclosure for rare fields (non-EU border crossing), no autocomplete on credential fields, Croatian error strings from l10n
UX-DR13: Implement empty states: queue empty with illustration + Start scanning CTA, history empty with 30-day retention explanation
UX-DR14: Implement responsive strategy: portrait-first, SafeArea + Flexible + scroll views, increased horizontal padding on wide phones, cap line length, no multi-column forms in v1
UX-DR15: Implement accessibility: WCAG 2.1 AA contrast targets, ≥48dp touch targets, state never color-only (icon + text), respect Reduce motion, TalkBack labels for icons/status/torch, focus management on error (move to first invalid field)
UX-DR16: Implement FLAG_SECURE on credential entry/display and guest PII screens per NFR16 — verify TalkBack and contrast still pass
UX-DR17: Implement single shared `InputDecorationTheme` and component themes (FilledButtonTheme, SegmentedButtonTheme, ChipTheme, NavigationBarTheme) to prevent per-widget style drift
UX-DR18: Implement camera-to-review visual continuity — shared color/typography rhythm so the flow does not feel like two different apps
UX-DR19: Implement neutral ad containers on queue and history screens — never compete with FAB/Send, follow Mobile Ads layout guidance, never interstitial during capture/review/send
UX-DR20: Implement Croatian as primary UI language with English fallback via ARB files — UI must tolerate longer Croatian strings (two-line titles, multiline errors, no clipped fixed-height)

### FR Coverage Map

| FR | Epic | Description |
|----|------|-------------|
| FR1 | Epic 4 | Camera document capture |
| FR2 | Epic 4 | MRZ extraction + checksum |
| FR3 | Epic 4 | OCR fallback |
| FR4 | Epic 4 | Manual entry/correction |
| FR5 | Epic 4 | Capture tier metadata |
| FR6 | Epic 4 | Read-only review card |
| FR7 | Epic 4 | Editable review mode |
| FR8 | Epic 4 | Non-document fields (dates, facility) |
| FR9 | Epic 4 | Client-side validation |
| FR10 | Epic 5 | Delete from queue |
| FR11 | Epic 3 | Add facility profile + defaults |
| FR12 | Epic 3 | Multi-facility CRUD |
| FR13 | Epic 3 | Session-scoped facility |
| FR14 | Epic 3 | Change facility between sessions |
| FR15 | Epic 3 | Encrypted credential storage |
| FR16 | Epic 5 | Local queue with facility association |
| FR17 | Epic 5 | View queue |
| FR18 | Epic 6 | Batch submit |
| FR19 | Epic 6 | Individual submit |
| FR20 | Epic 5 | State lifecycle tracking |
| FR21 | Epic 6 | Retry failed guests |
| FR22 | Epic 5 | 7-day stale purge |
| FR23 | Epic 6 | eVisitor authentication |
| FR24 | Epic 6 | Guest check-in submission |
| FR25 | Epic 6 | GUID generation + tracking |
| FR26 | Epic 6 | Session expiry re-auth |
| FR27 | Epic 6 | Croatian error mapping |
| FR28 | Epic 6 | API unavailability resilience |
| FR29 | Epic 6 | Non-EU conditional fields |
| FR30 | Epic 7 | 30-day history view |
| FR31 | Epic 7 | Status + timestamp per entry |
| FR32 | Epic 7 | 30-day auto-purge |
| FR33 | Epic 8 | AdMob display |
| FR34 | Epic 8 | UMP/CMP consent |
| FR35 | Epic 8 | Consent preference management |
| FR36 | Epic 3 | First-launch onboarding |
| FR37 | Epic 4 | Audio/haptic feedback |
| FR38 | Epic 4 | Croatian field-level validation |
| FR39 | Epic 5 | Duplicate scan warning (24h) |

## Epic List

### Epic 1: Project Foundation & App Shell
The app launches with themed Material 3 UI, bottom navigation between tabs, Croatian/English localization, and all foundational infrastructure (Drift schema, Riverpod, code gen pipeline, build flavors). No user-facing features yet, but the runnable skeleton that every feature plugs into. Story 1.6 builds the mock eVisitor server in parallel.
**FRs covered:** None directly (infrastructure enabling all FRs)
**NFRs addressed:** NFR4, NFR10, NFR11, NFR12
**UX-DRs:** UX-DR1, UX-DR2, UX-DR9, UX-DR11, UX-DR14, UX-DR17, UX-DR20

### Epic 2: Test Infrastructure & Deployment Quality
Docker compose pipeline (Android emulator + test runner containers) provides a deterministic `docker-compose up` E2E entrypoint. Patrol E2E suite covers all four user journeys (minimum 5 passing tests). CI jobs enforce coverage ≥70%, automate E2E on every PR. QA reports and AI Integration Log complete the training deliverables. Mock eVisitor server (Story 1.6) is a prerequisite — built in Epic 1.
**FRs covered:** None directly (enables quality assurance of all FRs)
**NFRs addressed:** NFR test strategy, CI pipeline, coverage gate
**UX-DRs:** N/A

### Epic 3: Facility Management & Onboarding
Host can add facility profiles with encrypted credentials, configure per-facility defaults (payment category, arrival organisation, service type, default stay), manage multiple facilities (edit, delete), and get guided through first-launch setup. The app knows who the host is and which facilities they manage.
**FRs covered:** FR11, FR12, FR13, FR14, FR15, FR36
**NFRs addressed:** NFR9, NFR15, NFR16
**UX-DRs:** UX-DR3, UX-DR12, UX-DR16

### Epic 4: Document Capture & Guest Review
Host can start a scanning session (scoped to a facility), capture a passport or ID card photo, see extracted data via MRZ (with checksum validation), OCR fallback, or manual entry. The submission snapshot card shows "what will be sent" — read-only on clean MRZ, editable when extraction is degraded. Host confirms and the guest enters the queue. Audio/haptic feedback signals success.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR37, FR38
**NFRs addressed:** NFR1a, NFR1b, NFR2, NFR5, NFR7, NFR13, NFR23
**UX-DRs:** UX-DR4, UX-DR5, UX-DR18

### Epic 5: Guest Queue & Local Workflow
Host can view all queued guests with facility tags and status chips, delete guests before submission, and see the state machine in action (captured → confirmed → ready). Duplicate scan warning within 24h. Queue is offline-durable — survives app kill, process death, device reboot. Stale entries auto-purge after 7 days.
**FRs covered:** FR10, FR16, FR17, FR20, FR22, FR39
**NFRs addressed:** NFR3, NFR8, NFR20, NFR22, NFR26, NFR27, NFR28
**UX-DRs:** UX-DR6, UX-DR13, UX-DR15

### Epic 6: eVisitor Submission & Error Handling
Host can submit all ready guests in batch or individually. The app authenticates with eVisitor (deferred login at first send), handles cookie sessions, submits via CheckInTourist/ImportTourists, shows per-guest results with Croatian error messages, supports retry for failed guests, handles auth expiry (pausedAuth state + re-auth prompt), and enforces non-EU conditional fields. Partial batch success is first-class UI.
**FRs covered:** FR18, FR19, FR21, FR23, FR24, FR25, FR26, FR27, FR28, FR29
**NFRs addressed:** NFR6, NFR19, NFR21, NFR25, NFR29
**UX-DRs:** UX-DR7, UX-DR8, UX-DR10

### Epic 7: Submission History
Host can view a 30-day history of submitted guests with status, timestamp, and facility context. Auto-purge clears entries older than 30 days. Provides proof-of-submission for inspector questions.
**FRs covered:** FR30, FR31, FR32
**NFRs addressed:** NFR14
**UX-DRs:** UX-DR13

### Epic 8: Ads & Consent Management
App displays non-intrusive banner ads on queue and history screens. UMP/CMP consent dialog presented before first ad load (EEA/UK compliance). Host can manage ad consent preferences in settings. Ads never interrupt capture, review, or submission flows.
**FRs covered:** FR33, FR34, FR35
**NFRs addressed:** NFR17, NFR24
**UX-DRs:** UX-DR19

---

## Epic 1: Project Foundation & App Shell

The app launches with themed Material 3 UI, bottom navigation between tabs, Croatian/English localization, and all foundational infrastructure (Drift schema, Riverpod, code gen pipeline, build flavors).

### Story 1.1: Flutter Project Initialization & Build Configuration

As a **developer**,
I want **the Flutter project created with all dependencies, build flavors, folder structure, and CI pipeline**,
So that **I have a working, analyzable codebase ready for feature implementation**.

**Acceptance Criteria:**

**Given** no project exists
**When** `flutter create --org hr.prijavko --platforms android prijavko` is run
**Then** the project compiles and runs on an Android emulator

**Given** the project is initialized
**When** I inspect `pubspec.yaml`
**Then** all architecture-specified dependencies are present: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `drift`, `dio`, `dio_cookie_manager`, `cookie_jar`, `freezed_annotation`, `json_annotation`, `go_router`, `flutter_secure_storage`, `google_mlkit_text_recognition`, `mrz_parser`, `camera`, `google_mobile_ads`, `firebase_crashlytics`, `firebase_analytics`, `connectivity_plus`, `path_provider`, `uuid` and dev dependencies: `build_runner`, `drift_dev`, `freezed`, `json_serializable`, `riverpod_lint`, `custom_lint`
**And** `analysis_options.yaml` is configured with strict rules (zero warnings policy)

**Given** build flavors are configured
**When** I run `flutter run --dart-define-from-file=config/dev.json`
**Then** the app launches with `API_BASE` pointing to `https://www.evisitor.hr/testApi` and `AD_ENABLED` set to `false`
**And** `config/prod.json` has `API_BASE` pointing to `https://www.evisitor.hr` and `AD_ENABLED` set to `true`

**Given** the folder structure is created
**When** I inspect `lib/`
**Then** the feature-based structure exists: `core/config/`, `core/theme/`, `core/l10n/`, `core/router/`, `core/result/`, `core/utils/`, `data/database/`, `data/database/tables/`, `data/database/daos/`, `data/database/migrations/`, `data/api/`, `data/repositories/`, `data/models/`, `features/capture/`, `features/queue/`, `features/facility/`, `features/send/`, `features/history/`, `features/onboarding/`, `features/settings/`, `shared/widgets/`

**Given** Android configuration
**When** I inspect `AndroidManifest.xml`
**Then** camera and internet permissions are declared, `android:allowBackup="false"` is set (or scoped `backup_rules.xml` excluding credentials and guest DB), and min/target SDK are configured

**Given** CI is configured
**When** I inspect `.github/workflows/ci.yml`
**Then** it runs `flutter analyze`, `flutter test`, and `build_runner` verify on push to `main`, and builds release AAB with prod config on tag

### Story 1.2: Core Domain Models, Database Schema & Code Generation

As a **developer**,
I want **the Drift database schema, freezed domain models, error handling pattern, and code generation pipeline working end-to-end**,
So that **all features have a shared data foundation to build on**.

**Acceptance Criteria:**

**Given** the project from Story 1.1
**When** I run `dart run build_runner build --delete-conflicting-outputs`
**Then** all `.g.dart` and `.freezed.dart` files are generated without errors

**Given** Drift tables are defined
**When** I inspect the database schema
**Then** 4 tables exist: `facilities` (id, name, facilityCode, defaults JSON), `credentials` (id, facilityId FK, encryptedUsername, encryptedPassword, createdAt), `guests` (id, guid UUID, facilityId FK, sessionId FK, state enum, captureTier enum, all eVisitor fields, eVisitorResponse, errorMessage, isTerminalFailure, createdAt, confirmedAt, submittedAt, source), `scan_sessions` (id, facilityId FK, startedAt, endedAt, guestCount)
**And** WAL mode is enabled for crash safety
**And** foreign keys are enforced
**And** indexes exist on `idx_guests_facility_id`, `idx_guests_state`

**Given** DAOs are defined
**When** I inspect `FacilitiesDao`, `GuestsDao`, `ScanSessionsDao`
**Then** each DAO provides basic CRUD operations and `.watch()` stream methods for reactive queries

**Given** freezed models are defined
**When** I inspect `data/models/`
**Then** `Guest`, `Facility`, `ScanSession` freezed models exist with `copyWith`, `==`, serialization
**And** `GuestState` enum has values: `captured`, `confirmed`, `ready`, `sending`, `sent`, `failed`, `pausedAuth`
**And** `CaptureTier` enum has values: `mrz`, `ocr`, `manual`
**And** `Failure` sealed class has variants: `NetworkFailure`, `AuthFailure`, `ApiFailure(userMessage)`, `ValidationFailure(fields)`, `StorageFailure`

**Given** `Result<T, Failure>` is defined
**When** I inspect `core/result/result.dart`
**Then** a sealed class `Result<T, Failure>` with `Success(T value)` and `Failure(Failure failure)` variants exists

**Given** core utilities are defined
**When** I inspect `core/utils/`
**Then** `DateFormatter` handles `YYYYMMDD` ↔ `DateTime` and Croatian display format `dd.MM.yyyy.`
**And** `UuidGenerator` produces UUID v4 strings
**And** `PiiScrubber` strips guest names, document numbers, MRZ data, and credentials from log messages

**Given** `MigrationStrategy` is defined
**When** I inspect `data/database/migrations/`
**Then** schema versioning with numbered migrations exists for future schema evolution
**And** the initial schema is version 1

### Story 1.3: Material 3 Theme, AppQueueTheme & Component Themes

As a **developer**,
I want **centralized Material 3 light/dark themes with queue state tokens and shared component themes**,
So that **all future screens reuse one visual system and queue status styling is consistent**.

**Acceptance Criteria:**

**Given** the app builds
**When** themes are applied in `PrijavkoApp`
**Then** `ThemeData` uses Material 3 and a teal-seeded `ColorScheme` for both light and dark from the same seed

**Given** `AppQueueTheme` is registered
**When** it is read from `Theme.of(context).extension<AppQueueTheme>()`
**Then** semantic tokens exist for queue states: queued, sending, failed-retryable, failed-terminal, paused-auth, sent — each with color and icon mapping
**And** failure severity follows architecture: `failed + isTerminalFailure==false` → retryable token, `failed + isTerminalFailure==true` → terminal token

**Given** component themes are configured
**When** I inspect `ThemeData`
**Then** shared `InputDecorationTheme`, `FilledButtonThemeData`, `NavigationBarThemeData`, `ChipThemeData` are defined once per brightness

**Given** Stories 1.4–1.5 are not yet implemented
**When** the app runs
**Then** the root remains a minimal placeholder (no `go_router` / full shell in this story) but uses the new theme — router and l10n land in 1.4–1.5

---

### Story 1.4: Localization (ARB) & Croatian Default

As a **host**,
I want **UI strings in Croatian with English available**,
So that **copy matches the product language and stays maintainable**.

**Acceptance Criteria:**

**Given** `flutter gen-l10n` / codegen is configured
**When** the app builds
**Then** `AppLocalizations` (or generated equivalent) is produced from ARB without errors

**Given** ARB files exist
**When** I inspect `assets/l10n/`
**Then** `app_hr.arb` (Croatian, primary) and `app_en.arb` (English, fallback) include tab labels, common actions (confirm, cancel, retry, send, delete), generic error placeholder, and app title — ready for Story 1.5 shell

**Given** locale resolution
**When** the app runs
**Then** Croatian-first behavior is explicit in code (policy documented) per PRD

**Given** placeholder UI from Story 1.3
**When** visible strings are shown
**Then** they use generated l10n — no hardcoded Croatian in new paths

---

### Story 1.5: go_router Shell, Onboarding Guard, Scaffold & Connectivity

As a **host**,
I want **bottom navigation, onboarding entry when no facility exists, and offline awareness**,
So that **I can move around the app and later features plug into fixed routes**.

**Acceptance Criteria:**

**Given** at least one facility profile exists
**When** the app launches
**Then** a shell route shows a bottom `NavigationBar` with Home, Queue, History, Settings (placeholder bodies, strings from l10n)

**Given** go_router is configured
**When** I inspect `app_router.dart`
**Then** stack routes exist as stubs for future camera → review → confirm (full-screen over tabs)
**And** a route guard redirects to onboarding when no facility profiles exist; redirect refreshes when `facilities` changes
**And** predictive back is enabled for Android 14+ (`enableOnBackInvokedCallback` + router behavior)

**Given** shared widgets
**When** I inspect `shared/widgets/`
**Then** `PrijavkoScaffold` and `ConnectivityBanner` (`connectivity_plus`) exist

**Given** responsive foundation
**When** the app runs on various widths
**Then** `SafeArea` is used, scroll/flex as needed, horizontal padding increases on wide phones (>600dp), no clipped titles at large text scale

**Given** Stories 1.3–1.4 are complete
**When** `MaterialApp` is replaced
**Then** `MaterialApp.router` preserves theme + l10n + `routerConfig`

---

### Story 1.6: Mock eVisitor Server

As a **developer**,
I want **a local Fastify + TypeScript mock of the eVisitor REST API running from day one**,
So that **every subsequent epic can make real HTTP calls against a deterministic backend without depending on the real eVisitor test API**.

**Acceptance Criteria:**

**Given** the mock server is started (`pnpm dev` from `test-infra/mock-evisitor/`)
**When** the Flutter app runs with `config/local.json` on an Android Studio AVD
**Then** `http://10.0.2.2:8080` resolves to the mock and `Login`, `CheckInTourist`, `ImportTourists` requests succeed

**Given** a `Login` POST with valid test credentials
**When** the mock processes the request
**Then** it responds 200 with `Set-Cookie: ASP.NET_SessionId=testsession123` matching the real eVisitor cookie name

**Given** a `Login` POST with invalid credentials
**When** the mock processes the request
**Then** it responds 401

**Given** a `CheckInTourist` or `ImportTourists` POST with a guest whose doc number matches `ERR_VALIDATION_*`
**When** the mock processes the request
**Then** it responds 400 with `{SystemMessage: "...", UserMessage: "Putovnica nije važeća."}`

**Given** a guest doc number matching `ERR_DUPLICATE_*`
**When** the mock processes the request
**Then** it responds 409 with `{SystemMessage: "...", UserMessage: "Gost je već prijavljen."}`

**Given** a request with `X-Mock-Scenario: expire-session` header or absent/expired cookie
**When** the mock processes the request
**Then** it responds with 401 or 302 → login HTML body (both paths exercised)

**Given** a request with `X-Mock-Scenario: unavailable` header
**When** the mock processes the request
**Then** it responds 503 with `{SystemMessage: "Service unavailable", UserMessage: ""}`

**Given** `GET /healthz`
**When** the mock is running
**Then** it responds 200 `{"status":"ok"}`

**Given** contract tests in `test-infra/mock-evisitor/test/`
**When** `vitest` runs
**Then** all fixture response shapes, status codes, and cookie headers are verified

**Technical notes:**
- Stack: Fastify + TypeScript, `pnpm` workspaces under `test-infra/mock-evisitor/`
- Fixtures in `test-infra/mock-evisitor/fixtures/` — JSON files, not hardcoded responses
- Postman MCP used during development to validate endpoint contracts interactively
- Cookie expiry configurable via env var `SESSION_TTL_SECONDS` (default 300) for re-auth E2E tests
- Local dev start: `cd test-infra/mock-evisitor && pnpm dev` — documented in `test-infra/README.md`
- Implement parallel with Story 1.1 (project init) — TypeScript project has no Flutter dependency

---

## Epic 2: Test Infrastructure & Deployment Quality

Docker compose pipeline (Android emulator + test runner containers) provides a deterministic `docker-compose up` E2E entrypoint. Patrol E2E suite covers all four user journeys with minimum 5 passing tests. CI jobs enforce coverage ≥70%, automate E2E on every PR. QA reports and AI Integration Log complete the training deliverables.

**Prerequisite:** Story 1.6 (Mock eVisitor Server) must be complete before any story in this epic starts.

**Execution sequencing:**

| Story | Start when | Blocks |
|---|---|---|
| 2.1 Docker compose pipeline | After Story 1.6 (mock server) | 2.2, 2.3 |
| 2.2 GitHub Actions E2E CI | After 2.1 | Automated regression on all subsequent PRs |
| 2.3 Patrol E2E test suite | After 2.1 + Epics 3–7 complete, **before Epic 8** | 2.4 coverage report |
| 2.4–2.6 QA reports + AI log | After all feature epics (3–8) complete | Training submission |

**Implementation order in practice:** Epic 1 (+ Story 1.6 in parallel) → 2.1 → 2.2 → Epics 3–7 → 2.3 → Epic 8 → 2.4 → 2.5 → 2.6

---

### Story 2.1: Docker Compose E2E Pipeline

As a **developer/CI pipeline**,
I want **`docker-compose -f docker-compose.e2e.yml up` to build the APK, boot an Android emulator, install the app, and run the Patrol E2E suite**,
So that **E2E tests run deterministically in CI without requiring a physical device or developer setup**.

**Acceptance Criteria:**

**Given** a Linux machine with Docker and `/dev/kvm` available (GHA `ubuntu-latest`)
**When** `docker-compose -f docker-compose.e2e.yml up --abort-on-container-exit` is run
**Then** the three containers start in dependency order: `mock-evisitor` → `android-emulator` → `test-runner`

**Given** all three containers are healthy
**When** `test-runner` executes
**Then** it builds the APK with `config/test.json`, connects to `android-emulator:5555` via ADB, installs the APK, and runs `patrol test`

**Given** the Patrol suite completes
**When** the compose command exits
**Then** JUnit XML and coverage artifacts are written to `./test-infra/output/`
**And** compose exits with the test runner's exit code (non-zero on failure)

**Given** any container fails its healthcheck
**When** `depends_on: condition: service_healthy` is evaluated
**Then** compose aborts rather than running tests against a broken dependency

**Given** Apple Silicon dev machine
**When** a developer attempts to run the compose pipeline locally
**Then** documentation in `test-infra/README.md` clearly states this is CI-only on Apple Silicon and directs to the local fast-loop instructions

**Technical notes:**
- `docker-compose.e2e.yml` — separate from any future app-services compose file
- `test-runner` Dockerfile: multi-stage — Flutter SDK base (heavy, cached) + patrol_cli + ADB tooling
- `budtmo/docker-android:emulator_14.0` (API 34, x86_64); `privileged: true` + `/dev/kvm` mount required
- `config/test.json`: `API_BASE=http://mock-evisitor:8080` (Docker service DNS) — never used outside compose

---

### Story 2.2: GitHub Actions E2E CI Job

As a **developer**,
I want **the E2E Patrol suite to run automatically on every PR and push to `main` via GitHub Actions**,
So that **regressions are caught before merge without manual intervention**.

**Acceptance Criteria:**

**Given** a push or PR to any branch
**When** the `base-checks` CI job passes (analyze + unit/widget tests)
**Then** the `e2e` job starts and runs `docker-compose -f docker-compose.e2e.yml up --abort-on-container-exit`

**Given** the KVM enablement step in the GHA workflow
**When** the `ubuntu-latest` runner starts
**Then** `/dev/kvm` is accessible inside the `android-emulator` container

**Given** Docker layer caching via `actions/cache`
**When** Dockerfiles have not changed since last run
**Then** warm pipeline completes in under 15 minutes total

**Given** the E2E job completes (pass or fail)
**When** the workflow finishes
**Then** JUnit XML and coverage artifacts are uploaded via `actions/upload-artifact` and visible in the GHA run summary

**Given** a `coverage-gate` job on push to `main`
**When** combined Dart + mock-server coverage is below 70% meaningful
**Then** the job fails with a clear report indicating which files are below threshold

**Technical notes:**
- Workflow file: `.github/workflows/e2e.yml`
- KVM enablement: `udevadm` rule for `/dev/kvm` group permissions
- `budtmo/docker-android` image pinned by digest in CI to prevent silent image changes

---

### Story 2.3: Patrol E2E Test Suite — Core User Journeys

As a **QA engineer**,
I want **Patrol E2E tests covering all four user journeys defined in the PRD**,
So that **complete scan-to-submit flows are verified end-to-end on a real Android emulator with a minimum of 5 passing tests**.

**Acceptance Criteria:**

**Given** the Patrol suite runs against the compose pipeline
**When** Journey 1 (happy path: scan → review → queue → batch send → history) executes
**Then** the test passes: guest captured, confirmed, sent, visible in history

**Given** Journey 2 (OCR fallback + eVisitor validation error)
**When** the test runs with a guest doc number `ERR_VALIDATION_*`
**Then** the app shows the Croatian `UserMessage` error on the queue row and the guest transitions to `failed(isTerminal: true)`

**Given** Journey 3 (first-time onboarding)
**When** the test runs on a fresh app install with no facility profiles
**Then** the onboarding guard redirects correctly and facility setup completes before queue access

**Given** Journey 4 (multi-facility session switching — Marina)
**When** the test runs with two facility profiles configured
**Then** the facility chip is visible on queue rows and switching facilities updates the active context

**Given** the camera permission system dialog
**When** the test reaches the camera screen for the first time
**Then** `$.native` grants the permission via Patrol's native automator — no manual grant required

**Given** the a11y journey (1 dedicated test)
**When** the queue screen renders with a guest in `failed` state
**Then** TalkBack-compatible `semanticsLabel` on the queue row is a single coherent string verified via `find.bySemanticsLabel`

**Minimum test count:** ≥5 passing Patrol E2E tests (training brief requirement). Journeys 1–4 + a11y journey = 5 minimum.

**Technical notes:**
- Test files in `integration_test/` using Patrol's `patrolTest` + `$` finder syntax
- Mock eVisitor server (Story 1.6) provides deterministic backend for all journey assertions

---

### Story 2.4: Test Coverage Report & Gap Analysis

As a **developer**,
I want **a coverage report identifying gaps against the 70% meaningful threshold**,
So that **I can close the most impactful gaps before release**.

**Acceptance Criteria:**

**Given** `flutter test --coverage` runs on the full test suite
**When** `lcov` generates the report (excluding `*.g.dart`, `*.freezed.dart`, `main.dart`)
**Then** total meaningful coverage is ≥70%

**Given** the mock server test suite runs (`vitest --coverage`)
**When** the report is generated (excluding fixture JSON files)
**Then** mock server meaningful coverage is ≥70%

**Given** coverage falls below 70% in any area
**When** the gap analysis runs
**Then** a written report in `_bmad-output/coverage-report.md` lists uncovered paths by priority (state machine > error mapping > validation > transport > UI)

---

### Story 2.5: Accessibility & Security QA Reports

As a **developer/QA engineer**,
I want **documented accessibility and security review reports**,
So that **the app meets WCAG AA intent and common mobile security requirements before release**.

**Acceptance Criteria:**

**Given** the accessibility review
**When** TalkBack is enabled on AVD and all primary screens are navigated
**Then** a report in `_bmad-output/accessibility-report.md` documents: zero critical WCAG violations, any warnings, and remediations applied

**Given** the security review
**When** AI-assisted review runs against OWASP Mobile Top 10 + project PII rules
**Then** a report in `_bmad-output/security-review.md` documents: findings, severity, and remediations
**And** all critical/high findings are resolved before the report is finalized

**Given** `dart pub audit`
**When** run against current `pubspec.lock`
**Then** no high-severity vulnerabilities in dependencies (or documented exceptions with justification)

---

### Story 2.6: AI Integration Log

As a **developer**,
I want **a completed AI Integration Log documenting AI and MCP usage throughout development**,
So that **the training deliverable is met and the log serves as an honest retrospective on AI-assisted development**.

**Acceptance Criteria:**

**Given** the log file at `_bmad-output/ai-integration-log.md`
**When** reviewed at project completion
**Then** it contains entries for: Agent Usage, MCP Server Usage (Postman MCP), Test Generation, Debugging with AI, and Limitations Encountered

**Given** each story completion
**When** the developer wraps up a story
**Then** a brief log entry is appended — not saved for a single retrospective dump at the end

**Given** the Limitations section
**When** written
**Then** it honestly identifies at least 3 cases where AI output required significant human correction or judgment

---

## Epic 3: Facility Management & Onboarding

Host can add facility profiles with encrypted credentials, configure per-facility defaults, manage multiple facilities (edit, delete), and get guided through first-launch setup. The app knows who the host is and which facilities they manage.

### Story 3.1: Facility Profile CRUD & Credential Storage

As a **host**,
I want **to add, edit, and delete facility profiles with my eVisitor credentials stored securely**,
So that **I can manage my properties and have my login details ready for submission without typing them each time**.

**Acceptance Criteria:**

**Given** the host navigates to facility management
**When** they tap "Add Facility"
**Then** a form appears with fields: display name, facility code, eVisitor username (OIB), eVisitor password, and per-facility defaults (TTPaymentCategory, ArrivalOrganisation, OfferedServiceType, default stay duration)

**Given** the host fills in valid facility details and taps Save
**When** the facility is persisted
**Then** the facility profile is saved to the `facilities` Drift table
**And** credentials (username + password) are encrypted via `flutter_secure_storage` (Android Keystore-backed) and stored in the `credentials` table
**And** no plaintext credentials exist in the Drift database or SharedPreferences

**Given** credential fields are displayed
**When** the host interacts with username/password inputs
**Then** keyboard autocomplete/suggestions are disabled (`enableSuggestions: false`, `autocorrect: false`) per NFR15
**And** the screen has `FLAG_SECURE` applied — no screenshots or recent-app thumbnails capture credentials

**Given** the host has existing facility profiles
**When** they view the facility list
**Then** all saved facilities are displayed with name and facility code
**And** the host can tap a facility to edit its details (name, defaults, credentials)
**And** the host can delete a facility with confirmation dialog (destructive action per UX-DR9)

**Given** the host edits a facility's credentials
**When** they save
**Then** the old encrypted credential blob is replaced with the new one in Keystore
**And** the facility profile updates in the `facilities` table

**Given** form validation
**When** the host submits with missing required fields (name, facility code, username, password)
**Then** inline Croatian validation errors appear on the invalid fields per UX-DR12
**And** the form uses single-column layout with validation on blur + submit

### Story 3.2: Session-Scoped Facility Selection

As a **host**,
I want **to select which facility I'm registering guests for when I start scanning**,
So that **every captured guest is tagged to the correct property and I never submit to the wrong facility**.

**Acceptance Criteria:**

**Given** the host taps "Start Scanning" from home
**When** the facility picker appears
**Then** a bottom sheet displays all saved facility profiles for selection
**And** the host must pick a facility before proceeding to document type selection and camera

**Given** a facility is selected
**When** the scanning session begins
**Then** the `FacilitySessionBar` widget appears as an always-visible anchor showing the facility display name
**And** the `FacilitySessionBar` stays visible during capture and review screens
**And** a `scan_sessions` record is created in Drift with the selected facility and start timestamp

**Given** the host finishes a session (or returns to home)
**When** they tap "Start Scanning" again
**Then** the app returns to neutral state — no lingering facility context
**And** the facility picker appears fresh, requiring explicit selection

**Given** only one facility profile exists
**When** the host taps "Start Scanning"
**Then** the single facility is still shown in the picker (no auto-select bypass — explicit confirmation is the poka-yoke)

**Given** no facility profiles exist
**When** the host taps "Start Scanning"
**Then** they are redirected to the facility setup flow (onboarding or facility add screen)

### Story 3.3: First-Launch Onboarding Flow

As a **new host**,
I want **to be guided through adding my first facility when I install the app**,
So that **I can start scanning guests without confusion about what to set up first**.

**Acceptance Criteria:**

**Given** the app is launched for the first time (no facility profiles in DB)
**When** the home screen would normally appear
**Then** the go_router route guard redirects to the onboarding screen instead

**Given** the onboarding screen is displayed
**When** the host reads the content
**Then** brief copy explains: "Add your eVisitor facility to get started" — clear, not sketchy (trust-building per UX emotional goals)
**And** a prominent CTA leads to the facility add form (reuses Story 2.1 form)

**Given** the host completes facility setup during onboarding
**When** the first facility is saved
**Then** the app navigates to the home screen
**And** subsequent app launches skip onboarding (route guard checks facility count > 0)

**Given** the host dismisses or navigates away from onboarding without adding a facility
**When** they return to the app
**Then** onboarding appears again — the app cannot proceed to scanning without at least one facility

### Story 3.4: Facility Defaults & Per-Facility Configuration

As a **host with multiple facilities**,
I want **each facility to have its own default values for payment category, arrival organisation, service type, and stay duration**,
So that **I don't have to re-enter these common fields for every guest at each property**.

**Acceptance Criteria:**

**Given** the host is adding or editing a facility
**When** they reach the defaults section of the form
**Then** fields are available for: TTPaymentCategory (dropdown/selection), ArrivalOrganisation (dropdown/selection), OfferedServiceType (dropdown/selection), and default stay duration (number of days)
**And** these fields use progressive disclosure — collapsed under a "Defaults" section, not cluttering the initial add flow

**Given** defaults are saved for a facility
**When** a guest is captured during a session with that facility
**Then** the review card pre-fills these default values for the guest (stay duration, payment category, etc.)
**And** the host can override any pre-filled default on the review card

**Given** a facility has no defaults configured
**When** a guest is captured
**Then** the default fields on the review card are empty — the host must fill them manually
**And** no error occurs from missing defaults — they are optional configuration

---

## Epic 4: Document Capture & Guest Review

Host can start a scanning session, capture a passport or ID card photo, see extracted data via MRZ (with checksum validation), OCR fallback, or manual entry. The submission snapshot card shows "what will be sent." Host confirms and the guest enters the queue.

### Story 4.1: Camera Setup & Document Capture

As a **host**,
I want **to open the camera, see a document alignment guide, and capture a still photo of a guest's passport or ID card**,
So that **the app can extract guest data from the document image**.

**Acceptance Criteria:**

**Given** a scanning session is active (facility selected)
**When** the host selects a document type (Passport or ID Card)
**Then** the `DocumentCameraView` opens full-screen with a camera preview, document alignment frame (passport or ID card shape), and a torch toggle button

**Given** the camera screen is displayed
**When** the host has not granted camera permission
**Then** a full-screen explanation is shown with an "Open Settings" action — no infinite retry loop

**Given** the camera is ready
**When** the host taps the shutter button
**Then** a still image is captured
**And** an immediate loading indicator appears ("Reading document…") within 1 second per NFR2
**And** the captured image bytes are passed to the ML Kit / MRZ extraction pipeline
**And** the image bytes are discarded after extraction — never written to disk per NFR13

**Given** the camera is active in low-light conditions
**When** the host taps the torch toggle
**Then** the device flashlight activates to illuminate the document

**Given** the capture flow
**When** the host taps back/cancel
**Then** they return to the session (facility still active) — can scan another guest or end session

**Given** audio/haptic feedback is enabled
**When** a document is captured and MRZ checksum passes
**Then** a success audio cue and/or haptic feedback fires per FR37
**And** when MRZ fails, an error-tone or distinct haptic signals the degraded path

### Story 4.2: MRZ Extraction with Checksum Validation

As a **host**,
I want **the app to automatically read the MRZ zone of the captured document and validate it**,
So that **guest data is extracted accurately without manual typing**.

**Acceptance Criteria:**

**Given** a document image is captured
**When** ML Kit text recognition runs on-device (no network required per NFR23)
**Then** the system attempts to detect and extract the MRZ zone

**Given** an MRZ zone is detected
**When** the text is parsed by `mrz_parser`
**Then** ICAO TD1 (3×30 — ID cards), TD2 (2×36), and TD3 (2×44 — passports) formats are supported
**And** composite checksum validation runs per ICAO 9303 spec

**Given** MRZ checksum passes
**When** fields are extracted
**Then** the following fields are populated: surname, given names, document number, nationality, date of birth, sex, document expiry date
**And** the capture tier is set to `CaptureTier.mrz`
**And** fields NOT available from MRZ (city of birth, city of residence, residence address) remain empty for manual entry or OCR

**Given** MRZ checksum fails
**When** the parsed data has invalid check digits
**Then** the system proceeds to OCR fallback (Story 3.3) — not a dead end

**Given** no MRZ zone is detected in the image
**When** text recognition completes
**Then** the system proceeds to OCR fallback — the host is not asked to "try again" unless they choose to

**Given** performance requirements
**When** MRZ extraction completes on a mid-range device (Snapdragon 600-series, 2022+, release build)
**Then** capture-to-parsed-data display completes within 3 seconds per NFR1a

### Story 4.3: OCR Fallback Extraction

As a **host**,
I want **the app to attempt OCR text extraction when MRZ fails or is absent**,
So that **I still get partially pre-filled fields instead of typing everything manually**.

**Acceptance Criteria:**

**Given** MRZ extraction failed (checksum invalid or MRZ not detected)
**When** the system falls back to OCR
**Then** ML Kit text recognition extracts text regions from the full document image (on-device, no network)
**And** the capture tier is set to `CaptureTier.ocr`

**Given** OCR text is extracted
**When** fields are mapped from recognized text
**Then** the system attempts to populate: surname, given names, document number, date of birth, nationality from text regions
**And** fields that cannot be confidently extracted remain empty for manual entry

**Given** OCR extraction completes
**When** results are presented
**Then** the review card opens in editable mode (not read-only) — the host knows extraction was degraded and should verify

**Given** OCR also fails to extract meaningful data
**When** no fields could be populated
**Then** the system falls through to full manual entry (capture tier set to `CaptureTier.manual`)
**And** the review card opens fully editable with all fields empty

**Given** performance requirements
**When** OCR fallback completes on a mid-range device
**Then** capture-to-parsed-data display completes within 5 seconds per NFR1b

### Story 4.4: Guest Review Card, Validation & Queue Entry

As a **host**,
I want **to review extracted guest data on a submission snapshot card, correct any errors, fill in remaining fields, and confirm the guest into the queue**,
So that **I know exactly what will be sent to eVisitor and can fix problems before submission**.

**Acceptance Criteria:**

**Given** MRZ extraction succeeded (checksum passed)
**When** the review card appears
**Then** the `GuestSubmissionSnapshotCard` displays in read-only mode with a tier badge showing "MRZ"
**And** all extracted fields are shown (name, document number, DOB, nationality, sex, expiry)
**And** non-MRZ fields (city of birth, city of residence, stay dates, payment category) show facility defaults if configured or empty if not
**And** a prominent "Confirm" button (FilledButton per UX-DR9) adds the guest to the queue

**Given** OCR or manual extraction
**When** the review card appears
**Then** the card displays in editable mode with the appropriate tier badge ("OCR" or "Manual")
**And** all fields are editable — the host can correct any extracted value
**And** empty fields are clearly indicated as requiring input

**Given** the review card is in read-only mode
**When** the host taps "Edit"
**Then** the card switches to editable mode (FR7) — all fields become editable

**Given** non-EU guest (citizenship outside EU)
**When** the review card is displayed
**Then** additional mandatory fields appear: BorderCrossing and PassageDate (per FR29)
**And** these fields are shown via progressive disclosure — visible only when citizenship triggers the requirement

**Given** the host fills in stay dates
**When** arrival date and departure date fields are set
**Then** the dates are formatted for display in Croatian format (dd.MM.yyyy.)
**And** departure must be after arrival
**And** stay duration must not exceed 90 days (MUP constraint)

**Given** field validation runs (on blur + on Confirm tap)
**When** invalid data is detected
**Then** inline Croatian error messages appear on the invalid fields per FR38
**And** field length limits are enforced: document number ≤ 16 chars, name/surname ≤ 64 chars, city of birth/residence ≤ 64 chars
**And** the "Confirm" button is disabled while validation errors exist

**Given** all validation passes and the host taps Confirm
**When** the guest is added to the queue
**Then** a new `guests` record is inserted into Drift with state `captured` → immediately transitioned to `confirmed`
**And** the guest is associated with the active session's facility
**And** a UUID v4 GUID is generated and persisted for idempotency (FR25)
**And** the app returns to the camera for the next guest (or session can be ended)
**And** FLAG_SECURE is applied to the review screen (guest PII visible per NFR16)

---

## Epic 5: Guest Queue & Local Workflow

Host can view all queued guests with facility tags and status chips, delete guests before submission, see the state machine in action. Queue is offline-durable. Stale entries auto-purge after 7 days.

### Story 5.1: Queue List UI with State Chips & Facility Tags

As a **host**,
I want **to view all my queued guests with their status, facility assignment, and document info at a glance**,
So that **I know exactly what's ready to send and can manage my pending registrations**.

**Acceptance Criteria:**

**Given** the host navigates to the Queue tab
**When** guests exist in the queue
**Then** a list of `QueueGuestRow` widgets is displayed, each showing: guest name (surname + given name), document number hint, facility chip (facility display name), and status chip (state from state machine)
**And** status chips are styled using `AppQueueTheme` `ThemeExtension` tokens — each state has distinct color + icon (never color-only per UX-DR15)
**And** the states rendered include: confirmed/ready (queued), sending, sent (success), failed-retryable, failed-terminal, pausedAuth

**Given** the queue is empty
**When** the host views the Queue tab
**Then** an empty state is displayed with an illustration and a "Start Scanning" CTA button per UX-DR13

**Given** the queue has many guests
**When** the list renders with up to 50 guests
**Then** scrolling remains smooth with no sustained jank per NFR3

**Given** the Queue tab in the NavigationBar
**When** guests are in the queue (state < sent)
**Then** a Badge on the Queue tab shows the count of pending guests per UX-DR11

**Given** the host taps a guest row
**When** the detail view opens
**Then** the host sees full guest details including all eVisitor fields, capture tier, facility, and current state

### Story 5.2: Queue Management — Delete & Duplicate Warning

As a **host**,
I want **to remove guests from the queue before submission and be warned about duplicate scans**,
So that **I can correct mistakes and avoid accidentally registering the same guest twice**.

**Acceptance Criteria:**

**Given** a guest is in the queue with state `confirmed` or `ready`
**When** the host selects "Remove" on the guest row
**Then** a confirmation dialog appears (destructive action per UX-DR9)
**And** upon confirmation, the guest record is deleted from the Drift `guests` table
**And** the queue list updates reactively (Drift stream → provider → UI)

**Given** a guest is in state `sent`
**When** the host views the guest
**Then** no "Remove" action is available — sent guests move to history

**Given** a guest is in state `sending`
**When** the host views the guest
**Then** no "Remove" action is available — cannot delete while in-flight

**Given** the host captures a new guest
**When** `GuestsDao.findDuplicate()` detects a match (same facilityId + dateOfBirth + documentNumber within 24 hours) per FR39
**Then** a soft warning is displayed: "A guest with the same document was scanned recently"
**And** the warning does not block the capture — the host can still confirm (soft warning, not hard block)

### Story 5.3: Queue Durability, State Recovery & Auto-Purge

As a **host**,
I want **my guest queue to survive app crashes, process death, and device reboots without losing any data**,
So that **I never lose captured guests and can always resume where I left off**.

**Acceptance Criteria:**

**Given** guests are in the queue
**When** the app is killed (process death, crash, or force stop)
**Then** all guest records persist in the Drift database (SQLite with WAL mode) per NFR20
**And** on next app launch, the queue displays exactly the same guests with their last known states

**Given** a guest was in `sending` state when the app crashed
**When** the app restarts
**Then** the guest's state is recovered to `ready` (not stuck in transient `sending` state) per NFR26
**And** the host can retry sending manually — no ghost sends or duplicate anxiety

**Given** the app was in an active session (facility selected)
**When** the app is killed and restarted
**Then** the session context (active facility, queue position) is restored per NFR27
**And** the host sees continuity of workflow, not a blank slate

**Given** unsent guests exist in the queue
**When** 7 days pass since their `createdAt` timestamp
**Then** the system automatically purges these stale entries per FR22
**And** purge runs on app launch (not continuous background process)

**Given** the app is updated via Play Store
**When** the new version launches
**Then** all queue data survives without data loss per NFR28
**And** Drift migration strategy handles any schema changes

**Given** the device is offline
**When** the host uses the app
**Then** all capture, review, and queue functions remain fully operational per NFR22
**And** the `ConnectivityBanner` indicates offline status

---

## Epic 6: eVisitor Submission & Error Handling

Host can submit guests to eVisitor in batch or individually, handle Croatian errors, retry failed submissions, and see per-guest results. Deferred auth at first send. Partial batch success is first-class UI.

### Story 6.1: eVisitor Authentication & Cookie Session Management

As a **host**,
I want **the app to log in to eVisitor with my stored credentials and maintain the session across submissions**,
So that **I don't have to type my login every time and the app handles session expiry automatically**.

**Acceptance Criteria:**

**Given** the host initiates a send action for the first time in a session
**When** no active eVisitor cookie session exists
**Then** the app retrieves encrypted credentials from `flutter_secure_storage` for the relevant facility
**And** sends `POST Resources/AspNetFormsAuth/Authentication/Login` with `(UserName, Password, apikey)` to eVisitor
**And** all communication uses HTTPS exclusively per NFR12

**Given** authentication succeeds
**When** the server returns `true` + cookies (`.ASPXAUTH`, affinity, language)
**Then** cookies are stored in `PersistCookieJar` (file-backed under `getApplicationDocumentsDirectory()/.cookies/`)
**And** cookies survive process death — no re-login required until session expiry
**And** subsequent API calls include these cookies automatically

**Given** a stored session exists (cookies present)
**When** the host sends a guest
**Then** the app reuses the existing cookies — no unnecessary re-login

**Given** the eVisitor session expires mid-batch (401 response or redirect-to-login)
**When** the app detects auth failure per NFR19
**Then** the app automatically re-authenticates using stored credentials
**And** replays the failed request once after successful re-auth
**And** no guest data is lost during re-authentication

**Given** re-authentication fails (wrong password, account locked, etc.)
**When** the retry auth attempt fails
**Then** all in-flight and pending guests transition to `pausedAuth` state
**And** an auth prompt dialog appears for the host to verify/update credentials
**And** after successful manual re-auth, `resumeAfterAuth()` resets all `pausedAuth` guests to `ready`

**Given** multi-facility batch send
**When** guests belong to different facilities
**Then** the app authenticates per-facility using each facility's stored credentials
**And** cookie jars are scoped or managed to prevent credential mixing

### Story 6.2: Guest Submission & XML Payload Construction

As a **host**,
I want **to submit my queued guests to eVisitor individually or all at once**,
So that **guests are registered in the government system and I've met my legal obligation**.

**Acceptance Criteria:**

**Given** guests in the queue with state `ready`
**When** the host taps "Send All"
**Then** the app submits guests sequentially (one API call per guest, not concurrent) per architecture retry policy
**And** each guest transitions to `sending` state before its API call
**And** a `LinearProgressIndicator` shows overall batch progress per UX-DR10

**Given** an individual guest in state `ready`
**When** the host taps "Send" on that guest's row
**Then** only that guest is submitted — other guests are unaffected

**Given** a guest is being submitted
**When** the `XmlPayloadBuilder` constructs the payload
**Then** all Dart camelCase fields are mapped to eVisitor PascalCase names (TouristName, DocumentNumber, etc.)
**And** dates are formatted as `YYYYMMDD`, times as `hh:mm`
**And** the guest's persisted GUID is sent as the `ID` parameter (mandatory since 2017-06-01) per FR25
**And** non-EU guests include BorderCrossing and PassageDate fields per FR29

**Given** eVisitor accepts the guest
**When** a success response is returned
**Then** the guest transitions to `sent` state with `submittedAt` timestamp in Drift
**And** the eVisitor response is stored on the guest record

**Given** eVisitor rejects the guest
**When** an error response `{SystemMessage, UserMessage}` is returned
**Then** the guest transitions to `failed` state with `errorMessage` set to the `UserMessage` (Croatian)
**And** `isTerminalFailure` is set based on HTTP status: `true` for 400/404 (bad data), `false` for 429/503/timeout/network

**Given** the client-side timeout
**When** 15 seconds elapse without a response per NFR6
**Then** the request is cancelled, the guest transitions to `failed` with `isTerminalFailure = false`
**And** retry is available immediately

**Given** duplicate submission prevention per NFR29
**When** a guest with an existing GUID has already been sent
**Then** the app checks GUID tracking before re-sending — prevents the same guest being submitted twice even after crash recovery

**Given** a failure on one guest in a batch
**When** that guest is marked `failed`
**Then** the batch continues for remaining guests — failure on one does not abort the rest

### Story 6.3: Error Mapping, Retry & Failure Classification

As a **host**,
I want **to see eVisitor errors in Croatian, understand what to fix, and retry failed guests**,
So that **I can resolve submission problems without guessing what went wrong**.

**Acceptance Criteria:**

**Given** eVisitor returns an error with `{SystemMessage, UserMessage}`
**When** the `ErrorMapper` processes the response
**Then** `UserMessage` is passed through directly as the Croatian human-readable error per FR27
**And** the error is wrapped in `Failure.api(userMessage: "...")` preserving the Croatian text to UI

**Given** a guest failed with `isTerminalFailure == false` (network, timeout, 429, 503)
**When** the host views the failed guest
**Then** the `EVisitorMessagePanel` displays the error message
**And** a "Retry" action (FilledButton) is available per FR21
**And** the row uses the `failed-retryable` ThemeExtension token (warning-level color + retry icon)

**Given** the host taps Retry on a retryable failure
**When** retry is initiated
**Then** the guest transitions from `failed` → `ready` → `sending`
**And** exponential backoff with jitter is applied: 1s, 2s, 4s base + random 0–500ms per NFR21
**And** max 3 attempts per manual send action

**Given** a guest failed with `isTerminalFailure == true` (400 bad data, business rule rejection)
**When** the host views the failed guest
**Then** the `EVisitorMessagePanel` shows the Croatian error with a "Fix" action to edit fields
**And** the row uses the `failed-terminal` ThemeExtension token (error-level color + edit icon)
**And** Retry is disabled until fields are edited — the host must fix the data first

**Given** the host edits a terminally failed guest's fields
**When** corrections are saved
**Then** the guest transitions from `failed` → `ready` (retry now enabled)
**And** `isTerminalFailure` is cleared

**Given** client-side validation errors
**When** detected before submission
**Then** Croatian error strings from l10n ARB files are used (matching eVisitor terminology where known)

### Story 6.4: Batch Send UI & Auth Pause Handling

As a **host**,
I want **to see per-guest results during batch send, understand partial success, and handle auth interruptions clearly**,
So that **I always know which guests were registered and which need attention**.

**Acceptance Criteria:**

**Given** a batch send is in progress
**When** the `BatchSendSummary` screen/panel is displayed
**Then** each guest shows its individual result: sending (spinner), sent (green check), failed-retryable (warning), failed-terminal (error)
**And** aggregate progress is visible (e.g., "5 of 7 sent")
**And** the UI remains responsive — network operations never block the UI thread per NFR8

**Given** the batch completes with mixed results (partial success)
**When** the summary is displayed
**Then** the host sees which guests succeeded and which failed — per-row clarity, not all-or-nothing
**And** the summary persists until dismissed (not auto-vanish)
**And** "Retry Failed" action is available for all retryable failures

**Given** auth expires during a batch (401 detected)
**When** automatic re-auth also fails
**Then** all remaining unsent + in-flight guests transition to `pausedAuth` state
**And** the `BatchSendSummary` shows `paused_auth` state with a "Re-authenticate" action
**And** already-sent guests in this batch retain their `sent` status — no rollback

**Given** the host re-authenticates successfully after auth pause
**When** credentials are verified
**Then** all `pausedAuth` guests transition back to `ready` via `resumeAfterAuth()`
**And** the host can resume sending with one tap

**Given** the app is offline when send is attempted
**When** no network is available
**Then** the send action is blocked with a clear message ("No network — sending will wait")
**And** the queue remains intact — no data loss per FR28
**And** the `ConnectivityBanner` is visible

---

## Epic 7: Submission History

Host can view a 30-day history of submitted guests with status, timestamp, and facility context. Provides proof-of-submission for inspector questions.

### Story 7.1: History List with Status & Timestamps

As a **host**,
I want **to view a history of all guests I've submitted in the past 30 days**,
So that **I have proof of registration if an inspector asks and can verify what was sent**.

**Acceptance Criteria:**

**Given** the host navigates to the History tab
**When** submitted guests exist (state = `sent` or `failed` with `submittedAt` set)
**Then** a list displays each historical entry with: guest name, document number hint, facility name, submission status (sent/failed), timestamp of submission
**And** entries are sorted by submission date (newest first)

**Given** the host taps a history entry
**When** the detail view opens
**Then** full guest details are shown: all eVisitor fields, capture tier, facility, submission timestamp, eVisitor response, and failure reason (if failed)

**Given** the history is empty
**When** the host views the History tab
**Then** an empty state explains "No submissions in the past 30 days" with a brief note about 30-day retention per UX-DR13

**Given** FLAG_SECURE requirements
**When** the history screen displays guest PII
**Then** FLAG_SECURE is applied per NFR16

### Story 7.2: History Auto-Purge (30 Days)

As a **host**,
I want **old submission records to be automatically deleted after 30 days**,
So that **guest personal data isn't retained longer than necessary for my records**.

**Acceptance Criteria:**

**Given** history entries exist with `submittedAt` timestamps
**When** the app launches (or a periodic check runs)
**Then** entries older than 30 days (based on device-local clock, UTC-normalized) are permanently deleted from the Drift `guests` table per NFR14
**And** deletion is irrecoverable — no manual recovery possible

**Given** a guest was submitted 29 days ago
**When** the purge runs
**Then** the entry is retained — only entries strictly older than 30 days are purged

**Given** the device clock is abnormal (set far in the future)
**When** the purge runs
**Then** UTC-normalized comparison prevents premature purge under normal clock drift
**And** extreme clock manipulation is the host's responsibility (documented, not defended against)

---

## Epic 8: Ads & Consent Management

App displays non-intrusive banner ads on queue and history screens. UMP/CMP consent dialog presented before first ad load. Ads never interrupt capture, review, or submission flows.

### Story 8.1: UMP/CMP Consent Flow

As a **host in the EEA/UK**,
I want **to be asked for ad personalization consent before any ads load**,
So that **my privacy is respected and the app complies with EEA regulations**.

**Acceptance Criteria:**

**Given** the app launches for the first time (or consent has not yet been collected)
**When** the consent check runs
**Then** the UMP/CMP consent dialog is presented per FR34
**And** the dialog appears before the first ad load — no ads shown without consent decision

**Given** the consent dialog is displayed
**When** the host makes a consent choice (accept personalized, accept non-personalized, or reject)
**Then** the choice is persisted and respected for all future ad loads per FR35
**And** AdMob SDK is configured according to the consent level

**Given** the consent flow
**When** the dialog is presented
**Then** it does not appear during capture, review, or send flows — it is positioned during app init or settings access
**And** the consent UI feels transparent and honest — not "ads sneaking in" (per UX emotional goals)

**Given** the host wants to change consent
**When** they navigate to Settings
**Then** an option to "Manage ad preferences" re-presents the consent dialog
**And** the new choice takes effect immediately

**Given** Google Play data safety requirements per NFR17
**When** the app declares data collection
**Then** ad network data collection is disclosed per consent level

### Story 8.2: AdMob Integration & Banner Placement

As a **host**,
I want **ads displayed unobtrusively while I manage my queue and history**,
So that **the app remains free while ads don't interfere with my core workflow**.

**Acceptance Criteria:**

**Given** consent has been collected and ads are enabled (prod flavor)
**When** the host views the Queue or History screens
**Then** a banner ad is displayed in a neutral container (`AdBannerContainer` widget) per UX-DR19
**And** the ad container does not compete with the FAB, Send button, or primary actions
**And** the ad loads asynchronously — screen content appears immediately, ad fills in when ready

**Given** the host is on the Camera, Review, Send Progress, or Onboarding screens
**When** the screen renders
**Then** no ads are displayed — ads never interrupt capture, review, or submission flows per NFR24 and PRD

**Given** the dev build flavor
**When** the app runs with `config/dev.json`
**Then** ads are disabled (`AD_ENABLED: false`) — no AdMob calls in development

**Given** the ad fails to load (network issue, no fill)
**When** the ad container has no ad
**Then** the container collapses gracefully — no blank space or error shown
**And** core app functionality is unaffected

**Given** a full-screen interstitial ad
**When** the ad SDK attempts to show it
**Then** it is never displayed — no full-screen interstitials during any flow per NFR24
