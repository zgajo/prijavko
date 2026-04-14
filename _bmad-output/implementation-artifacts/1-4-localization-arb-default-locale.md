# Story 1.4: Localization (ARB) & Croatian Default

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **host**,
I want **the app UI strings in Croatian with English available**,
so that **copy matches the product language and stays maintainable in ARB files**.

## Acceptance Criteria

1. **gen-l10n** — Given `pubspec.yaml` enables generation and `l10n.yaml` (or equivalent) points at ARBs, when `flutter pub get` / build runs, then **`AppLocalizations`** (Flutter-generated class) is produced from ARB without analyzer errors. `flutter gen-l10n` succeeds.

2. **ARB files** — Given `assets/l10n/`, then **`app_hr.arb`** (template locale **hr**, Croatian copy) and **`app_en.arb`** (English) exist with **metadata** (`@@locale` where applicable) and at least these keys for Story 1.5 shell prep:
   - Tab labels: Home, Queue, History, Settings
   - Actions: confirm, cancel, retry, send, delete
   - One generic error string (e.g. `errorGeneric`)
   - **App title** (used in `MaterialApp.title` / `AppBar` / placeholder)
   - Croatian strings are the **authoritative** product copy; English is translation for testers / bilingual hosts.

3. **Default locale policy** — Given device locale may be non-Croatian, when locale resolution runs, then behavior is **Croatian-first** per PRD: implement explicit resolution (e.g. `localeResolutionCallback` or `localeListResolutionCallback` on `MaterialApp`) so **`hr` is chosen** when supported (including when device lists `en` only — app still defaults UI to Croatian unless you intentionally prefer `en` from device; **document the exact rule in a code comment** next to the callback). Testers must be able to verify HR-default vs EN via widget test or documented override.

4. **App wiring** — Given `PrijavkoApp` from Story 1.3, when built, then `MaterialApp` includes:
   - `localizationsDelegates`: `AppLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate` (as required by [Flutter internationalization](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization))
   - `supportedLocales`: at minimum `Locale('hr')`, `Locale('en')`
   - **No hardcoded Croatian** (or English product copy) in **new** UI paths — placeholder `AppBar` / body use **`context.l10n`** (see Dev Notes for `BuildContext` extension pattern).

5. **Dependencies** — `flutter_localizations` is declared with `sdk: flutter`; `pubspec.yaml` has `flutter: generate: true`; ARB assets path is consistent with `l10n.yaml` / Flutter docs.

6. **Tests** — Widget test: `MaterialApp` (or `PrijavkoApp` with test-friendly wrapping) with explicit **`Locale('en')`** (or `'hr'`) loads without missing-delegate crash and asserts a known localized string matches expected translation for that locale.

## Tasks / Subtasks

- [x] Add **`flutter_localizations`** + set **`flutter: generate: true`** in `pubspec.yaml`; add **`l10n.yaml`** at package root with `arb-dir: assets/l10n`, **`template-arb-file: app_hr.arb`**, `output-localization-file` / `output-dir` under **`lib/core/l10n/`** to match [Source: `_bmad-output/planning-artifacts/architecture.md` — Project Structure]. (AC: #1, #5)

- [x] Create **`assets/l10n/app_hr.arb`** (template) and **`assets/l10n/app_en.arb`** with all keys listed in AC #2; ensure **`app_en.arb`** mirrors keys (Flutter validates). Register **`assets/`** in `pubspec.yaml` if not already. (AC: #2)

- [x] Run **`flutter gen-l10n`** (or `flutter pub get` which triggers gen) and ensure generated `AppLocalizations` is imported from the configured output path; add **`lib/core/l10n/context_l10n.dart`** (or single barrel) exporting **`extension type`** / **`BuildContext` → `AppLocalizations l10n`** so widgets match **`context.l10n.*`** from project-context. (AC: #1, #4)

- [x] Update **`prijavko/lib/app.dart`**: wire delegates, `supportedLocales`, locale resolution with **documented Croatian-first policy** comment; replace hardcoded `'Prijavko'` strings with l10n keys; keep theme from Story 1.3 unchanged. (AC: #3, #4)

- [x] Add **`test/core/l10n/`** widget test (e.g. `app_localizations_test.dart`) per AC #6 — pump app with `localizationsDelegates` + explicit locale, expect string. (AC: #6)

## Dev Notes

### Scope

- **In:** ARB assets, `l10n.yaml`, generated `AppLocalizations`, `MaterialApp` localization fields, placeholder screen strings, focused tests.
- **Out:** `go_router`, shell `NavigationBar`, onboarding — **Story 1.5**. Still **define tab label keys** in ARB now so 1.5 only **binds** them.

### Architecture compliance

- **ARB location:** `assets/l10n/app_hr.arb` + `app_en.arb` [Source: `architecture.md` — Complete Project Directory Structure].
- **Generated / helpers:** `lib/core/l10n/` for generated output + small extension/barrel — aligns with architecture diagram (`l10n.dart` / generated siblings). Do **not** scatter ARB under `lib/` without `l10n.yaml` pointing correctly.
- **Strings in widgets:** `context.l10n.errorGeneric` pattern [Source: `project-context.md` — Widget Rules]. Implement `l10n` getter once; every feature imports the same pattern.

### Technical requirements (guardrails)

| Topic | Requirement |
|-------|-------------|
| Template locale | **`app_hr.arb` = template** (primary Croatian). `app_en.arb` follows keys. |
| `MaterialApp.title` | Use **localized app title** from ARB (or l10n key), not raw `'Prijavko'` long-term — at minimum placeholder `AppBar` uses l10n. |
| Delegates order | Include Material/Cupertino/Widgets globals **after** `AppLocalizations.delegate` per Flutter docs. |
| Croatian-first | **Explicit** resolution — e.g. prefer `hr` from `supportedLocales` when device locale is unsupported, or always start app in `hr` unless user selects `en` later (selection is **out of scope**; default = HR). Encode the chosen rule in **one block comment** in `app.dart`. |
| CI | `flutter analyze` zero warnings; `flutter test` green. |

### Library / framework

- **`flutter_localizations`**: SDK dependency (no extra pub.dev package for core i18n).
- **Code gen:** Flutter tool reads `l10n.yaml`; no `build_runner` for ARB (separate from Drift/freezed). CI should still run `flutter test` which compiles generated files.

### File structure (expected touch list)

| Path | Action |
|------|--------|
| `prijavko/pubspec.yaml` | `generate: true`, `flutter_localizations`, assets |
| `prijavko/l10n.yaml` | **New** — arb-dir, template, output under `lib/core/l10n/` |
| `prijavko/assets/l10n/app_hr.arb` | **New** |
| `prijavko/assets/l10n/app_en.arb` | **New** |
| `prijavko/lib/core/l10n/` | Generated `app_localizations.dart` (+ delegates) + optional `context_l10n.dart` / barrel |
| `prijavko/lib/app.dart` | Delegates, locales, resolution, l10n for visible strings |
| `prijavko/test/core/l10n/*.dart` | **New** widget test |

### Testing requirements

- Mirror path: `test/core/l10n/...` for l10n-specific tests [Source: `project-context.md` — Test Organization].
- Use **`testWidgets`** with **`MaterialApp`** (or full `PrijavkoApp` if `ProviderScope`/config already required — reuse `widget_test.dart` patterns from Story 1.1/1.3).
- Assert **no throw** from `AppLocalizations.of(context)` when locale is set.

### Previous story intelligence (Story 1.3)

- **`PrijavkoApp`** is `StatelessWidget`; **`buildLightTheme` / `buildDarkTheme`** — preserve; only add localization fields.
- **Placeholder** uses `AppBar` + `Center` text — **replace** `'Prijavko'` literals with l10n.
- Review noted **ProviderScope** coverage gap in `widget_test` — if `PrijavkoApp` gains dependencies later, keep tests minimal; for 1.4, prefer **`MaterialApp` + theme + l10n** in isolation if simpler.

### Project context reference

- [Source: `_bmad-output/project-context.md`] — Croatian UI, English via ARB; no hardcoded Croatian in widgets; longer Croatian strings tolerated (UX-DR20 in epics).

### References

- `_bmad-output/planning-artifacts/epics.md` — Story 1.4 acceptance criteria (lines ~340–363)
- `_bmad-output/planning-artifacts/architecture.md` — `assets/l10n/`, `lib/core/l10n/`, agent rules §7 Croatian strings
- Flutter: [Internationalizing Flutter apps](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization)

### Latest tech notes (2026)

- **`flutter gen-l10n`** is the supported path; `generate: true` in `pubspec` is required.
- Prefer **single `l10n.yaml`** at package root; **`synthetic-package: false`** + explicit `output-dir` keeps sources in `lib/` for analysis and grep.
- **`@` metadata keys** in ARB (`@appTitle`: description) improve translator context — optional but cheap.

## Dev Agent Record

### Agent Model Used

Cursor Agent (dev-story workflow)

### Debug Log References

### Completion Notes List

- Implemented `l10n.yaml` with `app_hr.arb` as template, ARBs under `assets/l10n/`, codegen to `lib/core/l10n/`.
- Wired `MaterialApp` with delegates (order per AC), `supportedLocales` `hr` + `en`, `onGenerateTitle` + `context.l10n` for UI copy.
- **`localeResolutionCallback`**: match platform to `hr`/`en` when supported; **fallback to `hr`** when unsupported (Croatian-first).
- Added `ContextL10n` extension and widget tests for explicit `Locale('en')` / `Locale('hr')` string lookups.

### Key implementation files (behavior map)

- `prijavko/lib/app.dart` (delegates, locale resolution, `PrijavkoApp` UI strings)
- `prijavko/lib/core/l10n/context_l10n.dart` (`BuildContext.l10n`)
- `prijavko/lib/core/l10n/app_localizations*.dart` (generated)
- `prijavko/assets/l10n/app_hr.arb` / `app_en.arb` (source strings)
- `prijavko/l10n.yaml` / `prijavko/pubspec.yaml` (gen-l10n + `flutter_localizations`)
- `prijavko/test/core/l10n/app_localizations_test.dart` (en/hr assertions)

### File List

- `prijavko/pubspec.yaml`
- `prijavko/l10n.yaml`
- `prijavko/assets/l10n/app_hr.arb`
- `prijavko/assets/l10n/app_en.arb`
- `prijavko/lib/core/l10n/app_localizations.dart`
- `prijavko/lib/core/l10n/app_localizations_en.dart`
- `prijavko/lib/core/l10n/app_localizations_hr.dart`
- `prijavko/lib/core/l10n/context_l10n.dart`
- `prijavko/lib/app.dart`
- `prijavko/test/core/l10n/app_localizations_test.dart`
- `prijavko/test/widget_test.dart`
- `prijavko/test/data/database/drift_dao_test.dart` (dart format only)

### Change Log

- Story 1.4: ARB + gen-l10n, Croatian-first `localeResolutionCallback`, `context.l10n`, tests (2026-04-14)

## Story Completion Status

**done** — Code review passed (2026-04-14); `flutter analyze` clean, `flutter test` green.
