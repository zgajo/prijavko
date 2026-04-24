# CI pipeline — prijavko

This document maps each GitHub Actions workflow to its trigger, scope, and
failure signal. Every story lands on top of these guardrails, so if a
workflow is flaky or silently skipped the rest of the bootstrap collapses.

All Flutter-using workflows pin `flutter-version: '3.38.7'` via
`subosito/flutter-action@v2`. Upgrading Flutter is a single-line change in
every workflow plus `pubspec.yaml`.

## Workflow catalogue

| Workflow | Trigger | Scope | Failure signal |
| --- | --- | --- | --- |
| [`analyze.yml`](../../.github/workflows/analyze.yml) | Every `push` and `pull_request` (all branches) | `flutter pub get` → `dart analyze --fatal-warnings --fatal-infos` → `dart format --set-exit-if-changed .` | Merge blocked. Any analyzer warning/info or unformatted file fails the job. |
| [`pii_guard.yml`](../../.github/workflows/pii_guard.yml) | Every `push` and `pull_request` | Greps `lib/`, `test/`, `integration_test/` for the PII log regex documented in [`pii-guard-regex.md`](./pii-guard-regex.md). | Merge blocked. A single matching line fails the job with `::error::PII log pattern detected`. |
| [`test.yml`](../../.github/workflows/test.yml) | Every `push` and `pull_request` | `flutter test` — unit + widget tests only; integration tests run in a separate job. | Merge blocked on any failing unit/widget test. |
| [`integration_fake.yml`](../../.github/workflows/integration_fake.yml) | Every `push` and `pull_request` | `flutter test integration_test/ --dart-define=EVISITOR_ENV=fake` — exercises the app against the in-repo Dio fake (Story 1.3+). Today probes only first-frame paint. | Merge blocked on any failing integration test. |
| [`testapi_canary.yml`](../../.github/workflows/testapi_canary.yml) | Nightly `cron: '0 3 * * *'` (UTC) + manual `workflow_dispatch` | Will exercise `test.evisitor.hr` via `--dart-define=EVISITOR_ENV=test` once Epic 6 lands. Today a `echo` placeholder keeps the schedule live. | Red run on the Actions tab. Does **not** block PRs — its job is to surface contract drift between releases. |
| [`build_aab.yml`](../../.github/workflows/build_aab.yml) | `push` of a tag matching `v*` | Derives `versionName`/`versionCode` from the tag, runs `flutter build appbundle --release --dart-define=EVISITOR_ENV=prod --obfuscate --split-debug-info=build/symbols/`, uploads AAB + `build/symbols/` as artifacts (90-day retention). | Tag-run red. PRs are unaffected (the workflow only fires on tag push). |

## Release versioning strategy (AC9.3)

Tag shape is `vX.Y.Z` with an optional alphanumeric pre-release suffix
(`-dryrun`, `-beta`, `-rc1`, …). Non-matching tags are rejected by the
`Derive version name + code from tag` step before any build work begins.

| Tag | `versionName` | `versionCode` |
| --- | --- | --- |
| `v1.0.0` | `1.0.0` | `1000000` |
| `v1.0.1` | `1.0.1` | `1000010` |
| `v1.1.0` | `1.1.0` | `1010000` |
| `v1.0.100` | `1.0.100` | `1001000` |
| `v1.100.0` | `1.100.0` | `2000000` *(rejected — minor ≥ 100 would collide with `v2.0.0`; bump the major)* |
| `v1.0.0-dryrun` | `1.0.0-dryrun` | `1000000` |
| `v2.3.4-beta` | `2.3.4-beta` | `2030040` |

Formula: `versionCode = MAJOR * 1_000_000 + MINOR * 10_000 + PATCH * 10`.

Why this shape rather than `X*10000 + Y*100 + Z` (the initial story draft):
the narrower formula collides at `PATCH ≥ 100` or `MINOR ≥ 100`
(`v1.0.100 == v1.1.0 == 10100`) — a real-world possibility once the app
ships past its first year. The widened formula reserves two decimal digits
of headroom per position, and the trailing `* 10` leaves a 0..9 hotfix
counter per patch (currently unused, reserved for a future
`--build-number-override` Gradle property if a hotfix ever needs a
monotonic code on the same semver).

Pre-release suffixes are preserved in `versionName` for traceability but
stripped from `versionCode` so two tags sharing the same `X.Y.Z` core
cannot be uploaded to the same Play track without an explicit bump.

Derivation lives inline in
[`build_aab.yml`](../../.github/workflows/build_aab.yml) under
`Derive version name + code from tag`. Artifacts are suffixed
`-UNSIGNED-DRY-RUN` until Story 10.7/10.8 wires a real upload-keystore
secret (Poka-yoke — see that story for the signing cutover).

## SDK targets

Hardcoded in [`android/app/build.gradle.kts`](../../android/app/build.gradle.kts)
— deliberately **not** inherited from `flutter.*` so a Flutter channel bump
cannot silently drift what Play sees.

| Setting | Value | Rationale |
| --- | --- | --- |
| `minSdk` | `24` (Android 7.0, Nougat) | PRD NFR-C1 floor. ~98% Play device coverage; gets `NetworkSecurityConfig`, JIT, and modern TLS defaults for free. |
| `targetSdk` | `36` (Android 16) | Play requires `35` for new apps/updates since 2025-08-31 and moves the floor to `36` on 2026-08-31. Pinning `36` now clears that cliff ahead of time. |
| `compileSdk` | `36` | Matches `targetSdk`. Lets us call Android 16 APIs behind runtime version checks without the compiler complaining. |
| `ndkVersion` | `28.2.13676358` | Exact NDK mandated by Flutter `3.38.7` stable (`FlutterExtension.ndkVersion`). Bumping Flutter = bumping this string in lockstep. |

**Chosen on:** 2026-04-23.
**Play policy source:** <https://developer.android.com/google/play/requirements/target-sdk>.

When Flutter is upgraded, re-read `FlutterExtension.ndkVersion` in the new
Flutter SDK and update `ndkVersion` in `build.gradle.kts` — do not leave it
unpinned.

## PII guard regex

See [`pii-guard-regex.md`](./pii-guard-regex.md) for the exact pattern,
passing examples (allowed code), and failing examples (blocked code).
