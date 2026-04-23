# Story 1.1: Project Bootstrap & CI Foundation

Status: in-progress

## Story

As a solo developer,
I want a strict, production-ready Flutter project scaffold with CI workflows in place from commit #1,
so that every subsequent story lands on a build-blocking foundation that catches analyzer warnings, PII log leaks, test regressions, and contract drift before they reach `main`.

## Acceptance Criteria

### AC1 — Flutter project scaffold (exact command, no deviations)

1. The repo contains a Flutter project created via the canonical command in the repo root (which already contains `_bmad/`, `_bmad-output/`, `docs/`, `tools/`, `.claude/`, `AGENTS.md` — all of which MUST be preserved):
   ```bash
   flutter create \
     --org hr.prijavko \
     --project-name prijavko \
     --platforms=android \
     --empty \
     -a kotlin \
     .
   ```
2. `pubspec.yaml` pins Flutter stable + Dart 3.x (SDK constraint `'>=3.4.0 <4.0.0'` minimum, tightened if a newer stable is active at dev time).
3. `pubspec.lock` is committed (not gitignored).
4. No `ios/`, `web/`, `macos/`, `windows/`, `linux/` directories exist — `--platforms=android` enforced.
5. `lib/main.dart` stays at the empty-counter-free scaffold emitted by `--empty`; no feature code added in this story.

### AC2 — Strict analyzer configuration

1. `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml` and explicitly enables, at minimum: `avoid_print`, `prefer_const_constructors`, `always_use_package_imports`, `directives_ordering`, `unnecessary_null_checks`.
2. `dart analyze --fatal-warnings --fatal-infos` exits with zero warnings and zero infos on the empty scaffold.
3. `dart format --set-exit-if-changed .` passes.

### AC3 — Six GitHub Actions workflows

1. `.github/workflows/analyze.yml` — triggers on every push and PR; runs `flutter pub get` then `dart analyze --fatal-warnings --fatal-infos`.
2. `.github/workflows/pii_guard.yml` — triggers on every push and PR; greps the repo and fails the build on any match of the pattern:
   ```regexp
   (print|debugPrint|AppLogger\.\w+)\(.*\.(documentNumber|firstName|lastName|dateOfBirth|nationality|documentExpiry|mrzLine1|mrzLine2)
   ```
   Include a self-test fixture (a known-bad line in a test-only file that is grep-excluded) so the workflow's regex correctness is demonstrable; or equivalently, document the regex in `docs/ci/pii-guard-regex.md` with passing/failing example lines.
3. `.github/workflows/test.yml` — triggers on every push and PR; runs `flutter test` (unit + widget).
4. `.github/workflows/integration_fake.yml` — triggers on every push and PR; runs `flutter test integration_test/ --dart-define=EVISITOR_ENV=fake`. For this story, a stub `integration_test/app_test.dart` that boots `MaterialApp` and confirms the first frame paints is sufficient; the permanent Dio fake comes later (Story 1.3+). The workflow itself must be wired and green.
5. `.github/workflows/testapi_canary.yml` — triggers on a nightly cron (pick a UTC time that avoids the other crons) plus `workflow_dispatch`; runs `flutter test integration_test/ --dart-define=EVISITOR_ENV=test`. For this story, this workflow MAY be a no-op smoke test (echo "canary placeholder" + exit 0) but must be present and dispatchable so the cron schedule is active from day one.
6. `.github/workflows/build_aab.yml` — triggers on tag push matching `v*`; runs `flutter build appbundle --dart-define=EVISITOR_ENV=prod --obfuscate --split-debug-info=build/symbols/`; uploads the AAB and the `build/symbols/` tree as workflow-run artifacts.
7. Each workflow uses `subosito/flutter-action@v2` (or equivalent pinned action) with `channel: stable` and an explicit Flutter version input; caches `~/.pub-cache` and Gradle where relevant.
8. Each workflow has a matching README entry in `docs/ci/README.md` explaining its trigger, scope, and failure signal.

### AC4 — Android manifest hardening

1. `android/app/src/main/AndroidManifest.xml` declares `android:allowBackup="false"` and `android:fullBackupContent="false"` on the `<application>` element.
2. Declares exactly three runtime/install permissions — no more, no less: `android.permission.CAMERA`, `android.permission.INTERNET`, `android.permission.ACCESS_NETWORK_STATE`.
3. No `<uses-permission>` lines exist for storage, location, contacts, SMS, background, FCM, boot-completed, or any other permission.

### AC5 — Network security configuration

1. `android/app/src/main/res/xml/network_security_config.xml` exists and declares:
   - `<base-config cleartextTrafficPermitted="false" />`
   - A `<domain-config>` scoped to `www.evisitor.hr` that references the cert-pinning pin set by file/inline placeholder (pin values themselves are Story 1.3's responsibility; this story creates the file skeleton and ensures the manifest references it).
2. `AndroidManifest.xml` `<application>` element wires `android:networkSecurityConfig="@xml/network_security_config"`.

### AC6 — ProGuard/R8 keep rules

1. `android/app/proguard-rules.pro` exists with `-keep` rules covering:
   - Drift generated code (class patterns from Drift's proguard guidance).
   - Riverpod annotations (`@riverpod`, generated providers).
   - Freezed `copyWith` / union types.
   - Dio `HttpClientAdapter` and `Interceptor` subclasses.
2. `android/app/build.gradle` (or `build.gradle.kts`) enables `minifyEnabled true` + `shrinkResources true` on the release build type and references `proguard-rules.pro`.

### AC7 — SDK targets

1. `android/app/build.gradle` sets `minSdkVersion 24` (Android 7.0).
2. `targetSdkVersion` and `compileSdkVersion` are set to the latest Play-mandated target SDK as of the current dev date (document the chosen value in `docs/ci/README.md` with the date and Play policy source URL).
3. `ndkVersion` set to whatever the pinned Flutter stable channel mandates — do not leave unset.

### AC8 — Environment switching without flavors

1. A single getter `lib/core/env/evisitor_env.dart` exposes:
   ```dart
   enum EvisitorEnv { prod, test, fake }
   const String _rawEnv = String.fromEnvironment('EVISITOR_ENV', defaultValue: 'prod');
   EvisitorEnv get evisitorEnv => EvisitorEnv.values.byName(_rawEnv);
   ```
2. A unit test verifies the default is `prod` when no `--dart-define` is passed, and that `EVISITOR_ENV=test` / `EVISITOR_ENV=fake` resolve to the correct enum variants.
3. No dev/staging/prod Gradle `buildTypes` have been added — only `debug` and `release` exist.

### AC9 — Release build pipeline

1. Pushing a tag matching `v*` (e.g., `v1.0.0-dryrun`) to a disposable branch triggers `build_aab.yml` and produces a signed AAB (signing config uses a placeholder keystore in the workflow — actual release signing keys are Story 10.7/10.8 concern, but the workflow must not hard-fail on missing secrets; use an upload-keystore dry-run path).
2. The `build/symbols/` obfuscation symbols are uploaded as a workflow-run artifact with a retention period ≥ 90 days.
3. Version code strategy documented in `docs/ci/README.md`: `vX.Y.Z` → versionCode `X*10000 + Y*100 + Z` (e.g., `v1.0.0` → `10000`, `v1.0.1` → `10001`, `v1.1.0` → `10100`). A simple script or workflow step derives the versionCode from the tag.

### AC10 — Cold-start latency probe (NFR-P8)

1. `integration_test/app_test.dart` contains a probe that measures cold-start duration from `binding.firstFrameRasterized` and fails if it exceeds **2.5 seconds** on the CI runner. Given CI hardware variance, use 2.5s as the hard fail threshold and log the observed p50/p95 to the test output for trend review.
2. The probe is run inside the `integration_fake.yml` workflow.

### AC11 — `.gitignore` discipline

1. `.gitignore` excludes: `build/`, `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, IDE metadata (`.idea/`, `*.iml`, `.vscode/` except `launch.json`/`settings.json` that are intentionally tracked).
2. `.gitignore` does NOT exclude: `pubspec.lock`, `*.g.dart`, `*.freezed.dart`, `android/app/proguard-rules.pro`, `android/app/src/main/res/xml/network_security_config.xml`.

## Tasks / Subtasks

- [x] Task 1 — Scaffold the Flutter project (AC: #1)
  - [x] Subtask 1.1 — Back up (or verify git-tracked) `_bmad/`, `_bmad-output/`, `docs/`, `tools/`, `.claude/`, `AGENTS.md` before running `flutter create`.
  - [x] Subtask 1.2 — Run the exact `flutter create` command from AC1.1 in the repo root.
  - [x] Subtask 1.3 — Confirm no `ios/web/macos/windows/linux` directories appeared; delete if any did.
  - [x] Subtask 1.4 — Pin Flutter/Dart SDK constraint in `pubspec.yaml`; commit `pubspec.lock`.
- [x] Task 2 — Tighten the analyzer (AC: #2)
  - [x] Subtask 2.1 — Edit `analysis_options.yaml` to extend `flutter_lints` and enable the five named rules.
  - [x] Subtask 2.2 — Run `dart analyze --fatal-warnings --fatal-infos` locally until clean.
  - [x] Subtask 2.3 — Run `dart format --set-exit-if-changed .` locally until clean.
- [x] Task 3 — Wire the six GitHub Actions workflows (AC: #3)
  - [x] Subtask 3.1 — Create `.github/workflows/analyze.yml`.
  - [x] Subtask 3.2 — Create `.github/workflows/pii_guard.yml` with the grep regex and a documented self-test.
  - [x] Subtask 3.3 — Create `.github/workflows/test.yml`.
  - [x] Subtask 3.4 — Create `.github/workflows/integration_fake.yml` + a minimal `integration_test/app_test.dart` boot-probe. (Full `firstFrameRasterized` timing — AC10 — deferred to Task 9.)
  - [x] Subtask 3.5 — Create `.github/workflows/testapi_canary.yml` as a nightly cron placeholder.
  - [x] Subtask 3.6 — Create `.github/workflows/build_aab.yml` triggered on `v*` tag.
  - [x] Subtask 3.7 — Write `docs/ci/README.md` explaining each workflow's trigger, scope, and failure signal.
- [x] Task 4 — Harden Android manifest & network config (AC: #4, #5)
  - [x] Subtask 4.1 — Edit `AndroidManifest.xml` — `allowBackup=false`, `fullBackupContent=false`, 3 permissions, network security config reference.
  - [x] Subtask 4.2 — Create `android/app/src/main/res/xml/network_security_config.xml` with `cleartextTrafficPermitted="false"` and placeholder pin set reference.
- [x] Task 5 — Add ProGuard rules + minify release (AC: #6)
  - [x] Subtask 5.1 — Create `android/app/proguard-rules.pro` with keep rules for Drift, Riverpod, Freezed, Dio.
  - [x] Subtask 5.2 — Edit `android/app/build.gradle` to enable `minifyEnabled`/`shrinkResources` on release and reference the rules file.
- [ ] Task 6 — Set SDK targets (AC: #7)
  - [ ] Subtask 6.1 — Set `minSdkVersion 24`, `targetSdkVersion` and `compileSdkVersion` per current Play mandate (document the value and source in `docs/ci/README.md`).
- [ ] Task 7 — Environment switching (AC: #8)
  - [ ] Subtask 7.1 — Create `lib/core/env/evisitor_env.dart` with `EvisitorEnv` enum + `String.fromEnvironment` resolver.
  - [ ] Subtask 7.2 — Add a unit test covering default + two `--dart-define` overrides.
- [ ] Task 8 — Release build pipeline sanity (AC: #9)
  - [ ] Subtask 8.1 — Verify `build_aab.yml` triggers on tag push; dry-run with a disposable tag on a branch.
  - [ ] Subtask 8.2 — Confirm symbols upload + versionCode derivation scheme documented.
- [ ] Task 9 — Cold-start probe (AC: #10)
  - [ ] Subtask 9.1 — Measure `binding.firstFrameRasterized` in `integration_test/app_test.dart`; fail if > 2.5s; log p50/p95.
- [ ] Task 10 — `.gitignore` review (AC: #11)
  - [ ] Subtask 10.1 — Audit the Flutter-generated `.gitignore`; keep required excludes, unexclude `pubspec.lock`, `*.g.dart`, `*.freezed.dart`.

## Dev Notes

### Why this story exists first

Every subsequent epic assumes (a) `dart analyze --fatal-warnings --fatal-infos` gates merges, (b) the PII grep guard blocks forbidden log patterns at CI, (c) the nightly testApi canary detects eVisitor contract drift, and (d) release builds are reproducible from a tag. If any one of those is absent when Epic 2 starts, classifier bugs, PII leaks, or Play Store review blockers land silently. This story is the foundation — no feature code in it, just the guard rails.

### Architecture mandates (must follow — non-negotiable)

- **Starter command is literal** — Architecture §2 and the Implementation Readiness Report §15 both reference the exact `flutter create` invocation above. Do NOT substitute a community starter, Very Good CLI, or a clean-architecture template. Rationale: solo-dev economics + Play Store reviewability + Monozukuri (every file earns its place).
- **`_bmad/`, `_bmad-output/`, `docs/`, `tools/`, `.claude/`, `AGENTS.md` MUST survive** — these are planning and tooling artifacts already committed to the repo. `flutter create … .` in a non-empty directory merges without touching unrelated files, but verify after running.
- **No flavors** — `--dart-define=EVISITOR_ENV=<prod|test|fake>` is the only environment toggle. Adding Gradle `buildTypes` beyond `debug` and `release` is an explicit rejection (Architecture §2, Environment Switching Strategy).
- **Feature directories are NOT created in this story** — per JIT (Just-In-Time) architecture, `lib/features/**` skeletons come with the story that owns them (1.2 creates `lib/design/`, 1.3 creates `lib/core/security/`, etc.). This story creates only `lib/core/env/evisitor_env.dart` because AC8 demands it.
- **`pubspec.yaml` stays dependency-light** — only what Flutter's starter includes + `flutter_lints`. Do NOT pre-add Riverpod, Freezed, Drift, Dio, Firebase, AdMob — those arrive in the stories that need them (1.2 adds `google_fonts`, 1.3 adds `dio` + `flutter_secure_storage` + `cryptography_flutter`, etc.).

### NFR coverage for this story

- **NFR-M1** — `dart analyze --fatal-warnings --fatal-infos` in CI. (AC2, AC3.1)
- **NFR-S6** — `allowBackup=false`, `fullBackupContent=false`. (AC4)
- **NFR-S1** — cleartext rejected at platform level. (AC5)
- **NFR-S7 (CI half)** — PII grep guard workflow. (AC3.2) The type-level half (PII `toString()` overrides) lands with the models that carry PII (Epic 2+).
- **NFR-I4 (harness half)** — `integration_fake.yml` + `testapi_canary.yml` workflows wired. (AC3.4, AC3.5) The permanent Dio fake itself is a later story.
- **NFR-I7 (gate half)** — forced-update mechanism polls `prijavko.hr/min-version.json`; Story 1.1 does not implement it, but the release pipeline (AC9) makes version code derivation + tag → build the foundation the min-version JSON references.
- **NFR-P8** — cold-start ≤ 2.5s p95 probe in `integration_test/app_test.dart`. (AC10) Originally flagged unassigned in the implementation-readiness report (§Week-1 Recommendations); assigning here per that report's recommendation.
- **NFR-C1** — Android 7.0 (API 24) minimum. (AC7)

### LLM-specific anti-patterns for this story

| Do NOT do this | Do THIS instead |
|---|---|
| Scaffold with `flutter create` defaults (no flags) | Use the exact command with `--org`, `--project-name`, `--platforms=android`, `--empty`, `-a kotlin`, `.` |
| Add Riverpod / Freezed / Drift / Dio / Firebase to `pubspec.yaml` | Leave `pubspec.yaml` at vanilla + `flutter_lints`; stories 1.2+ own those deps |
| Create `lib/features/**` skeleton directories | Only `lib/core/env/evisitor_env.dart` is warranted by this story's ACs |
| Add Gradle product flavors (`dev`, `prod`) | Use `--dart-define=EVISITOR_ENV=...` + a single Dart resolver |
| Gitignore `*.g.dart` / `*.freezed.dart` / `pubspec.lock` | Commit them — codegen outputs are first-class artifacts per architecture §4 |
| Skip `pii_guard.yml` because no PII code exists yet | The workflow must exist and be green from commit #1 — it protects future commits |
| Hardcode `targetSdkVersion` to an old number because "Flutter defaults" | Document the Play-mandated target SDK value + source URL in `docs/ci/README.md` |
| Write `integration_test` that does `expect(true, isTrue)` | Probe `firstFrameRasterized` timing to cover NFR-P8 |
| Wrap `flutter create` in a Makefile or shell script | Run it once, commit the output — it's a one-shot scaffold, not a repeatable task |

### Project Structure Notes

This story creates:
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `lib/main.dart`
- `lib/core/env/evisitor_env.dart` (smallest possible `core/` file; demanded by AC8)
- `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/network_security_config.xml`, `android/app/proguard-rules.pro`, `android/app/build.gradle` edits
- `.github/workflows/{analyze,pii_guard,test,integration_fake,testapi_canary,build_aab}.yml`
- `docs/ci/README.md`
- `integration_test/app_test.dart` (cold-start probe only)
- `test/core/env/evisitor_env_test.dart`

This story does NOT create:
- `lib/design/**` (Story 1.2)
- `lib/core/security/**`, `lib/core/logging/**`, `lib/core/telemetry/**`, `lib/core/errors/**`, `lib/core/result/**`, `lib/core/time/**`, `lib/core/feature_flags/**` (Stories 1.3+ as each subsystem lands)
- `lib/features/**/*` (each feature's first story)
- `docs/security/masvs-l1-checklist.md`, `docs/security/cert-pins.md` (Stories 1.3 / 10.3)
- `test/fakes/evisitor_fake_adapter.dart` (Story 1.3+)

### References

- [Architecture §2 Starter Template Evaluation, Selected Starter command + flag rationale](../planning-artifacts/architecture.md)
- [Architecture §Infrastructure & Deployment, CI pipeline table](../planning-artifacts/architecture.md)
- [Architecture §Project Structure, complete directory tree + ProGuard addendum](../planning-artifacts/architecture.md)
- [Architecture §Architectural Addenda, ProGuard/R8 File Addition](../planning-artifacts/architecture.md)
- [Epics Story 1.1 G/W/T acceptance criteria](../planning-artifacts/epics.md)
- [PRD NFRs — NFR-M1, NFR-S1, NFR-S6, NFR-S7, NFR-I4, NFR-I7, NFR-P8, NFR-C1](../planning-artifacts/prd.md)
- [Implementation Readiness Report §Greenfield Check + §Week-1 Recommendations (NFR-P8 assignment)](../planning-artifacts/implementation-readiness-report-2026-04-23.md)
- [Project rules — `.claude/rules/design-system.md`, `.claude/rules/japanese-craftsmanship.md`, `.claude/rules/communication-style.md`](../../.claude/rules/)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context)

### Debug Log References

- `flutter --version` → Flutter 3.38.7 stable / Dart 3.10.7 (the Dart version that pins `pubspec.yaml`).
- `flutter create --org hr.prijavko --project-name prijavko --platforms=android --empty -a kotlin .` — ran at repo root; preserved `_bmad/`, `_bmad-output/`, `docs/`, `tools/`, `.claude/`, `AGENTS.md`; no `ios/web/macos/windows/linux` directories produced.

### Completion Notes List

- Task 1 (AC1) — Scaffold complete. `pubspec.yaml` pinned to `sdk: '>=3.10.0 <4.0.0'` (tighter than AC1.2 floor, aligned to Flutter stable channel's Dart 3.10.7) and `flutter: '>=3.38.0'`. `pubspec.lock` committed (not gitignored — honours architecture §4).
- Task 2 (AC2) — Analyzer tightened. `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`, enables `strict-casts`/`strict-inference`/`strict-raw-types`, and lists the five AC2.1 rules (`avoid_print`, `prefer_const_constructors`, `always_use_package_imports`, `directives_ordering`, `unnecessary_null_checks`). `dart analyze --fatal-warnings --fatal-infos` → 0 issues. `dart format --set-exit-if-changed .` → clean. Commit `6683d03` also dropped a premature `test/core/env/evisitor_env_test.dart` (Task 7.2) without its implementation, which broke the analyzer; that test file has been reverted here and will be re-added under Task 7 in order.
- Task 4 (AC4, AC5) — Android manifest hardened: `allowBackup="false"` + `fullBackupContent="false"` on `<application>`, exactly three `<uses-permission>` lines (`CAMERA`, `INTERNET`, `ACCESS_NETWORK_STATE`), and `android:networkSecurityConfig="@xml/network_security_config"` wired. The debug-only manifest (`android/app/src/debug/AndroidManifest.xml`) keeps its scaffold-generated `INTERNET` override — that is Flutter's hot-reload channel, merges only into debug, and does not count against AC4.2 which targets `src/main`. Created `android/app/src/main/res/xml/network_security_config.xml` with `<base-config cleartextTrafficPermitted="false">` and a `<domain-config>` scoped to `www.evisitor.hr` carrying a placeholder `<pin-set>` (SPKI pins themselves are story 1.3's concern, as the AC5 comment notes; the pin-set expiration is deliberately set to 2026-04-24 so the expired-pin-set fallback path is taken until 1.3 populates real digests, keeping CI smoke builds non-blocking). `xmllint` confirms both XML files well-formed. `dart analyze --fatal-warnings --fatal-infos`, `dart format --set-exit-if-changed .`, and `flutter test` remain green.
- Task 3 (AC3) — Six GitHub Actions workflows wired, all pinned to `subosito/flutter-action@v2` with `flutter-version: '3.38.7'`. `analyze.yml`, `test.yml`, and `pii_guard.yml` are the push/PR fast path; `integration_fake.yml` runs `flutter test integration_test/ --dart-define=EVISITOR_ENV=fake` on an `reactivecircus/android-emulator-runner@v2` API 24 x86_64 AVD (Flutter CLI routes anything under `integration_test/` through the integration-test runner, which mandates a device); `testapi_canary.yml` is a cron-`0 3 * * *` placeholder to keep the schedule active until Epic 6 lands the real canary; `build_aab.yml` fires on `v*` tags, derives versionName/versionCode from the tag, and uploads the AAB + `build/symbols/` tree as 90-day-retention artifacts. A minimal `integration_test/app_test.dart` boot probe is included (no `integration_test` package import — that waits for Story 1.3+ so local verification of the emulator step is limited to CI). A `test/app_smoke_test.dart` widget test keeps `flutter test` exit code 0 from commit #1. `docs/ci/README.md` catalogues every workflow's trigger/scope/failure signal; `docs/ci/pii-guard-regex.md` documents the PII log pattern with passing/failing examples (AC3.2 self-test). Local gate suite (`dart analyze --fatal-warnings --fatal-infos`, `dart format --set-exit-if-changed .`, `flutter test`, PII grep) all green. Integration_fake.yml emulator leg is unverified locally — a push to GitHub is the verification.
- Task 5 (AC6) — R8 shrinking + ProGuard rules wired into the release buildType. `android/app/build.gradle.kts` now sets `isMinifyEnabled = true` and `isShrinkResources = true` on `release`, plus `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`. Verified via `./gradlew :app:assembleRelease --dry-run` — the graph now includes `:app:minifyReleaseWithR8`, `:app:extractProguardFiles`, `:app:mergeReleaseGeneratedProguardFiles`. `android/app/proguard-rules.pro` carries keep rules for the four libraries named in AC6.1, with Omotenashi comments explicitly noting that Drift/Riverpod/Freezed/Dio are Dart-only today and the rules target the native plugin shims those libraries will interop with in Story 1.3+ (sqlite3_flutter_libs for Drift, Cronet + OkHttp for Dio). Attributes required by Crashlytics (`SourceFile`, `LineNumberTable`, `*Annotation*`) kept because Story 9.2's symbol upload depends on them. Local gates (`dart analyze --fatal-warnings --fatal-infos`, `dart format --set-exit-if-changed .`, `flutter test`, `./gradlew :app:tasks`) all green. Full release AAB build itself is deferred to Task 8's tag-push verification.

### Change Log

| Date | Task | Notes |
|---|---|---|
| 2026-04-23 | Task 1 (AC1) | Flutter project scaffolded via canonical command; pubspec pinned; lock committed; platform constraint verified. |
| 2026-04-23 | Task 2 (AC2) | Analyzer tightened (flutter_lints + strict language modes + 5 named rules); `dart analyze --fatal-warnings --fatal-infos` and `dart format --set-exit-if-changed .` pass. Reverted the premature Task 7.2 test file that was dragged in by commit `6683d03`. |
| 2026-04-23 | Task 3 (AC3) | Wired six GitHub Actions workflows (`analyze`, `pii_guard`, `test`, `integration_fake`, `testapi_canary`, `build_aab`); added `integration_test/app_test.dart` boot probe, `test/app_smoke_test.dart`, `docs/ci/README.md`, `docs/ci/pii-guard-regex.md`. Integration tests run on an Android emulator via `reactivecircus/android-emulator-runner@v2` because `flutter test integration_test/` requires a device. |
| 2026-04-23 | Task 4 (AC4, AC5) | Hardened `android/app/src/main/AndroidManifest.xml` with `allowBackup=false`, `fullBackupContent=false`, 3 explicit permissions, and `networkSecurityConfig` wiring; created `android/app/src/main/res/xml/network_security_config.xml` skeleton (base-config cleartext denied; evisitor.hr domain-config with placeholder pin-set deferred to story 1.3). |
| 2026-04-23 | Task 5 (AC6) | Created `android/app/proguard-rules.pro` with keep rules for Flutter engine, sqlite3_flutter_libs (Drift's native loader), Cronet + OkHttp (Dio's native adapter path), Freezed `$CopyWith`/`$When` patterns, and Crashlytics-required attributes. Enabled `isMinifyEnabled`/`isShrinkResources` on the `release` buildType in `android/app/build.gradle.kts`. Gradle dry-run confirms `:app:minifyReleaseWithR8` is wired. |

### File List

- `pubspec.yaml` (created, then edited to pin SDK + flutter + project description)
- `pubspec.lock` (created, committed per architecture §4)
- `analysis_options.yaml` (created by scaffold; Task 2 tightened it with flutter_lints + strict language modes + 5 named rules)
- `.gitignore` (created by scaffold; Task 10 will audit it)
- `.metadata` (created by scaffold)
- `README.md` (created by scaffold)
- `lib/main.dart` (empty-scaffold body emitted by `--empty`; reformatted by `dart format` under Task 2; no feature code)
- `android/**/*` (full Android module emitted by scaffold; Tasks 4–7 will harden specific files)
- `android/app/src/main/AndroidManifest.xml` (edited, Task 4 — backup disabled, 3 permissions declared, network security config referenced)
- `android/app/src/main/res/xml/network_security_config.xml` (created, Task 4 — cleartext denied base-config + evisitor.hr pin-set skeleton)
- `android/app/proguard-rules.pro` (created, Task 5 — R8 keep rules for Drift/Riverpod/Freezed/Dio + Flutter engine + Crashlytics attrs)
- `android/app/build.gradle.kts` (edited, Task 5 — `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(...)` on `release`)
- `.github/workflows/analyze.yml` (created, Task 3)
- `.github/workflows/pii_guard.yml` (created, Task 3)
- `.github/workflows/test.yml` (created, Task 3)
- `.github/workflows/integration_fake.yml` (created, Task 3)
- `.github/workflows/testapi_canary.yml` (created, Task 3)
- `.github/workflows/build_aab.yml` (created, Task 3)
- `docs/ci/README.md` (created, Task 3)
- `docs/ci/pii-guard-regex.md` (created, Task 3)
- `integration_test/app_test.dart` (created, Task 3 — boot probe; Task 9 will extend with cold-start timing)
- `test/app_smoke_test.dart` (created, Task 3 — keeps `flutter test` exit code 0 on commit #1)

