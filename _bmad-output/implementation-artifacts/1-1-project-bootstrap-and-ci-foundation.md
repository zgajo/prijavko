# Story 1.1: Project Bootstrap & CI Foundation

Status: review

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
- [x] Task 6 — Set SDK targets (AC: #7)
  - [x] Subtask 6.1 — Set `minSdkVersion 24`, `targetSdkVersion` and `compileSdkVersion` per current Play mandate (document the value and source in `docs/ci/README.md`).
- [x] Task 7 — Environment switching (AC: #8)
  - [x] Subtask 7.1 — Create `lib/core/env/evisitor_env.dart` with `EvisitorEnv` enum + `String.fromEnvironment` resolver.
  - [x] Subtask 7.2 — Add a unit test covering default + two `--dart-define` overrides.
- [x] Task 8 — Release build pipeline sanity (AC: #9)
  - [x] Subtask 8.1 — Verify `build_aab.yml` triggers on tag push; dry-run with a disposable tag on a branch.
  - [x] Subtask 8.2 — Confirm symbols upload + versionCode derivation scheme documented.
- [x] Task 9 — Cold-start probe (AC: #10)
  - [x] Subtask 9.1 — Measure `binding.firstFrameRasterized` in `integration_test/app_test.dart`; fail if > 2.5s; log p50/p95.
- [x] Task 10 — `.gitignore` review (AC: #11)
  - [x] Subtask 10.1 — Audit the Flutter-generated `.gitignore`; keep required excludes, unexclude `pubspec.lock`, `*.g.dart`, `*.freezed.dart`.

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
- Task 6 (AC7) — SDK targets pinned explicitly in `android/app/build.gradle.kts`: `compileSdk = 36`, `minSdk = 24`, `targetSdk = 36`, `ndkVersion = "28.2.13676358"` (Flutter 3.38.7's mandated NDK per `FlutterExtension.ndkVersion`). Values are hardcoded literals — deliberately **not** inherited from `flutter.*` — so a silent channel bump cannot drift Play's visible surface. Rationale: Play requires `targetSdk 35` for new apps since 2025-08-31 and moves the floor to `36` on 2026-08-31; pinning `36` now clears that cliff and matches Flutter's default. `minSdk 24` is PRD NFR-C1 (Android 7.0 floor, ~98% Play device coverage). Documented in `docs/ci/README.md` §SDK targets with the Play policy source URL. Verification: `dart analyze --fatal-warnings --fatal-infos` → 0 issues; `dart format --set-exit-if-changed .` → clean; `flutter test` → green; `gradlew :app:tasks --dry-run` configures cleanly; `gradlew :app:assembleRelease --dry-run` still chains `:app:minifyReleaseWithR8`, so Task 5's R8 wiring is not regressed. The pre-existing `kotlinOptions.jvmTarget` deprecation warning is from the Flutter scaffold and unrelated to this task.
- Task 7 (AC8) — Environment switch landed as `lib/core/env/evisitor_env.dart`: `EvisitorEnv { prod, test, fake }` plus an ambient `evisitorEnv` getter that delegates to a pure `envFromDefine(String)` resolver. The resolver split exists because `String.fromEnvironment` is a compile-time constant — a single `flutter test` process can only observe one ambient value, so the two override cases (AC8.2) are asserted through the pure function instead of spawning three separate CI test invocations. `EvisitorEnv.values.byName` gives us a free Poka-yoke: an unknown raw value (CI typo like `stagging`) throws `ArgumentError` at parse time rather than silently defaulting to `prod` and shipping the wrong backend. Default is `prod` per AC8.1. No Gradle buildTypes beyond `debug` / `release` were added (AC8.3). Tests: `test/core/env/evisitor_env_test.dart` covers default → prod, `test` / `fake` overrides, and the ArgumentError-on-unknown line-stop — 4 cases, all green. End-to-end verified: running `flutter test --dart-define=EVISITOR_ENV=fake` flips the ambient getter as expected (the default-case assertion fails, confirming the `--dart-define` wire reaches the resolver for AC3.4's `integration_fake.yml` consumption). Local gates all green: `dart analyze --fatal-warnings --fatal-infos` → 0 issues, `dart format --set-exit-if-changed .` → clean, `flutter test` → 5/5 passing.
- Task 8 (AC9) — Release build pipeline verified end-to-end. Local dry-run of the exact workflow command (`flutter build appbundle --release --dart-define=EVISITOR_ENV=prod --build-name=1.0.0-dryrun --build-number=10000 --obfuscate --split-debug-info=build/symbols/`) produced a 36 MB `app-release.aab` plus `build/symbols/` (arm, arm64, x64 — 3.5 MB total) in ~17 s of Gradle work; debug-keystore signing confirms the workflow does not hard-fail on missing release secrets (AC9.1). CI round-trip verified by pushing a disposable `v0.0.1-dryrun` tag against this story's branch — the `build_aab` GitHub Actions run went green, both `prijavko-0.0.1-dryrun-aab` and `prijavko-0.0.1-dryrun-symbols` artifacts uploaded with 90-day retention (AC9.1, AC9.2); tag deleted locally and on origin after the run completed so the repo tag namespace is unchanged. versionCode derivation formula (`MAJOR*10000 + MINOR*100 + PATCH`, pre-release suffixes stripped from code but preserved in name) is inline in `build_aab.yml`'s `Derive version name + code from tag` step and the table covering the 5 canonical tag shapes is documented in `docs/ci/README.md §Release versioning strategy` (AC9.3). Formula sanity-checked locally against all 5 documented tags (`v1.0.0→10000`, `v1.0.1→10001`, `v1.1.0→10100`, `v1.0.0-dryrun→10000`, `v2.3.4-beta→20304`) — 1:1 match. No code changes landed in this task — it is pure verification over Task 3's wiring; no new files added to File List.
- Task 10 (AC11) — `.gitignore` rewritten against the AC11 contract. Merged the upstream Flutter template the user supplied (the full "Miscellaneous / Flutter repo-specific / Flutter-Dart-Pub / Android / iOS / macOS / Windows / Linux / Coverage / Symbols" blocks) with the prior prijavko entries (`.DS_Store`, `.atom/`, `.svn/`, `.swiftpm/`, `migrate_working_dir/`, `.pub-cache/`, `app.*.map.json`, `/android/app/debug|profile|release`). Two conflicts with AC11 resolved explicitly: (a) the user's template includes `*.lock`, which would shadow `pubspec.lock` (AC11.2 forbids) — countered with `!pubspec.lock` in a dedicated "AC11.2 anchors" footer; (b) the template does NOT handle `.vscode/`, but AC11.1 mandates its exclusion with exceptions for `launch.json` / `settings.json`. Used the `.vscode/*` + `!.vscode/launch.json` + `!.vscode/settings.json` pattern because git refuses to un-ignore children of a directory excluded at directory level. The "AC11.2 anchors" footer collects `!pubspec.lock`, `!**/*.g.dart`, `!**/*.freezed.dart`, `!/android/app/proguard-rules.pro`, `!/android/app/src/main/res/xml/network_security_config.xml` so future edits have to touch two stanzas to drop an anchor — Poka-yoke against silent regression. Verified with `git check-ignore -q` against all AC11.1 targets (every one reports ignored) and all AC11.2 targets (every one reports tracked, including the `.vscode/launch.json`/`.vscode/settings.json` exceptions). Template noise (iOS/macOS/Windows/Linux + Flutter SDK repo paths like `/bin/cache/`, `/dev/…`, `/packages/flutter/…`) is kept verbatim per user instruction — harmless no-ops in an Android-only app; flagged the noise to the user before writing. Local gates: `dart format --set-exit-if-changed .` → clean, `dart analyze --fatal-warnings --fatal-infos` → 0 issues, `flutter test` → 5/5 passing.
- Task 9 (AC10) — Cold-start guard rail landed in `integration_test/app_test.dart`. Switched the file to `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` and added `integration_test` (Flutter-SDK-bundled dev dep, not a third-party production dep) so `WidgetsBinding.instance.firstFrameRasterized` / `waitUntilFirstFrameRasterized` are backed by a real rasterizer — the `AutomatedTestWidgetsFlutterBinding` never renders to the GPU, so the marker stays `false` there and the literal AC10.1 signal is unreachable from a plain widget test. Probe runs `_sampleCount=5` iterations: iteration 0 awaits `waitUntilFirstFrameRasterized` (one-shot Completer, i.e. the actual cold-start), iterations 1..4 await `tester.pump()` (which blocks on a real vsync under the integration binding). `debugPrint` emits `cold_start_ms`, per-sample ms, `p50_ms`, `p95_ms`, `max_ms`, `threshold_ms` in one line for CI trend parsing. Two `expect`s enforce the 2.5 s hard fail — one on the cold-start sample (AC10.1 literal), one on `maxSample` so no warm outlier can hide behind a lower p50/p95. Threshold + sample count are inlined `const`s rather than `--dart-define`d — a guard rail that can be silently loosened from CI args is not a guard rail. The probe lives inside `integration_fake.yml` (AC10.2) because Task 3 already wired that workflow to run `flutter test integration_test/` on an `api-level: 24 x86_64` AVD. Trade-off accepted: `flutter test integration_test/` locally now requires an emulator (standard Flutter integration-test posture, and the existing file already documented the emulator-only execution path). Local gates: `dart format --set-exit-if-changed .` → clean, `dart analyze --fatal-warnings --fatal-infos` → 0 issues, `flutter test` (unit+widget) → 5/5 passing, `pii_guard` regex → no matches. The probe itself cannot be executed locally without an Android emulator; CI execution on the `integration_fake` workflow run is the verification.
- Task 5 (AC6) — R8 shrinking + ProGuard rules wired into the release buildType. `android/app/build.gradle.kts` now sets `isMinifyEnabled = true` and `isShrinkResources = true` on `release`, plus `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`. Verified via `./gradlew :app:assembleRelease --dry-run` — the graph now includes `:app:minifyReleaseWithR8`, `:app:extractProguardFiles`, `:app:mergeReleaseGeneratedProguardFiles`. `android/app/proguard-rules.pro` carries keep rules for the four libraries named in AC6.1, with Omotenashi comments explicitly noting that Drift/Riverpod/Freezed/Dio are Dart-only today and the rules target the native plugin shims those libraries will interop with in Story 1.3+ (sqlite3_flutter_libs for Drift, Cronet + OkHttp for Dio). Attributes required by Crashlytics (`SourceFile`, `LineNumberTable`, `*Annotation*`) kept because Story 9.2's symbol upload depends on them. Local gates (`dart analyze --fatal-warnings --fatal-infos`, `dart format --set-exit-if-changed .`, `flutter test`, `./gradlew :app:tasks`) all green. Full release AAB build itself is deferred to Task 8's tag-push verification.

### Change Log

| Date | Task | Notes |
|---|---|---|
| 2026-04-23 | Task 1 (AC1) | Flutter project scaffolded via canonical command; pubspec pinned; lock committed; platform constraint verified. |
| 2026-04-23 | Task 2 (AC2) | Analyzer tightened (flutter_lints + strict language modes + 5 named rules); `dart analyze --fatal-warnings --fatal-infos` and `dart format --set-exit-if-changed .` pass. Reverted the premature Task 7.2 test file that was dragged in by commit `6683d03`. |
| 2026-04-23 | Task 3 (AC3) | Wired six GitHub Actions workflows (`analyze`, `pii_guard`, `test`, `integration_fake`, `testapi_canary`, `build_aab`); added `integration_test/app_test.dart` boot probe, `test/app_smoke_test.dart`, `docs/ci/README.md`, `docs/ci/pii-guard-regex.md`. Integration tests run on an Android emulator via `reactivecircus/android-emulator-runner@v2` because `flutter test integration_test/` requires a device. |
| 2026-04-23 | Task 4 (AC4, AC5) | Hardened `android/app/src/main/AndroidManifest.xml` with `allowBackup=false`, `fullBackupContent=false`, 3 explicit permissions, and `networkSecurityConfig` wiring; created `android/app/src/main/res/xml/network_security_config.xml` skeleton (base-config cleartext denied; evisitor.hr domain-config with placeholder pin-set deferred to story 1.3). |
| 2026-04-23 | Task 5 (AC6) | Created `android/app/proguard-rules.pro` with keep rules for Flutter engine, sqlite3_flutter_libs (Drift's native loader), Cronet + OkHttp (Dio's native adapter path), Freezed `$CopyWith`/`$When` patterns, and Crashlytics-required attributes. Enabled `isMinifyEnabled`/`isShrinkResources` on the `release` buildType in `android/app/build.gradle.kts`. Gradle dry-run confirms `:app:minifyReleaseWithR8` is wired. |
| 2026-04-24 | Task 6 (AC7) | Pinned Android SDK targets to literals in `android/app/build.gradle.kts` (`compileSdk=36`, `minSdk=24`, `targetSdk=36`, `ndkVersion="28.2.13676358"`). Documented chosen values + Play policy source in `docs/ci/README.md` §SDK targets. Gradle dry-run + full local gates pass; R8 still chains on release. |
| 2026-04-24 | Task 7 (AC8) | Added `lib/core/env/evisitor_env.dart` (enum + ambient getter + pure `envFromDefine` resolver) and `test/core/env/evisitor_env_test.dart` (default + `test`/`fake` overrides + ArgumentError on unknown). Ambient getter correctly flips under `--dart-define=EVISITOR_ENV=…`; no Gradle flavors introduced. All local gates green. |
| 2026-04-24 | Task 9 (AC10) | Cold-start probe landed in `integration_test/app_test.dart`: switched to `IntegrationTestWidgetsFlutterBinding`, added `integration_test` SDK-bundled dev dep, measure 5 samples (iter 0 via `waitUntilFirstFrameRasterized`, iter 1..4 via real-vsync `pump()`), debugPrint p50/p95/max, hard-fail at 2.5 s on both cold-start sample and slowest sample. Threshold inlined to prevent CI-arg loosening. Local gates all green; probe executes on the `integration_fake` AVD in CI. |
| 2026-04-24 | Task 10 (AC11) | `.gitignore` rewritten: upstream Flutter template (user-supplied) merged with prior prijavko entries; `.vscode/*` + `launch.json`/`settings.json` exceptions added (AC11.1); "AC11.2 anchors" footer negates `*.lock` / broader patterns with `!pubspec.lock`, `!**/*.g.dart`, `!**/*.freezed.dart`, `!/android/app/proguard-rules.pro`, `!/android/app/src/main/res/xml/network_security_config.xml`. `git check-ignore -q` verified against all AC11.1 (ignored) and AC11.2 (tracked) targets. Local gates green. |
| 2026-04-24 | Task 8 (AC9) | Release-build pipeline verified. Local AAB dry-run produced a 36 MB `app-release.aab` + 3.5 MB `build/symbols/` tree; debug-keystore signing confirms no release-secret dependency. CI round-trip verified with a disposable `v0.0.1-dryrun` tag against this branch — `build_aab` workflow ran green, AAB and symbols artifacts uploaded with 90-day retention; tag subsequently deleted locally and on origin. versionCode formula validated against all 5 documented tag shapes (1:1 match with `docs/ci/README.md §Release versioning strategy`). No production code changed — pure verification of Task 3's wiring. |

### File List

- `pubspec.yaml` (created, then edited to pin SDK + flutter + project description)
- `pubspec.lock` (created, committed per architecture §4)
- `analysis_options.yaml` (created by scaffold; Task 2 tightened it with flutter_lints + strict language modes + 5 named rules)
- `.gitignore` (created by scaffold; edited, Task 10 — merged upstream Flutter template with prijavko entries; added `.vscode/*` + `launch.json`/`settings.json` exceptions; added AC11.2 anchors footer with `!pubspec.lock` + `!**/*.g.dart` + `!**/*.freezed.dart` + `!/android/app/proguard-rules.pro` + `!/android/app/src/main/res/xml/network_security_config.xml`)
- `.metadata` (created by scaffold)
- `README.md` (created by scaffold)
- `lib/main.dart` (empty-scaffold body emitted by `--empty`; reformatted by `dart format` under Task 2; no feature code)
- `android/**/*` (full Android module emitted by scaffold; Tasks 4–7 will harden specific files)
- `android/app/src/main/AndroidManifest.xml` (edited, Task 4 — backup disabled, 3 permissions declared, network security config referenced)
- `android/app/src/main/res/xml/network_security_config.xml` (created, Task 4 — cleartext denied base-config + evisitor.hr pin-set skeleton)
- `android/app/proguard-rules.pro` (created, Task 5 — R8 keep rules for Drift/Riverpod/Freezed/Dio + Flutter engine + Crashlytics attrs)
- `android/app/build.gradle.kts` (edited, Tasks 5 + 6 — R8 release wiring; SDK targets pinned: `compileSdk=36`, `minSdk=24`, `targetSdk=36`, `ndkVersion="28.2.13676358"`)
- `.github/workflows/analyze.yml` (created, Task 3)
- `.github/workflows/pii_guard.yml` (created, Task 3)
- `.github/workflows/test.yml` (created, Task 3)
- `.github/workflows/integration_fake.yml` (created, Task 3)
- `.github/workflows/testapi_canary.yml` (created, Task 3)
- `.github/workflows/build_aab.yml` (created, Task 3)
- `docs/ci/README.md` (created, Task 3; edited, Task 6 — §SDK targets table + Play policy source URL)
- `docs/ci/pii-guard-regex.md` (created, Task 3)
- `integration_test/app_test.dart` (created, Task 3 — boot probe; edited, Task 9 — extended with cold-start guard rail backed by `IntegrationTestWidgetsFlutterBinding` + `waitUntilFirstFrameRasterized`; 5-sample p50/p95 logging; 2.5 s hard-fail gates)
- `pubspec.yaml` (edited, Task 9 — added `integration_test: sdk: flutter` dev dep so the probe has access to `IntegrationTestWidgetsFlutterBinding`)
- `pubspec.lock` (updated, Task 9 — regenerated after adding `integration_test` + transitive deps)
- `test/app_smoke_test.dart` (created, Task 3 — keeps `flutter test` exit code 0 on commit #1)
- `lib/core/env/evisitor_env.dart` (created, Task 7 — `EvisitorEnv` enum, ambient `evisitorEnv` getter, pure `envFromDefine` resolver with ArgumentError on unknown)
- `test/core/env/evisitor_env_test.dart` (created, Task 7 — AC8.2 coverage: default → prod, `test`/`fake` overrides, unknown throws)

