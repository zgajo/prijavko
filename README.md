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

Seven GitHub Actions workflows — see [docs/ci/README.md](docs/ci/README.md)
for the trigger/scope/failure-signal matrix: `analyze`, `pii_guard`,
`spec_drift`, `test`, `integration_fake`, `testapi_canary` (nightly cron),
`build_aab` (`v*` tag).

## Architecture (at a glance)

Feature-based, Drift-as-truth, `Result<T, Failure>` over thrown exceptions.
Full document: [_bmad-output/planning-artifacts/architecture.md](_bmad-output/planning-artifacts/architecture.md).

| Layer | Path | Role |
| --- | --- | --- |
| App shell | [lib/app/](lib/app/) | Root `MaterialApp.router`, `go_router` config, `ProviderScope` boot |
| Core infra | [lib/core/](lib/core/) | Env switch, secure storage, Dio + cert pinning, cookie jar, logging, Drift DB |
| Design system | [lib/design/](lib/design/) | Material 3 tokens + theme builders (light/dark, dark-first) |
| Features | [lib/features/](lib/features/) | One folder per feature with `data/ domain/ presentation/`; no cross-feature imports |
| Shared widgets | [lib/widgets/](lib/widgets/) | Custom widgets that wrap Material 3 primitives where a primitive is insufficient |
| Localization | [lib/l10n/](lib/l10n/) | ARB files; Croatian primary, English fallback |

State flows: Drift writes → Riverpod stream providers → UI rebuilds. Side
effects live on Notifiers; widgets never mutate persisted state directly.

## Planning artifacts

Architecture, PRD, epics, stories, and retrospectives live in
[_bmad-output/](_bmad-output/). Do not mix planning docs into `lib/` or `test/`.

## Agent rules

AI coding agents read [AGENTS.md](AGENTS.md) (symlinked as `CLAUDE.md` for
Claude Code) on every session. Project rules live under
[.claude/rules/](.claude/rules/).
