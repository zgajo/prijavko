# Deferred work

## Deferred from: code review of task-01-project-scaffold.md (2026-04-17)

- **Error handler swallows error details:** `setErrorHandler` logs the error but returns a generic body; when debugging mock misbehaviour in integration tests the actual error is invisible in the response.

- **`.nvmrc` pins major only (`22`):** Not fully reproducible across Node 22.x patch releases; low impact for a local test tool but worth pinning a specific version before CI is wired up (story 2-1).

- **`@fastify/cookie` registered without `secret`:** If future tasks add signed cookies the server will silently produce unsigned ones; clarify signing intent when auth routes are added (task 3/6).

- **Plugin registration errors unhandled from `buildApp()`:** If a plugin rejects, the error propagates as an unhandled rejection from `main()`. Test isolation patterns for task 7 should add per-test `app.close()` and catch plugin errors explicitly.

- **`bodyLimit` 1 MB applies globally:** Any future route handling larger payloads (binary blobs, bulk exports) will get a misleading 500 from the custom error handler rather than a 413. Revisit per-route `bodyLimit` when adding routes in tasks 3–6.

## Deferred from: code review of 1-5-go-router-shell-onboarding-guard-connectivity.md (2026-04-14)

- **Duplicate onboarding tests:** `widget_test.dart` and `app_router_test.dart` both cover empty DB → onboarding; merge or specialize (e.g. widget_test locale-only, router test insert path only) when convenient.

- **Stream subscription teardown:** `FacilitiesRouteRefreshNotifier.dispose` uses `unawaited` cancel; revisit only if teardown ordering causes flakes.

## Deferred from: code review of 1-3-material-3-theme-app-queue-theme.md (2026-04-14)

- **Commit scope:** Story 1.4/1.5 markdown stubs and `epics.md` changes landed in the same change set as Story 1.3 theme implementation; defer stricter story-scoped commits to team preference.

- **Config override test:** Removing the dev API string from the root widget removed the widget test that exercised `ProviderScope` + `appConfigProvider` overrides; reintroduce config coverage in a dedicated test file when convenient so Story 1.1 dart-define behavior does not rely on manual checks only.

## Deferred from: code review (2026-04-14) — 1-2-core-domain-models-database-schema-code-generation.md

- **PII scrubber — unstructured names / short doc numbers:** Deferred per review decision (option 3). Follow-up story: stronger heuristics or structured redaction at log call sites beyond `extraSecrets`.

- **Generated schema verification (AC2):** Chunk A excluded `*.g.dart`; confirm `app_database.g.dart` migration matches the intended four tables, foreign keys, and guest indexes before closing the story.

- **Enum read path on corruption:** `GuestState.fromDbValue` / peers throw `ArgumentError` on unknown ints; decide later whether reads should map to a safe sentinel or surface `Failure`/`Result` at the repository boundary.

## Deferred from: code review of 1-1-flutter-project-initialization-build-configuration.md (2026-04-14)

- CI `git diff` after `build_runner` only validates changes under `prijavko/` because the workflow `defaults.run.working-directory` is `prijavko`. If codegen is ever added at the repo root, this job would not catch drift there.

- **Release signing (user 1c):** Tag CI builds still use the default Flutter `release` signing block (debug keys). Add a dedicated story or task for release keystore / Play App Signing secrets and Gradle `signingConfigs.release` before treating tag AABs as store-upload artifacts.

- **Lint enforcement (user 2b):** Follow-up story when the pub graph allows: reintroduce `riverpod_lint` and/or enable `custom_lint` as an analyzer plugin (or gate CI on `dart run custom_lint`) without solver conflicts.
