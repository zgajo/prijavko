# Story 1.2: Core Domain Models, Database Schema & Code Generation

Status: done

<!-- Ultimate context engine analysis completed — comprehensive developer guide created. Optional: run validate-create-story before dev-story. -->

## Story

As a **developer**,
I want **the Drift database schema, freezed domain models, error handling pattern, and code generation pipeline working end-to-end**,
so that **all features have a shared data foundation to build on**.

## Acceptance Criteria

1. **Code generation** — Given the project from Story 1.1, when `dart run build_runner build --delete-conflicting-outputs` is run, then all `.g.dart` and `.freezed.dart` files generate without errors and `dart analyze` is clean.

2. **Drift schema** — Given Drift tables are defined, when the schema is inspected, then **four** tables exist with at least the columns below; **WAL mode** enabled; **foreign keys enforced**; indexes **`idx_guests_facility_id`**, **`idx_guests_state`** per epic, plus **`idx_guests_submitted_at`** and **`idx_guests_created_at`** for purge queries per [Source: `_bmad-output/project-context.md` — Drift & Database Rules].

   | Table | Purpose / key columns |
   |-------|------------------------|
   | `facilities` | `id`, `name`, `facilityCode`, `defaults` (JSON blob for facility defaults) |
   | `credentials` | `id`, `facilityId` (FK), `encryptedUsername`, `encryptedPassword`, `createdAt` |
   | `guests` | `id`, `guid` (UUID string), `facilityId` (FK), `sessionId` (FK, nullable if no session yet), `state`, `captureTier`, **eVisitor payload fields** (see Dev Notes), `eVisitorResponse` (nullable text/JSON), `errorMessage`, `isTerminalFailure`, `createdAt`, `confirmedAt`, `submittedAt`, `source` (`local` / `remote`) |
   | `scan_sessions` | `id`, `facilityId` (FK), `startedAt`, `endedAt`, `guestCount` |

3. **DAOs** — Given DAOs exist, when `FacilitiesDao`, `GuestsDao`, `ScanSessionsDao` are inspected, then each exposes basic CRUD and **`.watch()`** (or equivalent stream) methods for reactive queries.

4. **Freezed models** — Given `lib/data/models/` is inspected, then **`Guest`**, **`Facility`**, **`ScanSession`** freezed classes exist with `copyWith`, equality, and JSON where needed for facility defaults; **`GuestState`** enum: `captured`, `confirmed`, `ready`, `sending`, `sent`, `failed`, `pausedAuth`; **`CaptureTier`**: `mrz`, `ocr`, `manual`; **`GuestSource`**: `local`, `remote` (maps `source` column); **`Failure`** sealed hierarchy: `NetworkFailure`, `AuthFailure`, `ApiFailure(String userMessage)`, `ValidationFailure(Map<String,String> fields)`, `StorageFailure` (align field names with [Source: `architecture.md` — Error Handling Pattern]).

5. **`Result<T, Failure>`** — Given `lib/core/result/result.dart` exists, then a **sealed** `Result` type represents success (`T value`) or failure (`Failure`) without conflating the variant name with the `Failure` type (e.g. `Result.success` / `Result.failure` via freezed or sealed class pattern).

6. **Core utils** — Given `lib/core/utils/`, then **`DateFormatter`**: `YYYYMMDD` ↔ `DateTime`, Croatian display `dd.MM.yyyy.`; **`UuidGenerator`**: UUID v4 strings; **`PiiScrubber`**: strips guest names, document numbers, MRZ-like patterns, and credential substrings from arbitrary strings intended for logs (integrate with Crashlytics path in later stories).

7. **Migrations** — Given `data/database/migrations/`, then schema **version 1** initial migration and a clear pattern for numbered `onUpgrade` steps [Source: `architecture.md` — Migration Strategy; `project-context.md` — Drift Migration Discipline].

## Tasks / Subtasks

- [x] Define **enums** `GuestState`, `CaptureTier`, `GuestSource` and **freezed** `Failure` in `lib/data/models/` (or `core/` per your barrel strategy — keep public API consistent with architecture tree). (AC: #4)
- [x] Implement **sealed `Result<T, Failure>`** in `lib/core/result/result.dart` (freezed recommended for parity with `Failure`). (AC: #5)
- [x] Implement **`DateFormatter`**, **`UuidGenerator`**, **`PiiScrubber`** under `lib/core/utils/`. (AC: #6)
- [x] Define **Drift tables** under `lib/data/database/tables/` with explicit `nullable()` where optional; **int**/**bigint** PKs as appropriate; **text** for UUID `guid`; map Dart `camelCase` → SQL `snake_case` per [Source: `architecture.md` — Drift Database Naming]. Use **locked rules** in "Guest row" below (TEXT eVisitor dates, `DateTimeColumn` for audit timestamps, `IntColumn` + converter for enums). (AC: #2)
- [x] Enable **WAL** and **foreign_keys** in the `QueryExecutor` / `NativeDatabase` setup in `app_database.dart`. (AC: #2)
- [x] Add **indexes**: `idx_guests_facility_id`, `idx_guests_state`, `idx_guests_submitted_at`, `idx_guests_created_at`. (AC: #2)
- [x] Implement **DAOs** with CRUD + watch streams in `lib/data/database/daos/`. (AC: #3)
- [x] Wire **`AppDatabase`** + `@DriftDatabase` including all tables + DAOs; add **`migration_strategy.dart`** with schema version **1**. (AC: #2, #7)
- [x] Register **database provider** (Riverpod): Story 1.1 uses **hand-written** `Provider` — follow the same pattern until `riverpod_generator` is added; **singleton** DB instance, `autoDispose` false. [Source: Story 1.1 completion notes]
- [x] Run **`dart run build_runner build --delete-conflicting-outputs`**; fix analyzer issues. (AC: #1)
- [x] **Tests**: unit tests for `DateFormatter`, `UuidGenerator`, `PiiScrubber`; Drift **in-memory** or isolated-file tests for DAO CRUD + streams; `flutter test` green. (AC: #1, #3)

## Dev Notes

### Scope boundaries

- **In scope:** Schema v1, models, `Result`/`Failure`, utils, DAOs, migrations skeleton, codegen pipeline verified.
- **Out of scope:** Repositories, Dio, go_router shell, theme — **Story 1.3+**. Do not implement feature screens or guest state machine notifiers here; only data layer + core types so later stories plug in.

### Guest row: locked decisions + full eVisitor field list

**Why these choices (no more “pick one”):**

| Topic | Decision | Rationale |
|-------|-----------|-----------|
| **eVisitor dates & times in Drift** | **`TextColumn`** for every value the API uses as `YYYYMMDD` or `hh:mm` | Matches wire format 1:1; avoids storing device-local `DateTime` and breaking the **Europe/Zagreb** rule [Source: `project-context.md`]. `DateFormatter` parses/validates and formats UI + API. |
| **Audit timestamps** (`createdAt`, `confirmedAt`, `submittedAt`) | **`DateTimeColumn`** (Drift default — Unix ms) | Purge and sorting; treat values as **UTC** when persisting (use `DateTime.utc(...)` or `toUtc()` at write boundary). |
| **`GuestState` / `CaptureTier` / `GuestSource`** | **`IntColumn` + `TypeConverter` with fixed int constants** | Reordering Dart enum members must not change DB meaning; map explicitly (e.g. `GuestState.ready = 2` in one place). |
| **`guid`** | **`TextColumn`** (UUID string, lowercase with hyphens) | Idempotency key for eVisitor `ID` [Source: `project-context.md`]. |
| **`bool` columns** | **`BoolColumn`** | `isTerminalFailure`; nullable bool allowed where “unknown” matters. |

**`guests` table — columns (implement all in v1; nullable where marked):**

| Group | Drift column (camelCase → snake_case) | Notes |
|-------|--------------------------------------|--------|
| Keys | `id`, `guid`, `facilityId`, `sessionId` | `sessionId` nullable FK. |
| State | `state`, `captureTier`, `source` | Converters to enums (`GuestSource.local` / `.remote`). |
| Stay window | `stayFromDate`, `stayFromTime`, `foreseenStayUntilDate`, `foreseenStayUntilTime` | TEXT `YYYYMMDD` / `hh:mm`. |
| Identity | `documentType`, `documentNumber`, `touristName`, `touristSurname`, `touristMiddleName`?, `gender`, `countryOfBirth`, `cityOfBirth`, `dateOfBirth`, `citizenship`, `countryOfResidence`, `cityOfResidence` | `dateOfBirth` TEXT `YYYYMMDD`. |
| Optional contact / stay | `residenceAddress`?, `touristEmail`?, `touristTelephone`?, `accommodationUnitType`? | PRD optional. |
| Facility-driven (snapshot on guest) | `ttPaymentCategory`, `arrivalOrganisation`, `offeredServiceType` | Copied from facility defaults at capture; still stored on row for history accuracy. |
| Non-EU | `borderCrossing`?, `passageDate`? | `passageDate` TEXT `YYYYMMDD`. |
| API / errors | `eVisitorResponse`? (raw JSON), `errorMessage`?, `isTerminalFailure`? | Last submit response + failure UX [Source: `architecture.md` — Failure Severity]. |
| Audit | `createdAt`, `confirmedAt`?, `submittedAt`? | `DateTimeColumn` UTC semantics. |

**`facilities.defaults` JSON** (single TEXT blob): include at least `ttpaymentCategory`, `arrivalOrganisation`, `offeredServiceType`, `defaultStayDuration` (int days or agreed shape) — same keys the facility UI will edit in Epic 2; validate in a later story.

**Freezed `Guest`:** same fields as the table; **`String`** for every eVisitor `YYYYMMDD` / `hh:mm` field; **`DateTime?`** for `createdAt` / `confirmedAt` / `submittedAt` only (matches `DateTimeColumn` reads).

This aligns with [Source: `_bmad-output/planning-artifacts/prd.md` — eVisitor API surface] and [Source: `architecture.md` — Data Architecture].

### Architecture compliance

| Topic | Requirement |
|-------|-------------|
| Drift | 2.31+ in repo; WAL + FK [Source: `architecture.md`, `project-context.md`] |
| Naming | Tables `PascalCase` class → `snake_case` SQL; indexes `idx_{table}_{columns}` |
| Errors | `Failure` freezed sealed; `ValidationFailure` uses `Map<String,String>` for field errors |
| Result | Repositories will return `Result` in later stories — types must be ready |
| PII | `PiiScrubber` prepares NFR18; no PII in `debugPrint` paths — use scrubber in any temporary logging |
| Indexes | Purge indexes **required** in addition to epic’s two — prevents ANR on history delete [Source: `project-context.md`] |

### Library & codegen (repo reality)

- **Story 1.1** omitted `riverpod_generator` / `riverpod_lint` due to pub solver — keep **hand-written** providers for `AppDatabase` / `AppConfig` until graph allows codegen [Source: Story 1.1 Dev Agent Record].
- **`build.yaml`** exists with `drift_dev` options — extend if needed for `drift` + `freezed` build order; `project-context.md` recommends generator order: drift → freezed → json_serializable → riverpod — **riverpod codegen skipped** for now.
- **`uuid` package** already in `pubspec.yaml` — use in `UuidGenerator`.

### File structure requirements

Create real files (remove `.gitkeep` where replaced):

| Path | Role |
|------|------|
| `lib/core/result/result.dart` | Sealed `Result` + parts |
| `lib/core/utils/date_formatter.dart` | Date/time helpers |
| `lib/core/utils/uuid_generator.dart` | UUID v4 |
| `lib/core/utils/pii_scrubber.dart` | Log sanitization |
| `lib/data/models/*.dart` | freezed models + enums |
| `lib/data/database/app_database.dart` | `@DriftDatabase` |
| `lib/data/database/tables/*.dart` | Table classes |
| `lib/data/database/daos/*.dart` | DAOs |
| `lib/data/database/migrations/migration_strategy.dart` | Version + `onUpgrade` |

[Source: `architecture.md` — Complete Project Directory Structure]

### Testing requirements

- Mirror paths: `test/core/utils/...`, `test/data/database/...`.
- Drift: use in-memory executor or temporary file; **single open** per test isolate [Source: `project-context.md` — Single DB instance].
- Do not add `integration_test/` for this story unless trivial.

### Previous story intelligence (Story 1.1)

- **Codegen is CI-gated** — same `build_runner` + clean git tree expectation under `prijavko/`.
- **Analyzer**: `custom_lint` analyzer plugin may be disabled locally; still run `dart analyze` / `flutter analyze` clean.
- **Firebase**: `PiiScrubber` should be used before any future `Crashlytics` breadcrumb that might touch dynamic strings.
- **`json_annotation` ^4.9.0** pinned — keep compatible with `json_serializable` / `drift_dev`.

### Latest technical notes (2026)

- Drift **2.31.x**: use `NativeDatabase.createInBackground` or documented WAL setup for Android; verify `sqlite3_flutter_libs` init in `main.dart` if required by your Drift template (Flutter docs + Drift getting started).
- SQLite **FK**: enable `PRAGMA foreign_keys = ON` in the executor Drift uses.

### Project context reference

- Full rules: `_bmad-output/project-context.md` (Result contract, Drift-as-truth prep, no cross-feature imports — data layer only here).

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.2]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Data Architecture, Naming, Project Structure, Format Patterns]
- [Source: `_bmad-output/planning-artifacts/prd.md` — eVisitor fields & constraints]
- [Source: `_bmad-output/project-context.md` — Error Handling, Drift rules, codegen]
- [Source: `_bmad-output/implementation-artifacts/1-1-flutter-project-initialization-build-configuration.md` — prior artifact paths and solver notes]

## Dev Agent Record

### Agent Model Used

Cursor agent (implementation session, 2026-04-14).

### Debug Log References

None.

### Completion Notes List

- Drift v1 schema: `facilities`, `scan_sessions`, `credentials`, `guests` with FKs, WAL + `PRAGMA foreign_keys` on `NativeDatabase` open path; enum columns use int + `TypeConverter` with stable `dbValue` on Dart enums.
- `app_database.dart` imports enum/converter types so generated `app_database.g.dart` resolves `GuestState` / companions; Freezed 3 data classes use `sealed class` where required.
- `sqlite3_flutter_libs` 0.6.0+eol is a no-op stub (SQLite bundled via `sqlite3` / Drift); removed obsolete `applyWorkaroundToOpenSqlite3OnOldAndroidVersions` call from `main.dart`.
- Explicit `path` dependency added for `depend_on_referenced_packages` / `import 'package:path/path.dart'`.
- Tests: unit tests for core utils; in-memory Drift tests for Facilities/Guests/ScanSessions DAOs with FK + `.watch()` first emission.

### Key implementation files (behavior map)

- `prijavko/lib/data/database/app_database.dart` — `@DriftDatabase`, WAL/FK setup, `AppDatabase.forTesting`
- `prijavko/lib/data/database/tables/guests.dart` — guest columns + purge indexes
- `prijavko/lib/data/database/converters/enum_converters.dart` — stable enum ↔ int mapping
- `prijavko/lib/data/database/migrations/migration_strategy.dart` — v1 `onCreate` / `onUpgrade` pattern
- `prijavko/lib/data/database/app_database_provider.dart` — Riverpod singleton DB
- `prijavko/lib/data/models/` — `Failure`, `Result`, `Guest` / `Facility` / `ScanSession`, enums
- `prijavko/lib/core/utils/` — `DateFormatter`, `UuidGenerator`, `PiiScrubber`

### File List

- `prijavko/pubspec.yaml`
- `prijavko/lib/main.dart`
- `prijavko/lib/core/result/result.dart`
- `prijavko/lib/core/result/result.freezed.dart`
- `prijavko/lib/core/utils/date_formatter.dart`
- `prijavko/lib/core/utils/uuid_generator.dart`
- `prijavko/lib/core/utils/pii_scrubber.dart`
- `prijavko/lib/data/models/capture_tier.dart`
- `prijavko/lib/data/models/guest_source.dart`
- `prijavko/lib/data/models/guest_state.dart`
- `prijavko/lib/data/models/failure.dart`
- `prijavko/lib/data/models/failure.freezed.dart`
- `prijavko/lib/data/models/facility_defaults.dart`
- `prijavko/lib/data/models/facility_defaults.freezed.dart`
- `prijavko/lib/data/models/facility_defaults.g.dart`
- `prijavko/lib/data/models/facility.dart`
- `prijavko/lib/data/models/facility.freezed.dart`
- `prijavko/lib/data/models/guest.dart`
- `prijavko/lib/data/models/guest.freezed.dart`
- `prijavko/lib/data/models/scan_session.dart`
- `prijavko/lib/data/models/scan_session.freezed.dart`
- `prijavko/lib/data/models/models.dart`
- `prijavko/lib/data/database/converters/enum_converters.dart`
- `prijavko/lib/data/database/tables/facilities.dart`
- `prijavko/lib/data/database/tables/scan_sessions.dart`
- `prijavko/lib/data/database/tables/credentials.dart`
- `prijavko/lib/data/database/tables/guests.dart`
- `prijavko/lib/data/database/daos/facilities_dao.dart`
- `prijavko/lib/data/database/daos/facilities_dao.g.dart`
- `prijavko/lib/data/database/daos/guests_dao.dart`
- `prijavko/lib/data/database/daos/guests_dao.g.dart`
- `prijavko/lib/data/database/daos/scan_sessions_dao.dart`
- `prijavko/lib/data/database/daos/scan_sessions_dao.g.dart`
- `prijavko/lib/data/database/migrations/migration_strategy.dart`
- `prijavko/lib/data/database/app_database.dart`
- `prijavko/lib/data/database/app_database.g.dart`
- `prijavko/lib/data/database/app_database_provider.dart`
- `prijavko/test/core/utils/date_formatter_test.dart`
- `prijavko/test/core/utils/uuid_generator_test.dart`
- `prijavko/test/core/utils/pii_scrubber_test.dart`
- `prijavko/test/data/database/drift_dao_test.dart`

### Change Log

- 2026-04-14: Implemented Story 1.2 — Drift schema v1 (four tables, indexes, WAL/FK), freezed domain + `Result`/`Failure`, core utils, DAOs + migration skeleton, `appDatabaseProvider`, tests; analyzer clean; `flutter test` green.
- 2026-04-14: Code review — `parseYyyyMmDd` strict calendar validation; `ScanSessionsDao` watch tests; PII scrubber decision (3) documented on `PiiScrubber`.

### Review Findings

- [x] [Review][Decision] PII scrubber vs AC6 (names / generic doc numbers) — **Resolved (2026-04-14):** Option 3 — keep current heuristics (MRZ-like, 6+ digits, UUIDs) and `extraSecrets` for call-site–known values; document the limitation in code/README; track richer name/doc-token scrubbing in a later story. AC wording can be aligned when that story is written.

- [x] [Review][Patch] Strict calendar validation for `parseYyyyMmDd` [`prijavko/lib/core/utils/date_formatter.dart:14-26`] — Reject or return null when `YYYYMMDD` is not a real calendar date (avoid `DateTime.utc` normalization changing the day). **Fixed 2026-04-14:** round-trip check on parsed UTC date.

- [x] [Review][Patch] Add DAO watch tests for `ScanSessionsDao` [`prijavko/test/data/database/drift_dao_test.dart`] — Exercise `watchAllSessions` and/or `watchSessionsForFacility` to mirror AC3 coverage on other DAOs. **Fixed 2026-04-14:** added `scanSessionsDao watchAllSessions and watchSessionsForFacility`.

- [x] [Review][Defer] Re-review Drift-generated schema for AC2 [`prijavko/lib/data/database/app_database.g.dart`] — deferred; code review Chunk A excluded `*.g.dart`; verify generated migration reflects four tables, FKs, WAL/FK pragmas path, and indexes.

- [x] [Review][Defer] Unknown DB ints for enum columns throw `ArgumentError` [`prijavko/lib/data/models/guest_state.dart:14-22` (and peers)] — deferred; broader corruption / migration strategy is out of Story 1.2 scope unless you want defensive parsing now.

## Story Completion Status

**done** — Code review complete; patch findings addressed.
