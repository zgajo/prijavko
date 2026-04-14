# Story 1.1: Flutter Project Initialization & Build Configuration

Status: done

<!-- Ultimate context engine analysis completed — comprehensive developer guide created. Optional: run validate-create-story before dev-story. -->

## Story

As a **developer**,
I want **the Flutter project created with all dependencies, build flavors (dev/prod via dart-define), feature folder structure, Android hardening, and CI pipeline**,
so that **I have a working, analyzable codebase ready for Story 1.2+ feature implementation**.

## Acceptance Criteria

1. **Project bootstrap** — Given no project exists, when `flutter create --org hr.prijavko --platforms android prijavko` is run, then the project compiles and runs on an Android emulator.

2. **Dependencies & analysis** — Given the project is initialized, when `pubspec.yaml` is inspected, then all dependencies below are declared with compatible versions, and `analysis_options.yaml` enforces strict analysis (zero-warnings policy target: `dart analyze` clean).

   **Runtime:** `flutter_riverpod`, `riverpod_annotation`, `drift`, `dio`, `dio_cookie_manager`, `cookie_jar`, `freezed_annotation`, `json_annotation`, `go_router`, `flutter_secure_storage`, `google_mlkit_text_recognition`, `mrz_parser`, `camera`, `google_mobile_ads`, `firebase_core`, `firebase_crashlytics`, `firebase_analytics`, `connectivity_plus`, `path_provider`, `uuid`

   **Dev:** `build_runner`, `drift_dev`, `freezed`, `json_serializable`, `riverpod_generator`, `riverpod_lint`, `custom_lint`

   *Note:* `firebase_core` is required for Crashlytics/Analytics; add if not implicit.

3. **Environment config** — Given `config/dev.json` and `config/prod.json` exist, when the app is run with `flutter run --dart-define-from-file=config/dev.json`, then runtime config exposes `API_BASE` = `https://www.evisitor.hr/testApi` and `AD_ENABLED` = `false`; `config/prod.json` exposes `API_BASE` = `https://www.evisitor.hr` and `AD_ENABLED` = `true`.

4. **App config wiring** — Given compile-time defines are set, when `lib/core/config/app_config.dart` (or equivalent) is read, then it reads `API_BASE` and `AD_ENABLED` (via `String.fromEnvironment` / build-time injection from dart-define) without hardcoding secrets.

5. **Folder structure** — Given `lib/` is inspected, then the following **directories exist** (use `.gitkeep` where empty so Git tracks them): `core/config/`, `core/theme/`, `core/l10n/`, `core/router/`, `core/result/`, `core/utils/`, `data/database/`, `data/database/tables/`, `data/database/daos/`, `data/database/migrations/`, `data/api/`, `data/repositories/`, `data/models/`, `features/capture/`, `features/queue/`, `features/facility/`, `features/send/`, `features/history/`, `features/onboarding/`, `features/settings/`, `shared/widgets/`.

6. **Android manifest & backup** — Given `AndroidManifest.xml` is inspected, then `INTERNET` and `CAMERA` are declared; `android:allowBackup` is `false` **or** full backup is disabled via `backup_rules.xml` that excludes app-private DB and credential paths; min/target SDK align with PRD intent (min API ≥ 24 for Keystore/camera baseline; compile/target latest stable per current Flutter/Android template).

7. **Application ID** — Given architecture and project-context specify **`hr.prijavko.app`**, when Gradle is configured, then `applicationId` / `namespace` match `hr.prijavko.app` (adjust from default `hr.prijavko.prijavko` produced by `flutter create`).

8. **CI** — Given `.github/workflows/ci.yml` exists, when it runs on push to `main`, then it runs `flutter analyze`, `flutter test`, and a codegen check (`dart run build_runner build --delete-conflicting-outputs` + fail if working tree dirty for generated files, or equivalent verify step). On **tag** push, it builds release **AAB** with `config/prod.json` defines.

## Tasks / Subtasks

- [x] Run `flutter create --org hr.prijavko --platforms android prijavko`; open in IDE; confirm `flutter run` on emulator. (AC: #1)
- [x] Set Android **`applicationId` / `namespace` to `hr.prijavko.app`** in `android/app/build.gradle(.kts)`. (AC: #7)
- [x] Add all **pubspec** dependencies and dev_dependencies; run `dart pub get`. (AC: #2)
- [x] Add **`analysis_options.yaml`**: include `package:flutter_lints` or stricter rules + **`custom_lint`** + **`riverpod_lint`**; fix all issues until `dart analyze` is clean. (AC: #2)
- [x] Add **`build.yaml`** if needed for Drift/riverpod_generator options per Drift docs. (AC: #2, #8)
- [x] Create **`config/dev.json`** and **`config/prod.json`** with exact URLs and flags from AC #3. (AC: #3)
- [x] Implement **`lib/core/config/app_config.dart`** reading compile-time defines; document run command in `README.md`. (AC: #4)
- [x] Create **feature folder tree** under `lib/` with `.gitkeep` as needed. (AC: #5)
- [x] Add minimal **`lib/main.dart`**: `runApp` + `ProviderScope` (can show placeholder `MaterialApp` home) so Riverpod is wired. (AC: #2, #5)
- [x] **AndroidManifest**: permissions; backup strategy per AC #6; add **`res/xml/backup_rules.xml`** if using scoped backup. (AC: #6)
- [x] **Firebase**: Create Firebase Android app with package `hr.prijavko.app`; add **`google-services.json`** under `android/app/`; apply Google Services + Firebase Crashlytics Gradle plugins per current FlutterFire docs. Initialize Crashlytics/Analytics in `main.dart` with **no PII** (stub handlers OK). (AC: #2)
- [x] **CI**: Add `.github/workflows/ci.yml` — analyze, test, build_runner verify, tag → `flutter build appbundle --dart-define-from-file=config/prod.json`. (AC: #8)
- [x] **`README.md`**: document dev run, prod build, and CI behavior. (AC: #8)

## Dev Notes

### Scope (this story vs next)

- **In scope:** Project skeleton, deps, lint, config JSON, dart-define wiring, folder layout, Android permissions/backup/ID, CI, Firebase wiring for Crashlytics/Analytics stubs.
- **Out of scope for 1.1:** Drift tables, DAOs, `Result`/`Failure` implementation, go_router shell, theme — those are **Story 1.2 / 1.3**. Do not implement business features; avoid cross-feature imports.

### Architecture compliance

| Topic | Requirement |
|-------|-------------|
| Stack | Flutter (Dart), Riverpod 3 + codegen, Drift, Dio, go_router, freezed — [Source: `_bmad-output/planning-artifacts/architecture.md` — Starter Template, State Management] |
| Config | Dev/prod via `--dart-define-from-file`; no secrets in repo — [Source: `architecture.md` — Build Flavors, Environment Configuration] |
| Structure | Feature-based `lib/` layout matches architecture tree; `data/` shared by features — [Source: `architecture.md` — Project Structure, Project Structure & Boundaries] |
| CI | Analyze + test + codegen on `main`; release AAB on tag — [Source: `architecture.md` — Development Workflow, epics Additional Requirements] |
| Package ID | **`hr.prijavko.app`** — [Source: `_bmad-output/project-context.md` — Technology Stack] |

### Library & tooling

- Prefer **latest stable** Flutter/Dart; lock versions in `pubspec.lock` after `pub get`.
- **Firebase:** Use FlutterFire CLI or manual Gradle setup; ensure Crashlytics does not log PII (align later with `PiiScrubber` in Story 1.2).
- **custom_lint / riverpod_lint:** Required by epic AC — configure `analyzer.plugins` in `analysis_options.yaml`.

### File structure requirements

- Align with [Source: `architecture.md` — Complete Project Directory Structure]. Story 1.1 creates **directories** + minimal entrypoints; full files (e.g. `app_router.dart`, `app_database.dart`) land in 1.2/1.3.
- **`build.yaml`**: Often needed for Drift `drift_dev` options — add now to avoid churn in 1.2.

### Testing requirements

- `flutter test` must pass (default placeholder test is fine; can add one smoke test that `AppConfig` parses expected dev defines when invoked with `--dart-define-from-file=config/dev.json` in CI).
- No integration tests required for 1.1 unless trivial.

### Project context reference

- Global rules: `_bmad-output/project-context.md` (imports, no `setState`, Riverpod codegen, etc.) — full enforcement starts with feature code in later stories; 1.1 should not violate them in scaffold code.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.1]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Starter Template Evaluation, Build Flavors, Directory Structure, Development Workflow]
- [Source: `_bmad-output/planning-artifacts/prd.md` — Min Android API 24+, Target latest]
- [Source: `_bmad-output/project-context.md` — Technology Stack, CI, analysis]

## Dev Agent Record

### Agent Model Used

GPT-5.2 (Cursor agent)

### Debug Log References

### Completion Notes List

- Bootstrap: `prijavko/` created with `flutter create --org hr.prijavko --platforms android prijavko`; Android `applicationId` / `namespace` / Kotlin `MainActivity` → `hr.prijavko.app`.
- Dependencies: all runtime packages from AC declared; dev: `build_runner`, `drift_dev`, `freezed`, `json_serializable`, `custom_lint`. **`riverpod_generator`** not added (pub solver: `riverpod_generator` 4.x + `flutter_test` pinned `test_api`). **`riverpod_lint`** not added (pub solver: `riverpod_lint` 3.x + `drift_dev` + `flutter_test`). Hand-written `Provider` for `AppConfig`; `json_annotation` pinned to `^4.9.0` so `json_serializable` + `drift_dev` resolve. **`custom_lint`**: in `dev_dependencies`; `analyzer.plugins` for `custom_lint` disabled locally (analyzer plugin AOT snapshot error on Dart 3.10); use `dart run custom_lint` when supported.
- Config: `config/dev.json`, `config/prod.json`; `AppConfig` via `String.fromEnvironment`; `prijavko/README.md` documents run/build/CI.
- Layout: feature + data + core + shared dirs with `.gitkeep` per AC.
- Android: `INTERNET`, `CAMERA`; `android:allowBackup="false"`; `minSdk` ≥ 24; `google-services.json` placeholder (replace from Firebase); GMS + Crashlytics Gradle plugins; `main.dart` initializes Firebase + Crashlytics handlers + Analytics instance (no user/PII).
- CI: `.github/workflows/ci.yml` — `dart analyze`, `flutter test`, `build_runner` + `git diff --exit-code` on `main`/PRs; tag pushes build release AAB with `config/prod.json` and upload artifact.
- Tests: `test/widget_test.dart` overrides `appConfigProvider` and asserts dev-like API string.

### Key implementation files (behavior map)

- `prijavko/lib/main.dart` — Firebase init, Crashlytics hooks, `ProviderScope`, `runApp`
- `prijavko/lib/app.dart` — root `MaterialApp` + reads `appConfigProvider`
- `prijavko/lib/core/config/app_config.dart` — compile-time defines
- `prijavko/lib/core/config/app_config_provider.dart` — Riverpod `Provider` for `AppConfig`
- `prijavko/android/app/build.gradle.kts` — applicationId, namespace, minSdk, Firebase plugins
- `prijavko/android/settings.gradle.kts` — Google Services + Crashlytics plugin IDs
- `prijavko/android/app/src/main/AndroidManifest.xml` — permissions, `allowBackup`
- `prijavko/pubspec.yaml` — dependencies and dev_dependencies
- `prijavko/analysis_options.yaml` — strict analysis + flutter_lints
- `.github/workflows/ci.yml` — analyze, test, codegen gate, tag AAB

### File List

- `prijavko/pubspec.yaml`
- `prijavko/pubspec.lock`
- `prijavko/analysis_options.yaml`
- `prijavko/build.yaml`
- `prijavko/README.md`
- `prijavko/config/dev.json`
- `prijavko/config/prod.json`
- `prijavko/lib/main.dart`
- `prijavko/lib/app.dart`
- `prijavko/lib/core/config/app_config.dart`
- `prijavko/lib/core/config/app_config_provider.dart`
- `prijavko/lib/core/theme/.gitkeep`
- `prijavko/lib/core/l10n/.gitkeep`
- `prijavko/lib/core/router/.gitkeep`
- `prijavko/lib/core/result/.gitkeep`
- `prijavko/lib/core/utils/.gitkeep`
- `prijavko/lib/data/database/.gitkeep`
- `prijavko/lib/data/database/tables/.gitkeep`
- `prijavko/lib/data/database/daos/.gitkeep`
- `prijavko/lib/data/database/migrations/.gitkeep`
- `prijavko/lib/data/api/.gitkeep`
- `prijavko/lib/data/repositories/.gitkeep`
- `prijavko/lib/data/models/.gitkeep`
- `prijavko/lib/features/capture/.gitkeep`
- `prijavko/lib/features/queue/.gitkeep`
- `prijavko/lib/features/facility/.gitkeep`
- `prijavko/lib/features/send/.gitkeep`
- `prijavko/lib/features/history/.gitkeep`
- `prijavko/lib/features/onboarding/.gitkeep`
- `prijavko/lib/features/settings/.gitkeep`
- `prijavko/lib/shared/widgets/.gitkeep`
- `prijavko/test/widget_test.dart`
- `prijavko/android/app/build.gradle.kts`
- `prijavko/android/settings.gradle.kts`
- `prijavko/android/app/google-services.json`
- `prijavko/android/app/src/main/AndroidManifest.xml`
- `prijavko/android/app/src/main/kotlin/hr/prijavko/app/MainActivity.kt`
- `.github/workflows/ci.yml`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-04-14: Story 1.1 implemented — Flutter app `prijavko/`, Android `hr.prijavko.app`, env JSON + `AppConfig`, Firebase/Crashlytics/Analytics wiring (placeholder `google-services.json`), strict analysis, CI + README. Pub solver notes for `riverpod_generator` / `riverpod_lint` documented in `prijavko/README.md`.

### Review Findings

- [x] [Review][Defer] Release tag AAB uses debug signing — deferred: formal release keystore / Play App Signing in CI left to a later story (user choice **1c**); current tag artifact remains debug-signed for smoke verification.

- [x] [Review][Defer] AC #2 lint stack vs repo reality — deferred: follow-up story when resolver graph allows `riverpod_lint` and/or stable `custom_lint` analyzer plugin (user choice **2b**).

- [x] [Review][Patch] `AD_ENABLED` parsing is loose — fixed: `AppConfig.fromEnvironment` now requires non-empty `AD_ENABLED` and only accepts `true`/`false` (case-insensitive); invalid values throw `StateError`.

- [x] [Review][Patch] README vs CI analyze command — fixed: README uses `flutter analyze` and states CI uses the same.

- [x] [Review][Patch] Firebase init failure path — fixed: `main.dart` catches `Firebase.initializeApp` failures and shows a minimal error-screen `MaterialApp` before Crashlytics wiring.

- [x] [Review][Defer] CI codegen drift check scope — `git diff --exit-code` runs under `prijavko/` only; generated-file drift outside that subtree would not fail the job (monorepo edge case). [`.github/workflows/ci.yml` `defaults.run.working-directory: prijavko`] — deferred, pre-existing layout choice.

## Story Completion Status

**done** — Code review decisions resolved (2026-04-14): release signing and full lint enforcement deferred per user; patch items applied in `prijavko/`. Replace Firebase `google-services.json` with a real project file before shipping; add release signing before Play upload.
