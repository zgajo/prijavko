# prijavko

Croatian eVisitor guest registration for small hosts — fast, offline-tolerant,
privacy-first. Android-only Flutter app that lets tourism hosts (apartments,
rooms, small hotels) scan guest travel documents, buffer check-ins in a local
queue, and batch-submit to the national eVisitor system.

## Stack (authoritative)

Flutter stable + Dart 3.x, Material 3, Riverpod 3, Drift, Freezed, Dio,
go_router, on-device MRZ + ML Kit OCR, Firebase Crashlytics (PII-scrubbed),
AdMob with UMP/CMP consent. Android `minSdk 24`, `targetSdk 36`. No iOS.

Environment is switched via `--dart-define=EVISITOR_ENV=<prod|test|fake>` —
**no Gradle flavors**. See [lib/core/env/evisitor_env.dart](lib/core/env/evisitor_env.dart).

## Build

```bash
flutter pub get
flutter analyze                       # zero warnings, zero infos
flutter test                          # unit + widget
flutter test integration_test/ \
  --dart-define=EVISITOR_ENV=fake     # integration (needs an Android emulator)
flutter build appbundle --release \
  --dart-define=EVISITOR_ENV=prod \
  --obfuscate --split-debug-info=build/symbols/
```

## CI

Six GitHub Actions workflows — see [docs/ci/README.md](docs/ci/README.md) for
the trigger/scope/failure-signal matrix: `analyze`, `pii_guard`, `test`,
`integration_fake`, `testapi_canary` (nightly cron), `build_aab` (`v*` tag).

## Planning artifacts

Architecture, PRD, epics, stories, and retrospectives live in
[_bmad-output/](_bmad-output/). Do not mix planning docs into `lib/` or `test/`.

## Agent rules

AI coding agents read [AGENTS.md](AGENTS.md) (symlinked as `CLAUDE.md` for
Claude Code) on every session. Project rules live under
[.claude/rules/](.claude/rules/).
