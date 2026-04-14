# Deferred work

## Deferred from: code review (2026-04-14) — 1-2-core-domain-models-database-schema-code-generation.md

- **PII scrubber — unstructured names / short doc numbers:** Deferred per review decision (option 3). Follow-up story: stronger heuristics or structured redaction at log call sites beyond `extraSecrets`.

- **Generated schema verification (AC2):** Chunk A excluded `*.g.dart`; confirm `app_database.g.dart` migration matches the intended four tables, foreign keys, and guest indexes before closing the story.

- **Enum read path on corruption:** `GuestState.fromDbValue` / peers throw `ArgumentError` on unknown ints; decide later whether reads should map to a safe sentinel or surface `Failure`/`Result` at the repository boundary.

## Deferred from: code review of 1-1-flutter-project-initialization-build-configuration.md (2026-04-14)

- CI `git diff` after `build_runner` only validates changes under `prijavko/` because the workflow `defaults.run.working-directory` is `prijavko`. If codegen is ever added at the repo root, this job would not catch drift there.

- **Release signing (user 1c):** Tag CI builds still use the default Flutter `release` signing block (debug keys). Add a dedicated story or task for release keystore / Play App Signing secrets and Gradle `signingConfigs.release` before treating tag AABs as store-upload artifacts.

- **Lint enforcement (user 2b):** Follow-up story when the pub graph allows: reintroduce `riverpod_lint` and/or enable `custom_lint` as an analyzer plugin (or gate CI on `dart run custom_lint`) without solver conflicts.
