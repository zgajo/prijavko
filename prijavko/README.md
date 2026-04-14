# prijavko

Android-only Flutter app for eVisitor guest registration. Story 1.1 scaffold: Riverpod, Drift (runtime + `drift_dev`), Dio, Firebase (Crashlytics + Analytics), config via `--dart-define-from-file`.

## Prerequisites

- Flutter stable (see `pubspec.yaml` SDK constraint)
- Android SDK (for device/emulator builds)
- Replace `android/app/google-services.json` with the file from your Firebase Android app (`hr.prijavko.app`)

## Run (dev)

From this directory:

```sh
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

Expected defines: `API_BASE=https://www.evisitor.hr/testApi`, `AD_ENABLED=false` (see `config/dev.json`).

## Build (prod)

```sh
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

## Tests & analysis

Local checks (CI uses `flutter analyze`, same analyzer via the Flutter tool):

```sh
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## CI (GitHub Actions)

On push to `main` and on pull requests, `.github/workflows/ci.yml` runs `flutter analyze`, `flutter test`, then `build_runner` and **fails if `git diff` is non-empty** (generated files must be committed).

On **git tag** pushes, the workflow also builds a **release AAB** with `config/prod.json` and uploads it as an artifact.

## Dependency notes (Story 1.1)

- **`riverpod_generator`**: not included yet; Flutter’s pinned `test` / `test_api` currently conflict with `riverpod_generator` 4.x alongside `flutter_test`. Providers are hand-written; migrate to codegen when the toolchain allows.
- **`riverpod_lint`**: omitted; conflicts with `drift_dev` + `flutter_test` on the resolved graph. Revisit with Drift/Riverpod upgrades.
- **`custom_lint`**: listed in `dev_dependencies`; the analyzer plugin snapshot failed under Dart 3.10 in one local setup—prefer `dart run custom_lint` when supported, or re-enable `analyzer.plugins` once stable.
- **`json_annotation`**: pinned to `^4.9.0` so `json_serializable` + `drift_dev` + `flutter_test` resolve together; relax when upgrading Drift/JSON stack.

## Project layout

Feature-first structure under `lib/` (`core/`, `data/`, `features/*`, `shared/`). Empty dirs use `.gitkeep` so Git tracks the skeleton.
