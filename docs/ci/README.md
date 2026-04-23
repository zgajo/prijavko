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

Tag shape is `vX.Y.Z` with an optional pre-release suffix:

| Tag | `versionName` | `versionCode` |
| --- | --- | --- |
| `v1.0.0` | `1.0.0` | `10000` |
| `v1.0.1` | `1.0.1` | `10001` |
| `v1.1.0` | `1.1.0` | `10100` |
| `v1.0.0-dryrun` | `1.0.0-dryrun` | `10000` |
| `v2.3.4-beta` | `2.3.4-beta` | `20304` |

Formula: `versionCode = MAJOR * 10000 + MINOR * 100 + PATCH`. Pre-release
suffixes (`-dryrun`, `-beta`, etc.) are preserved in `versionName` for
traceability but stripped from `versionCode` so two tags sharing the same
`X.Y.Z` core cannot be uploaded to the same Play track without an explicit
bump. The derivation lives inline in [`build_aab.yml`](../../.github/workflows/build_aab.yml) `Derive version name + code from tag`.

## SDK targets

_Populated by Story 1.1 Task 6 (AC7.2) — `minSdkVersion`, `targetSdkVersion`,
`compileSdkVersion`, and the Play policy URL that justifies the chosen
target. Not yet filled in; will be updated before Task 6 is committed._

## PII guard regex

See [`pii-guard-regex.md`](./pii-guard-regex.md) for the exact pattern,
passing examples (allowed code), and failing examples (blocked code).
