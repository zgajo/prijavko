---
project_name: 'prijavko'
user_name: 'Darko'
date: '2026-04-14'
sections_completed:
  - 'technology_stack'
  - 'language_rules'
  - 'framework_rules'
  - 'testing_rules'
  - 'code_quality_style'
  - 'workflow_rules'
  - 'critical_dont_miss'
status: 'complete'
completedAt: '2026-04-14'
rule_count: 127
optimized_for_llm: true
party_mode_review: 'Critical Don''t-Miss Rules reviewed by Winston (Architect), Amelia (Developer), Sally (UX Designer)'
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

| Layer | Technology | Version Constraint |
|-------|-----------|-------------------|
| Framework | Flutter (Dart) | Latest stable, Android-only v1 |
| State Management | Riverpod | 3.0 with `riverpod_generator` |
| Database | Drift | 2.32+ (SQLite, WAL mode) |
| HTTP | Dio | 5.x + `dio_cookie_manager` + `PersistCookieJar` |
| Navigation | go_router | Latest stable |
| Models | freezed + json_serializable | Latest stable |
| Code Generation | build_runner | Unified pipeline for Drift + Riverpod + Freezed |
| MRZ/OCR | google_mlkit_text_recognition + mrz_parser | On-device only, no network |
| Camera | camera plugin | Latest stable |
| Credential Storage | flutter_secure_storage | Android Keystore-backed |
| Ads | Google Mobile Ads SDK + UMP/CMP | EEA consent required |
| Crash Reporting | Firebase Crashlytics | PII scrubbing mandatory |
| Build Flavors | dev / prod | `--dart-define-from-file` with `config/dev.json` and `config/prod.json` |
| Package ID | hr.prijavko.app | |

**Critical version notes:**
- Riverpod 3.0 specifically — not Bloc, not Provider, not ChangeNotifier
- Drift 2.32+ for isolate threading support and WAL mode
- Dio 5.x (not http package) — required for cookie jar integration
- `flutter_secure_storage` (not deprecated `security-crypto`) for Keystore access
- ML Kit is on-device bundled model — never cloud API

## Critical Implementation Rules

### Dart Language Rules

**Null Safety & Type Strictness:**
- Null safety enforced — no `// ignore: ...` for null checks
- Strict custom `analysis_options.yaml` — zero warnings policy
- Drift columns: explicitly `nullable()` or not — no implicit nulls
- Freezed models: required fields have no default; optional fields use `String?` with `@Default` where a sensible default exists
- UI: never display `null` — show placeholder text or hide field. No "null" or empty strings rendered

**Error Handling — `Result<T, Failure>` Contract:**
- All data/repository layer methods return `Result<T, Failure>` — never throw exceptions
- `Failure` is a `freezed` sealed hierarchy: `NetworkFailure`, `AuthFailure`, `ApiFailure(userMessage)`, `ValidationFailure(fields)`, `StorageFailure`
- No raw `try/catch` except at three boundaries: Dio interceptors, platform channel bridge, main isolate error handler
- Providers map `Result.failure` → `AsyncValue.error` with typed `Failure` preserved
- Anti-pattern: `try { } catch (e) { print(e); }` → use `Result.failure(Failure.from(e))`

**Async Patterns:**
- All async operations exposed to UI via Riverpod `AsyncValue<T>`
- Loading/error/data handled with `.when()` in widgets
- No `if (mounted) setState(...)` — Riverpod eliminates this pattern entirely
- `autoDispose` by default on providers; only keep-alive for app-lifecycle singletons (Dio instance, DB instance)

**Import Discipline:**
- No cross-feature imports: `features/capture/` must never import from `features/queue/` etc.
- Features may import from `core/` and `data/` only
- Cross-feature coordination happens through Drift DB as shared bus (write to table → other feature watches stream)
- Anti-pattern: `import '../../../features/send/...'` from capture → go through `data/` layer or shared provider
- Each feature folder has a barrel file (`{feature_name}.dart`) exporting its public API

**Constants:**
- `camelCase` (Dart convention) — not `SCREAMING_CASE`
- Example: `defaultStayDuration`, `maxRetryAttempts` — not `DEFAULT_STAY_DURATION`

### Flutter & Riverpod Rules

**Riverpod 3.0 Provider Patterns:**
- Always use `riverpod_generator` annotations — no hand-written providers
- Provider name = annotated function name + `Provider` suffix (auto-generated)
- State updates only via notifier methods — never modify state directly from widgets
- `autoDispose` by default; only keep-alive for app-lifecycle providers (Dio, DB)
- Cross-feature data: widget reads provider A and provider B independently — no provider importing another feature's provider. Go through shared `data/` layer.

**Drift-as-Truth Pattern (Critical):**
- Drift DB is the single source of truth for all guest/queue state
- Every state transition writes to Drift FIRST, then the Riverpod provider observing the Drift stream updates the UI
- No optimistic in-memory state — DB write → stream → UI rebuild
- DB reactivity: Drift `.watch()` streams → `StreamProvider` or `AsyncNotifierProvider`
- Anti-pattern: holding guest state in `StateNotifier` without Drift persistence

**Guest State Machine (7 states):**
- `captured → confirmed → ready → sending → sent / failed / pausedAuth`
- Each transition is a method on `GuestQueueNotifier` (e.g. `confirmGuest()`, `markReady()`, `markSending()`, `markSent()`, `markFailed()`)
- `sending` is a transient state — on app restart, recover to `ready` (never stuck in `sending`)
- `failed` has two sub-types: `isTerminalFailure == true` (bad data, edit required) vs `false` (network, retryable)
- `pausedAuth` → bulk state for all in-flight guests when re-auth fails; `resumeAfterAuth()` resets to `ready`

**Navigation (go_router):**
- Shell route for bottom navigation (Home, Queue, History, Settings)
- Stack navigation for camera → review → confirm flow
- Route guard: redirect to onboarding if no facility profiles exist
- Predictive back gesture support (Android 14+)

**Freezed Models:**
- All domain models (Guest, Facility, ScanSession) use `freezed`
- `Failure` hierarchy as `freezed` sealed class for pattern matching
- `copyWith`, `==`, `toString` provided by freezed — never hand-write these
- JSON serialization via `json_serializable` where needed (facility defaults)

**Code Generation Pipeline:**
- Single command: `dart run build_runner build --delete-conflicting-outputs`
- Generators: `drift_dev`, `riverpod_generator`, `freezed`, `json_serializable`
- Generated files: `.g.dart` / `.freezed.dart` — commit to repo (solo dev, simpler CI)
- MUST run `build_runner` after modifying any file that uses code generation

**Widget Rules:**
- No `setState()` anywhere — use Riverpod exclusively
- Colors: `theme.colorScheme.error` or `ThemeExtension` token — never `Color(0xFFFF0000)`
- Strings: `context.l10n.errorGeneric` from ARB — never hardcoded Croatian strings in widgets
- Credential access: via `FacilityRepository` → provider — never `flutter_secure_storage.read()` in a widget
- FLAG_SECURE on credential entry/display and guest PII screens

### Testing Rules

**Test Organization:**
- Test file mirrors source file path exactly: `lib/features/queue/providers/guest_queue_notifier.dart` → `test/features/queue/providers/guest_queue_notifier_test.dart`
- Test fixtures in `test/fixtures/`: `mrz_samples/` (ICAO TD1/TD3 vectors), `evisitor_responses/` (mock API shapes)
- Integration tests in `test/integration/` for cross-feature flows (capture-to-queue, queue-to-send)
- On-device tests in `integration_test/` for real camera + ML Kit

**Unit Test Priorities:**
- MRZ parser: checksum pass/fail with real ICAO TD1/TD3 vectors (German, Austrian, Croatian samples)
- Guest state machine: all 7 states, all transitions, process death recovery (`sending` → `ready` on restart)
- Error mapper: API `{SystemMessage, UserMessage}` → typed `Failure` with Croatian `userMessage` preserved
- XML payload builder: Dart model → eVisitor XML with correct PascalCase field names
- Validators: field length limits (doc ≤16, name ≤64), date format `YYYYMMDD`, non-EU conditional fields
- Retry logic: exponential backoff with jitter, terminal vs retryable failure classification

**Widget Test Priorities:**
- Guest submission snapshot card: read-only vs editable states, field validation display
- Queue guest row: state chip rendering for all 7 states, facility tag visibility
- Facility picker: session-scoped selection, multi-facility list

**Mock Conventions:**
- Mock eVisitor server returns real error response shapes (not simplified stubs)
- Use fixture files for API responses: `submit_success.json`, `submit_error_category.json`, `submit_error_duplicate.json`
- Camera/ML Kit: use sample document images for instrumented tests on real device

**Quality Gates:**
- `dart analyze` with zero warnings before code is considered complete
- `dart format lib/ test/` on all modified files
- `flutter test` must pass before commit

### Code Quality & Style Rules

**Naming Conventions:**

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.dart` | `guest_queue_notifier.dart` |
| Classes | `PascalCase` | `GuestQueueNotifier` |
| Variables / params | `camelCase` | `facilityCode`, `guestState` |
| Constants | `camelCase` | `defaultStayDuration` (not SCREAMING_CASE) |
| Enums | `PascalCase` type, `camelCase` values | `GuestState.confirmed` |
| Private members | `_camelCase` | `_cookieJar` |
| Providers | auto-generated `camelCaseProvider` | `guestQueueProvider` |
| Drift tables | `PascalCase` class → `snake_case` SQL | `class Guests extends Table` |
| Drift columns | `camelCase` Dart → `snake_case` SQL | `facilityCode` → `facility_code` |
| Foreign keys | `{table_singular}Id` | `facilityId`, `sessionId` |
| DAOs | `{Table}Dao` | `GuestsDao`, `FacilitiesDao` |
| Feature folders | `snake_case` noun | `capture/`, `queue/`, `send/` |
| Screen files | `{feature}_screen.dart` | `queue_screen.dart` |
| Provider files | `{concern}_notifier.dart` | `guest_queue_notifier.dart` |

**Project Structure (Feature-Based):**

```
lib/
├── core/           # Shared: theme, l10n, config, utils (used by ≥2 features)
├── data/           # Shared: Drift DB, Dio, repositories, models
├── features/{x}/   # Feature-scoped: presentation/, providers/, data/
│   ├── presentation/screens/   # Full-screen routed widgets
│   ├── presentation/widgets/   # Feature-specific reusable widgets
│   ├── providers/              # Riverpod providers + notifiers
│   └── {feature}.dart          # Barrel file
└── shared/widgets/ # Cross-feature widgets (imports core/ only)
```

**Documentation:**
- Every public function/class: Dart doc comment explaining intent and non-obvious constraints
- Comment the WHY (business context, eVisitor API quirk, MUP constraint) — not the WHAT
- No commented-out code — remove it, git has history

**Formatting:**
- `dart format` on all files — no manual formatting overrides
- `analysis_options.yaml` with strict custom rules — zero warnings policy
- No unused imports, variables, or dead code

### Development Workflow Rules

**Daily Commands:**

```bash
# Run with test API
flutter run --dart-define-from-file=config/dev.json

# Code generation after model/provider/table changes
dart run build_runner build --delete-conflicting-outputs

# Analyze + format
dart analyze && dart format lib/ test/

# Tests
flutter test

# Build release AAB for Play Store
flutter build appbundle --dart-define-from-file=config/prod.json
```

**Build Flavors:**

| Flavor | API Base | Ads | Usage |
|--------|----------|-----|-------|
| `dev` | `https://www.evisitor.hr/testApi` | Disabled | Development + testing |
| `prod` | `https://www.evisitor.hr` | Enabled | Play Store release |

- Configured via `--dart-define-from-file` — no staging flavor for v1
- Config files: `config/dev.json`, `config/prod.json`

**CI (GitHub Actions):**
- On push to `main`: `flutter analyze` + `flutter test` + `build_runner` verify
- On tag: build release APK/AAB with prod config
- Manual Play Store upload for v1

**Commit Standards:**
- Atomic commits — clear message explaining WHY the change was made
- `dart analyze` + `dart format` + `flutter test` must pass before commit
- Run `build_runner` if any codegen-annotated files changed
- Small PRs (< 400 lines)

**Drift Migration Discipline:**
- Each schema change = numbered migration in `onUpgrade`
- Integration test verifies migration from every prior version to current
- Queue data must survive app updates without data loss (NFR28)

### Critical Don't-Miss Rules

**eVisitor API Gotchas:**
- Date format to eVisitor is `YYYYMMDD` (e.g. `"20260414"`) — NOT ISO 8601
- Time format is `hh:mm` (e.g. `"18:30"`)
- **Timezone rule:** all dates/times use facility local time (`Europe/Zagreb`) — not device local, not UTC. `PassageDate` near midnight drifts otherwise.
- eVisitor field names are PascalCase (`TouristName`, `DocumentNumber`) — `XmlPayloadBuilder` handles the mapping, never use PascalCase in business logic
- API returns `{SystemMessage, UserMessage}` — pass `UserMessage` through to UI unchanged (it's already Croatian)
- **Empty `UserMessage` fallback:** API sometimes sends empty `UserMessage` with populated `SystemMessage` only. Rule: `userFacing = userMessage?.trim().isNotEmpty == true ? userMessage! : systemMessage`. Map to `ApiFailure` with the resolved Croatian text.
- **Non-JSON error bodies:** eVisitor may return HTML error pages — map to `NetworkFailure` or `AuthFailure`, not crash
- Non-EU guests require `BorderCrossing` + `PassageDate` as mandatory fields — conditional form logic
- MUP field length limits: document ≤16, name/surname ≤64 — validate client-side before send
- Cookie-based Forms Auth — cookies must survive process death via `PersistCookieJar`
- **401 vs HTML redirect:** eVisitor may return 302/200 with login HTML body, not always status 401. Treat both as auth failure for re-auth path.
- On 401 or redirect-to-login: re-auth transparently → replay failed request once → if re-auth fails, set all in-flight guests to `pausedAuth`
- **Replay gotcha:** Dio `RequestOptions` body streams are single-use — must `copyWith(data: …)` with rebuilt data on 401 replay, or POST body is empty
- Each guest needs a UUID v4 `ID` parameter (mandatory since 2017-06-01) — generated at creation, persisted in Drift, sent with every submission
- **UUID on retry:** NEVER generate a new UUID on retry — reuse the original. eVisitor uses this for idempotency/dedup.
- **Charset:** UTF-8 end-to-end. Croatian diacritics must survive XML encoding. NFC normalization if comparing strings for duplicate detection.

**Dio & Cookie Jar Rules:**
- **Interceptor order matters:** `CookieManager` → auth/401 handler → retry → logging. Wrong order = infinite 401 loop or retry without refreshed cookies.
- **Cold-start gating:** cookie jar must be loaded and attached to Dio BEFORE any request fires. Agents fire health checks too early → 401 storm.
- **Cookie jar per flavor:** separate storage paths for dev (`testApi`) and prod. Cookies must never bleed between environments.
- **Dio + jar = main isolate only.** Never share Dio/cookie jar with Drift's background isolate.

**Retry Policy:**
- Max 3 attempts per manual send action
- Exponential backoff with jitter: 1s, 2s, 4s base + random 0–500ms
- Retryable: 429, 503, timeout, network error
- Non-retryable: 400 (bad data → terminal failure, edit required), 401 (re-auth flow), 404
- **Unknown 4xx → non-retryable** unless explicitly listed as retryable
- Batch: sequential per guest, failure on one does not abort remaining batch
- **Double-send prevention:** use DB-level `UPDATE … WHERE state = 'ready'` pattern, not in-memory `if (state == ready)` check. Rapid tap can double-fire otherwise.

**Drift & Database Rules:**
- **Single DB instance:** one `QueryExecutor` / app database opened once as a long-lived provider. Never open a second connection (even in tests) — causes locking/migration issues.
- **Drift isolate rule:** Drift's background isolate handles DB reads/writes. Dio stays on main isolate. No mixing.
- **Transactions:** one transaction per guest state transition, not one giant transaction for the whole batch. Otherwise rollback semantics fight partial success.
- **Index on purge columns:** `submittedAt` and `createdAt` must have indexes — `DELETE` without index → ANR on large history tables.
- **Startup reconciliation:** on cold start, sweep rows in `sending` state → reset to `ready`. This prevents "stuck in sending" after process death.
- **CancelToken → state machine:** if user leaves screen or `CancelToken` fires during send, state must not stay `sending`. Treat cancellation like a retryable failure → `ready`.

**Security — Never Forget:**
- NEVER log PII: no guest names, document numbers, MRZ data, or credentials at ANY log level
- **No PII in Crashlytics breadcrumbs, custom keys, or analytics payloads** — agents add `setCustomKey('doc', …)` by habit
- Discard camera image bytes immediately after ML Kit processing — only extracted text fields persist
- **Also discard raw `RecognizedText` string** after extracting MRZ lines — agents log `recognizedText.text` in debug (PII leak)
- `android:allowBackup="false"` or scoped `backup_rules.xml` excluding credentials + guest DB
- Keyboard autocomplete disabled on credential fields: `enableSuggestions: false`, `autocorrect: false`
- HTTPS only in Dio — no HTTP fallback
- Debug logs stripped in release builds via `kReleaseMode` guard — includes `dart:developer` `log()`
- **No certificate pinning in v1** — explicit decision, not an oversight. Prevents agents adding a broken pin.
- **No SQLite encryption in v1** — acceptable risk for device-local storage. Explicit so agents don't add half-measures.

**ML Kit & MRZ Integration:**
- ML Kit returns lines in **reading order**, not MRZ block order — must sort/filter to 2–3 MRZ lines before passing to `mrz_parser`
- MRZ checksum fail → state is `captured` + editable review card, NOT auto-queued as `confirmed`. Agents map checksum error to network retry — wrong.
- TD1 (3×30) vs TD3 (2×44): different line counts. Partial OCR → parser throws → catch at boundary only, map to `ValidationFailure`, not `StorageFailure`

**Data Lifecycle:**
- 30-day purge on submitted guests (against `submittedAt`)
- 7-day purge on unsent stale queue items (against `createdAt`)
- Guests table doubles as queue (state < `sent`) and history (state = `sent`/`failed_terminal`) — single table, partitioned by `state` column
- `source` column (`local`/`remote`) anticipates Phase 2 read-back — include in schema now

**Validation Layers (3-tier, don't mix):**

| Layer | Responsibility |
|-------|---------------|
| Domain model constructors | Poka-yoke: field length, required presence, date format |
| Repository layer | Business rules: non-EU fields, facility assignment, duplicate check (24h), cross-field validation (exit before entry) |
| Presentation layer | Display errors only — never computes validation. Don't validate invisible fields (hidden non-EU fields). |

**Code Generation Pipeline:**
- Pin order in `build.yaml`: drift → freezed → json_serializable → riverpod. Wrong order → intermittent "getter not found" on `@JsonKey`.
- After editing any `@DriftDatabase` / `@riverpod` / `@freezed` file, MUST run `build_runner` before `dart analyze` — stale `.g.dart` files cause phantom errors.
- Renaming `@riverpod` function renames the generated `fooProvider` — grep test imports for broken `ProviderScope` overrides.

**UX Implementation Rules:**
- **State must never be color-only** — queue status needs icon + label. No `Container(color: …)` as the only failure affordance.
- **Retryable failure ≠ error red** — use warning/attention color for retryable (network issues). Reserve `ColorScheme.error` for terminal failures only. Agents reach for `error` because the enum says "failed."
- **One primary action per failure surface** — Retry OR Edit OR Re-auth, not three equal buttons.
- **`UserMessage` passthrough is UI copy** — render multiline at readable width, NOT a one-line `SnackBar` that truncates Croatian legalese.
- **Batch send = per-guest progress** — ban single `CircularProgressIndicator` for multi-guest send. Row-level sending → outcome.
- **Non-EU field appearance needs explanation** — one-line localized explainer when `BorderCrossing`/`PassageDate` appear. Screen reader announcement when mandatory fields appear/disappear on country change.
- **Touch targets ≥48dp** on stress paths (chips, row actions, torch toggle). One-handed door context.
- **Facility chip on every queue row** — even when "obvious" for single-facility users. Multi-facility anxiety is the story.
- **Semantic labels for queue rows** — single spoken TalkBack summary (e.g. "Ana Horvat, Apartment Blue, failed, can retry"), not "button, button, icon, text" soup.
- **Dynamic type support** — no fixed-height error strips. Croatian eVisitor copy runs long; must accommodate large text settings.

**Anti-Pattern Quick Reference:**

| Don't | Do Instead |
|-------|-----------|
| `try { } catch (e) { print(e); }` | `Result.failure(Failure.from(e))` |
| Hold guest state in memory only | Write to Drift first, observe stream |
| `if (mounted) setState(...)` | Use Riverpod — no `setState` |
| Hardcoded `"Greška"` in widget | `context.l10n.errorGeneric` from ARB |
| `Color(0xFFFF0000)` for error | `theme.colorScheme.error` or `ThemeExtension` |
| `import '../../../features/send/...'` from capture | Go through `data/` layer |
| `flutter_secure_storage.read()` in a widget | Read via repository → provider |
| `dynamic` type | Specific type or `Object?` |
| `error` color on retryable failure | Warning/attention color; `error` only for terminal |
| Single spinner for batch send | Per-guest row-level progress |
| `if (state == ready)` in memory | `UPDATE … WHERE state = 'ready'` at DB level |
| New UUID on retry | Reuse original UUID — idempotency key |
| `recognizedText.text` in logs | Discard raw text after MRZ extraction |

**Localization:**
- Primary language: Croatian (`app_hr.arb`)
- Fallback: English (`app_en.arb`)
- ARB files in `assets/l10n/`
- All user-facing strings via `context.l10n` — zero hardcoded strings in widgets
- eVisitor API errors are already Croatian — pass through unchanged as plain text (no HTML rendering)

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Cross-reference with `_bmad-output/planning-artifacts/architecture.md` for full architectural context

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack or patterns change
- Remove rules that become obvious over time
- This document was party-mode reviewed by Architect, Developer, and UX Designer perspectives

**When in doubt:** Drift is truth, Result is the error contract, Croatian is the UI language, `Europe/Zagreb` is the timezone.

Last Updated: 2026-04-14
