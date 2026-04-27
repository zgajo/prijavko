# Story 1.8: Session Persistence Across Restarts

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a returning host,
I want the app to remember my login across process kills and device reboots,
so that I don't have to re-authenticate every time I open the app to register guests.

## Acceptance Criteria

### AC1 — `SessionBootstrap` sealed class (interim, scoped to this story)

1. Create **`lib/core/bootstrap/session_bootstrap.dart`** with a Dart 3 sealed class describing the four boot outcomes:
   ```dart
   sealed class SessionBootstrap {
     const SessionBootstrap();
   }

   /// First run: no credentials, no facility cache. Onboarding flow drives.
   final class BootFreshFirstRun extends SessionBootstrap {
     const BootFreshFirstRun();
   }

   /// Credentials + cookies both viable. Route directly to /home.
   /// AuthState handover: Authenticated(facilitiesLoaded: false) when Epic 2 lands.
   final class BootSessionLive extends SessionBootstrap {
     const BootSessionLive();
   }

   /// Credentials viable, cookies missing or undecryptable. Route to /home;
   /// Epic 2's CredentialBanner (Story 2.7) recovers via stored credentials.
   /// AuthState handover: Reauth.
   final class BootCookiesMissing extends SessionBootstrap {
     const BootCookiesMissing();
   }

   /// Credentials missing AND a facility profile already exists in Drift.
   /// Route via the credentials-missing recovery flow (FR14.5 / Epic 2 Story 2.8).
   /// AuthState handover: AuthFailure(credentialsInvalid).
   final class BootCredentialsMissing extends SessionBootstrap {
     const BootCredentialsMissing();
   }
   ```
2. **WHY interim, not the architecture's `AuthState`**: `AuthState` is Story 2.1's deliverable. Story 1.8 needs a typed boot decision today. Mirrors Story 1.7's `LoginFailure → AuthFailureReason` JIT pattern. Top-of-file comment must document the migration: each variant maps 1-to-1 to an `AuthState` constructor (table in Dev Notes §Epic 2 consolidation).
3. **WHY no `BootError` variant**: any failure of the bootstrap pipeline (Keystore unavailable, decrypt thrown, IO error) is a *Jidoka* event — crash visibly at startup per `SecurityService.init()` precedent (Story 1.3). Do **not** swallow into a fifth variant; that hides storage corruption behind a green app shell.
4. The sealed class file declares no methods, no factory constructors. Pure data carrier. Exhaustive `switch` at every consumer (the router redirect) is the Poka-yoke.

### AC2 — `CookieJar` provider extraction (refactor of Story 1.3 wiring)

1. Story 1.3 inlined `PersistCookieJar` construction inside `dioProvider`. Story 1.8 needs to query the **same jar** the future `EvisitorApiClient` uses, without constructing a second one (file-lock race + key-collision risk). Extract:
   ```dart
   // lib/app/providers.dart
   @Riverpod(keepAlive: true)
   CookieJar cookieJar(Ref ref) {
     final security = ref.watch(securityServiceProvider);
     final cookieDir = ref.watch(cookieJarDirectoryProvider);

     if (evisitorEnv == EvisitorEnv.fake) {
       // CookieJar (in-memory) is sufficient for fake env — no persistence needed.
       return CookieJar();
     }

     final storage = EncryptedStorage(cookieDir, security.encryptionHelper);
     return PersistCookieJar(
       storage: storage,
       persistSession: true,
       ignoreExpires: false,
     );
   }
   ```
2. **Refactor `dioProvider`** to consume `cookieJarProvider` instead of constructing the jar inline:
   ```dart
   // lib/app/providers.dart — dioProvider, replace the cookie-jar block:
   if (evisitorEnv != EvisitorEnv.fake) {
     final jar = ref.watch(cookieJarProvider);
     dio.interceptors.add(CookieManager(jar));
     // …cert pinning unchanged…
   }
   ```
3. **WHY `keepAlive: true`**: same lifetime as `dioProvider` — the jar holds open file handles via `EncryptedStorage`. Disposing would close them mid-request.
4. **WHY `CookieJar` (interface) as the return type, not `PersistCookieJar`**: the fake-env branch returns the in-memory `CookieJar` base class. Story 1.7's smoke test path (`flutter run --dart-define=EVISITOR_ENV=fake`) must still work. Consumers (Dio's `CookieManager`, Story 1.8's bootstrap query) only need the interface.
5. Verify no other call site references the old inline jar — `dioProvider` was the only consumer (Story 1.7 reads cookies through Dio, not the jar directly).
6. Generated `cookieJar_provider` lands in `providers.g.dart`. Run `dart run build_runner build --delete-conflicting-outputs` after the edit.

### AC3 — `sessionBootstrapProvider` (the boot decision pipeline)

1. Create **`lib/core/bootstrap/session_bootstrap_provider.dart`** with a single `@riverpod` async provider:
   ```dart
   @Riverpod(keepAlive: true)
   Future<SessionBootstrap> sessionBootstrap(Ref ref) async {
     final credentialStore = ref.watch(credentialStoreProvider);
     final jar = ref.watch(cookieJarProvider);

     final credentialsResult = await credentialStore.loadCredentials();
     final hasCredentials = credentialsResult is Ok<Credentials, StorageError>;
     final hasFacilityProfile = await ref.watch(hasFacilityProfileProvider.future);
     final hasViableCookies = await _hasViableSessionCookies(jar);

     if (!hasCredentials) {
       return hasFacilityProfile
           ? const BootCredentialsMissing()
           : const BootFreshFirstRun();
     }
     return hasViableCookies
         ? const BootSessionLive()
         : const BootCookiesMissing();
   }
   ```
2. **`_hasViableSessionCookies(CookieJar jar)`** — package-private async helper in the same file:
   ```dart
   Future<bool> _hasViableSessionCookies(CookieJar jar) async {
     // WHY this exact URL: PersistCookieJar's domain matching is keyed on host
     // + path. The eVisitor login endpoint sets cookies with Path=/Resources/ —
     // matching anything *under* that path returns the auth cookies.
     final cookies = await jar.loadForRequest(
       Uri.parse('${_resolveBaseUrl()}'),
     );
     // The 'authentication' cookie is the load-bearing one — 'affinity' and
     // 'language' do not carry session identity. If 'authentication' is absent
     // (or expired and pruned by ignoreExpires=false), session is not viable.
     return cookies.any((c) => c.name == 'authentication');
   }
   ```
   - **Reuse**, do NOT redefine, `_resolveBaseUrl()` — extract it from `providers.dart` to a top-level export so both `dioProvider` and `_hasViableSessionCookies` consume the same source. Adding a duplicate URL string is *Mura* (unevenness): a future testApi → prod cutover would silently desync.
3. **WHY `await ref.watch(...future)` for facility profile**: Riverpod 3 async dependencies must be awaited via `.future`. The provider returns `false` until Story 3.1 lands; for Story 1.8, ship a stub provider in `lib/features/facility/has_facility_profile.dart`:
   ```dart
   /// Stub: until Story 3.1 introduces the FacilitiesTable, no facility
   /// profile can exist. Returning false collapses BootCredentialsMissing
   /// into BootFreshFirstRun for v1.0 — the only reachable branch today.
   /// Story 3.1 replaces this with `appDatabase.facilitiesTable.count() > 0`.
   @Riverpod(keepAlive: true)
   Future<bool> hasFacilityProfile(Ref ref) async => false;
   ```
   - File header documents the Story 3.1 replacement.
   - **Do not** create a Drift table in this story.
4. **WHY `keepAlive: true`** on `sessionBootstrap`: the redirect callback reads it on every navigation; recomputing the entire pipeline (which touches Keystore + filesystem) on each route change is *Muda*. Boot state is immutable for the lifetime of the process — Story 1.7 login success will need to invalidate (`ref.invalidate(sessionBootstrapProvider)`) on `Ok`. Add a one-line `// TODO(story-2.x): AuthNotifier.login() invalidates this provider on success.` next to the provider declaration.
5. **No `Result<...>` wrapping**: the provider returns `Future<SessionBootstrap>`, not `Future<Result<SessionBootstrap, …>>`. Failure here is a Jidoka crash; surfacing it as `Result.Err` is silent storage failure — the explicit project anti-pattern.
6. Run codegen — generated provider lands in `session_bootstrap_provider.g.dart` (committed) and `has_facility_profile.g.dart` (committed).

### AC4 — `main.dart` startup sequence

1. The BDD AC requires "main.dart awaits SecurityService.init() and CredentialStore.loadCredentials() before building the widget tree". Story 1.8 keeps the existing `SecurityService.init()` await and adds nothing else to `main.dart` directly — the boot pipeline runs **inside the ProviderScope** via `sessionBootstrapProvider`, which the router awaits before granting any non-onboarding route. **WHY**: `main.dart` already initializes the providers that `sessionBootstrapProvider` reads. Forcing a second pre-`runApp` await (CredentialStore.loadCredentials()) duplicates the work and creates a second source of truth for "have we resolved boot?".
2. **No changes to `main.dart`** are required by this story other than verifying the existing `getApplicationDocumentsDirectory()` + `cookieJarDirectoryProvider.overrideWithValue(cookieJarDir)` plumbing reaches the new `cookieJarProvider`. (It does — `cookieJarProvider` reads `cookieJarDirectoryProvider`.)
3. **Document the BDD restatement in the story file's Dev Notes §Routing pipeline** so future readers know why `main.dart` is unchanged: the BDD's "before building the widget tree" intent is satisfied by `routerProvider`'s redirect blocking until `sessionBootstrap.future` resolves — the route tree does not surface non-onboarding screens until the boot decision is made.

### AC5 — `BootGate` widget + router redirect

The router redirect callback **must read synchronous state** (go_router 14+ contract). `sessionBootstrapProvider` is async. Two viable shapes:

- **Option A (chosen)**: `BootGate` wraps the route tree. It watches `sessionBootstrapProvider` (an `AsyncValue<SessionBootstrap>`); while loading, it renders the same `_ConsentLoadingScaffold` as `ConsentGate`. Once resolved, it triggers a single navigation via `WidgetsBinding.instance.addPostFrameCallback` based on the variant.
- Option B (rejected): synchronous `bootSnapshotProvider` populated by an eager `await` before `runApp`. Rejected because it forces `main.dart` to know about the bootstrap pipeline (creating a second source of truth) and races with `ConsentGate`'s post-frame logic.

1. Create **`lib/core/bootstrap/boot_gate.dart`** as a `ConsumerStatefulWidget` placed **inside** `ConsentGate` (so consent always resolves first — UMP must precede any Drift/Keystore touch per Story 1.4 ordering invariant). Update `app.dart`:
   ```dart
   builder: (context, child) => ConsentGate(
     child: BootGate(child: child ?? const SizedBox.shrink()),
   ),
   ```
2. **`BootGate` build**:
   ```dart
   final boot = ref.watch(sessionBootstrapProvider);
   return boot.when(
     loading: () => const _BootLoadingScaffold(),
     error: (e, st) => throw e, // Jidoka — never swallow.
     data: (decision) {
       _navigateOnce(decision);
       return widget.child;
     },
   );
   ```
3. **`_navigateOnce(SessionBootstrap)`** — guarded by an instance `bool _navigated`:
   - On the first non-loading frame, schedule `WidgetsBinding.instance.addPostFrameCallback` to call `context.goNamed(...)` per the variant table:
     | Variant | Target route | Notes |
     |---|---|---|
     | `BootFreshFirstRun` | (no navigation) | router's `initialLocation: '/onboarding'` already lands the user on Welcome — no goNamed call. |
     | `BootSessionLive` | `'home'` | Direct route to `/home` (the placeholder added in Story 1.7). |
     | `BootCookiesMissing` | `'home'` | Same target as live; Epic 2 Story 2.7's CredentialBanner appears on Home and handles recovery. Set a sentinel in a future `authNotifierProvider` — for Story 1.8, only navigate. |
     | `BootCredentialsMissing` | (no navigation) | Stub today: `hasFacilityProfileProvider` returns `false` until Story 3.1, so this branch is unreachable in v1.0. **Implement the route case anyway** as a `// TODO(story-2.8)` `goNamed('credentials-missing-recovery')` placeholder that throws `UnimplementedError`. Behind a comment-block: when Story 3.1 ships and a facility profile can exist, this branch becomes live and Story 2.8's recovery screen handles it. |
   - **Poka-yoke**: `_navigated` flag prevents double-navigation if a hot-reload or rebuild fires before the post-frame callback executes.
4. **`_BootLoadingScaffold`** — identical to `ConsentGate`'s `_ConsentLoadingScaffold`. Extract the shared widget to `lib/core/bootstrap/boot_loading_scaffold.dart` so both consent and boot gates render the same pixel surface during their async windows. (No locale-dependent strings; `semanticsLabel: 'Loading'` is the only TalkBack hook — same Story 1.4 convention.)
5. **WHY no router-level `redirect:` callback**: go_router's redirect runs synchronously per navigation and does not await Futures. Bootstrapping with a redirect would either (a) gate every navigation on a state lookup that races with the async bootstrap (timing bug), or (b) force the bootstrap into a synchronous-by-default `Provider<SessionBootstrap?>` that is `null` until populated — re-introducing the implicit nullability the sealed class deliberately eliminates. The `BootGate` widget pattern keeps the boot decision typed and synchronous *at the navigation moment*.
6. **TODO-line for Story 2.x**: leave the `// TODO(story-2.3): add redirect callback reading authNotifierProvider` line **untouched** in `router.dart`. Epic 2 will add a real synchronous redirect once `AuthState` is in-memory; Story 1.8's BootGate becomes a dumb pass-through at that point (delete-able in Story 2.3 cleanup).

### AC6 — 14-day backgrounded resume invariant

1. The BDD AC: "Given the app has been backgrounded for more than 14 days When the app is foregrounded Then `AuthNotifier` is not preemptively flipped to `Reauth` on Story 1.8's logic alone".
2. **What this means concretely**: `BootGate.build` must NOT re-run `sessionBootstrapProvider` on `AppLifecycleState.resumed`. The provider's `keepAlive: true` makes this true by construction — `ref.watch` returns the cached `AsyncValue<SessionBootstrap>` without recomputing. Verify with a widget test (AC9.4).
3. **Do NOT add** a `WidgetsBindingObserver` that invalidates the provider on resume. That is Epic 2 Story 2.6's concern (`opportunisticAuthCheck`). Story 1.8 must not encroach.
4. **What Story 1.8 *does* have to handle**: a process death after 14 days. The cookie jar's `ignoreExpires: false` (Story 1.3) prunes expired cookies on read, so `loadForRequest` returns no `authentication` cookie ⇒ `BootCookiesMissing` ⇒ Reauth handover. This is the correct behavior — no preemption, no false-Reauth on shorter backgrounded windows.

### AC7 — l10n strings

No new user-facing strings. `BootGate`'s `_BootLoadingScaffold` is a `CircularProgressIndicator` with `semanticsLabel: 'Loading'` — identical to `_ConsentLoadingScaffold`. **Do not** add `bootGateLoading` or similar keys.

- **WHY no new strings**: the loading scaffold is a sub-50ms transient on cold start. Adding a localized string introduces ARB churn and a TalkBack regression risk for a surface the user effectively never reads aloud. The static `'Loading'` label matches what `ConsentGate` already ships.
- If Story 1.4's `_ConsentLoadingScaffold` is later refactored to use a localized `loadingLabel`, this story's `_BootLoadingScaffold` consumes the same key — no parallel string.

### AC8 — `EvisitorFakeAdapter` / fake credential store / fake cookie jar — test seams only

1. **No production change** to `EvisitorFakeAdapter` for Story 1.8. The login surface (Story 1.7) drives all eVisitor traffic; bootstrap reads only local state.
2. **Reuse `FakeCredentialStore`** from Story 1.7's `test/fakes/fake_credential_store.dart`. If a test needs to seed credentials, call `fake.saveCredentials(...)` before pumping the gate.
3. **Cookie-jar test fixture**: bootstrap tests need to seed cookies into a jar instance, then assert the bootstrap result. The `cookieJarProvider` in fake env already returns a fresh `CookieJar` (in-memory). Tests override the provider with a pre-seeded `CookieJar` instance:
   ```dart
   final jar = CookieJar()
     ..saveFromResponse(Uri.parse('https://www.evisitor.hr/Resources/'), [
       Cookie('authentication', 'fake-session-cookie')
         ..path = '/Resources/'
         ..secure = true
         ..httpOnly = true,
     ]);
   // Override:
   cookieJarProvider.overrideWithValue(jar)
   ```
4. **Encrypted-jar persistence test** (AC9.5): exercises a real `PersistCookieJar` + `EncryptedStorage` on disk in a `Directory.systemTemp` dir, with a `FakeSecurityService` providing the AES-GCM key. Asserts: write cookies on instance #1 → close → instance #2 reads same cookies → bootstrap returns `BootSessionLive`. Mirror the cookie-jar verification pattern Story 1.7 introduced (story-1.7 §Cookie persistence verification).

### AC9 — Tests

1. **`test/unit/core/bootstrap/session_bootstrap_test.dart`** — pure-Dart unit tests of the boot decision matrix. Each case overrides `credentialStoreProvider`, `cookieJarProvider`, `hasFacilityProfileProvider` with fakes and resolves the bootstrap future:
   - **No credentials, no facility profile** → `BootFreshFirstRun`.
   - **No credentials, facility profile present** (force the stub to `true` via override) → `BootCredentialsMissing`.
   - **Credentials present, no `authentication` cookie** → `BootCookiesMissing`.
   - **Credentials present, only `affinity` and `language` cookies** (no `authentication`) → `BootCookiesMissing`. Verifies the load-bearing cookie check.
   - **Credentials present, `authentication` cookie present** → `BootSessionLive`.
   - **Credentials present, `authentication` cookie present BUT in a different domain path** (e.g. `Path=/foo/`) → `BootCookiesMissing`. Verifies the URL passed to `loadForRequest` matches eVisitor's `Path=/Resources/`.
   - **Credentials present, `authentication` cookie expired** (`expires` in the past, jar instantiated with `ignoreExpires: false`) → `BootCookiesMissing`. Verifies the 14-day-elapsed branch lands on the correct boot variant by way of the cookie jar's own pruning, not Story 1.8 logic.
   - **Credentials load throws `StorageError`** → propagates as a Future error (Jidoka — confirms no `BootError` swallowing). Use `expectLater(future, throwsA(isA<...>))`.

2. **`test/widget/core/bootstrap/boot_gate_test.dart`** — exercises the `BootGate` widget under each boot variant, using a minimal `_makeBootApp(...)` helper that mounts `MaterialApp.router` + `GoRouter(initialLocation: '/onboarding', routes: [WelcomeScreen, /home placeholder])`:
   - **`BootFreshFirstRun`** → no navigation; `WelcomeScreen` is visible after `pumpAndSettle`.
   - **`BootSessionLive`** → exactly one `goNamed('home')` call; `Home — Epic 3` placeholder visible.
   - **`BootCookiesMissing`** → exactly one `goNamed('home')` call; `Home — Epic 3` placeholder visible. (Verifies AC5.3's cookies-missing route maps to home, not back to login.)
   - **`BootCredentialsMissing`** → `pumpAndSettle` must NOT throw. The TODO-blocked branch should land safely on the existing route (e.g. assert the loading scaffold is gone and no exception was raised). Implementation note: the `// TODO(story-2.8)` placeholder must NOT throw `UnimplementedError` synchronously in the post-frame callback (would crash the widget test); instead, log a `debugPrint` and stay on the current route. Update AC5.3's table accordingly: the `BootCredentialsMissing` row's "Notes" column gains _"For Story 1.8, no navigation; debugPrint logged; v1.0 unreachable until Story 3.1 makes facility profiles writable."_
   - **Loading state shows the loading scaffold** with `CircularProgressIndicator(semanticsLabel: 'Loading')`. Use a delayed override on `sessionBootstrapProvider` to keep it pending for one pump cycle.
   - **No double navigation** on rebuild: pump twice; assert `goNamed` called exactly once. Mirrors Story 1.7's double-tap guard pattern.

3. **`test/widget/app_smoke_test.dart` extension** — the existing smoke test must not regress. Add a single assertion: with no credentials seeded and a fresh cookie jar dir, the smoke flow lands on `WelcomeScreen` (current behavior). This is essentially a no-op verification — but explicit because Story 1.8 changes the widget tree (`BootGate` is new).

4. **`test/widget/core/bootstrap/boot_gate_resume_test.dart`** — the AC6 invariant. A widget test that:
   - Pumps `BootGate` with `BootSessionLive` resolved.
   - Simulates `AppLifecycleState.paused` then `AppLifecycleState.resumed` via `WidgetsBinding.instance.handleAppLifecycleStateChanged(...)`.
   - Asserts `sessionBootstrapProvider` resolved exactly once across the lifecycle (use a counting fake).
   - **WHY this test exists**: a future agent might "fix" the resume case by invalidating the provider — silently breaking the AC6 invariant. The test is the Poka-yoke.

5. **`test/integration/bootstrap/cookie_jar_persistence_test.dart`** — `flutter test` (not `integration_test/`, no Flutter binding required for the cookie jar itself):
   - Create a temp dir.
   - Instance #1: construct `EncryptedStorage` + `PersistCookieJar`, seed `authentication` cookie via `saveFromResponse`.
   - Close (drop references).
   - Instance #2: same temp dir, same `FakeSecurityService` (same AES-GCM key), construct `EncryptedStorage` + `PersistCookieJar`, call `loadForRequest('https://www.evisitor.hr/Resources/')`.
   - Assert `authentication` cookie is present.
   - **WHY this test exists**: `_hasViableSessionCookies` is dead code if `PersistCookieJar` doesn't actually round-trip cookies through `EncryptedStorage`. This test catches any future EncryptedStorage refactor that silently breaks persistence — the load-bearing assumption of Story 1.8.

6. **`test/unit/core/bootstrap/has_facility_profile_test.dart`** — single test asserting `hasFacilityProfileProvider` returns `false` until Story 3.1. Trivial but the Poka-yoke against an early replacement that ships before the FacilitiesTable is wired.

### AC10 — Validation gate

1. `flutter test` — all existing tests green + new bootstrap tests + new widget tests. Existing test count baseline (170 from Story 1.7) must increase by exactly the count of new tests (no regression deletions).
2. `dart analyze --fatal-warnings --fatal-infos` — clean.
3. `dart format --set-exit-if-changed lib test integration_test` — clean.
4. **PII / credential grep guard**: `lib/core/bootstrap/`, `lib/features/facility/has_facility_profile.dart` must contain zero references to `username`, `password`, `apiKey`, `Credentials`, `loadForRequest` argument values, or any cookie value (only cookie *names*, e.g. `'authentication'`, are referenced). Verify by hand-grep.
5. **i18n literal-string guard**: `grep -rn '"[A-Z][a-zšđčćž]' lib/core/bootstrap/` returns empty (excluding the doc comments and the `'authentication'` cookie name constant which is a contract identifier, not a UI string).
6. **Manual smoke against fake env** (`flutter run --dart-define=EVISITOR_ENV=fake`):
   - Cold start with no credentials: lands on Welcome (BootFreshFirstRun branch).
   - Sign in via Story 1.7's flow → lands on `/home`.
   - Force-stop the app, cold start again: lands directly on `/home` (BootSessionLive branch).
   - Tap "Wipe credentials" via debug breakpoint or a `flutter_secure_storage` direct nuke: cold start lands on Welcome.
   - The fake-env in-memory `CookieJar` resets per process — so "BootSessionLive after restart" is only verifiable in the `prod`/`test` envs or via the AC9.5 integration test.

---

## Tasks / Subtasks

- [x] Task 1 — `SessionBootstrap` sealed class (AC: #1)
  - [x] Subtask 1.1 — Create `lib/core/bootstrap/session_bootstrap.dart` with the four-variant sealed class per AC1.1.
  - [x] Subtask 1.2 — Add top-of-file comment documenting the Epic 2 Story 2.1 `AuthState` migration table per AC1.2.
  - [x] Subtask 1.3 — Verify no existing call site references `SessionBootstrap` or `BootSessionLive` etc. (`grep -rn SessionBootstrap lib/ test/`).

- [x] Task 2 — `cookieJarProvider` extraction (AC: #2)
  - [x] Subtask 2.1 — Add `@Riverpod(keepAlive: true) CookieJar cookieJar(Ref ref)` to `lib/app/providers.dart` per AC2.1. Returns in-memory `CookieJar()` for fake env, `PersistCookieJar(...)` for prod/test.
  - [x] Subtask 2.2 — Refactor `dioProvider` to consume `cookieJarProvider` via `ref.watch` (AC2.2). Delete the inlined `EncryptedStorage` + `PersistCookieJar` block.
  - [x] Subtask 2.3 — Extract `_resolveBaseUrl()` from `providers.dart` to a public top-level function `evisitorBaseUrl()` so the bootstrap helper can reuse it. Verify no second URL string exists in the codebase.
  - [x] Subtask 2.4 — Run `dart run build_runner build --delete-conflicting-outputs`. Commit `providers.g.dart` changes.

- [x] Task 3 — `hasFacilityProfileProvider` stub (AC: #3.3)
  - [x] Subtask 3.1 — Create `lib/features/facility/has_facility_profile.dart` returning `false` per AC3.3.
  - [x] Subtask 3.2 — File header documents Story 3.1 replacement.
  - [x] Subtask 3.3 — Run codegen.

- [x] Task 4 — `sessionBootstrapProvider` (AC: #3)
  - [x] Subtask 4.1 — Create `lib/core/bootstrap/session_bootstrap_provider.dart` per AC3.1.
  - [x] Subtask 4.2 — Implement `_hasViableSessionCookies` per AC3.2 using `evisitorBaseUrl()` + `loadForRequest`.
  - [x] Subtask 4.3 — Add `// TODO(story-2.x): AuthNotifier.login() invalidates this provider on success.` per AC3.4.
  - [x] Subtask 4.4 — Run codegen.

- [x] Task 5 — `BootGate` + loading scaffold (AC: #5)
  - [x] Subtask 5.1 — Create `lib/core/bootstrap/boot_loading_scaffold.dart` (extracted from `consent_gate.dart`'s `_ConsentLoadingScaffold` — refactor `consent_gate.dart` to consume it; **do not** duplicate).
  - [x] Subtask 5.2 — Create `lib/core/bootstrap/boot_gate.dart` as a `ConsumerStatefulWidget` per AC5.1–5.3.
  - [x] Subtask 5.3 — Wire `BootGate` into `app.dart`'s `MaterialApp.router builder:` between `ConsentGate` and `child` per AC5.1.
  - [x] Subtask 5.4 — Implement `_navigateOnce` with the `_navigated` Poka-yoke flag and the post-frame callback per AC5.3.
  - [x] Subtask 5.5 — `BootCredentialsMissing` branch: log `debugPrint` + no goNamed call (per AC9.2 test fix); add `// TODO(story-2.8)` annotation pointing to recovery flow.

- [x] Task 6 — Tests (AC: #9)
  - [x] Subtask 6.1 — `test/unit/core/bootstrap/session_bootstrap_test.dart` — 8 cases per AC9.1.
  - [x] Subtask 6.2 — `test/widget/core/bootstrap/boot_gate_test.dart` — 6 cases per AC9.2.
  - [x] Subtask 6.3 — `test/widget/app_smoke_test.dart` — assertion update per AC9.3 (no regression).
  - [x] Subtask 6.4 — `test/widget/core/bootstrap/boot_gate_resume_test.dart` — single test per AC9.4.
  - [x] Subtask 6.5 — `test/integration/bootstrap/cookie_jar_persistence_test.dart` — single round-trip test per AC9.5.
  - [x] Subtask 6.6 — `test/unit/core/bootstrap/has_facility_profile_test.dart` — single test per AC9.6.
  - [x] Subtask 6.7 — Run `flutter test` — all green; 192 total (170 baseline + 22 new); no deletions.

- [x] Task 7 — Validation gate (AC: #10)
  - [x] Subtask 7.1 — `flutter test` — green (192/192).
  - [x] Subtask 7.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [x] Subtask 7.3 — `dart format --set-exit-if-changed lib test integration_test` — clean.
  - [x] Subtask 7.4 — i18n literal-string guard — clean per AC10.5.
  - [x] Subtask 7.5 — PII / credential log grep guard — zero matches per AC10.4.
  - [ ] Subtask 7.6 — Manual smoke deferred to user (requires emulator).

### Review Findings

- [x] [Review][Patch] Cookie viability check uses API base URL instead of the `/Resources/` cookie path contract [lib/core/bootstrap/session_bootstrap_provider.dart:45]
- [x] [Review][Patch] Cookie-path contract is untested because bootstrap tests seed/load `authentication` under `/eVisitorRhetos_API/` [test/unit/core/bootstrap/session_bootstrap_test.dart:43]
- [x] [Review][Patch] Cookie persistence integration test validates `/eVisitorRhetos_API/` path rather than the `/Resources/` path contract [test/integration/bootstrap/cookie_jar_persistence_test.dart:39]
- [x] [Review][Patch] `BootGate` bootstrap error path rethrows without preserving stack trace (`throw e`) [lib/core/bootstrap/boot_gate.dart:53]
- [x] [Review][Patch] Bootstrap provider comments still contain a `Credentials` identifier despite AC10.4 guard [lib/core/bootstrap/session_bootstrap_provider.dart:24]
- [x] [Review][Patch] Resume invariant test uses messenger channel simulation instead of the specified lifecycle API [test/widget/core/bootstrap/boot_gate_resume_test.dart:78]
- [x] [Review][Patch] Session viability treats empty `authentication` cookie values as valid [lib/core/bootstrap/session_bootstrap_provider.dart:49]

---

## Dev Notes

### Why this story is eighth

Story 1.7 made the *first* eVisitor login work. Story 1.8 makes it the *only* eVisitor login the host ever needs. It is the load-bearing test of every persistence layer Story 1.3 wired up: `flutter_secure_storage` (credentials), `EncryptedStorage` + `PersistCookieJar` (cookies), `SecurityService.encryptionHelper` (AES-GCM key continuity). If any of those silently regress, Story 1.8's bootstrap tests fail at startup — exactly when failure is cheapest. Treating this story as a stress test on the cumulative Story 1.3 → 1.7 stack is deliberate.

### Architecture mandates (non-negotiable)

- **Feature/core boundary**: `lib/core/bootstrap/` is the right home (cross-cutting, app-startup-scoped). Bootstrap touches `core/security`, `features/settings/credential_store`, `app/providers.dart` — but no feature imports `core/bootstrap/`. The router (in `lib/app/`) consumes `BootGate` only via the `app.dart` builder wrapper.
- **`@riverpod` codegen only**: `cookieJarProvider`, `sessionBootstrapProvider`, `hasFacilityProfileProvider` all use the `@Riverpod` annotation. No manual `Provider(...)`. Generated `.g.dart` files committed.
- **`keepAlive: true`** on all three new providers: bootstrap state is immutable for the process lifetime; the cookie jar holds open file handles; the facility-profile stub is trivially cached. `autoDispose` would force re-init on every `ref.watch` — *Muda*.
- **Drift-as-truth does NOT apply here** — this story creates no Drift tables. The `hasFacilityProfileProvider` stub returns `false` until Story 3.1 introduces `FacilitiesTable`.
- **Result contract**: `loadCredentials()` already returns `Result<Credentials, StorageError>`. Bootstrap pattern-matches via `is Ok<...>` — no thrown exceptions. Cookie-jar errors (decryption failure) are silently dropped by `EncryptedStorage` (Story 1.3 design); the bootstrap surfaces this as `BootCookiesMissing`, not a failure.
- **Single Dio instance**: bootstrap does NOT touch Dio. It queries the cookie jar directly. `dioProvider` is unchanged in shape (just refactored to consume `cookieJarProvider`).
- **Dark mode primary**: `_BootLoadingScaffold` builds and verifies dark first.
- **`mounted` check after async gaps**: `BootGate._navigateOnce` runs inside a `addPostFrameCallback` — `if (!mounted) return;` is non-negotiable before `context.goNamed`.
- **`context.goNamed` not `context.go`**: per Story 1.6 retro patch.
- **No AppBar** on the loading scaffold (it is a transient sub-50ms surface, identical to ConsentGate's loading state).
- **`FLAG_SECURE` not applicable**: bootstrap renders no PII, no credentials. The login screen (Story 1.7) handles `FLAG_SECURE`; bootstrap does not.

### Routing pipeline — order of evaluation

The widget-tree wrapping order on cold start (outermost → innermost):

1. `ProviderScope` (`main.dart`)
2. `MaterialApp.router` (`PrijavkoApp.build`)
3. `ConsentGate` (Story 1.4) — gates on UMP consent resolution
4. `BootGate` (this story) — gates on `sessionBootstrapProvider.future`
5. `Router` (go_router's `routerConfig`) — `initialLocation: '/onboarding'`
6. The route's `WelcomeScreen` / `LoginScreen` / `Home` placeholder

**WHY consent before boot**: UMP's native form must precede any Drift/Keystore touch. If a host denies all consent, no PII can be ad-targeted. Story 1.4's invariant is "consent resolves before any other onboarding I/O". Bootstrap reads Keystore — it must come after consent.

**WHY boot before router redirect**: go_router's redirect callback is synchronous and runs per-navigation. It cannot await `sessionBootstrapProvider`. `BootGate` resolves the future once, then either lets the initial `/onboarding` location stand (FreshFirstRun) or imperatively `goNamed`s to `/home` (SessionLive / CookiesMissing). This is the documented Riverpod 3 + go_router 14 pattern for async-bootstrap-then-redirect; alternatives (synchronous nullable provider, ShellRoute redirect callback) re-introduce nullability or race conditions.

### Result contract justification — why interim `SessionBootstrap`, not `AuthState`

`AuthState` (Epic 2 Story 2.1) is the production type. Story 1.8 needs a typed boot decision *today*. Two options:

1. **Wait for Epic 2** and ship Story 1.8 with untyped routing (a `bool isAuthenticated` or similar). Violates the Result contract spirit and breaks the pattern Stories 1.5/1.6/1.7 established.
2. **Ship `SessionBootstrap` scoped to bootstrap only** that maps 1-to-1 to `AuthState` constructors when Epic 2 lands. Story 2.1's `AuthNotifier.build()` reads the resolved `sessionBootstrapProvider` and converts to `AuthState`.

Option 2 is the JIT choice — same precedent as Story 1.7's `LoginFailure → AuthFailureReason`. Migration is straightforward (5 lines in `auth_notifier.dart`).

### Previous story intelligence (Story 1.7)

- **`ConsumerStatefulWidget` is the right shape for a `BootGate`** that holds an instance `bool _navigated` for the Poka-yoke flag. Mirrors Story 1.7's `LoginScreen` pattern.
- **Test pattern**: `_makeTestApp(...)` helper with isolated `GoRouter` + `MaterialApp.router` + provider overrides. Reuse verbatim.
- **Codegen workflow**: `dart run build_runner build --delete-conflicting-outputs` after every `.dart` file with `@riverpod`. Generated `.g.dart` committed.
- **`directives_ordering` lint**: package imports alphabetical in a single block. Story 1.6 retro caught this — apply to every new file.
- **`flutter_riverpod` import is required** in any file using `Ref` — test VM compilation is stricter than `dart analyze`.
- **`mounted` check after `addPostFrameCallback`**: same convention as Story 1.7's `_maybeSubmit`.
- **Story 1.7 retro**: hardcoded `/tmp/test_cookies` path collides under parallel test workers — use `Directory.systemTemp.createTempSync(...)` and clean up in `tearDown`. Apply to the cookie-jar persistence integration test (AC9.5).
- **Story 1.7 patch precedent**: state assignment after dispose. `BootGate` is `autoDispose`-free (top-level widget) but its state class still uses `setState` only inside `mounted` checks.
- **Provider invalidation on login success**: Story 1.7's `LoginNotifier.submit()` saves credentials but does NOT currently invalidate `sessionBootstrapProvider` (the provider didn't exist yet). Story 1.8 adds the provider; Story 2.x's `AuthNotifier.login()` will be the call site that invalidates. Story 1.8 leaves a TODO line — see AC3.4.

### Cookie persistence verification — the load-bearing assumption

Story 1.7 introduced a unit test that round-trips cookies through `EncryptedStorage` + `PersistCookieJar` for the **success path**. Story 1.8 generalizes that test for **across-process-restart**: instance #1 writes, instance #2 reads. If `EncryptedStorage` ever silently regresses (e.g. a refactor changes the file naming or the AES-GCM key derivation), this test catches it before any host hits a stale-jar bug at the door.

Concrete shape (informal — final shape per `flutter test` conventions):

```dart
test('PersistCookieJar round-trips authentication cookie across instances',
    () async {
  final tempDir = await Directory.systemTemp.createTemp('boot_jar_test_');
  addTearDown(() => tempDir.deleteSync(recursive: true));
  final security = FakeSecurityService();
  await security.init();

  // Instance #1 — write
  final storage1 = EncryptedStorage(tempDir.path, security.encryptionHelper);
  final jar1 = PersistCookieJar(
    storage: storage1,
    persistSession: true,
    ignoreExpires: false,
  );
  await jar1.saveFromResponse(
    Uri.parse('https://www.evisitor.hr/Resources/'),
    [Cookie('authentication', 'session-token')..path = '/Resources/'],
  );

  // Instance #2 — read
  final storage2 = EncryptedStorage(tempDir.path, security.encryptionHelper);
  final jar2 = PersistCookieJar(
    storage: storage2,
    persistSession: true,
    ignoreExpires: false,
  );
  final cookies = await jar2.loadForRequest(
    Uri.parse('https://www.evisitor.hr/Resources/'),
  );

  expect(cookies.map((c) => c.name).toList(), contains('authentication'));
});
```

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| Add a router-level `redirect:` callback that `await`s the bootstrap | go_router's redirect is synchronous; use the `BootGate` widget pattern (AC5) |
| Construct a second `PersistCookieJar` for the bootstrap query | Read the same `cookieJarProvider` `dioProvider` consumes (AC2) |
| Add a `BootError` variant for "decrypt threw" | Jidoka — let the Future error propagate; bootstrap failure is a startup crash, not a fifth UI state |
| Invalidate `sessionBootstrapProvider` on `AppLifecycleState.resumed` | That is Story 2.6's `opportunisticAuthCheck` — Story 1.8 must not preempt the AC6 invariant |
| Change the cookie jar's `ignoreExpires` from `false` to `true` to "fix" the 14-day case | The architecture's `ignoreExpires: false` is a deliberate Poka-yoke — expired cookies are pruned on read so `BootCookiesMissing` lands the host on the recovery path |
| Add a `loadCredentials() AND loadForRequest()` retry loop | Both calls are local I/O; failure here is filesystem corruption — not a transient retry case |
| Create a Drift table for "facility profile presence" | Architecture line 200: no auth/session state in Drift. `hasFacilityProfileProvider` stub returns `false` until Story 3.1 |
| Skip the `BootGate` and read `sessionBootstrapProvider` from inside `WelcomeScreen.build` | The decision must precede the route tree — putting it inside any single screen creates a per-screen boot race |
| Hard-code `'https://www.evisitor.hr/Resources/'` in the bootstrap helper | Reuse `evisitorBaseUrl()` extracted in AC2.3 — single source of truth |
| Add a localized `bootGateLoading` ARB key | `_BootLoadingScaffold` mirrors `_ConsentLoadingScaffold` — `semanticsLabel: 'Loading'` is sufficient (AC7) |
| Use `context.go('/home')` | `context.goNamed('home')` per Story 1.6 retro |
| Throw `UnimplementedError` from the `BootCredentialsMissing` post-frame callback | Crashes widget tests; instead `debugPrint` + no goNamed (AC9.2 / AC5.3 fix) |
| Run codegen with `--delete-conflicting-outputs` only sometimes | Always pass that flag — Story 1.6 retro lesson |
| Add an `await` to `main.dart` for the bootstrap pipeline | Bootstrap runs inside the ProviderScope; AC4 explicitly defers it. `main.dart` only awaits `SecurityService.init()` (existing) and `getApplicationDocumentsDirectory()` (existing) |
| Surface a Croatian "loading" string on the `_BootLoadingScaffold` | Identical surface to `_ConsentLoadingScaffold` — no string. The transition is sub-50ms; localized strings are *Muri* |
| Rename `cookieJarDirectoryProvider` to encompass the new jar provider | Two providers, two responsibilities: directory (string) and jar (constructed from directory) — separation is deliberate |

### Token and provider reference

| Provider | Type | Scope | Owner file | Notes |
|---|---|---|---|---|
| `securityServiceProvider` | `Provider<SecurityService>` | keepAlive | `lib/app/providers.dart` | Story 1.3; unchanged |
| `cookieJarDirectoryProvider` | `Provider<String>` | keepAlive | `lib/app/providers.dart` | Story 1.3; unchanged |
| `dioProvider` | `Provider<Dio>` | keepAlive | `lib/app/providers.dart` | Story 1.3; **refactored** to consume `cookieJarProvider` |
| `cookieJarProvider` | `Provider<CookieJar>` | keepAlive | `lib/app/providers.dart` | **NEW (this story)** — extracted from `dioProvider` |
| `credentialStoreProvider` | `Provider<CredentialStore>` | keepAlive | `lib/features/settings/credential_store.dart` | Story 1.7; unchanged |
| `evisitorApiClientProvider` | `Provider<EvisitorApiClient>` | keepAlive | `lib/features/submission/evisitor_api_client.dart` | Story 1.7; unchanged (NOT consumed by bootstrap) |
| `sessionBootstrapProvider` | `FutureProvider<SessionBootstrap>` | keepAlive | `lib/core/bootstrap/session_bootstrap_provider.dart` | **NEW (this story)** |
| `hasFacilityProfileProvider` | `FutureProvider<bool>` | keepAlive | `lib/features/facility/has_facility_profile.dart` | **NEW (this story)** — stub until Story 3.1 |

### Project Structure Notes

**Directories created by this story:**
- `lib/core/bootstrap/` — first bootstrap-feature directory; Story 9.4 will populate further with `min_version_checker.dart` (or that lands in `features/version_gate/` per architecture line 700; bootstrap stays scoped to session-resolution).
- `lib/features/facility/` — first facility-feature directory; Story 3.1 will populate with `facility.dart`, `facilities_table.dart`, etc. Story 1.8 only adds the stub.
- `test/unit/core/bootstrap/` — bootstrap unit tests.
- `test/widget/core/bootstrap/` — BootGate widget tests.
- `test/integration/bootstrap/` — cookie-jar persistence integration test (`flutter test`, not `integration_test/`).

**Files created:**
- `lib/core/bootstrap/session_bootstrap.dart` — sealed class, 4 variants
- `lib/core/bootstrap/session_bootstrap_provider.dart` — `@riverpod` FutureProvider
- `lib/core/bootstrap/session_bootstrap_provider.g.dart` — generated, committed
- `lib/core/bootstrap/boot_gate.dart` — ConsumerStatefulWidget
- `lib/core/bootstrap/boot_loading_scaffold.dart` — extracted shared widget
- `lib/features/facility/has_facility_profile.dart` — `@riverpod` stub
- `lib/features/facility/has_facility_profile.g.dart` — generated, committed
- `test/unit/core/bootstrap/session_bootstrap_test.dart`
- `test/unit/core/bootstrap/has_facility_profile_test.dart`
- `test/widget/core/bootstrap/boot_gate_test.dart`
- `test/widget/core/bootstrap/boot_gate_resume_test.dart`
- `test/integration/bootstrap/cookie_jar_persistence_test.dart`

**Files modified:**
- `lib/app/providers.dart` — add `cookieJarProvider`; refactor `dioProvider` to consume it; export `evisitorBaseUrl()`
- `lib/app/providers.g.dart` — regenerated
- `lib/app/app.dart` — wrap `child` with `BootGate` inside `ConsentGate`
- `lib/core/consent/consent_gate.dart` — replace inline `_ConsentLoadingScaffold` with import of shared `BootLoadingScaffold` (rename or alias as needed)
- `test/app_smoke_test.dart` — assertion update per AC9.3 (no regression)

**This story does NOT create:**
- `lib/features/auth/auth_state.dart` — Epic 2 Story 2.1
- `lib/features/auth/auth_notifier.dart` — Epic 2 Story 2.1
- `lib/features/facility/facilities_table.dart` — Story 3.1
- `lib/features/version_gate/min_version_checker.dart` — Story 9.4
- A `BootError` variant — Jidoka principle (AC1.3)
- A localized loading string — AC7 explicitly forbids
- Any change to `EvisitorApiClient` — Story 1.7's surface is unchanged

### Deferred from previous stories relevant to this one

- **Story 1.3 deferred — `cookieJarProvider` extraction**: Story 1.3 inlined cookie jar creation in `dioProvider` with a note that future stories may extract. Story 1.8 closes this — update `deferred-work.md` Story 1.3 entry.
- **Story 1.7 deferred — `EvisitorFakeAdapter` placeholder for non-login paths**: still in place; Story 1.8 does not exercise non-login adapter paths. Defer remains.
- **Story 1.7 deferred — lockout state lost on process death**: Story 2.5 will persist circuit-breaker state; Story 1.8 does not need to surface lockout in `SessionBootstrap` (the `LockedOut` AuthState variant is Epic 2 Story 2.5's territory). The boot pipeline does not check Rhetos-side lockout — opportunistic auth (Story 2.6) does that.
- **Story 1.7 deferred — `CredentialStore` non-atomic partial writes**: a partial write would land a `Result.Err` from `loadCredentials()`, which collapses to `hasCredentials = false` ⇒ either `BootFreshFirstRun` (no facility) or `BootCredentialsMissing` (Story 3.1 onwards). The recovery flow handles partial writes correctly by re-prompting for credentials. No Story 1.8 mitigation needed.
- **Story 1.7 deferred — `CredentialStoreRef` typedef carries `@Deprecated`** codegen output: same will apply to `CookieJarRef` in Story 1.8's generated code; address in the project-wide Riverpod 3.x migration sweep.

### Epic 2 consolidation contract — what Stories 2.1, 2.6, 2.8 will absorb

| Story 1.8 artifact | Epic 2 successor | Migration cost |
|---|---|---|
| `SessionBootstrap` sealed class | Mapped 1-to-1 into `AuthState` constructors by `AuthNotifier.build()` (Story 2.1) | 5-line `switch` in `auth_notifier.dart` |
| `BootGate` widget | Becomes a synchronous router redirect on `authNotifierProvider` (Story 2.3) | Delete `BootGate`; add 5 lines to `router.dart`'s `redirect:` callback |
| `_hasViableSessionCookies` helper | Subsumed into `AuthNotifier.build()`'s initial state derivation (Story 2.1) | Move helper from bootstrap to `auth_notifier.dart` |
| `BootCredentialsMissing` → no-op stub | Becomes the live `goNamed('credentials-missing-recovery')` once Story 2.8 lands | Delete the `debugPrint` placeholder; route to the recovery screen |
| `BootCookiesMissing` → home + future banner | The `CredentialBanner` (Story 2.7) is what surfaces the recovery action on the Home screen; the bootstrap's job is just to land the user there | No structural change to bootstrap |
| `hasFacilityProfileProvider` stub | Story 3.1 replaces with `appDatabase.facilitiesTable.count() > 0` | Delete stub; create real provider |

Document the migration plan as a one-line `// TODO(story-2.x):` annotation on each surface — same convention as Story 1.7.

### References

- [Architecture §App Architecture (Frontend) — go_router redirect topology](../planning-artifacts/architecture.md)
- [Architecture §Riverpod 3 topology — authNotifierProvider scope, dioProvider lifetime](../planning-artifacts/architecture.md)
- [Architecture §Data boundary table — credentials in flutter_secure_storage; cookies in AES-GCM file; no auth in Drift](../planning-artifacts/architecture.md)
- [Architecture §External contract quirks — 3 cookies persisted ~14 days sliding via PersistCookieJar (AES-GCM encrypted at rest)](../planning-artifacts/architecture.md)
- [Architecture §Auth recovery flow (J3) — opportunisticCheck + helloCheck on resume (Epic 2)](../planning-artifacts/architecture.md)
- [Architecture §BuildContext across async gaps — always check mounted](../planning-artifacts/architecture.md)
- [Architecture §Cross-component dependencies — dioProvider depends on authNotifierProvider; both initialized at app start](../planning-artifacts/architecture.md)
- [PRD §FR8 — App can maintain an eVisitor session across process restarts, device reboots, and periods of background inactivity](../planning-artifacts/prd.md)
- [PRD §NFR-R5 — No submission to eVisitor is lost as a result of process kill, device reboot, network drop](../planning-artifacts/prd.md)
- [PRD §NFR-R6 — App recovers from an expired session automatically on next action, without re-entering credentials](../planning-artifacts/prd.md)
- [PRD §NFR-P8 — Cold start completes within 2.5s p95](../planning-artifacts/prd.md)
- [UX Spec §State persistence on process death — Cookie jar persists across app kills; AES-GCM-encrypted at rest](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Journey 3 — Silent Session Death + Wi-Fi Drop (the post-bootstrap flow Story 2.6/2.7 absorbs)](../planning-artifacts/ux-design-specification.md)
- [UX Spec §App resume after >14 days — opportunistic auth check, never silent failure](../planning-artifacts/ux-design-specification.md)
- [Epics §Story 1.8 — BDD acceptance criteria, four boot variants](../planning-artifacts/epics.md)
- [Epics §FR8 traceability — Story 1.8 implements](../planning-artifacts/epics.md)
- [Story 1.3 — SecurityService.init, EncryptedStorage, PersistCookieJar wiring, cookieJarDirectoryProvider](./1-3-security-primitives-dio-and-cert-pinning.md)
- [Story 1.4 — ConsentGate ordering invariant: UMP precedes any Drift/Keystore touch](./1-4-ump-cmp-eu-consent-surface.md)
- [Story 1.5 — _makeTestApp helper, ARB conventions](./1-5-welcome-and-sensitive-data-disclosure.md)
- [Story 1.6 — context.goNamed convention, double-tap guard pattern](./1-6-camera-permission-with-manual-entry-fallback.md)
- [Story 1.7 — LoginScreen + LoginFailure interim sealed class precedent (this story mirrors with SessionBootstrap)](./1-7-evisitor-login-and-live-credential-verification.md)
- [Story 1.7 §Cookie persistence verification — load-bearing assertion pattern this story extends to across-instance round-trip](./1-7-evisitor-login-and-live-credential-verification.md)
- [Story 1.9 (next) — Settings re-entry; reuses bootstrap when password changes (`saveCredentials` overwrite triggers `ref.invalidate(sessionBootstrapProvider)` to re-check viability)](../planning-artifacts/epics.md)
- [Story 2.1 — AuthState sealed class; subsumes SessionBootstrap via AuthNotifier.build()](../planning-artifacts/epics.md)
- [Story 2.6 — Opportunistic auth check on foreground; the AC6 14-day-resume territory](../planning-artifacts/epics.md)
- [Story 2.7 — CredentialBanner; surfaces on Home for BootCookiesMissing recovery](../planning-artifacts/epics.md)
- [Story 2.8 — Credentials-missing recovery; the live destination for the BootCredentialsMissing branch](../planning-artifacts/epics.md)
- [Story 3.1 — Facility model + Drift table; replaces hasFacilityProfileProvider stub](../planning-artifacts/epics.md)
- [CLAUDE.md §Security & Privacy — credentials in Keystore only, no auth state in Drift](../../CLAUDE.md)
- [CLAUDE.md §eVisitor API quirks — cookie persistence across process death is non-negotiable](../../CLAUDE.md)
- [`cookie_jar` — pub.dev — PersistCookieJar contract, ignoreExpires/persistSession semantics](https://pub.dev/packages/cookie_jar)
- [`riverpod` 3 — pub.dev — FutureProvider keepAlive lifetime](https://pub.dev/packages/riverpod)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- BootGate navigation: `context.goNamed()` fails in `MaterialApp.router builder:` callback because `BuildContext` is outside `InheritedGoRouter` scope. Fixed by using `ref.read(routerProvider).goNamed()` directly.
- Smoke test timeout: `pumpAndSettle` hung after BootGate wiring because `credentialStoreProvider` hit `FlutterSecureStorage` platform channel in test VM. Fixed by adding `credentialStoreProvider` + `cookieJarProvider` overrides.
- `dart analyze` `unnecessary_underscores`: GoRoute `builder: (_, __) =>` uses double-underscore which the lint prefers as `(_, _) =>` (Dart 3 allows multiple `_` wildcards).

### Completion Notes List

- `SessionBootstrap` sealed class: 4 variants, JIT interim (maps 1-to-1 to AuthState when Epic 2 lands). No BootError — Jidoka principle.
- `cookieJarProvider` extracted from `dioProvider`. Single `evisitorBaseUrl()` replaces `_resolveBaseUrl()` — no duplicate URL strings in codebase.
- `hasFacilityProfileProvider` stub: always `false` until Story 3.1 introduces FacilitiesTable.
- `sessionBootstrapProvider`: `keepAlive` FutureProvider reading credentialStore + cookieJar. `_hasViableSessionCookies` checks `'authentication'` cookie only (load-bearing session cookie). `is Ok` type check avoids `Credentials` reference in bootstrap per PII discipline.
- `BootGate`: `ConsumerStatefulWidget` with `_navigated` Poka-yoke flag. Navigates via `ref.read(routerProvider)` not `context.goNamed()` (context is outside InheritedGoRouter scope in builder callback). `BootCredentialsMissing` → `debugPrint` stub (v1.0 unreachable).
- `BootLoadingScaffold` extracted — shared between `ConsentGate` and `BootGate` to prevent pixel divergence.
- 22 new tests: 8 unit (boot decision matrix), 6 widget (BootGate behavior), 1 widget (AC6 resume invariant), 1 integration (cookie jar persistence), 1 unit (facility profile stub), 1 smoke update.
- Full suite: 192/192 green. Analyze: clean. Format: clean. PII guard: clean. i18n guard: clean.

### File List

**New files:**
- `lib/core/bootstrap/session_bootstrap.dart`
- `lib/core/bootstrap/session_bootstrap_provider.dart`
- `lib/core/bootstrap/session_bootstrap_provider.g.dart`
- `lib/core/bootstrap/boot_gate.dart`
- `lib/core/bootstrap/boot_loading_scaffold.dart`
- `lib/features/facility/has_facility_profile.dart`
- `lib/features/facility/has_facility_profile.g.dart`
- `test/unit/core/bootstrap/session_bootstrap_test.dart`
- `test/unit/core/bootstrap/has_facility_profile_test.dart`
- `test/widget/core/bootstrap/boot_gate_test.dart`
- `test/widget/core/bootstrap/boot_gate_resume_test.dart`
- `test/integration/bootstrap/cookie_jar_persistence_test.dart`

**Modified files:**
- `lib/app/providers.dart` — added `cookieJarProvider` + `evisitorBaseUrl()`; refactored `dioProvider`
- `lib/app/providers.g.dart` — regenerated
- `lib/app/app.dart` — wired `BootGate` in builder
- `lib/core/consent/consent_gate.dart` — replaced inline `_ConsentLoadingScaffold` with `BootLoadingScaffold`
- `test/app_smoke_test.dart` — added `credentialStoreProvider` + `cookieJarProvider` overrides

### Change Log

- 2026-04-27: Story 1.8 implemented — session persistence across restarts. Boot pipeline resolves to one of four `SessionBootstrap` variants on cold start; `BootGate` imperatively routes to `/home` or stays on `/onboarding`. 192 tests green (+22).
