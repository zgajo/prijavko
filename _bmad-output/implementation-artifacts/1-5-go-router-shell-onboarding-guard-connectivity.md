# Story 1.5: go_router Shell, Onboarding Guard, Scaffold & Connectivity

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **host**,
I want **bottom navigation, onboarding entry when no facility exists, and offline awareness**,
so that **I can move around the app and later features plug into fixed routes**.

## Acceptance Criteria

1. **Shell + tabs (facility exists)** — Given **at least one** row exists in the `facilities` Drift table, when the app launches, then a **shell route** shows a bottom `NavigationBar` with **Home, Queue, History, Settings** (placeholder bodies only), labels from **`context.l10n`** (`tabHome`, `tabQueue`, `tabHistory`, `tabSettings`). Selected tab updates the visible branch; use a **stateful shell** pattern so tab state is preserved (e.g. `StatefulShellRoute` + indexed stack — see Dev Notes).

2. **Router module** — Given `go_router` is configured, when inspecting `lib/core/router/app_router.dart` (and any small helpers in the same folder), then:
   - **Stack routes** exist as **named stubs** for the future full-screen capture flow (e.g. `/capture`, `/review`, `/confirm` — paths/names documented in file). They can render a minimal `Scaffold` + title until Epic 3.
   - A **redirect guard**: if **no** facility rows exist, user is sent to **`/onboarding`** (or equivalent); when at least one facility exists, shell routes are reachable.
   - **Redirect must re-run when `facilities` changes** — implement `GoRouter(refreshListenable: …)` (or equivalent) backed by a `Listenable` that notifies whenever `AppDatabase.facilitiesDao.watchAllFacilities()` emits (so after Epic 2 adds a facility, navigation updates without restart).

3. **Predictive back (Android 14+)** — Given the app targets modern Android, when building for release, then **predictive back** is enabled: set `android:enableOnBackInvokedCallback="true"` on the main `<activity>` in `AndroidManifest.xml` **and** ensure router/back behavior does not swallow required pops (follow [Flutter predictive back](https://docs.flutter.dev/release/breaking-changes/android-predictive-back) guidance; `go_router` integrates when manifest flag is set).

4. **Shared widgets** — Given `shared/widgets/`, then **`PrijavkoScaffold`** wraps shell content consistently (app bar optional per screen; respects theme from Story 1.3). **`ConnectivityBanner`** uses **`connectivity_plus`** (already in `pubspec.yaml`) and shows an offline (or “no connection”) affordance when not connected; place banner in a way that does not break `SafeArea` (e.g. below status bar / above body — exact UX left minimal but visible in widget tests).

5. **Connectivity provider** — Architecture gap closure: add a **`connectivityProvider`** (or similarly named Riverpod provider) in **`lib/core/`** (not inside a feature) exposing connection status for `ConnectivityBanner` and future send-gating (Epic 5). Use **`StreamProvider` / `Stream` from `Connectivity().onConnectivityChanged`** (or current `connectivity_plus` API) — document disposal if needed.

6. **MaterialApp.router** — Given Stories 1.3–1.4 are complete, when replacing `MaterialApp`, then **`MaterialApp.router`** preserves **theme** (`buildLightTheme` / `buildDarkTheme`), **l10n** (same delegates, `supportedLocales`, **`localeResolutionCallback`** / policy as today), and passes **`routerConfig`** from the app’s `GoRouter` instance (see Dev Notes for `ProviderScope` / `ConsumerWidget` wiring).

7. **Responsive baseline** — Given varying widths and text scale, when running the shell, then layouts use **`SafeArea`**, avoid **clipped** `AppBar` titles at large text scale, and for **wide layouts (>600dp logical width)** apply **horizontal padding** (e.g. `Center` + `ConstrainedBox` or `Padding`) so content does not stick to edges.

8. **Tests** — Add automated tests that fail if routing or connectivity wiring regresses:
   - **Router / redirect:** Using `ProviderScope` + **`appDatabaseProvider` override** with `AppDatabase.forTesting` (see `test/data/database/drift_dao_test.dart`), assert: **empty DB** → onboarding route is shown; **after inserting one facility** → shell / first tab is reachable (exact matcher may use `router.routerDelegate` or `tester` + `pumpWidget` with `MaterialApp.router`).
   - **Connectivity:** at least one test that **`ConnectivityBanner`** reflects a mocked/offlined stream state (override connectivity provider if you expose one for testing).

## Tasks / Subtasks

- [x] Add **`lib/core/router/app_router.dart`**: `GoRouter` with `redirect`, `refreshListenable` tied to **`facilitiesDao.watchAllFacilities()`**, `ShellRoute` / **`StatefulShellRoute`** for four tabs, stub stack routes for capture/review/confirm. Export a **`Provider<GoRouter>`** (or construct router inside `ConsumerWidget` with `ref.watch`) — document chosen pattern in file header. (AC: #2, #6)

- [x] Add **`GoRouterRefreshStream`** (or equivalent) in `core/router/`: `ChangeNotifier` + `StreamSubscription` with **dispose**, wrapping facility watch stream — **must** call `notifyListeners()` on each emission. (AC: #2)

- [x] Add placeholder screens: **`features/onboarding/presentation/screens/onboarding_screen.dart`** (minimal body + l10n; add **new ARB keys** if needed, e.g. short headline for “set up facility” — do not hardcode Croatian in Dart). Tab placeholders under **`features/`** subfolders per architecture (`queue`, `history`, `settings`, home can live under `facility` or a small `home` placeholder — prefer matching architecture tree). (AC: #1)

- [x] Implement **`shared/widgets/prijavko_scaffold.dart`** and **`shared/widgets/connectivity_banner.dart`**; wire banner via **`connectivityProvider`**. (AC: #4, #5)

- [x] Add **`lib/core/...`** file for **`connectivityProvider`** (`connectivity_plus`). (AC: #5)

- [x] Update **`lib/app.dart`**: switch to **`MaterialApp.router`**, keep l10n + theme + `onGenerateTitle` pattern from Story 1.4. (AC: #6)

- [x] Update **`android/app/src/main/AndroidManifest.xml`**: `android:enableOnBackInvokedCallback="true"` on `MainActivity`. (AC: #3)

- [x] Add **`test/core/router/`** (and/or **`test/shared/widgets/`**) tests per AC #8. (AC: #8)

- [x] Run **`flutter analyze`** / **`flutter test`** — zero analyzer warnings, all tests green.

## Dev Notes

### Scope

- **In:** `go_router` shell, onboarding **redirect**, placeholder tab + onboarding + stack stub screens, `PrijavkoScaffold`, `ConnectivityBanner` + core provider, `MaterialApp.router`, manifest predictive back, tests.
- **Out:** Real facility CRUD / full onboarding UX — **Epic 2**. **Out:** Real capture/review UI — **Epic 3**. Until 2.1 ships, **empty `facilities` table** keeps the user on the onboarding placeholder (expected).

### Architecture compliance

- **Router:** `lib/core/router/app_router.dart` — route guards, shell route [Source: `_bmad-output/planning-artifacts/architecture.md` — Complete Project Directory Structure].
- **Scaffold / banner:** `lib/shared/widgets/prijavko_scaffold.dart`, `connectivity_banner.dart` [Source: same — `shared/widgets/`].
- **Onboarding screen path:** `features/onboarding/presentation/screens/onboarding_screen.dart` [Source: same].
- **Navigation rules:** Shell = tabs; stack = camera → review → confirm [Source: `_bmad-output/project-context.md` — Navigation (go_router)].

### Technical requirements (guardrails)

| Topic | Requirement |
|-------|-------------|
| **DB for guard** | Use existing **`AppDatabase`** via **`appDatabaseProvider`** (`lib/data/database/app_database_provider.dart`). Redirect logic: `watchAllFacilities()` **empty** → onboarding. |
| **Riverpod** | Project uses **hand-written** `Provider` / `StreamProvider` (see `pubspec.yaml` — `riverpod_generator` omitted). Do **not** introduce generator annotations unless you also resolve version pins. |
| **L10n** | All user-visible strings via **`context.l10n`** / ARB; add keys to **`app_hr.arb`** (template) + **`app_en.arb`**. |
| **Import boundaries** | Router **`core/`** may depend on **`data/`** for DB access; **features** must not import other features [Source: `project-context.md`]. |
| **CI** | `flutter analyze` clean; `flutter test` green. |

### Library / framework

| Package | Role |
|---------|------|
| `go_router: ^17.2.1` (pubspec) | Declarative routes, `ShellRoute` / `StatefulShellRoute`, `redirect`, `refreshListenable`. |
| `connectivity_plus: ^7.1.1` | `ConnectivityBanner` + `connectivityProvider`. |
| `flutter_riverpod` | `ProviderScope` already in `main.dart`; expose `GoRouter` via provider or `ConsumerWidget`. |

### File structure (expected touch list)

| Path | Action |
|------|--------|
| `prijavko/lib/core/router/app_router.dart` | **New** — `GoRouter` + exports |
| `prijavko/lib/core/router/go_router_refresh_stream.dart` | **New** (name flexible) — `Listenable` + stream |
| `prijavko/lib/core/connectivity/connectivity_provider.dart` | **New** — `connectivityProvider` |
| `prijavko/lib/shared/widgets/prijavko_scaffold.dart` | **New** |
| `prijavko/lib/shared/widgets/connectivity_banner.dart` | **New** |
| `prijavko/lib/features/onboarding/presentation/screens/onboarding_screen.dart` | **New** |
| Tab placeholder screens | **New** under `features/*/presentation/screens/` (minimal) |
| `prijavko/lib/app.dart` | **Edit** — `MaterialApp.router` |
| `prijavko/assets/l10n/app_hr.arb` / `app_en.arb` | **Edit** — onboarding / offline strings if needed |
| `prijavko/android/.../AndroidManifest.xml` | **Edit** — predictive back flag |
| `prijavko/test/core/router/*.dart` | **New** — redirect tests |

### Testing requirements

- Mirror source layout: `test/core/router/...`, `test/shared/widgets/...` [Source: `project-context.md` — Test Organization].
- Use **`AppDatabase.forTesting`** + **`ProviderScope`** overrides — same pattern as `drift_dao_test.dart`.
- Prefer **pumpWidget** with **`MaterialApp.router(routerConfig: ...)`** and overridden `appDatabaseProvider` over testing implementation details of `GoRouter` internals unless necessary.

### Previous story intelligence (Story 1.4)

- **`PrijavkoApp`** uses **`localeResolutionCallback`** (`_resolveAppLocale`) — **preserve** when switching to `MaterialApp.router`.
- **`onGenerateTitle`** + **`context.l10n.appTitle`** — keep behavior.
- Tab label keys **`tabHome` / `tabQueue` / `tabHistory` / `tabSettings`** already exist in ARB — shell should bind **NavigationBar** destinations to these.
- Generated l10n: `lib/core/l10n/app_localizations*.dart`, extension **`context.l10n`** in `context_l10n.dart`.

### Project context reference

- [Source: `_bmad-output/project-context.md`] — Croatian UI via ARB; no hardcoded Croatian; `go_router` shell + stack; route guard if no facility.

### References

- `_bmad-output/planning-artifacts/epics.md` — Story 1.5 (lines ~366–395)
- `_bmad-output/planning-artifacts/architecture.md` — Navigation (`go_router`), directory layout, connectivity gap (`connectivityProvider` in `core/`)
- [Flutter — Internationalization](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization)
- [Flutter — Predictive back](https://docs.flutter.dev/release/breaking-changes/android-predictive-back)

### Latest tech notes (2026)

- **go_router 17.x:** Use **`StatefulShellRoute.indexedStack`** (or branches API) for bottom navigation so each tab keeps its own navigator stack [verify against current package docs].
- **`refreshListenable`:** Required so **`redirect`** runs again when Drift facility list changes — without it, users stay on onboarding after first facility insert.
- **`connectivity_plus`:** Prefer listening to **`onConnectivityChanged`**; map `ConnectivityResult.none` to offline banner.

## Dev Agent Record

### Agent Model Used

Cursor Agent (dev-story workflow)

### Debug Log References

_(none)_

### Completion Notes List

- Implemented `appRouterProvider` + `facilitiesRouteRefreshProvider` (`FacilitiesRouteRefreshNotifier` in `go_router_refresh_stream.dart`) so `GoRouter.redirect` re-runs when `watchAllFacilities()` emits (Epic 2 insert path).
- Shell: `StatefulShellRoute.indexedStack` + `MainNavigationShell` (Material 3 `NavigationBar`, l10n tab labels, `ConnectivityBanner` under `SafeArea`).
- Stack stubs `/capture`, `/review`, `/confirm` with route names; full-screen via `parentNavigatorKey: rootNavigatorKey`.
- Widget tests: `DatabaseConnection(..., closeStreamsSynchronously: true)` + `await db.close()` after unmount per Drift stream-query timer guidance; mock `connectivityProvider` in shell tests to avoid `MissingPluginException`.

### Key implementation files (behavior map)

- `prijavko/lib/core/router/app_router.dart` — `GoRouter`, redirects, tab shell, stack stubs, `appRouterProvider`
- `prijavko/lib/core/router/go_router_refresh_stream.dart` — Drift watch → `refreshListenable`
- `prijavko/lib/core/router/main_shell.dart` — bottom nav + banner layout
- `prijavko/lib/core/connectivity/connectivity_provider.dart` — `connectivityProvider`
- `prijavko/lib/shared/widgets/connectivity_banner.dart` — offline strip
- `prijavko/lib/shared/widgets/prijavko_scaffold.dart` — responsive tab/page chrome
- `prijavko/lib/app.dart` — `MaterialApp.router` + `ConsumerWidget`

### File List

- `prijavko/lib/core/router/app_router.dart` (new)
- `prijavko/lib/core/router/go_router_refresh_stream.dart` (new)
- `prijavko/lib/core/router/main_shell.dart` (new)
- `prijavko/lib/core/router/stack_route_stubs.dart` (new)
- `prijavko/lib/core/connectivity/connectivity_provider.dart` (new)
- `prijavko/lib/shared/widgets/prijavko_scaffold.dart` (new)
- `prijavko/lib/shared/widgets/connectivity_banner.dart` (new)
- `prijavko/lib/features/onboarding/presentation/screens/onboarding_screen.dart` (new)
- `prijavko/lib/features/home/presentation/screens/home_screen.dart` (new)
- `prijavko/lib/features/queue/presentation/screens/queue_screen.dart` (new)
- `prijavko/lib/features/history/presentation/screens/history_screen.dart` (new)
- `prijavko/lib/features/settings/presentation/screens/settings_screen.dart` (new)
- `prijavko/lib/app.dart` (modified)
- `prijavko/assets/l10n/app_hr.arb` (modified)
- `prijavko/assets/l10n/app_en.arb` (modified)
- `prijavko/lib/core/l10n/app_localizations*.dart` (generated)
- `prijavko/android/app/src/main/AndroidManifest.xml` (modified)
- `prijavko/test/core/router/app_router_test.dart` (new)
- `prijavko/test/shared/widgets/connectivity_banner_test.dart` (new)
- `prijavko/test/widget_test.dart` (modified)

### Change Log

- 2026-04-14 — Story 1.5: go_router shell, onboarding redirect + refreshListenable, connectivity provider/banner, MaterialApp.router, predictive back manifest, tests.
- 2026-04-14 — Code review patches: facility watch `onError`; `ConnectivityBanner` fail-safe on `AsyncValue.error`.

### Review Findings

- [x] [Review][Patch] Drift facility watch stream has no `onError` — if `watchAllFacilities()` errors, the error may surface as an uncaught async error instead of a defined router/refresh fallback. [`prijavko/lib/core/router/go_router_refresh_stream.dart:15`] — fixed: `listen(..., onError: ...)` reports via `FlutterError.reportError`; last known rows retained.

- [x] [Review][Patch] `ConnectivityBanner` maps `AsyncValue.error` to `SizedBox.shrink()` — on plugin failure the user gets no offline signal (same as “online”), which weakens AC4’s “offline affordance” under fault conditions. [`prijavko/lib/shared/widgets/connectivity_banner.dart:47`] — fixed: error branch shows same offline strip as “no connection” (fail-safe); widget test uses `overrideWithValue(AsyncError)`.

- [x] [Review][Defer] `widget_test.dart` and `app_router_test.dart` both assert empty DB → onboarding — redundant coverage; consolidate when touching tests. [`prijavko/test/widget_test.dart`, `prijavko/test/core/router/app_router_test.dart`] — deferred, low risk

- [x] [Review][Defer] `dispose` uses `unawaited(_subscription.cancel())` — acceptable for many apps; revisit if strict teardown ordering is required for tests or hot restart edge cases. [`prijavko/lib/core/router/go_router_refresh_stream.dart:31`] — deferred

- [x] [Review][Defer] Large `_bmad-output/planning-artifacts/prd.md` edits bundled with app code — prefer separate commits for planning vs implementation traceability. — deferred, process

## Story Completion Status

**done** — Implementation complete; code review patches applied; `dart analyze` clean; `flutter test` green (2026-04-14).
