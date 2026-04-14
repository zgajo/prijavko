# Story 1.1: Flutter Project Initialization & Build Configuration

Status: ready-for-dev

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

- [ ] Run `flutter create --org hr.prijavko --platforms android prijavko`; open in IDE; confirm `flutter run` on emulator. (AC: #1)
- [ ] Set Android **`applicationId` / `namespace` to `hr.prijavko.app`** in `android/app/build.gradle(.kts)`. (AC: #7)
- [ ] Add all **pubspec** dependencies and dev_dependencies; run `dart pub get`. (AC: #2)
- [ ] Add **`analysis_options.yaml`**: include `package:flutter_lints` or stricter rules + **`custom_lint`** + **`riverpod_lint`**; fix all issues until `dart analyze` is clean. (AC: #2)
- [ ] Add **`build.yaml`** if needed for Drift/riverpod_generator options per Drift docs. (AC: #2, #8)
- [ ] Create **`config/dev.json`** and **`config/prod.json`** with exact URLs and flags from AC #3. (AC: #3)
- [ ] Implement **`lib/core/config/app_config.dart`** reading compile-time defines; document run command in `README.md`. (AC: #4)
- [ ] Create **feature folder tree** under `lib/` with `.gitkeep` as needed. (AC: #5)
- [ ] Add minimal **`lib/main.dart`**: `runApp` + `ProviderScope` (can show placeholder `MaterialApp` home) so Riverpod is wired. (AC: #2, #5)
- [ ] **AndroidManifest**: permissions; backup strategy per AC #6; add **`res/xml/backup_rules.xml`** if using scoped backup. (AC: #6)
- [ ] **Firebase**: Create Firebase Android app with package `hr.prijavko.app`; add **`google-services.json`** under `android/app/`; apply Google Services + Firebase Crashlytics Gradle plugins per current FlutterFire docs. Initialize Crashlytics/Analytics in `main.dart` with **no PII** (stub handlers OK). (AC: #2)
- [ ] **CI**: Add `.github/workflows/ci.yml` — analyze, test, build_runner verify, tag → `flutter build appbundle --dart-define-from-file=config/prod.json`. (AC: #8)
- [ ] **`README.md`**: document dev run, prod build, and CI behavior. (AC: #8)

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

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

## Story Completion Status

**ready-for-dev** — Ultimate context engine analysis completed; developer has guardrails for bootstrap, IDs, config, and CI.
