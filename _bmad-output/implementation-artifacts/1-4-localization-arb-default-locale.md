# Story 1.4: Localization (ARB) & Croatian Default

Status: backlog

## Story

As a **host**,
I want **the app UI strings in Croatian with English available**,
so that **copy matches the product language and stays maintainable in ARB files**.

## Acceptance Criteria

1. **gen-l10n** — Given `pubspec.yaml` is configured, when `flutter gen-l10n` runs (via build), then `AppLocalizations` (or project naming) is generated from ARB files without analyzer errors.

2. **ARB files** — Given `assets/l10n/`, then **`app_hr.arb`** (template, Croatian) and **`app_en.arb`** (English) exist with at least: tab labels (Home, Queue, History, Settings), common actions (confirm, cancel, retry, send, delete), one generic error string, and **app title** string — enough for shell UI in Story 1.5.

3. **Default locale** — Given the device locale is not Croatian, when locale resolution runs, then **policy is documented in code comment** (e.g. default to `hr` vs follow device): product expectation is **Croatian-first** per PRD — implement explicit `localeListResolution` or `supportedLocales` + `locale` so testers can verify HR default behavior.

4. **App wiring** — Given `PrijavkoApp` from Story 1.3, when built, then `MaterialApp` includes `localizationsDelegates`, `supportedLocales`, and **`AppLocalizations.delegate`**, and the **placeholder** root widget uses **`context.l10n`** (or generated accessor) for at least one visible string (e.g. app title) — **no hardcoded Croatian** in new UI code paths.

5. **Dependency** — `flutter_localizations` is declared per Flutter docs; `pubspec.yaml` `flutter: generate: true` and asset entries for ARB if required.

6. **Tests** — Widget test with `MaterialApp` + explicit locale override loads English (or Croatian) string without missing delegate crash.

## Tasks / Subtasks

- [ ] Add `flutter_localizations` + enable code gen in `pubspec.yaml`. (AC: #1, #5)
- [ ] Create `assets/l10n/app_hr.arb`, `app_en.arb` with metadata + strings. (AC: #2)
- [ ] Wire delegates + locale resolution in `app.dart`. (AC: #3, #4)
- [ ] Replace any user-visible hardcoded string on the placeholder screen with l10n. (AC: #4)
- [ ] Add `test/core/l10n/` or widget test with locale. (AC: #6)

## Dev Notes

### Scope

- **In:** ARB, delegates, `app.dart` localization.
- **Out:** Tab bar strings used in navigation UI until **Story 1.5** wires router — still add tab label keys to ARB now so 1.5 only **uses** them.

### Depends on

- **Story 1.3** complete (theme stays; extend same `MaterialApp`).

### References

- `_bmad-output/planning-artifacts/epics.md` — l10n slice of former 1.3
- `_bmad-output/project-context.md` — strings from ARB, not inline Croatian

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### Key implementation files (behavior map)

### File List

## Story Completion Status

**backlog**
