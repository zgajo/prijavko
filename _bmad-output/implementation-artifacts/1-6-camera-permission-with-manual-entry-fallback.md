# Story 1.6: Camera Permission with Manual-Entry Fallback

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a host,
I want to grant or deny camera access with a clear explanation of why it's needed,
so that if I deny it the app still works — manual entry remains fully functional.

## Acceptance Criteria

### AC1 — Add `permission_handler` dependency

1. Add **`permission_handler: ^12.0.1`** (verify latest stable on pub.dev at install time) to `dependencies`. Annotate: `# Story 1.6 — runtime camera permission request; re-request from Settings in Story 1.9`.
2. **Android manifest**: Add `<uses-permission android:name="android.permission.CAMERA" />` to `android/app/src/main/AndroidManifest.xml` if not already present. The `permission_handler` plugin does NOT auto-add manifest permissions.
3. Run `flutter pub get`. Record exact resolved version in Change Log. Verify no transitive dep conflicts with existing Riverpod 2.6.x / go_router 14.x / Dart SDK 3.10 constraint. If a conflict appears, **stop and ask**.

### AC2 — `CapturePreference` enum and persistence

1. Create **`lib/core/capture/capture_preference.dart`**:
   ```dart
   enum CapturePreference { live, manualOnly }
   ```
   - `live` — user granted camera; downstream capture (Epic 4) defaults to MRZ-first.
   - `manualOnly` — user denied/skipped camera; downstream capture surfaces manual entry as primary path.

2. Create **`lib/core/capture/capture_preference_store.dart`**:
   - Uses `SharedPreferences` (lightweight, non-sensitive data — camera preference is not PII, not a credential).
   - **WHY not flutter_secure_storage**: Capture preference is a UX convenience flag, not a secret. Storing it in Keystore-backed storage is Muri (overburden) — unnecessarily slow init path and platform-channel complexity for a boolean-equivalent value.
   - **WHY SharedPreferences**: Already available transitively; `shared_preferences` is a Flutter-team-maintained first-party plugin. If not in `pubspec.yaml` yet, add it with annotation.
   - Key: `'prijavko_capture_preference_v1'` (versioned per `CredentialStore` pattern).
   - Methods:
     ```dart
     Future<void> save(CapturePreference preference)
     Future<CapturePreference> load() // defaults to CapturePreference.manualOnly if unset
     ```
   - Default to `manualOnly` if no preference is stored — safe fallback that never requires camera.

3. Create a `@riverpod` provider for `CapturePreferenceStore` in the same file or in a dedicated providers file under `lib/core/capture/`.

### AC3 — `PermissionService` abstraction (testability seam)

1. Create **`lib/core/permissions/permission_service.dart`**:
   ```dart
   abstract class PermissionService {
     Future<bool> requestCamera();
     Future<bool> isCameraGranted();
     Future<bool> isCameraPermanentlyDenied();
     Future<void> openSettings();
   }
   ```
   - **WHY interface**: `permission_handler` uses static methods and platform channels. Direct calls in widgets make unit/widget tests impossible without a real Android device. The interface seam follows the `ConsentService` / `SecurityService` pattern from Stories 1.3–1.4.

2. Create **`lib/core/permissions/permission_service_impl.dart`**:
   ```dart
   class PermissionServiceImpl implements PermissionService {
     @override
     Future<bool> requestCamera() async {
       final status = await Permission.camera.request();
       return status.isGranted;
     }

     @override
     Future<bool> isCameraGranted() async {
       return await Permission.camera.isGranted;
     }

     @override
     Future<bool> isCameraPermanentlyDenied() async {
       return await Permission.camera.isPermanentlyDenied;
     }

     @override
     Future<void> openSettings() async {
       await openAppSettings();
     }
   }
   ```

3. Create a `@riverpod` provider: `permissionServiceProvider` returning `PermissionServiceImpl()`. Tests override with `FakePermissionService`.

### AC4 — `CameraPermissionScreen` widget

1. Create **`lib/features/onboarding/camera_permission_screen.dart`** as a `ConsumerStatefulWidget`.
   - **WHY `ConsumerStatefulWidget` not `ConsumerWidget`**: The "Dopusti pristup" button handler calls `await requestCamera()` which shows the OS permission dialog — an async gap during which the user can rotate, switch apps, or trigger navigation. `State.mounted` is the robust guard for this. While `BuildContext.mounted` exists in Flutter 3.7+, `ConsumerStatefulWidget` makes the lifecycle explicit and matches the `WelcomeScreen` pattern for onboarding screens.
2. **Layout** (following UX spec §Standard screen skeleton + WelcomeScreen pattern):
   ```
   Scaffold (no AppBar — full-screen onboarding, same as WelcomeScreen)
   └── SafeArea
       └── Column
           ├── Expanded (scrollable content area)
           │   └── SingleChildScrollView
           │       └── Padding (horizontal: TokensSpace.s16)
           │           ├── SizedBox(height: TokensSpace.s64)  ← emotional top margin
           │           ├── Icon(Symbols.photo_camera_rounded, size: 64)
           │           ├── SizedBox(height: TokensSpace.s24)
           │           ├── Text(headline, style: displayMedium) ← "Pristup kameri"
           │           ├── SizedBox(height: TokensSpace.s16)
           │           ├── Text(rationale, style: bodyLarge)    ← MRZ scanning rationale
           │           └── SizedBox(height: TokensSpace.s32)
           └── Padding (TokensSpace.s16 all sides + bottom: TokensSpace.s24 gesture inset)
               └── Column
                   ├── FilledButton (full-width, "Dopusti pristup")   ← primary CTA
                   ├── SizedBox(height: TokensSpace.s12)
                   └── OutlinedButton (full-width, "Preskoči — ručni unos") ← secondary CTA
   ```
3. **Icon**: `Symbols.photo_camera_rounded` at 64dp, colored with `colorScheme.primary`. Centered above the headline. Provides visual context for camera permission — per UX spec "icons leading" pattern.
4. **Headline**: `AppLocalizations.of(context).cameraPermissionHeadline`, style `theme.textTheme.displayMedium` (same as WelcomeScreen — onboarding heading).
5. **Rationale body**: `AppLocalizations.of(context).cameraPermissionBody`, style `theme.textTheme.bodyLarge`. Croatian copy: "Kamera je potrebna za skeniranje MRZ koda s putovnica. Slike se ne pohranjuju ni ne šalju — obrada je potpuno na uređaju."
6. **Primary CTA — "Dopusti pristup"**: `FilledButton`, 56dp min-height (`TokensSize.buttonMinHeight`), full-width. `onPressed`:
   - Calls `ref.read(permissionServiceProvider).requestCamera()`.
   - On grant: saves `CapturePreference.live` via `CapturePreferenceStore`, then `context.go('/onboarding/login')` (Story 1.7 placeholder).
   - On deny: saves `CapturePreference.manualOnly`, then `context.go('/onboarding/login')`.
   - **Important**: `await` the permission request, then check `mounted` before navigating (per architecture §BuildContext across async gaps).
7. **Secondary CTA — "Preskoči — ručni unos"**: `OutlinedButton`, 48dp min-height (`TokensSize.outlinedButtonMinHeight`), full-width. `onPressed`:
   - Skips the OS permission dialog entirely.
   - Saves `CapturePreference.manualOnly` via `CapturePreferenceStore`.
   - `context.go('/onboarding/login')`.
8. **No AppBar**: Same reasoning as WelcomeScreen — full-screen onboarding, nothing before it (Welcome is behind, `context.go` replaced it).
9. **No ads**: Per UX spec §Ad Placement — "Welcome / onboarding: No." Camera permission is part of onboarding.
10. **All text from `AppLocalizations`**: Zero literal Croatian/English strings in `build()`.
11. **Dark mode primary**: Build and verify dark first. Colors from `Theme.of(context).colorScheme`.
12. **WCAG 2.1 AA**: 48×48dp touch targets (both buttons meet this). Body text ≥ 4.5:1, large text ≥ 3:1. M3 seed-based schemes meet AA.
13. **Semantics**: Icon has `Semantics(label:)`, buttons have accessible labels from text content (automatic for `FilledButton`/`OutlinedButton` with `Text` children).

### AC5 — Router updates

1. In `lib/app/router.dart`, replace the `TODO(story-1.6)` placeholder with the real `CameraPermissionScreen`:
   ```dart
   GoRoute(
     path: 'camera-permission',
     name: 'camera-permission',
     builder: (context, state) => const CameraPermissionScreen(),
   ),
   ```
2. Add a new child route under `/onboarding` for the login screen (Story 1.7 placeholder):
   ```dart
   GoRoute(
     path: 'login',
     name: 'login',
     // TODO(story-1.7): replace placeholder with LoginScreen
     // i18n-ignore: placeholder scaffold; replaced in Story 1.7
     builder: (context, state) => const Scaffold(
       body: Center(child: Text('Login — Story 1.7')),
     ),
   ),
   ```
3. Remove the `TODO(story-1.6)` and `i18n-ignore` comments from the camera-permission route.

### AC6 — l10n strings

1. Add to **`lib/l10n/app_en.arb`**:
   ```json
   "cameraPermissionHeadline": "Camera Access",
   "@cameraPermissionHeadline": { "description": "Camera permission screen headline" },
   "cameraPermissionBody": "The camera is needed to scan passport MRZ codes. Photos are never stored or sent — processing is entirely on-device.",
   "@cameraPermissionBody": { "description": "Camera permission rationale explaining why camera is needed and privacy assurance" },
   "cameraPermissionAllowButton": "Allow access",
   "@cameraPermissionAllowButton": { "description": "Primary CTA requesting camera permission from the OS" },
   "cameraPermissionSkipButton": "Skip — manual entry",
   "@cameraPermissionSkipButton": { "description": "Secondary CTA skipping camera permission and using manual entry path" }
   ```

2. Add to **`lib/l10n/app_hr.arb`**:
   ```json
   "cameraPermissionHeadline": "Pristup kameri",
   "cameraPermissionBody": "Kamera je potrebna za skeniranje MRZ koda s putovnica. Slike se ne pohranjuju ni ne šalju — obrada je potpuno na uređaju.",
   "cameraPermissionAllowButton": "Dopusti pristup",
   "cameraPermissionSkipButton": "Preskoči — ručni unos"
   ```

3. Run `flutter gen-l10n`. Verify all new getters appear on `AppLocalizations`.
4. Full diacritics (č/ć/š/ž/đ). No ASCII approximation per UX-DR24.

### AC7 — Tests

1. **`test/fakes/fake_permission_service.dart`**:
   - `FakePermissionService implements PermissionService` with scripted return values.
   - Constructor takes `bool grantCamera`, `bool permanentlyDenied`.
   - `requestCamera()` returns the scripted `grantCamera` value.
   - `isCameraGranted()` returns `grantCamera`.
   - `isCameraPermanentlyDenied()` returns `permanentlyDenied`.
   - `openSettings()` is a no-op.
   - Tracks whether `requestCamera()` was called (for assertion in "skip" test).

2. **`test/fakes/fake_capture_preference_store.dart`**:
   - In-memory implementation. `save()` stores the value, `load()` returns it.
   - Allows asserting on what value was saved after a user action.

3. **`test/widget/features/onboarding/camera_permission_screen_test.dart`**:
   - Helper function pattern matching `welcome_screen_test.dart`: `_makeTestApp()` creating a `GoRouter` + `MaterialApp.router` with provider overrides for `permissionServiceProvider` and `capturePreferenceStoreProvider`.
   - **Test: headline renders in Croatian** — `find.text('Pristup kameri')`.
   - **Test: rationale body renders** — `find.textContaining('skeniranje MRZ koda')`.
   - **Test: Allow button renders as FilledButton** — `find.text('Dopusti pristup')`, `find.byType(FilledButton)`.
   - **Test: Skip button renders as OutlinedButton** — `find.text('Preskoči — ručni unos')`, `find.byType(OutlinedButton)`.
   - **Test: tapping Allow triggers permission request and navigates to login** — fake grants permission, tap "Dopusti pristup", `pumpAndSettle()`, verify login stub is visible and `CapturePreference.live` was saved.
   - **Test: tapping Allow when permission denied still navigates to login** — fake denies permission, tap "Dopusti pristup", verify `CapturePreference.manualOnly` saved and login stub visible.
   - **Test: tapping Skip does NOT trigger permission request and navigates to login** — tap "Preskoči", verify `requestCamera` was NOT called, `CapturePreference.manualOnly` saved, login stub visible.
   - **Test: camera icon renders** — `find.byIcon(Symbols.photo_camera_rounded)`.
   - **Test: no AppBar** — `find.byType(AppBar)` findsNothing.
   - **Test: dark theme pumps without errors** — pump with dark theme, no `ErrorWidget`.
   - **Test: light theme pumps without errors** — pump with light theme, no `ErrorWidget`.
   - Guards AC4.

4. **`test/unit/core/capture/capture_preference_store_test.dart`**:
   - Test: default load returns `manualOnly`.
   - Test: save `live` then load returns `live`.
   - Test: save `manualOnly` then load returns `manualOnly`.

5. **Golden tests**:
   - Add `matchesGoldenFile('goldens/camera_permission_dark.png')` and `matchesGoldenFile('goldens/camera_permission_light.png')`.
   - Run `flutter test --update-goldens` to generate baselines.
   - Commit golden files to `test/widget/features/onboarding/goldens/`.

6. **Update existing tests**:
   - `test/widget/features/onboarding/welcome_screen_test.dart` — update the camera-permission stub route text if needed (currently `'camera-permission-stub'`). The navigation test asserts on this text; if the real screen replaces the stub in the router, the welcome_screen_test still uses its own test router and is unaffected.
   - `test/app_smoke_test.dart` — may need `permissionServiceProvider` override if the app flow now hits the permission screen. Verify and update.
   - `integration_test/app_test.dart` — same verification.

### AC8 — Validation gate

1. `flutter test` — all tests green.
2. `dart analyze --fatal-warnings --fatal-infos` — clean.
3. `dart format --set-exit-if-changed lib test integration_test` — clean.
4. PII grep guard: camera permission screen files have no PII references. The screen displays only static rationale text — no guest data, no MRZ, no credentials.
5. i18n literal-string guard: `grep -rn '"[A-Z][a-zšđčćž]' lib/features/onboarding/camera_permission_screen.dart` returns empty.
6. Icons guard: no `Icons.*` usage. Camera icon uses `Symbols.photo_camera_rounded` per design system.

---

## Tasks / Subtasks

- [x] Task 1 — Add `permission_handler` dependency and Android manifest permission (AC: #1)
  - [x] Subtask 1.1 — Add `permission_handler: ^12.0.1` to `pubspec.yaml` with annotated comment.
  - [x] Subtask 1.2 — Add `shared_preferences` to `pubspec.yaml` if not present (for `CapturePreferenceStore`).
  - [x] Subtask 1.3 — Add `<uses-permission android:name="android.permission.CAMERA" />` to `AndroidManifest.xml`. (already present from Story 1.1 AC4.2)
  - [x] Subtask 1.4 — `flutter pub get`. Record exact resolved versions. Verify no transitive conflicts.

- [x] Task 2 — `CapturePreference` enum and `CapturePreferenceStore` (AC: #2)
  - [x] Subtask 2.1 — Create `lib/core/capture/capture_preference.dart` with `CapturePreference` enum.
  - [x] Subtask 2.2 — Create `lib/core/capture/capture_preference_store.dart` with `SharedPreferences`-backed persistence.
  - [x] Subtask 2.3 — Create `@riverpod` provider for `CapturePreferenceStore`.
  - [x] Subtask 2.4 — Run `dart run build_runner build --delete-conflicting-outputs`. Commit generated `.g.dart`.

- [x] Task 3 — `PermissionService` abstraction and implementation (AC: #3)
  - [x] Subtask 3.1 — Create `lib/core/permissions/permission_service.dart` (abstract interface).
  - [x] Subtask 3.2 — Create `lib/core/permissions/permission_service_impl.dart` (production implementation using `permission_handler`).
  - [x] Subtask 3.3 — Create `@riverpod` provider for `permissionServiceProvider`.
  - [x] Subtask 3.4 — Run `dart run build_runner build --delete-conflicting-outputs`. Commit generated `.g.dart`.

- [x] Task 4 — l10n strings (AC: #6)
  - [x] Subtask 4.1 — Add 4 camera-permission keys to `app_en.arb`.
  - [x] Subtask 4.2 — Add 4 camera-permission values to `app_hr.arb`. Full diacritics.
  - [x] Subtask 4.3 — Run `flutter gen-l10n`. Verify generated getters.

- [x] Task 5 — `CameraPermissionScreen` widget (AC: #4)
  - [x] Subtask 5.1 — Create `lib/features/onboarding/camera_permission_screen.dart` as `ConsumerStatefulWidget` with layout per AC4.2.
  - [x] Subtask 5.2 — Wire headline, rationale, camera icon — all text from `AppLocalizations`.
  - [x] Subtask 5.3 — Wire "Dopusti pristup" `FilledButton`: call `requestCamera()`, save preference, navigate to login.
  - [x] Subtask 5.4 — Wire "Preskoči — ručni unos" `OutlinedButton`: save `manualOnly`, navigate to login.
  - [x] Subtask 5.5 — Check `mounted` after async `requestCamera()` before calling `context.go()`.

- [x] Task 6 — Router updates (AC: #5)
  - [x] Subtask 6.1 — Replace placeholder with `CameraPermissionScreen` in `router.dart`.
  - [x] Subtask 6.2 — Add `/onboarding/login` placeholder route for Story 1.7.
  - [x] Subtask 6.3 — Remove `TODO(story-1.6)` and `i18n-ignore` comments.

- [x] Task 7 — Tests (AC: #7)
  - [x] Subtask 7.1 — Create `test/fakes/fake_permission_service.dart`.
  - [x] Subtask 7.2 — Create `test/fakes/fake_capture_preference_store.dart`.
  - [x] Subtask 7.3 — Create `test/widget/features/onboarding/camera_permission_screen_test.dart` per AC7.3.
  - [x] Subtask 7.4 — Create `test/unit/core/capture/capture_preference_store_test.dart` per AC7.4.
  - [x] Subtask 7.5 — Add golden tests for dark + light (generate baselines with `--update-goldens`).
  - [x] Subtask 7.6 — Update `app_smoke_test.dart` and `integration_test/app_test.dart` if needed. (smoke test verified green; integration_test unaffected)
  - [x] Subtask 7.7 — Run all tests and verify green.

- [x] Task 8 — Validation gate (AC: #8)
  - [x] Subtask 8.1 — `flutter test` — all tests green. (74 tests)
  - [x] Subtask 8.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [x] Subtask 8.3 — `dart format --set-exit-if-changed lib test integration_test` — clean.
  - [x] Subtask 8.4 — i18n literal-string guard on `lib/features/onboarding/camera_permission_screen.dart`. (clean)
  - [x] Subtask 8.5 — PII grep guard on `lib/features/onboarding/`. (clean)

---

## Dev Notes

### Why this story is sixth

Stories 1.1–1.5 built scaffold, design system, security primitives, UMP consent, and the Welcome/routing/l10n infrastructure. Story 1.6 is the **second user-facing onboarding screen**. It adds one new dependency (`permission_handler`) and introduces two new patterns:
1. **`PermissionService` interface seam** — mirrors the `ConsentService` pattern for testability.
2. **`CapturePreference` persistence** — a lightweight flag consumed downstream by Epic 4's capture pipeline.

The screen itself is intentionally simple (icon + text + two buttons) because the complexity is in the permission lifecycle and downstream flag consumption — not in the UI.

### Architecture mandates (non-negotiable)

- **Feature-based folders**: `lib/features/onboarding/camera_permission_screen.dart` — per architecture §Project Structure. Camera permission is an onboarding step, not a capture step.
- **Core infrastructure in `lib/core/`**: `CapturePreference` enum and `PermissionService` abstraction live in `lib/core/capture/` and `lib/core/permissions/` respectively — they are cross-feature infrastructure consumed by onboarding (Story 1.6), settings (Story 1.9), and capture (Epic 4).
- **`@riverpod` codegen only**: All new providers use `@riverpod` annotation. No manual `Provider(...)` calls.
- **Interface seam for platform channels**: `PermissionService` abstraction prevents direct `permission_handler` calls in widgets. Same pattern as `ConsentService` (Story 1.4) and `SecurityService` (Story 1.3).
- **No cross-feature imports**: `lib/features/onboarding/` imports from `lib/core/` and `lib/design/` only.
- **All UI strings via `AppLocalizations`**: Zero literal strings in `build()`. Croatian primary, English fallback. Full diacritics.
- **Dark mode primary**: Build and verify dark first.
- **`context.go()` not `context.push()`**: Linear onboarding — no back-stack.
- **No ads on onboarding screens**: Per UX spec §Ad Placement and architecture §AdMob Placement Policy.
- **Standard screen skeleton**: SafeArea, 16dp horizontal padding, bottom CTA zone, gesture inset (24dp bottom).
- **48×48dp minimum touch targets**: Both buttons exceed this (56dp and 48dp min-heights).
- **No AppBar on onboarding screens**: Full-screen disclosure/education screens.
- **`mounted` check after async gaps**: Per architecture §BuildContext across async gaps.

### Previous story intelligence (Story 1.5)

- **WelcomeScreen navigates to `/onboarding/camera-permission`** via `context.go()`. Story 1.6 replaces the placeholder at that route with the real `CameraPermissionScreen`.
- **Story 1.5's `ConsumerStatefulWidget` pattern**: Used for `TapGestureRecognizer` lifecycle. Camera permission screen also uses `ConsumerStatefulWidget` — not for recognizers, but for the `mounted` guard after the async `requestCamera()` call. Consistent onboarding screen pattern.
- **Story 1.5's test pattern**: `_makeTestApp()` helper creating isolated `GoRouter` + `MaterialApp.router` with `ProviderScope`, locale `hr`, localization delegates. Reuse this exact pattern for camera permission tests.
- **Story 1.5's golden test pattern**: Ahem font, layout-geometry-only golden comparisons. Same approach for camera permission goldens.
- **l10n import path**: `package:prijavko/l10n/app_localizations.dart` (modern Flutter with `generate: true` outputs to `lib/l10n/`).
- **Codegen workflow**: `dart run build_runner build --delete-conflicting-outputs` after writing `@riverpod`-annotated files. Generated `.g.dart` files are committed.
- **`FakeConsentService` pattern**: Tests override provider with fake. Apply same pattern: `FakePermissionService` overrides `permissionServiceProvider`.
- **Review finding from Story 1.5**: Hard-coded `' & '` connector violated zero-literal-strings. Lesson: verify EVERY string in `build()` comes from `AppLocalizations`.
- **Story 1.5's `go_router` version**: Resolved at 14.8.1 (not 17.x due to Riverpod 2.x constraint). Same version used by this story.

### Token and spacing reference (from `lib/design/tokens.dart`)

| Token | Value | Usage in camera permission screen |
|---|---|---|
| `TokensSpace.s12` | 12dp | Between primary and secondary buttons |
| `TokensSpace.s16` | 16dp | Screen edge padding, gap between headline and rationale |
| `TokensSpace.s24` | 24dp | Between icon and headline, bottom gesture inset |
| `TokensSpace.s32` | 32dp | After rationale before CTA section |
| `TokensSpace.s64` | 64dp | Top margin (emotional spacing per UX spec) |
| `TokensSize.buttonMinHeight` | 56dp | FilledButton min-height |
| `TokensSize.outlinedButtonMinHeight` | 48dp | OutlinedButton min-height |

Typography tokens (from `lib/design/theme.dart`):

| TextTheme slot | Size/Weight/LineHeight | Use |
|---|---|---|
| `displayMedium` | 45/700/52 | Camera permission headline |
| `bodyLarge` | 16/400/24 | Rationale body text |
| `labelLarge` | 14/600/20 | Button text |

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| Call `Permission.camera.request()` directly in the widget | Call via `ref.read(permissionServiceProvider).requestCamera()` — testability seam |
| Store camera preference in `flutter_secure_storage` | Use `SharedPreferences` — it's a UX flag, not a secret |
| Store camera preference in Drift | Drift is for queue/facility data. A simple key-value flag belongs in `SharedPreferences` |
| Use `ConsumerWidget` for this screen | Use `ConsumerStatefulWidget` — async permission request needs `mounted` guard; matches WelcomeScreen onboarding pattern |
| Create the camera-permission screen in `lib/core/` | It goes in `lib/features/onboarding/camera_permission_screen.dart` — it's a feature screen |
| Create `PermissionService` in `lib/features/onboarding/` | It goes in `lib/core/permissions/` — it's cross-feature infrastructure (also used by Settings in Story 1.9) |
| Use `context.push('/onboarding/login')` | Use `context.go()` — linear onboarding, no back-stack |
| Use `Navigator.push` or `Navigator.of(context)` | Use `go_router`'s `context.go()`. Navigator 1.0 API is banned. |
| Navigate without checking `mounted` after async | Always `if (!context.mounted) return;` after `await requestCamera()` |
| Show a rationale dialog before the OS permission dialog | Just show the rationale on the screen itself. The OS handles the actual permission dialog. |
| Add `<uses-permission>` for camera in the wrong manifest | Add to `android/app/src/main/AndroidManifest.xml` (the main manifest, not debug or profile) |
| Use `Icons.camera_alt` | Use `Symbols.photo_camera_rounded` from `lib/design/icons.dart` |
| Hardcode colors for the icon | Use `Theme.of(context).colorScheme.primary` |
| Skip the `mounted` check because "it's fast" | Permission request shows an OS dialog — user can rotate, navigate away, or kill the app during it |
| Re-prompt for camera permission if denied | One request per onboarding flow. Re-request only from Settings (Story 1.9). Respect the user's choice. |
| Put the login screen implementation in this story | Create only the placeholder route with `TODO(story-1.7)`. Story 1.7 implements the real screen. |
| Skip golden tests | Follow Story 1.5 pattern — dark + light golden baselines. |
| Use `permission_handler: ^11.x` | Use `^12.0.1` — latest stable, requires `compileSdkVersion 35` (already set). |

### SharedPreferences dependency decision

**Check `pubspec.yaml`**: `shared_preferences` is NOT currently a declared dependency (as of Story 1.5). However, it may be transitively available through `path_provider` or other packages. **Declare it explicitly** in `pubspec.yaml` with annotation: `# Story 1.6 — CapturePreference persistence (non-sensitive UX flag)`.

If adding `shared_preferences` creates a transitive conflict, consider alternatives:
1. Use `path_provider` + a plain text file (ugly but dependency-free).
2. Store in a Drift table (heavy but already available — violates Muri principle for a boolean flag).
3. **Preferred**: `shared_preferences` is a Flutter-team first-party plugin with no known conflicts. Add it.

### permission_handler — version 12.0.1

- **BREAKING in 12.x**: `compileSdkVersion 35` required for Android. The project already targets latest SDK per Story 1.1 AC6 — verify `android/app/build.gradle` has `compileSdkVersion 35` or higher.
- API: `Permission.camera.request()` returns `PermissionStatus`. Check `.isGranted`, `.isDenied`, `.isPermanentlyDenied`.
- `openAppSettings()` opens the app's system settings page (for re-granting denied permissions in Story 1.9).
- **Manifest must declare the permission**: `permission_handler` does NOT auto-add `<uses-permission>` entries. The developer must add `android.permission.CAMERA` to `AndroidManifest.xml`.
- **Android 14+ behavior**: Camera permission is a one-time request. If permanently denied, the only recovery is through system settings (`openAppSettings()`).
- Fluent callback API available (`onGrantedCallback`, etc.) but overkill for a simple request-and-check flow. Use the basic `request()` + status check.

### Project Structure Notes

**Directories created by this story:**
- `lib/core/capture/` — CapturePreference enum and store
- `lib/core/permissions/` — PermissionService abstraction

**Files created:**
- `lib/core/capture/capture_preference.dart` — CapturePreference enum
- `lib/core/capture/capture_preference_store.dart` — SharedPreferences persistence + provider
- `lib/core/capture/capture_preference_store.g.dart` — generated, committed
- `lib/core/permissions/permission_service.dart` — abstract interface
- `lib/core/permissions/permission_service_impl.dart` — production implementation
- `lib/core/permissions/permission_service_impl.g.dart` — generated, committed (if provider is here)
- `lib/features/onboarding/camera_permission_screen.dart` — CameraPermissionScreen widget
- `test/fakes/fake_permission_service.dart` — test fake
- `test/fakes/fake_capture_preference_store.dart` — test fake
- `test/widget/features/onboarding/camera_permission_screen_test.dart` — widget tests
- `test/unit/core/capture/capture_preference_store_test.dart` — unit tests
- `test/widget/features/onboarding/goldens/camera_permission_dark.png` — golden baseline
- `test/widget/features/onboarding/goldens/camera_permission_light.png` — golden baseline

**Files modified:**
- `pubspec.yaml` — permission_handler, shared_preferences
- `pubspec.lock` — regenerated
- `lib/l10n/app_en.arb` — 4 new camera-permission keys
- `lib/l10n/app_hr.arb` — 4 new camera-permission values
- `lib/l10n/app_localizations.dart` — regenerated
- `lib/l10n/app_localizations_en.dart` — regenerated
- `lib/l10n/app_localizations_hr.dart` — regenerated
- `lib/app/router.dart` — placeholder replaced with CameraPermissionScreen, login placeholder added
- `android/app/src/main/AndroidManifest.xml` — `<uses-permission>` for CAMERA

**This story does NOT create:**
- `lib/features/onboarding/login_screen.dart` — Story 1.7
- `lib/features/settings/` permission re-request UI — Story 1.9
- Any camera capture logic — Epic 4
- Any Drift tables — not needed for a boolean preference

### Deferred work from previous stories relevant to this one

- **Architecture doc lists `lib/features/onboarding/consent_screen.dart`** but consent landed in `lib/core/consent/`. Do NOT modify the architecture doc in this story — the discrepancy is already logged in deferred-work.md.
- **`outlinedButton` WCAG contrast** not asserted by test (deferred from Story 1.2). This story introduces the first `OutlinedButton` in the real onboarding flow. Golden tests provide visual regression coverage but not computed contrast assertion.

### Epic 4 contract — how `CapturePreference` is consumed downstream

Epic 4 (Confident Capture Pipeline) reads `CapturePreference` to determine the default capture mode:
- `CapturePreference.live` → MRZ-first capture flow (camera stream → ML Kit → auto-shutter).
- `CapturePreference.manualOnly` → Manual entry as primary path. Camera is never opened. No re-prompt for camera permission.

This story only **writes** the preference. Epic 4 **reads** it. The enum and store must be in `lib/core/capture/` so both onboarding and capture features can import them without cross-feature violations.

### Settings re-request contract (Story 1.9)

Story 1.9 will add a "Pristup kameri" Settings tile that:
1. Calls `permissionServiceProvider.requestCamera()` to re-request.
2. If granted, updates `CapturePreference` to `live`.
3. If permanently denied, calls `permissionServiceProvider.openSettings()` to open system settings.

This story prepares the infrastructure (interface + implementation) that Story 1.9 consumes. The `openSettings()` method on `PermissionService` exists for this purpose.

### References

- [Architecture §Project Structure — `lib/features/onboarding/`, `lib/core/`](../planning-artifacts/architecture.md#project-structure--boundaries)
- [Architecture §AdMob Placement Policy — no ads on onboarding](../planning-artifacts/architecture.md#admob-placement-policy)
- [Architecture §Architectural Boundaries — feature dependency graph, onboarding → auth](../planning-artifacts/architecture.md#architectural-boundaries)
- [Architecture §BuildContext across async gaps — always check mounted](../planning-artifacts/architecture.md)
- [Architecture §Naming Patterns — kebab-case route paths, snake_case files, PascalCase classes](../planning-artifacts/architecture.md#naming-patterns)
- [PRD §FR4 — camera permission grant or deny; manual entry fully functional if denied](../planning-artifacts/prd.md)
- [PRD §FR1 — linear first-run onboarding flow](../planning-artifacts/prd.md)
- [UX Spec §Journey 1 mermaid — camera permission node between Welcome and Login](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Error States — "Camera permission denied: manual entry becomes the primary path"](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Typography — displayMedium (45/700/52) for onboarding headings](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Spacing — 4dp base grid, s64 top margin for emotional moments](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Standard Screen Skeleton — SafeArea/content/CTA/gesture inset](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Button Hierarchy — FilledButton primary (56dp), OutlinedButton secondary (48dp)](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Accessibility — WCAG 2.1 AA, 48×48dp touch targets, semantics on controls](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Copy — Croatian primary, sentence case, imperative CTAs, full diacritics](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Ad Placement — Welcome/onboarding: No ads](../planning-artifacts/ux-design-specification.md)
- [Epics §Story 1.6 — BDD acceptance criteria, capturePreference contract](../planning-artifacts/epics.md)
- [Epics §FR4 → Story 1.6 traceability](../planning-artifacts/epics.md)
- [CLAUDE.md §Permissions — runtime only when needed, rationale strings](../../CLAUDE.md)
- [CLAUDE.md §Tech Stack — permission_handler not listed; added here as justified new dependency](../../CLAUDE.md)
- [Story 1.5 — WelcomeScreen pattern, test patterns, l10n, codegen workflow](./1-5-welcome-and-sensitive-data-disclosure.md)
- [Story 1.7 (next) — Login screen; receives navigation from camera permission screen](../planning-artifacts/epics.md)
- [Story 1.9 — Settings camera re-request; consumes PermissionService.openSettings()](../planning-artifacts/epics.md)
- [Epic 4 — Capture pipeline; reads CapturePreference to determine default capture mode](../planning-artifacts/epics.md)
- [`permission_handler` 12.0.1 — pub.dev](https://pub.dev/packages/permission_handler)
- [`shared_preferences` — pub.dev](https://pub.dev/packages/shared_preferences)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Resolved versions: permission_handler 12.0.1, shared_preferences 2.5.5. No transitive conflicts.
- CAMERA already declared in AndroidManifest.xml (Story 1.1 AC4.2) — subtask 1.3 was a no-op.
- `Ref` type requires `flutter_riverpod` import even when using `riverpod_annotation` — test VM compilation is stricter than `dart analyze` alone. Fixed by adding explicit `flutter_riverpod` import to both `capture_preference_store.dart` and `permission_service_impl.dart`.
- `directives_ordering` lint: package imports must be alphabetically sorted in a single block (no blank line separating prijavko imports from other packages). Fixed in both source files.

### Completion Notes List

- All 8 tasks / all subtasks complete.
- 74 tests green (16 unit + 13 camera-permission widget + 12 welcome-screen widget + 1 smoke + design tests).
- New infrastructure: `CapturePreference` enum + `CapturePreferenceStore` (SharedPreferences-backed, versioned key, default `manualOnly`). `PermissionService` interface seam + `PermissionServiceImpl`. Both follow ConsentService / SecurityService testability patterns.
- `CameraPermissionScreen`: ConsumerStatefulWidget, mounted guard after async requestCamera(), all text via AppLocalizations, zero literal strings.
- Golden baselines committed (dark + light).
- `dart analyze --fatal-warnings --fatal-infos`: clean. `dart format`: clean.

### File List

**New files:**
- `lib/core/capture/capture_preference.dart`
- `lib/core/capture/capture_preference_store.dart`
- `lib/core/capture/capture_preference_store.g.dart`
- `lib/core/permissions/permission_service.dart`
- `lib/core/permissions/permission_service_impl.dart`
- `lib/core/permissions/permission_service_impl.g.dart`
- `lib/features/onboarding/camera_permission_screen.dart`
- `test/fakes/fake_permission_service.dart`
- `test/fakes/fake_capture_preference_store.dart`
- `test/unit/core/capture/capture_preference_store_test.dart`
- `test/widget/features/onboarding/camera_permission_screen_test.dart`
- `test/widget/features/onboarding/goldens/camera_permission_dark.png`
- `test/widget/features/onboarding/goldens/camera_permission_light.png`

**Modified files:**
- `pubspec.yaml` — permission_handler 12.0.1, shared_preferences 2.5.5 added
- `pubspec.lock` — regenerated
- `lib/l10n/app_en.arb` — 4 camera-permission keys
- `lib/l10n/app_hr.arb` — 4 camera-permission values
- `lib/l10n/app_localizations.dart` — regenerated
- `lib/l10n/app_localizations_en.dart` — regenerated
- `lib/l10n/app_localizations_hr.dart` — regenerated
- `lib/app/router.dart` — placeholder → CameraPermissionScreen; login placeholder added

### Change Log

- 2026-04-27: Story 1.6 implemented — camera permission screen, PermissionService seam, CapturePreference persistence, l10n, router, tests, goldens. Branch: story-1-6-camera-permission.

---

## Review Findings

Code review by parallel adversarial agents (Blind Hunter, Edge Case Hunter, Acceptance Auditor) — 2026-04-27.

### Decision Needed

- [x] [Review][Decision] **SharedPreferences Result contract** — `CapturePreferenceStore.save()` and `load()` are declared as `Future<void>` / `Future<CapturePreference>` (per AC2), but the project rule mandates all data-layer functions return `Result<T, Failure>`. `SharedPreferences.setString()` can throw (disk full, PlatformException) and is silently swallowed; user gets stuck on screen with no feedback and no navigation. Decision: add `Result` wrapping to `save()`/`load()`, or treat this store as a lightweight convenience layer exempt from the contract (safe fallback to `manualOnly` on failure is acceptable)?

- [x] [Review][Decision] **permanentlyDenied path: no UI feedback, `openSettings()` dead code** — When camera is permanently denied, `Permission.camera.request()` returns immediately without showing an OS dialog. `requestCamera()` returns `false`, saves `manualOnly`, navigates. UX: user taps "Dopusti pristup", button responds instantly with no dialog, screen changes — looks broken. `isCameraPermanentlyDenied()` and `openSettings()` are defined in the AC3 interface but have zero call sites. Decision: does this story need to detect permanently-denied state and show an "Otvorite postavke" nudge (inline or via `openSettings()`), or is the silent-fallback-to-manualOnly path acceptable and the full handling deferred to Story 1.9?

### Patches

- [x] [Review][Patch] **No in-flight guard on `_onAllow`/`_onSkip` — double-tap race** — Both handlers are `async` with no `_isInFlight` flag. Double-tap during OS dialog or during `save()` fires concurrent executions: two `requestCamera()` calls and two `context.go()` calls. Fix: add `bool _isInFlight = false`, `setState` before each await, check at top of each handler, set `onPressed: _isInFlight ? null : _onAllow`. [`lib/features/onboarding/camera_permission_screen.dart`]

- [x] [Review][Patch] **Allow-denied test missing `requestCameraCallCount` assertion** — The "tapping Allow when permission denied" test asserts `savedPreference` and navigation but not that `requestCamera()` was actually called. A refactor that skips `requestCamera()` entirely would pass. Fix: add `expect(fakePermission.requestCameraCallCount, 1)`. [`test/widget/features/onboarding/camera_permission_screen_test.dart`]

- [x] [Review][Patch] **Semantics label on icon duplicates visible headline — double-announcement** — `Semantics(label: l10n.cameraPermissionHeadline, child: Icon(...))` followed immediately by `Text(l10n.cameraPermissionHeadline)` causes screen readers to announce the headline twice in succession. The icon is decorative; the text already communicates the label. Fix: replace with `ExcludeSemantics(child: Icon(...))` or add `excludeFromSemantics: true` to the `Semantics` wrapper. [`lib/features/onboarding/camera_permission_screen.dart`]

- [x] [Review][Patch] **Hardcoded `'/onboarding/login'` string — use named navigation** — `context.go('/onboarding/login')` called in both `_onAllow` and `_onSkip`. The route already declares `name: 'login'`. Hardcoded path silently breaks at runtime if the route tree changes; `goNamed` would surface the regression as an assertion. Fix: `context.goNamed('login')`. [`lib/features/onboarding/camera_permission_screen.dart`]

### Deferred

- [x] [Review][Defer] **`CapturePreferenceStore` not behind abstract interface** [`lib/core/capture/capture_preference_store.dart`] — deferred, pre-existing design: `FakeCapturePreferenceStore` extends the concrete class rather than an interface. Any new method added to `CapturePreferenceStore` silently falls through to real SharedPreferences in tests. Contrast with `PermissionService` (abstract) + `PermissionServiceImpl`. Consider extracting `AbstractCapturePreferenceStore` in a future story if the class gains additional methods.

- [x] [Review][Defer] **AutoDispose providers captured before long await** [`lib/features/onboarding/camera_permission_screen.dart`] — deferred, pre-existing design: `ref.read(capturePreferenceStoreProvider)` is captured before `await requestCamera()`. Safe today because both providers are stateless value types; becomes fragile if either is converted to a stateful `Notifier`. Document with a comment or migrate to a `Notifier`-hosted action method.

- [x] [Review][Defer] **`restricted`/`limited` permission status → silent `manualOnly` with no OS dialog** [`lib/core/permissions/permission_service_impl.dart`] — deferred, edge case: on MDM-managed or OEM-restricted devices, `Permission.camera.request()` returns immediately without showing a dialog. User taps "Dopusti pristup" and the screen advances silently in manual-only mode with no explanation. Relevant for Story 1.9 or an explicit settings-screen remediation.

- [x] [Review][Defer] **No test for SharedPreferences write failure** [`test/unit/core/capture/capture_preference_store_test.dart`] — deferred, pending Result contract decision: blocked on `decision-needed` item 1. If `Result` wrapping is added to `save()`, add a test for `PlatformException` propagation.

- [x] [Review][Defer] **`openAppSettings()` return value discarded** [`lib/core/permissions/permission_service_impl.dart`] — deferred, not called in this story: `openSettings()` is defined but unused. `openAppSettings()` returns a `bool` (success/failure) that is currently discarded. When Story 1.9 wires the "open settings" action, change `openSettings()` return type to `Future<bool>` and update the interface and implementation.
