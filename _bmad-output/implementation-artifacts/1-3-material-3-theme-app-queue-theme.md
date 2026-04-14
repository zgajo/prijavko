# Story 1.3: Material 3 Theme, AppQueueTheme & Component Themes

Status: done

## Story

As a **developer**,
I want **centralized Material 3 light/dark themes with queue state tokens and shared component themes**,
so that **all future screens reuse one visual system and queue status styling is consistent**.

## Acceptance Criteria

1. **Material 3 + teal** — Given `PrijavkoApp` builds, when themes are applied, then `ThemeData` uses `useMaterial3: true` and a teal-seeded `ColorScheme` for **light** and **dark** from the **same** seed (no palette drift between modes).

2. **`AppQueueTheme` ThemeExtension** — Given `ThemeExtension` is registered, when `AppQueueTheme` is read from `Theme.of(context)`, then semantic tokens exist for: **queued**, **sending**, **failed-retryable**, **failed-terminal**, **paused-auth**, **sent** — each with **Color** + **IconData** (labels can be l10n keys in Story 1.4). Mapping: `GuestState.failed` + `isTerminalFailure == false` → **failed-retryable**; `failed` + `isTerminalFailure == true` → **failed-terminal**. [Source: `epics.md` — UX-DR2]

3. **Component themes** — Given `buildLightTheme` / `buildDarkTheme` (or equivalent), when inspected, then **`InputDecorationTheme`**, **`FilledButtonThemeData`**, **`NavigationBarThemeData`**, **`ChipThemeData`** are set once per brightness so feature code does not restyle these primitives ad hoc.

4. **App wiring** — Given Story 1.1’s `MaterialApp` still has no `go_router` (that is Story 1.5), when the app runs, then **`PrijavkoApp`** uses `theme`, `darkTheme`, `themeMode: ThemeMode.system` and the root child is still a minimal placeholder (e.g. `Scaffold` + `AppBar` + short text) **styled by the new theme** — remove the debug “API_BASE” `Center` from Story 1.1 or replace with non-debug placeholder.

5. **Tests** — Widget test: `Theme.of(context).extension<AppQueueTheme>()` is non-null; light/dark `ThemeData` both resolve; `flutter analyze` + `flutter test` green.

## Tasks / Subtasks

- [x] Add `lib/core/theme/app_theme.dart` — builders for light/dark `ThemeData` + component themes. (AC: #1, #3, #4)
- [x] Add `lib/core/theme/queue_theme_extension.dart` — `AppQueueTheme` + `copyWith` / `lerp`. (AC: #2)
- [x] Register extension in both themes; export from a small barrel if useful. (AC: #2)
- [x] Update `lib/app.dart` to apply themes; keep **no** router/l10n in this story. (AC: #4)
- [x] Add `test/core/theme/` widget or plain tests for extension presence. (AC: #5)

### Review Findings

- [x] [Review][Decision] `sent` vs `pausedAuth` both use `ColorScheme.tertiary` — Resolved: **sent** → `primaryContainer`, **paused-auth** → `tertiary` (distinct roles). [prijavko/lib/core/theme/queue_theme_extension.dart]

- [x] [Review][Patch] Clamp `t` in `AppQueueTheme.lerp` before `Color.lerp` — [prijavko/lib/core/theme/queue_theme_extension.dart:103]

- [x] [Review][Patch] Set `InputDecorationTheme.focusedErrorBorder` to match `errorBorder`/`focusedBorder` geometry — [prijavko/lib/core/theme/app_theme.dart:29]

- [x] [Review][Defer] Same commit bundles Story 1.4/1.5 stubs and `epics.md` edits with 1.3 theme code — process noise for reviewers; prefer story-scoped commits next time. [_bmad-output/implementation-artifacts/]

- [x] [Review][Defer] `widget_test.dart` dropped `ProviderScope` + `AppConfig` override coverage when removing API debug text — consider a dedicated `test/core/config/` test in a follow-up so Story 1.1 flavor/config wiring stays guarded. [prijavko/test/widget_test.dart]

## Dev Notes

### Scope

- **In:** Theme files, `AppQueueTheme`, `ThemeData` composition, `app.dart` theme hooks only.
- **Out:** `go_router`, ARB/l10n, `ConnectivityBanner`, `PrijavkoScaffold`, facility redirect — **Stories 1.4–1.5**.

### References

- `_bmad-output/planning-artifacts/epics.md` (original Epic 1 story 1.3 theme slice)
- `_bmad-output/project-context.md` — use `ColorScheme` / `ThemeExtension`, not raw `Color(0x…)` for semantics

## Dev Agent Record

### Agent Model Used

Composer (Cursor agent)

### Debug Log References

### Completion Notes List

- Implemented `buildLightTheme` / `buildDarkTheme` with shared `Colors.teal` seed, `useMaterial3: true`, and component themes (`InputDecorationTheme`, `FilledButtonThemeData`, `NavigationBarThemeData`, `ChipThemeData`).
- Added `AppQueueTheme` `ThemeExtension` with six semantic token pairs (color + icon), `fromColorScheme`, `copyWith`, `lerp`; registered on both themes; barrel `lib/core/theme/theme.dart`.
- Wired `PrijavkoApp` with `theme`, `darkTheme`, `themeMode: ThemeMode.system`; replaced debug API string with minimal placeholder; `PrijavkoApp` is `StatelessWidget` (config no longer displayed at root).
- Tests: `test/core/theme/app_queue_theme_test.dart` (extension + M3), updated `test/widget_test.dart` for new shell.

### Key implementation files (behavior map)

- `prijavko/lib/core/theme/app_theme.dart` (light/dark builders, component themes)
- `prijavko/lib/core/theme/queue_theme_extension.dart` (`AppQueueTheme` tokens)
- `prijavko/lib/core/theme/theme.dart` (barrel)
- `prijavko/lib/app.dart` (MaterialApp theme wiring)
- `prijavko/test/core/theme/app_queue_theme_test.dart`
- `prijavko/test/widget_test.dart`

### File List

- `prijavko/lib/core/theme/app_theme.dart` (new)
- `prijavko/lib/core/theme/queue_theme_extension.dart` (new)
- `prijavko/lib/core/theme/theme.dart` (new)
- `prijavko/lib/app.dart` (modified)
- `prijavko/test/core/theme/app_queue_theme_test.dart` (new)
- `prijavko/test/widget_test.dart` (modified)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified)

### Change Log

- 2026-04-14: Story 1.3 — Material 3 teal themes, `AppQueueTheme` extension, app wiring, tests; sprint status 1-3 → review.
- 2026-04-14: Code review — `sent`/`pausedAuth` colors split (`primaryContainer` vs `tertiary`); `lerp` clamps `t`; `focusedErrorBorder` on inputs; sprint status 1-3 → done.

## Story Completion Status

**done**
