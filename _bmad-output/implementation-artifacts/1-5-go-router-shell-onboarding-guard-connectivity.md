# Story 1.5: go_router Shell, Onboarding Guard, Scaffold & Connectivity

Status: backlog

## Story

As a **host**,
I want **bottom navigation across main sections, a safe onboarding entry when I have no facility, and offline awareness**,
so that **I can move around the app and later features plug into fixed routes**.

## Acceptance Criteria

1. **Shell + tabs** — Given `go_router` is configured, when the user opens the app with **≥1 facility** in Drift, then a **shell route** shows a bottom `NavigationBar` with four branches: Home, Queue, History, Settings — each with **placeholder** body (title + subtitle via **l10n** from Story 1.4). Tapping tabs switches branch without losing state (`IndexedStack` / `StatefulShellRoute` pattern).

2. **Stack routes (stubs)** — Given the router is inspected, then **full-screen** routes exist for future **capture → review → confirm** (placeholder `Scaffold` + `AppBar` + “TODO Epic 3” or equivalent), registered on a **root** navigator so they **cover** the bottom bar.

3. **Onboarding redirect** — Given **zero** rows in `facilities`, when the app starts or facilities become empty, then navigation **redirects** to **`/onboarding`** (placeholder: short copy that a facility must be added; CTA may be disabled until Epic 2). Given **≥1** facility, landing is **not** stuck on onboarding. Redirect **re-runs** when facilities change (use `refreshListenable` / stream → `GoRouterRefreshStream` / `ChangeNotifier` — do not one-shot async redirect without refresh).

4. **Predictive back** — Given Android 14+ predictive back, then `AndroidManifest` sets `android:enableOnBackInvokedCallback="true"` where appropriate and router/stack behavior does not trap back navigation on stub screens (smoke test on emulator).

5. **`PrijavkoScaffold`** — Given `shared/widgets/`, then **`PrijavkoScaffold`** documents/wraps shell layout expectations (body + navigation slot — align with `StatefulNavigationShell`).

6. **`ConnectivityBanner`** — Given connectivity changes, when the device is offline, then a **non-blocking** banner (e.g. `MaterialBanner` or slim top banner) shows offline state using **`connectivity_plus`**; hides when online.

7. **Responsive foundation** — Shell bodies use **`SafeArea`**, scroll where needed, **horizontal padding increases** for width **> 600** logical px; no fixed tiny heights that clip large text / long Croatian strings.

8. **`MaterialApp.router`** — Replace plain `MaterialApp` with **`MaterialApp.router`**: `routerConfig` from `app_router.dart`, preserve **theme** (1.3) + **l10n** (1.4).

9. **Tests** — Widget tests with **`ProviderScope`** + in-memory `AppDatabase.forTesting`: **0** facilities → onboarding route; **1** facility → shell + tab switch works. Do not open multiple DB instances per isolate. [Source: Story 1.2]

## Tasks / Subtasks

- [ ] Implement `lib/core/router/app_router.dart` + `GoRouter` provider/factory. (AC: #1–3, #8)
- [ ] Add placeholder screens under `features/home|queue|history|settings|onboarding/...`. (AC: #1, #3)
- [ ] Add stack placeholder routes for capture/review/confirm. (AC: #2)
- [ ] Wire `facilitiesExist` / `watchAllFacilities` refresh for redirect (thin provider in `data/` or `core` per layering). (AC: #3)
- [ ] Add `PrijavkoScaffold`, `ConnectivityBanner`. (AC: #5–6)
- [ ] Apply responsive padding helper or `LayoutBuilder` pattern on shell bodies. (AC: #7)
- [ ] Manifest + back smoke. (AC: #4)
- [ ] Widget tests for redirect + tabs. (AC: #9)

## Dev Notes

### Scope

- **In:** Router, shell, guards, shared widgets, connectivity, responsive shell, tests.
- **Out:** Real onboarding UX (Epic 2), real feature UIs, Queue tab **Badge** (Epic 4).

### Depends on

- **1.3** (theme), **1.4** (l10n) — merge in `MaterialApp.router`.

### References

- `_bmad-output/planning-artifacts/architecture.md` — Navigation, shell + stack
- `_bmad-output/implementation-artifacts/1-2-core-domain-models-database-schema-code-generation.md` — `AppDatabase.forTesting`

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### Key implementation files (behavior map)

### File List

## Story Completion Status

**backlog**
