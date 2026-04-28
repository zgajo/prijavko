# Story 2.1: AuthState Sealed Class & AuthNotifier Skeleton

Status: ready-for-dev

Satisfies: foundational for FR9, FR10, FR11, FR14, FR14.5 | NFR-I2, NFR-R6 — see [PRD §Functional Requirements](../planning-artifacts/prd.md#functional-requirements)

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want a single, exhaustively-typed representation of the authentication state machine, plus a Riverpod 3 `Notifier` that resolves the initial state from `sessionBootstrapProvider` and exposes the four canonical mutators,
so that every UI surface, every interceptor, and every error path reads from one source of truth — and a missing `SessionBootstrap → AuthState` transition or an out-of-notifier `state = X` mutation becomes a compile-time / CI-time impossibility.

## Acceptance Criteria

### AC1 — `AuthFailureReason` enum (single source for failure variants)

1. Create **`lib/core/errors/auth_failure_reason.dart`** declaring:
   ```dart
   /// Compile-time exhaustive failure reasons consumed by AuthState.AuthFailure.
   ///
   /// WHY in `lib/core/errors/` (not `lib/features/auth/`):
   /// architecture §Project Structure (line 650) places `auth_failure_reason.dart`
   /// inside `features/auth/`, BUT Story 2.2 lands `EvisitorErrorClass` at
   /// `lib/core/errors/`. Co-locating the auth-failure enum in the same package
   /// keeps "all classifier-adjacent enums" in one folder and keeps `features/auth/`
   /// focused on FSM + notifier code. This deviates from architecture line 650
   /// deliberately — record the deviation in the Project Structure Notes
   /// section so a future doc sweep updates the architecture doc, not the file.
   enum AuthFailureReason {
     sessionDead,
     credentialsInvalid,
     lockedOut,
     network,
     contractBreak,
   }
   ```
2. **WHY a top-level enum (not nested inside `AuthState`):** Dart enums declared
   inside sealed classes are syntactically forbidden. The enum is referenced by
   `AuthFailure(reason: ...)`, by future `EvisitorErrorClass → AuthFailureReason`
   mapping in Story 2.3, and by the `auth_state_transition` telemetry event in
   Epic 9. Single top-level declaration is the only sane shape.
3. **WHY exactly five variants (not the eight from `EvisitorErrorClass`):**
   `AuthFailureReason` is the *FSM-relevant* subset. `throttled | serverError |
   validationError` from Story 2.2's `EvisitorErrorClass` are non-auth concerns
   and must NOT collapse into `AuthFailure` — they bubble to per-call error
   handling. Story 2.3 owns the `EvisitorErrorClass → AuthFailureReason` mapping
   that drops the three irrelevant variants (or, on the failing branch, leaves
   AuthState untouched).
4. The enum file has zero Flutter imports. Pure Dart.

### AC2 — `AuthState` sealed class (seven variants — exact match to architecture §Auth state machine + Initial)

1. Create **`lib/features/auth/auth_state.dart`** declaring exactly seven `final class` subclasses of a `sealed class AuthState`:
   ```dart
   sealed class AuthState {
     const AuthState();
   }

   /// Synchronous pre-bootstrap window only — emitted exclusively while
   /// `sessionBootstrapProvider`'s future is `AsyncLoading`. Never produced by
   /// the SessionBootstrap → AuthState switch (AC3.2). The router's redirect
   /// callback (Story 2.3) treats `Initial` as "do not navigate yet".
   final class Initial extends AuthState {
     const Initial();
   }

   final class Unauthenticated extends AuthState {
     const Unauthenticated();
   }

   final class Authenticating extends AuthState {
     const Authenticating();
   }

   /// Successful auth. `facilitiesLoaded` flips to `true` once
   /// `facilityNotifierProvider` (Epic 3 Story 3.2) emits its first non-empty
   /// or empty-but-resolved snapshot. Today (Story 2.1) only the `false` shape
   /// is reachable — Story 3.2 owns the `true` transition.
   final class Authenticated extends AuthState {
     const Authenticated({required this.facilitiesLoaded});
     final bool facilitiesLoaded;
   }

   /// Cookies expired or undecryptable; credentials are still viable.
   /// Recovery: Story 2.4's `AuthNotifier.reauthenticate()` (today: stub).
   final class Reauth extends AuthState {
     const Reauth();
   }

   /// Client-side circuit breaker tripped. `retryAfter` is UTC.
   /// Today (Story 2.1) NO code emits `LockedOut` — the variant exists so the
   /// FSM is complete and exhaustive `switch` callers (router redirect, UI
   /// chips) can compile. Story 2.5 adds the only producer.
   final class LockedOut extends AuthState {
     const LockedOut({required this.retryAfter});
     final DateTime retryAfter;
   }

   final class AuthFailure extends AuthState {
     const AuthFailure({required this.reason});
     final AuthFailureReason reason;
   }
   ```
2. **WHY seven (architecture says six):** architecture §Auth state machine (line 220) lists six (no `Initial`). The epic AC explicitly mandates seven, with `Initial` reserved for the pre-bootstrap window. Without `Initial`, `AuthNotifier.build()` would have to invent a pseudo-default before `sessionBootstrapProvider` resolves — exactly the "implicit default" the FSM is meant to ban (Epic 1 retro §6 #2). The seventh variant is a Poka-yoke against a synchronous sentinel polluting the post-bootstrap surface.
3. **WHY `final class` (not `class`):** sealed-class subclasses are by default `class`, which permits further subclassing — opening a backdoor for a third-party extension that bypasses the exhaustive `switch` invariant. `final class` closes the door. Mirrors the `SessionBootstrap` shape from Story 1.8.
4. **WHY `Authenticated.facilitiesLoaded` is required (not nullable):** absent flag would leak the "we don't know yet" state into the type — and a router redirect that branches on `facilitiesLoaded` would be ambiguous on a `null`. Required `bool` forces every emit site to commit.
5. **WHY `LockedOut.retryAfter` UTC (not local):** `flutter_secure_storage` round-trip via Story 2.5's `LockoutStore` will use ISO-8601 strings; UTC-only is the contract. Document inline as `// retryAfter is UTC; format with .toLocal() for UI display.`
6. The file imports only `package:prijavko/core/errors/auth_failure_reason.dart`. No Flutter imports.
7. **`toString()` / `==` / `hashCode`:** explicitly NOT implemented. Equality on sealed-class variants in Dart 3 is identity-based by default — fine for the FSM (no two `Authenticated(facilitiesLoaded: false)` instances need to compare equal; consumers compare by `is` pattern).
8. **Re-exports:** `auth_state.dart` re-exports `AuthFailureReason` so consumers can `import 'package:prijavko/features/auth/auth_state.dart' show AuthState, AuthFailureReason, ...;` without a second import line. Keeps the public surface clean.

### AC3 — `AuthNotifier`: Riverpod 3 `Notifier<AuthState>` consuming `sessionBootstrapProvider`

1. Create **`lib/features/auth/auth_notifier.dart`** with:
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:prijavko/core/bootstrap/session_bootstrap.dart';
   import 'package:prijavko/core/bootstrap/session_bootstrap_provider.dart';
   import 'package:prijavko/core/errors/auth_failure_reason.dart';
   import 'package:prijavko/features/auth/auth_state.dart';
   import 'package:riverpod_annotation/riverpod_annotation.dart';

   part 'auth_notifier.g.dart';

   // WHY keepAlive: AuthState is process-lifetime — disposing on autoDispose
   // would lose `LockedOut` mid-countdown (Story 2.5) and force re-bootstrap
   // on every navigation. Architecture §Riverpod 3 topology line 315 mandates
   // global root scope.
   //
   // TODO(story-2.3): `AuthInterceptor.onError` will call
   //   `ref.read(authNotifierProvider.notifier).handleAuthFailure(...)`.
   //   The single permitted external mutator entry point.
   // TODO(story-2.4): `reauthenticate()` body — currently a stub that
   //   transitions to AuthFailure(credentialsInvalid) on call.
   // TODO(story-2.5): `consecutiveFailures` + `lockedUntil` fields and the
   //   real `LockedOut` producer. Today no code emits `LockedOut`.
   // TODO(story-2.x): `LoginNotifier` becomes a thin adapter; the screen
   //   calls `authNotifier.login(...)` directly.
   @Riverpod(keepAlive: true)
   class AuthNotifier extends _$AuthNotifier { ... }
   ```
2. **`build()` body (the load-bearing piece of this story):**
   ```dart
   @override
   AuthState build() {
     // WHY ref.listen (NOT fireImmediately, NOT await): build() must be
     // synchronous (architecture line 305 — go_router redirect reads state
     // synchronously). The bootstrap future drives `state =` updates AFTER
     // build returns; until then, the notifier emits whatever the synchronous
     // bootstrap snapshot resolves to.
     //
     // CRITICAL Riverpod 3 contract: `state = X` is FORBIDDEN during build().
     // We must NOT use `fireImmediately: true` on the listener — it would
     // invoke the callback synchronously (during build) and the callback
     // attempts a state assignment, which throws `StateError`. Instead:
     //   (a) Read the current AsyncValue synchronously and map it for the
     //       initial return value (covers the warm-cache hot-reload case
     //       where bootstrap is already resolved before AuthNotifier builds).
     //   (b) Listen WITHOUT fireImmediately for subsequent transitions
     //       (covers the cold-start case where bootstrap is `AsyncLoading`
     //       during build and resolves later).
     ref.listen<AsyncValue<SessionBootstrap>>(
       sessionBootstrapProvider,
       (previous, next) {
         next.whenData(_applyBootstrapTransition);
       },
     );
     final snapshot = ref.read(sessionBootstrapProvider);
     return snapshot.maybeWhen(
       data: _mapBootstrapToAuthState,
       orElse: () => const Initial(),
     );
   }
   ```
3. **`_mapBootstrapToAuthState(SessionBootstrap)` — pure function, the EXHAUSTIVE switch (Epic 1 retro §6 #2):**
   ```dart
   AuthState _mapBootstrapToAuthState(SessionBootstrap bootstrap) {
     // WHY exhaustive switch (not `if/else`): adding a fifth SessionBootstrap
     // variant later breaks compilation HERE — forcing a deliberate update
     // (Poka-yoke per Epic 1 retro action item §6 #2). Implicit defaults are
     // banned: every variant maps to exactly one AuthState constructor.
     return switch (bootstrap) {
       BootFreshFirstRun() => const Unauthenticated(),
       BootSessionLive() => const Authenticated(facilitiesLoaded: false),
       BootCookiesMissing() => const Reauth(),
       BootCredentialsMissing() =>
         const AuthFailure(reason: AuthFailureReason.credentialsInvalid),
     };
   }

   void _applyBootstrapTransition(SessionBootstrap bootstrap) {
     state = _mapBootstrapToAuthState(bootstrap);
   }
   ```
   - **WHY two helpers (one pure, one with side effect):** the listener at AC3.2 needs the side-effecting `_applyBootstrapTransition` (post-build state assignment). The build-time initial-return path needs the pure `_mapBootstrapToAuthState` (no state assignment). Sharing the switch keeps the table in one place — adding a new SessionBootstrap variant breaks BOTH at compile time, not just the listener.
4. **Mapping table (must appear verbatim in the story-file Dev Notes section AND as a top-of-file doc comment in `auth_notifier.dart`):**

   | `SessionBootstrap` (Story 1.8) | `AuthState` (this story) | Rationale |
   |---|---|---|
   | `BootFreshFirstRun` | `Unauthenticated()` | No credentials, no facility cache → onboarding flow drives login. |
   | `BootSessionLive` | `Authenticated(facilitiesLoaded: false)` | Credentials + cookies viable; facilities load lazily (Epic 3 Story 3.2). |
   | `BootCookiesMissing` | `Reauth()` | Credentials viable, cookies expired/undecryptable → silent re-auth (Story 2.4 wires the producer). |
   | `BootCredentialsMissing` | `AuthFailure(reason: credentialsInvalid)` | Facility profile exists but Keystore is empty → recovery flow (Story 2.8). |

5. **`Initial` is never produced by `_mapBootstrapToAuthState`.** It is emitted ONLY as the `build()` return value during the synchronous pre-bootstrap window — when `ref.read(sessionBootstrapProvider)` returns `AsyncLoading` or `AsyncError`. Once the listener fires with `AsyncData`, the switch emits one of the four mapped variants. A test (AC7.2) asserts the switch is exhaustive and that no other variant can land in `state` during boot.
6. **`Initial` is not legal post-bootstrap.** A second listener emission with `AsyncLoading` (e.g. someone calls `ref.invalidate(sessionBootstrapProvider)` mid-life) must NOT revert state to `Initial`. The `whenData` filter above ignores `AsyncLoading` and `AsyncError`. **WHY:** invalidation followed by re-resolution should be a transparent re-derivation, not a UI flash through the loading scaffold.
7. **`AsyncError` from the listener:** any error in `sessionBootstrapProvider`'s pipeline propagates per the Story 1.8 Jidoka contract (`BootGate` rethrows). Therefore, by the time `AuthNotifier.build()` runs, the bootstrap pipeline has either resolved (`AsyncData`) or crashed (handled by the surrounding `BootGate`). The listener's `whenData` filter is correct: in practice the only emitted variant on the runtime hot path is `AsyncData`. Document this invariant inline.
8. **Hot-reload / warm-cache case:** because `sessionBootstrapProvider` is `keepAlive`, a hot reload of `auth_notifier.dart` rebuilds the notifier while the bootstrap result is still cached as `AsyncData`. The synchronous `ref.read` at AC3.2 covers this: `build()` returns the mapped state directly without flashing through `Initial`. A test (AC7.2 — fifth case) asserts this behavior.

### AC4 — Public method signatures (skeleton bodies; Stories 2.2 / 2.3 / 2.4 / 2.5 fill them)

1. **`Future<void> login({required String username, required String password})`** — minimal functional implementation:
   ```dart
   Future<void> login({required String username, required String password}) async {
     // Poka-yoke against double-submit / re-entrancy.
     if (state is Authenticating) return;
     state = const Authenticating();

     final apiClient = ref.read(evisitorApiClientProvider);
     final result = await apiClient.login(userName: username, password: password);

     state = switch (result) {
       Ok() => const Authenticated(facilitiesLoaded: false),
       // Story 2.1 ships a SHALLOW LoginFailure → AuthFailureReason mapping.
       // Story 2.3 replaces this with the EvisitorErrorClassifier output.
       Err(:final error) => AuthFailure(reason: _shallowMap(error)),
     };
   }

   AuthFailureReason _shallowMap(LoginFailure failure) => switch (failure) {
     CredentialsInvalid() => AuthFailureReason.credentialsInvalid,
     // Story 2.5 owns the real LockedOut transition + persistence.
     // For Story 2.1 the FSM treats AccountLockedOut as credentialsInvalid
     // (the closest non-LockedOut variant); a unit test asserts this stop-gap
     // is intentional with a `// stop-gap until Story 2.5` annotation.
     AccountLockedOut() => AuthFailureReason.credentialsInvalid,
     NetworkUnreachable() => AuthFailureReason.network,
     ServerError() => AuthFailureReason.contractBreak,
     ContractBreak() => AuthFailureReason.contractBreak,
   };
   ```
   - **WHY `Future<void>` (not `Future<Result<void, Failure>>`):** the screen reads state via `ref.watch(authNotifierProvider)` — the `Result` would be lossy (the screen needs the full `AuthFailureReason` not a generic `Failure`). The state IS the result. This is the architecture's "Auth error routing — single entry point" rule (line 510) applied: callers pattern-match on state, not on a returned envelope.
   - **WHY this story (2.1) wires `login()` rather than deferring**: the AC tests "every transition path is tested" (epic line 798) require `login()` functional enough to drive `Initial → Authenticating → Authenticated`, `Authenticating → AuthFailure(credentialsInvalid)`, and `Authenticating → AuthFailure(network)`. Stub-only would block testing. The shallow `LoginFailure → AuthFailureReason` mapping is the JIT-correct interim — Story 2.3 swaps it for the real classifier.
   - **WHY NOT yet wire `LoginScreen.submit()` to `authNotifier.login()`**: that is a separate migration touching `login_screen.dart`, `login_notifier.dart`, and 50+ tests. Out of scope per Epic 1 retro action item A3 (story-size red flag). Document the deferred migration in Project Structure Notes — Story 2.x picks it up.
   - **`evisitorApiClientProvider` and `LoginFailure`** are imported from existing Story 1.7 code; no new types.

2. **`Future<void> reauthenticate()` — STUB:**
   ```dart
   Future<void> reauthenticate() async {
     // TODO(story-2.4): load credentials, call EvisitorApiClient.login,
     // transition to Authenticated | AuthFailure(credentialsInvalid) |
     // LockedOut.
     // Today: a no-op that surfaces the credentials-missing flow if invoked
     // from the route-redirect path. The interceptor (Story 2.3) will not
     // call this until 2.4 lands.
     state = const AuthFailure(reason: AuthFailureReason.credentialsInvalid);
   }
   ```
   - **WHY a deliberately-broken stub (not `throw UnimplementedError`):** an unimplemented exception would crash the app the first time the route redirect from Story 2.3's interim wiring evaluates `Reauth → reauthenticate()`. A state transition keeps the FSM well-formed and routes the user via the credentials-missing flow until Story 2.4 fills in. A unit test asserts the stub behavior with a `// stop-gap until Story 2.4` annotation.

3. **`void handleAuthFailure(AuthFailureReason reason)` — interim signature:**
   ```dart
   void handleAuthFailure(AuthFailureReason reason) {
     // Hand-coded transition table — Story 2.3 replaces the parameter with
     // EvisitorErrorClass and Story 2.2's classifier produces the input.
     state = switch (reason) {
       AuthFailureReason.sessionDead => const Reauth(),
       AuthFailureReason.credentialsInvalid =>
         const AuthFailure(reason: AuthFailureReason.credentialsInvalid),
       AuthFailureReason.lockedOut =>
         // Story 2.5 owns the `retryAfter` source (server header or client
         // breaker). Until then, emit a 6-minute placeholder so the UI can
         // render the LockedOut chip variant — but log a stop-gap warning.
         LockedOut(retryAfter: DateTime.now().toUtc().add(const Duration(minutes: 6))),
       AuthFailureReason.network =>
         const AuthFailure(reason: AuthFailureReason.network),
       AuthFailureReason.contractBreak =>
         const AuthFailure(reason: AuthFailureReason.contractBreak),
     };
   }
   ```
   - **WHY parameter type is `AuthFailureReason` (not `EvisitorErrorClass`):** `EvisitorErrorClass` is Story 2.2's deliverable. Adopting it here would force Story 2.1 to ship the enum file at `lib/core/errors/evisitor_error_class.dart` AND the classifier function — bloating the story past the size red flag (Epic 1 retro action item A3). The interim signature is the JIT shape; Story 2.3's wiring step will refactor `handleAuthFailure(EvisitorErrorClass)` and update all call sites in one commit.
   - **TODO line in source:** `// TODO(story-2.3): change parameter type to EvisitorErrorClass once Story 2.2 lands the enum and classifier; the AuthInterceptor (Story 2.3) is the only call site.`

4. **`Future<void> logout()` — minimal:**
   ```dart
   Future<void> logout() async {
     // Wipe credentials and cookie jar; transition to Unauthenticated.
     await ref.read(credentialStoreProvider).wipeCredentials();
     // TODO(story-2.x): jar.deleteAll() once the eVisitor host scope is
     // documented as a const. For Story 2.1 the credential wipe is sufficient
     // — sessionBootstrap re-evaluation on next cold start lands on
     // BootFreshFirstRun (no credentials → no facility check needed).
     state = const Unauthenticated();
   }
   ```
   - **WHY ship `logout()` now (not defer):** `LockedOut` and the credentials-missing recovery path both need a clean way to reset the FSM. Test (AC7.4) asserts logout transitions to `Unauthenticated` and clears the Keystore.
   - `credentialStoreProvider.wipeCredentials()` already exists from Story 1.3.

5. **No other public methods.** Specifically NOT exposed:
   - `setLockedOut(...)` — Story 2.5
   - `markFacilitiesLoaded()` — Epic 3 Story 3.2
   - `opportunisticAuthCheck()` — Story 2.6

### AC5 — Wiring: `dioProvider` does NOT yet read `authNotifierProvider`

1. Story 2.1 introduces the `AuthNotifier` but does NOT yet wire it into `dioProvider` (the `AuthInterceptor` is Story 2.3's deliverable). The architecture's "Cross-component dependencies" line 369 ("`dioProvider` depends on `authNotifierProvider`") becomes true in Story 2.3.
2. **Why this split:** wiring the interceptor today would force Story 2.1 to ship a `QueuedInterceptor` subclass + `EvisitorErrorClassifier` (Story 2.2) at the same time. Both belong to their own stories. The split is per-task-commit hygiene (Epic 1 retro A1).
3. **Concrete deferred surface:** the existing `// TODO(story-2.3): add redirect callback reading authNotifierProvider` line in `lib/app/router.dart` stays untouched. Story 2.3 adds the interceptor; Story 2.3 also adds the redirect.
4. **What this story DOES change in `lib/app/`:** nothing. `app.dart`, `providers.dart`, `router.dart` are unchanged. The only reachable consumer of `authNotifierProvider` in Story 2.1 is the test suite.

### AC6 — CI grep guard against external `state = X` mutations

1. Add a new GitHub Actions workflow file at **`.github/workflows/auth-state-mutation-guard.yml`** (separate from `pii_guard.yml` — the two guards have orthogonal failure modes; a future regex change to one must not risk weakening the other):
   ```yaml
   - name: Forbid external AuthNotifier.state assignment
     run: |
       MATCHES=$(grep -rEn \
         '(authNotifier\.state\s*=|authNotifierProvider\.notifier\.state\s*=)' \
         lib/ test/ integration_test/ \
         --include='*.dart' \
         || true)
       if [ -n "$MATCHES" ]; then
         echo "::error::External AuthNotifier.state assignment forbidden:"
         echo "$MATCHES"
         exit 1
       fi
   ```
2. **WHY a CI grep guard (not a Dart lint):** there is no analyzer rule for "the `state` setter is private to the class". `Notifier.state` is `protected` in spirit but `public` in Dart. The grep guard is the cheapest enforcement; it runs in <1s.
3. **Scope the guard to forbid only the EXTERNAL assignment patterns above.** Internal assignments inside `auth_notifier.dart` (`state = const Authenticated(...)`) are fine — the regex matches `authNotifier.state =` and `authNotifierProvider.notifier.state =`, not bare `state =`.
4. **One legitimate-looking false-positive case to rule out**: a comment in `auth_notifier.dart` itself that mentions the forbidden pattern (e.g. for documentation). The regex only fires on actual code lines because it requires the leading qualifier; doc-string quotes around the pattern still match. Mitigation: the file `auth_notifier.dart` documents the forbidden pattern in a fenced ASCII block (no `authNotifier.` prefix in plain English) so the regex does not catch it. Verified by running the grep locally before committing.
5. **Architecture Anti-Pattern Reference table update:** the table (architecture line 583, "`notifier.state = X` from outside the notifier" → "Call an `AuthNotifier` method") already documents the rule. No doc change needed in 2.1; the new artifact is the CI gate.
6. **Test-suite exemption:** none. Tests interact with the notifier only via `container.read(authNotifierProvider.notifier).login(...)`-style method calls, never via direct `state =`. If a test ever needs to seed a state for assertion convenience, it constructs a fresh `ProviderContainer` with an override — never mutates a live notifier's state.

### AC7 — Tests

The test count baseline at end of Story 1.9 (post-review) is 206. Story 2.1 adds **~14 new** unit tests; final ≈ 220.

1. **`test/unit/features/auth/auth_state_test.dart`** — sealed class shape and exhaustiveness:
   - All seven variants are constructible with the documented parameter contracts.
   - **Exhaustiveness Poka-yoke**: a function `String describe(AuthState s) => switch (s) { ... }` covers all seven; the test's mere existence (compile-time exhaustive switch) is the assertion. **Add a comment in the test file**: `// If a new AuthState variant is added without updating describe(), this file fails to compile — by design.`
   - `Authenticated.facilitiesLoaded` round-trips both `true` and `false`.
   - `LockedOut.retryAfter` is preserved verbatim.
   - `AuthFailure.reason` round-trips all five `AuthFailureReason` values.

2. **`test/unit/features/auth/auth_notifier_bootstrap_test.dart`** — every `SessionBootstrap` variant maps to the correct `AuthState`:
   - For each of the four `SessionBootstrap` subclasses, override `sessionBootstrapProvider` to emit `AsyncData(variant)`, build the notifier, assert `container.read(authNotifierProvider)` equals the mapped `AuthState`. (Warm-cache path: `build()`'s synchronous `ref.read` returns the mapped state directly.)
   - **A fifth test** (cold-start path): override `sessionBootstrapProvider` to keep returning `AsyncLoading` for one frame; build the notifier; assert state is exactly `Initial`. Then override again with `AsyncData(BootSessionLive)`; pump the listener; assert state transitions to `Authenticated(facilitiesLoaded: false)`. This is the "Initial is reserved for pre-bootstrap" Poka-yoke AND verifies the post-build listener path.
   - **A sixth test** (`AsyncError` does NOT regress to `Initial`): seed the notifier in `Authenticated(...)`; emit `AsyncLoading` then `AsyncError` from `sessionBootstrapProvider`; assert state remains `Authenticated`. The `whenData` filter is the production guarantee (AC3.6).
   - **Test infrastructure:** override `sessionBootstrapProvider` with `AsyncValue.data(...)` / `AsyncValue.loading()` / `AsyncValue.error(...)` via Riverpod 3's `overrideWith` factory on a fresh `ProviderContainer` per test. No real Keystore, no real cookie jar — bootstrap is bypassed entirely.
   - **Tautological-test self-check (Epic 1 retro A4):** the test verifies the *result of the switch*, not just that a state was emitted. Mutating the production switch (e.g. swapping the `BootCookiesMissing → Reauth` mapping for `Authenticated`) MUST cause this test to fail.

3. **`test/unit/features/auth/auth_notifier_transitions_test.dart`** — every transition path the FSM allows in Story 2.1's surface:
   - `Initial → Authenticating → Authenticated(facilitiesLoaded: false)` — happy path through `login()` with `EvisitorFakeAdapter` scripted to `loginSuccess`.
   - `Authenticating → AuthFailure(credentialsInvalid)` — fake adapter scripts `loginCredsInvalid`.
   - `Authenticating → AuthFailure(network)` — fake adapter scripts `loginNetworkUnreachable`.
   - `Authenticating → AuthFailure(credentialsInvalid)` for `AccountLockedOut` failure (the "stop-gap until Story 2.5" mapping). The test name explicitly references the stop-gap; if Story 2.5 changes the mapping, this test reminds the developer to delete the stop-gap.
   - `Authenticated → Reauth` via `handleAuthFailure(sessionDead)`.
   - `Authenticated → AuthFailure(credentialsInvalid)` via `handleAuthFailure(credentialsInvalid)`.
   - `Authenticated → AuthFailure(network)` via `handleAuthFailure(network)`.
   - `Reauth → AuthFailure(credentialsInvalid)` via `reauthenticate()` — the "stop-gap until Story 2.4" stub.
   - `Authenticated → Unauthenticated` via `logout()`; assert `wipeCredentials` was called on the fake credential store.
   - `Authenticating → Authenticating` is a no-op when called twice (re-entrancy guard at the start of `login`); assert that the second call does NOT issue a second `apiClient.login` invocation.
   - `Initial` cannot be re-entered after the bootstrap listener has fired once (re-emit `AsyncLoading` on `sessionBootstrapProvider` overrideWith → assert state stays whatever it was, not `Initial`).
   - `LockedOut → ...` deliberately NOT tested in Story 2.1: the only producer is Story 2.5, which owns the inbound transitions. The FSM's outbound `LockedOut → Unauthenticated` is also Story 2.5's concern.

4. **CI grep guard self-test**: a small `bash` script invoked by `scripts/check-auth-state-guard.sh` is sufficient — but to keep things visible, add a single Dart unit test (`test/unit/ci/auth_state_guard_smoke_test.dart`) that uses `Process.runSync('grep', [...])` to assert zero matches across `lib/`. Skip this test if running on Windows (no grep). **WHY a Dart test in addition to the CI job:** local `flutter test` runs catch the violation before the developer pushes — same shape as Story 1.7's PII-guard local test.

5. **Test infrastructure shared with Story 1.8/1.9:**
   - Reuse `EvisitorFakeAdapter` from `test/fakes/evisitor_fake_adapter.dart` (Story 1.7 — already scripts `loginSuccess`, `loginCredsInvalid`, `loginNetworkUnreachable`, `loginAccountLocked`).
   - Reuse `FakeCredentialStore` from `test/fakes/fake_credential_store.dart` (Story 1.7).
   - Reuse `FakeSecurityService` from `test/fakes/fake_security_service.dart` (Story 1.3).
   - **No new test fakes** are introduced by this story.

6. **No widget tests:** Story 2.1 ships zero UI surface. The `LoginScreen.submit()` → `authNotifier.login()` migration is deferred to a follow-up. Today's `LoginScreen` continues calling `loginNotifierProvider`. A future story will add a widget test asserting the login screen drives the `AuthNotifier` end-to-end; not in 2.1 scope.

7. **No integration tests:** likewise. Story 2.3's `AuthInterceptor` integration test (10 concurrent sessionDead requests → exactly one `POST /Login`) is the natural integration test for the auth FSM. 2.1 unit-tests cover the FSM in isolation.

### AC8 — Validation gate

1. `flutter test` — all existing tests green + ~13 new unit tests; ~219 total. Zero deletions.
2. `dart analyze --fatal-warnings --fatal-infos` — clean.
3. `dart format --set-exit-if-changed lib test integration_test` — clean.
4. **PII / credential grep guard** (existing `pii_guard.yml` job) — clean.
5. **AuthNotifier external-mutation grep guard** (new — AC6) — passes locally and in CI.
6. **i18n literal-string guard**: `lib/features/auth/auth_notifier.dart` and `lib/features/auth/auth_state.dart` and `lib/core/errors/auth_failure_reason.dart` contain zero user-facing Croatian or English strings. They are pure logic / type files; localization is done at the screen layer (Story 2.7's `CredentialBanner`, Story 2.9's Settings chip).
7. **Codegen freshness**: `dart run build_runner build --delete-conflicting-outputs` produces no diff after running. `auth_notifier.g.dart` is committed.
8. **Manual smoke against fake env** (`flutter run --dart-define=EVISITOR_ENV=fake`):
   - Cold start with no credentials → `BootFreshFirstRun` → `AuthNotifier` resolves to `Unauthenticated`. (Verify via a temporary `debugPrint` in `auth_notifier.dart` — REMOVE before commit.)
   - Sign in via the existing Story 1.7 LoginScreen path → `AuthNotifier` is independent of `LoginNotifier` (no migration in 2.1) so its state stays `Unauthenticated`. **This is the expected interim behavior**; flagged in commit message + Project Structure Notes so the next reviewer doesn't think it's a regression.
   - Force-stop the app and cold start with seeded credentials + cookies → `BootSessionLive` → `AuthNotifier` resolves to `Authenticated(facilitiesLoaded: false)`.

---

## Tasks / Subtasks

- [ ] Task 1 — `AuthFailureReason` enum (AC: #1)
  - [ ] Subtask 1.1 — Create `lib/core/errors/auth_failure_reason.dart` per AC1.1; document the architecture-doc deviation (AC1.1 §WHY) in the file header.
  - [ ] Subtask 1.2 — Verify no existing call site references `AuthFailureReason` (`grep -rn AuthFailureReason lib/ test/`); the symbol is brand-new.

- [ ] Task 2 — `AuthState` sealed class (AC: #2)
  - [ ] Subtask 2.1 — Create `lib/features/auth/auth_state.dart` per AC2.1 with all seven `final class` subclasses.
  - [ ] Subtask 2.2 — Re-export `AuthFailureReason` per AC2.8.
  - [ ] Subtask 2.3 — Verify `dart analyze` is clean; verify exhaustive `switch` in a scratch file (`test/unit/features/auth/auth_state_test.dart`'s `describe(...)` helper is the production proof).

- [ ] Task 3 — `AuthNotifier` skeleton (AC: #3, #4)
  - [ ] Subtask 3.1 — Create `lib/features/auth/auth_notifier.dart` with `@Riverpod(keepAlive: true) class AuthNotifier extends _$AuthNotifier` per AC3.
  - [ ] Subtask 3.2 — Implement `build()` with `ref.listen<AsyncValue<SessionBootstrap>>` per AC3.2.
  - [ ] Subtask 3.3 — Implement `_applyBootstrapTransition` exhaustive switch per AC3.3 (the EPIC-1-retro §6 #2 mandate).
  - [ ] Subtask 3.4 — Add the SessionBootstrap → AuthState mapping table as a top-of-file doc comment per AC3.4.
  - [ ] Subtask 3.5 — Implement `login(...)` per AC4.1; `_shallowMap(LoginFailure → AuthFailureReason)` per AC4.1 §sub-stop-gap.
  - [ ] Subtask 3.6 — Implement `reauthenticate()` stub per AC4.2.
  - [ ] Subtask 3.7 — Implement `handleAuthFailure(AuthFailureReason)` per AC4.3.
  - [ ] Subtask 3.8 — Implement `logout()` per AC4.4.
  - [ ] Subtask 3.9 — Run `dart run build_runner build --delete-conflicting-outputs`; commit `auth_notifier.g.dart`.
  - [ ] Subtask 3.10 — Verify no consumer of `authNotifierProvider` is wired into `dioProvider` or `router.dart` (AC5 — those wirings belong to Story 2.3).

- [ ] Task 4 — CI grep guard (AC: #6)
  - [ ] Subtask 4.1 — Add `.github/workflows/auth-state-mutation-guard.yml` per AC6.1 (dedicated workflow — orthogonal to `pii_guard.yml`).
  - [ ] Subtask 4.2 — Add `scripts/check-auth-state-guard.sh` that the CI workflow invokes; mirrors the local `flutter test` smoke (Subtask 5.4).
  - [ ] Subtask 4.3 — Run the guard locally; verify zero matches.

- [ ] Task 5 — Tests (AC: #7)
  - [ ] Subtask 5.1 — `test/unit/features/auth/auth_state_test.dart` — sealed-class shape + exhaustive `describe(...)` helper per AC7.1.
  - [ ] Subtask 5.2 — `test/unit/features/auth/auth_notifier_bootstrap_test.dart` — 4 mapping tests + 1 `Initial` cold-start test + 1 `AsyncError` regression-guard test per AC7.2.
  - [ ] Subtask 5.3 — `test/unit/features/auth/auth_notifier_transitions_test.dart` — 11 transition tests per AC7.3.
  - [ ] Subtask 5.4 — `test/unit/ci/auth_state_guard_smoke_test.dart` — local grep self-test per AC7.4 (skip on Windows).
  - [ ] Subtask 5.5 — Run `flutter test` — green; ~220 total (206 baseline + ~14 new).

- [ ] Task 6 — Validation gate (AC: #8)
  - [ ] Subtask 6.1 — `flutter test` — green.
  - [ ] Subtask 6.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [ ] Subtask 6.3 — `dart format --set-exit-if-changed lib test integration_test` — clean.
  - [ ] Subtask 6.4 — Existing `pii_guard.yml` — clean (per AC8.4).
  - [ ] Subtask 6.5 — New AuthNotifier external-mutation guard — clean (per AC8.5).
  - [ ] Subtask 6.6 — i18n literal-string guard — clean (per AC8.6).
  - [ ] Subtask 6.7 — Build runner is up to date; no codegen diff (per AC8.7).
  - [ ] Subtask 6.8 — Manual smoke deferred to user per AC8.8 (emulator required).

---

## Dev Notes

### Why this story is first in Epic 2

Epic 1 closed with five Epic-2-blocking handovers in place: `Result<T, Failure>` (Story 1.3), `EvisitorApiClient.login()` returning typed `Result<void, LoginFailure>` (1.7), `LoginFailure` interim sealed class (1.7), `SessionBootstrap` interim sealed class (1.8), and a `// TODO(story-2.3): add redirect callback reading authNotifierProvider` line in `router.dart`. Story 2.1 is the keystone that wires the FSM into existence so every later Epic 2 story has a single, typed, exhaustively-pattern-matchable target.

**Concretely, what 2.1 unlocks:**
- Story 2.2's `EvisitorErrorClassifier` has a typed consumer (`AuthFailureReason`).
- Story 2.3's `AuthInterceptor` has a `Notifier` to call into.
- Story 2.4's `reauthenticate()` has a body to fill (the stub from AC4.2 becomes the real one).
- Story 2.5's circuit breaker has fields to add (`consecutiveFailures` + `lockedUntil`) on a notifier that already exists.
- Story 2.7's `CredentialBanner` has a state stream to watch.
- Story 2.9's Settings chip has the same state stream.
- Stories 3.2 / 3.5 / 4.5 / 5.5 / 6.4 / 6.6 / 6.7 / 7.3 all consume `authNotifierProvider` for guarding scan/send/closure paths.

If 2.1 is wrong, every downstream story compounds the wrongness. That is why the Epic 1 retro §6 #2 explicitly mandated the `SessionBootstrap → AuthState` transition table — it is the load-bearing handshake.

### Architecture mandates (non-negotiable)

- **Feature/core boundary**: `AuthState` and `AuthNotifier` live in `lib/features/auth/` per architecture line 650. `AuthFailureReason` is moved to `lib/core/errors/` to co-locate with Story 2.2's `EvisitorErrorClass` — deliberate deviation from architecture line 650 documented in AC1.1.
- **`@riverpod` codegen only**: `AuthNotifier` uses `@Riverpod(keepAlive: true)`. No manual `NotifierProvider(...)`. Generated `auth_notifier.g.dart` committed.
- **`keepAlive: true`** on `authNotifierProvider`: process-lifetime FSM. `autoDispose` would lose `LockedOut` countdown (Story 2.5) and force re-bootstrap on every navigation. Architecture §Riverpod 3 topology line 315.
- **`Notifier<AuthState>` (not `AsyncNotifier`)**: synchronous state lookup is required by go_router's redirect callback (Story 2.3). The bootstrap pipeline's async-ness is bridged via `ref.listen` inside `build()` — never via the notifier's return type.
- **Drift-as-truth NOT applicable**: Story 2.1 creates no Drift tables and writes nothing to Drift. Architecture line 200: "no auth state in Drift — ever."
- **Result contract justification**: `AuthNotifier.login()` returns `Future<void>`, NOT `Future<Result<void, Failure>>`. The state IS the result — see AC4.1 §WHY. This is the single deliberate exemption from the project-wide `Result<T, Failure>` rule, mirroring architecture line 510 ("Auth error routing — single entry point").
- **`Single Dio instance`**: unchanged in Story 2.1. `dioProvider` does not yet read `authNotifierProvider`. Story 2.3 adds the wiring.
- **`mounted` check after async gaps**: not applicable to `AuthNotifier` (no `BuildContext`). The `_disposed` flag pattern from `LoginNotifier` (Story 1.7 line 26) is also not needed for 2.1 because `Notifier`'s `ref.onDispose` semantics handle the autoDispose case (and we are keepAlive — never disposed).
- **`FLAG_SECURE` not applicable**: bootstrap renders no PII, no credentials. `LoginScreen` (Story 1.7) handles `FLAG_SECURE`; the notifier itself does not surface UI.
- **`directives_ordering` lint** (Story 1.6 retro): package imports alphabetical in a single block.
- **`BuildContext across async gaps`**: not applicable; `AuthNotifier` does not use `BuildContext`.

### Routing pipeline — what doesn't change in 2.1

The widget-tree wrapping order on cold start is unchanged from Story 1.9: `ProviderScope` → `MaterialApp.router` → `ConsentGate` → `BootGate` → `Router`. Story 2.1 adds no widgets; it adds only the notifier + types.

The router's `redirect:` callback is still empty (the `// TODO(story-2.3):` line is untouched). Cold-start navigation still flows through `BootGate.goNamed('home')` exactly as Story 1.8 wired it. Story 2.3 will replace `BootGate`'s imperative navigation with a synchronous router redirect reading `authNotifierProvider` — at which point `BootGate` becomes a `BootLoadingScaffold` pass-through (or is deleted entirely).

### `SessionBootstrap → AuthState` transition table — the load-bearing handshake (Epic 1 retro §6 #2)

| `SessionBootstrap` (Story 1.8) | `AuthState` (Story 2.1) | Reachable in v1.0? | Story to verify producer |
|---|---|---|---|
| `BootFreshFirstRun` | `Unauthenticated()` | YES | 1.8 — currently the most reached path |
| `BootSessionLive` | `Authenticated(facilitiesLoaded: false)` | YES | 1.8 — reached after Story 1.7 login |
| `BootCookiesMissing` | `Reauth()` | YES (after 14-day session expiry) | 2.4 + 2.7 (recovery flow) |
| `BootCredentialsMissing` | `AuthFailure(reason: credentialsInvalid)` | NO (until Story 3.1 ships `FacilitiesTable`) | 2.8 (recovery screen) |

**A fifth `SessionBootstrap` variant introduced later (e.g. `BootStorageCorrupted`)** must compile-break `_applyBootstrapTransition` in `auth_notifier.dart`. The exhaustive `switch` is the Poka-yoke (AC3.3 §WHY).

### Result contract justification — why interim shallow `LoginFailure → AuthFailureReason` mapping

Story 2.1's `login()` shallow-maps `LoginFailure` (5 variants, Story 1.7) to `AuthFailureReason` (5 variants, Story 2.1). Story 2.3 will replace this with the full `EvisitorErrorClassifier` output (`EvisitorErrorClass` → `AuthFailureReason`). The shallow map is the JIT-correct interim:

- `CredentialsInvalid → credentialsInvalid` — exact.
- `AccountLockedOut → credentialsInvalid` — **stop-gap until Story 2.5**. Today, the Story 1.7 6-minute timer drives the lockout UI on the screen; the FSM treats it as credentialsInvalid. Story 2.5 adds the real `LockedOut` transition path.
- `NetworkUnreachable → network` — exact.
- `ServerError → contractBreak` — best fit; Story 2.3's classifier will distinguish `serverError` (5xx, retry-able) from `contractBreak` (unparseable, forced-update territory).
- `ContractBreak → contractBreak` — exact.

Each stop-gap mapping is annotated with `// stop-gap until Story 2.x` in source, and a paired test in AC7.3 explicitly references the stop-gap so a reviewer cannot delete the stop-gap mapping without simultaneously updating the test (Poka-yoke).

### Previous story intelligence (Story 1.8 / 1.9 / Epic 1 retro)

- **`SessionBootstrap` mapping comments in `lib/core/bootstrap/session_bootstrap.dart` lines 1–15** already document the 1-to-1 `AuthState` mapping. Story 2.1 honors that mapping verbatim. If the source comment ever drifts from the AC3 table, the comment is wrong (the AC is canonical) — open a follow-up to update the comment.
- **`BootGate.goNamed('home')` in `lib/core/bootstrap/boot_gate.dart` lines 80–86** routes both `BootSessionLive` and `BootCookiesMissing` to `/home`. When Story 2.3 wires the synchronous redirect, `BootCookiesMissing → Reauth` will be re-routed to a banner-overlay flow on `/home` — but that is Story 2.7's territory, not 2.1's. Today the `BootGate` imperative nav is correct; AuthNotifier merely tracks state in parallel.
- **`LoginNotifier` in `lib/features/auth/login_notifier.dart`** holds `LoginState` (autoDispose), independent from `AuthState`. Story 2.1 does NOT delete `LoginNotifier`. The `// TODO(story-2.1):` comment on line 1 of `login_notifier.dart` calls for a future thin-adapter migration — that is a **separate task**, deferred per Epic 1 retro action item A3 (story size). Story 2.1 ships `AuthNotifier.login()` as a fully-functional method that the eventual migration will route to.
- **`_disposed` flag pattern**: not used in `AuthNotifier` because `keepAlive: true` means the notifier outlives every async operation. The shape is documented in `LoginNotifier` (autoDispose) for the migration story to copy.
- **`directives_ordering` lint** (Story 1.6 retro): apply to every new file.
- **Per-task commits** (Epic 1 retro action A1): each task above gets its own commit. Six tasks → six commits. Watch story-2.1 commit count — A1 reinforcement.
- **Tautological-test self-check** (Epic 1 retro action A4): every test in AC7 has a comment naming what would have to change in production code for the test to fail. AC7.2's bootstrap mapping test, AC7.3's transition tests, and AC7.4's grep test all include this annotation.
- **Reentrancy guard** (Epic 1 retro action T1): `login()`'s `if (state is Authenticating) return;` is the same shape as Story 1.4's `_gathering`, 1.6's `_isInFlight`, 1.7's submit guard, 1.9's `_navigating`. T1 calls for extracting a `ReentrantGuard` mixin — **opportunistic, not in 2.1's scope**. Document as a candidate for Story 2.4 when the same shape appears for `reauthenticate`.
- **Spec dry-run** (Epic 1 retro action A2): every code block in this story file's AC was syntactically scanned for "literals that don't compile" — specifically the `@Riverpod(keepAlive: true) class AuthNotifier extends _$AuthNotifier` shape against `riverpod_annotation: ^3.0.3` (committed `2d05f9a`). The Riverpod 3 codegen pattern requires `class extends _$ClassName`, NOT `class extends Notifier<T>`. Confirmed via existing `LoginNotifier` shape in `lib/features/auth/login_notifier.dart:24`.

### Riverpod 3 codegen-shape quick reference (for the dev agent)

```dart
// CORRECT (this story's shape)
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() { ... }   // build returns AuthState (synchronous)

  Future<void> login(...) async { state = ...; }
}

// WRONG — would not compile against riverpod_annotation: ^3.0.3
class AuthNotifier extends Notifier<AuthState> {  // ❌ no codegen
  @override
  AuthState build() { ... }
}

// Generated provider name (auto-derived from class name in lower-camel-case)
// is `authNotifierProvider`. No manual declaration needed.
```

The above mirrors `LoginNotifier` in `lib/features/auth/login_notifier.dart:23–24`. Confirmed Riverpod 3.0.3 + Dart 3.10+ shape.

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| Use `AsyncNotifier<AuthState>` because the bootstrap is async | `Notifier<AuthState>` + `ref.listen<AsyncValue<SessionBootstrap>>` inside `build()`; emit `Initial` synchronously, transition on listener fire (AC3.2 §WHY) |
| Build `AuthState` with Freezed | Native `sealed class` + `final class` subclasses — architecture line 242 mandates "Freezed not used here (no copyWith needed for FSM transitions)" |
| Add an `AuthState.equals(...)` method or override `==` | Sealed-class identity equality is fine; consumers compare via `is` patterns (AC2.7) |
| Make `Authenticated.facilitiesLoaded` nullable or default to `false` | `required this.facilitiesLoaded` — required `bool`, no default (AC2.4 §WHY) |
| Make `LockedOut.retryAfter` local-time | UTC only; format with `.toLocal()` at the UI surface (AC2.5 §WHY) |
| Wire `AuthNotifier` into `dioProvider` via `AuthInterceptor` | Defer to Story 2.3 — wiring requires `EvisitorErrorClassifier` (Story 2.2) (AC5) |
| Add a router `redirect:` callback that reads `authNotifierProvider` | Defer to Story 2.3; the `// TODO(story-2.3):` line in `router.dart` stays untouched (AC5.3) |
| Migrate `LoginScreen.submit()` to `authNotifier.login()` | Out of scope; LoginNotifier stays autoDispose-scoped, the migration is a separate follow-up (AC4.1 §WHY NOT) |
| Add `consecutiveFailures` / `lockedOutUntil` fields to `AuthNotifier` | Defer to Story 2.5 (Epic 2 retro §6 #3 already documents this) |
| Implement real `reauthenticate()` body | Defer to Story 2.4; AC4.2 mandates a stub that transitions to `AuthFailure(credentialsInvalid)` |
| Take `EvisitorErrorClass` as the parameter to `handleAuthFailure` | Take `AuthFailureReason` for now; Story 2.3 refactors the signature once Story 2.2 ships the enum (AC4.3 §WHY) |
| Throw `UnimplementedError` from any stub method | Transition the FSM to a well-formed state instead — never crash the app from a future-Story stub (AC4.2 §WHY) |
| Skip the `Initial` variant because the architecture lists six | The epic AC mandates seven; the seventh closes the implicit-default-during-bootstrap hole (AC2.2 §WHY) |
| Make `_applyBootstrapTransition` an `if/else` chain | Exhaustive `switch` is the Poka-yoke against a fifth `SessionBootstrap` variant landing without a mapping (AC3.3 §WHY) |
| Re-emit `AuthState.Initial` when `sessionBootstrapProvider` is invalidated mid-life | Filter via `whenData` — invalidation should be transparent, not a UI flash through loading (AC3.6 §WHY) |
| Return `Future<Result<void, Failure>>` from `login()` | Return `Future<void>`; the state IS the result. This is the single deliberate exemption from the project-wide Result<T, Failure> rule (AC4.1 §WHY) |
| Persist `AuthState` to `flutter_secure_storage` or Drift | No auth state in Drift — ever (architecture line 200). The notifier is in-memory; cold start re-derives via `sessionBootstrapProvider` |
| Add `setLockedOut(retryAfter)` or any other public mutator | Only four public methods: `login`, `logout`, `reauthenticate`, `handleAuthFailure`. Story 2.5 adds `setLockedOut` if needed (AC4.5) |
| Trust `state = X` from a test or any external code | Tests interact via `container.read(authNotifierProvider.notifier).method(...)` only. The CI grep guard catches violations (AC6) |
| Co-locate `AuthFailureReason` in `lib/features/auth/` per architecture line 650 | Place in `lib/core/errors/` for adjacency with Story 2.2's `EvisitorErrorClass` — deliberate deviation, documented in AC1.1 §WHY |
| Use `Stream<AuthState>` watchers inside `AuthNotifier` | Riverpod's `ref.listen` is the idiomatic shape; `Stream` would force consumers off `ref.watch(authNotifierProvider)` — breaks the architecture's redirect-reads-state-synchronously contract |
| Skip the CI grep guard because "the team is small" | The guard prevents future agents from violating the FSM invariant under deadline pressure. Cost: <1s in CI. Value: catches a class of bug at 100% recall (AC6.2) |

### Token and provider reference

| Provider | Type | Scope | Owner file | Touched by 2.1? |
|---|---|---|---|---|
| `sessionBootstrapProvider` | `FutureProvider<SessionBootstrap>` | keepAlive | `lib/core/bootstrap/session_bootstrap_provider.dart` | **Read (via `ref.listen`)** |
| `credentialStoreProvider` | `Provider<CredentialStore>` | keepAlive | `lib/features/settings/credential_store.dart` | **Read** (in `logout()`) |
| `evisitorApiClientProvider` | `Provider<EvisitorApiClient>` | keepAlive | `lib/features/submission/evisitor_api_client.dart` | **Read** (in `login()`) |
| `dioProvider` | `Provider<Dio>` | keepAlive | `lib/app/providers.dart` | **Untouched** — Story 2.3 wires the interceptor |
| `cookieJarProvider` | `Provider<CookieJar>` | keepAlive | `lib/app/providers.dart` | **Untouched** |
| `routerProvider` | `Provider<GoRouter>` | keepAlive | `lib/app/router.dart` | **Untouched** — Story 2.3 adds the redirect |
| `loginNotifierProvider` | `NotifierProvider<LoginNotifier, LoginState>` | autoDispose | `lib/features/auth/login_notifier.dart` | **Untouched** — separate migration |
| `authNotifierProvider` | `NotifierProvider<AuthNotifier, AuthState>` | keepAlive | `lib/features/auth/auth_notifier.dart` | **NEW (this story)** |

### Project Structure Notes

**Files created:**
- `lib/core/errors/auth_failure_reason.dart` — top-level enum with five variants (deviates from architecture line 650; deviation documented in AC1.1)
- `lib/features/auth/auth_state.dart` — sealed class with seven `final class` subclasses; re-exports `AuthFailureReason`
- `lib/features/auth/auth_notifier.dart` — `@Riverpod(keepAlive: true)` notifier with `build()` consuming `sessionBootstrapProvider` + four public method skeletons
- `lib/features/auth/auth_notifier.g.dart` — generated by `build_runner`; committed
- `test/unit/features/auth/auth_state_test.dart` — sealed-class shape and exhaustiveness (AC7.1)
- `test/unit/features/auth/auth_notifier_bootstrap_test.dart` — 4 mapping tests + 1 `Initial` pre-bootstrap test (AC7.2)
- `test/unit/features/auth/auth_notifier_transitions_test.dart` — 11 transition tests (AC7.3)
- `test/unit/ci/auth_state_guard_smoke_test.dart` — local grep self-test (AC7.4)
- `.github/workflows/auth-state-mutation-guard.yml` — dedicated CI grep guard (AC6.1)
- `scripts/check-auth-state-guard.sh` — invoked by the workflow above

**Files modified:**
- (none in `lib/`) — `dioProvider`, `router.dart`, `app.dart`, `LoginScreen`, `LoginNotifier` are deliberately untouched per AC5

**This story does NOT create:**
- A migration of `LoginNotifier` / `LoginScreen` to call `authNotifier.login()` — separate follow-up (AC4.1 §WHY NOT)
- An `AuthInterceptor` — Story 2.3
- An `EvisitorErrorClass` enum or classifier — Story 2.2
- A circuit breaker (`consecutiveFailures` + `lockedOutUntil`) — Story 2.5
- A persistent `LockoutStore` — Story 2.5
- A real `reauthenticate()` body — Story 2.4
- An opportunistic `helloCheck()` on resume — Story 2.6
- A `CredentialBanner` widget — Story 2.7
- A credentials-missing recovery screen — Story 2.8
- A Settings auth-state row — Story 2.9
- A router `redirect:` callback — Story 2.3
- A widget test for `LoginScreen → AuthNotifier` — out of scope (LoginScreen is unchanged)
- An integration test for concurrent re-auth — Story 2.3

### Deferred from previous stories relevant to this one

- **Story 1.7 deferred — `EvisitorFakeAdapter` placeholder for non-login paths**: still in place. Story 2.1 only exercises the `login` paths; defer remains for Story 2.6's `helloCheck` and Story 2.4's reauthenticate fixtures.
- **Story 1.7 deferred — lockout state lost on process death**: Story 2.5 owns the persistent `LockoutStore`. Story 2.1's `_shallowMap(AccountLockedOut → credentialsInvalid)` is the documented stop-gap until 2.5 lands. The Epic 1 retro §6 #3 captures this.
- **Story 1.7 deferred — `LoginNotifier` → `AuthNotifier.login()` adapter migration**: still deferred. Story 2.1 ships `AuthNotifier.login()` so the future adapter has a target. The migration is a separate story / task; the `// TODO(story-2.1):` comment in `login_notifier.dart:1` is updated in that future story to `// TODO(story-2.x): adapter migration after AuthNotifier.login() lands.`
- **Story 1.8 deferred — `ref.invalidate(sessionBootstrapProvider)` on login success**: closed by this story's design. Story 2.1's `login()` does NOT call `ref.invalidate(sessionBootstrapProvider)`. Reason: `AuthNotifier.state` is the post-login source of truth; re-running bootstrap would just re-derive the same state (or worse, race with the in-memory state). The `// TODO(story-2.x):` line in `session_bootstrap_provider.dart:11` is informational only and can be left in place as historical context — a future doc-cleanup PR replaces it with a `// Resolved by Story 2.1: AuthNotifier derives via ref.listen; bootstrap is cold-start only.` annotation. Out of 2.1's scope; trivial to do later in a doc-only commit.
- **Epic 1 retro action A1 — per-task commits**: reinforced. Six tasks → six commits.
- **Epic 1 retro action A2 — spec dry-run**: applied to every code block in this story file. The Riverpod 3 codegen shape was specifically validated against `LoginNotifier`'s existing structure.
- **Epic 1 retro action A3 — story size**: 2.1 borderline (two verbs in title). Mitigated by deferring `LoginNotifier` migration, `AuthInterceptor` wiring, and router redirect to dedicated stories. Story sits at ~6 tasks / ~13 tests — within bounds.
- **Epic 1 retro action A4 — tautological-test self-check**: every test in AC7 has the named "what would have to change in production for this test to fail" annotation.
- **Epic 1 retro action T1 — `ReentrantGuard` extraction**: candidate for Story 2.4 when the same shape appears for `reauthenticate`. Not in 2.1's scope.
- **Epic 1 retro action T3 — architecture doc stale path**: trivial fix; not in 2.1's scope (separate doc-fix commit, low priority).
- **Epic 1 retro action T4 — `/Resources/` cookie-scope doc**: not relevant to 2.1 (no cookie code).
- **Epic 1 retro discovery §6 #2 — `SessionBootstrap → AuthState` transition table**: closed by AC3.4. The table is canonical here.
- **Epic 1 retro discovery §6 #3 — lockout persistence**: deferred to Story 2.5 (already in epic AC). Story 2.1's stop-gap mapping is the bridge.

### Epic 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10 consolidation contract — what future stories absorb

| Story 2.1 artifact | Future story successor | Migration cost |
|---|---|---|
| Shallow `LoginFailure → AuthFailureReason` mapping in `_shallowMap` | Story 2.3 replaces with the full `EvisitorErrorClassifier` output | Delete `_shallowMap`; have `login()` route through `EvisitorErrorClassifier.classify(...)` then `handleAuthFailure(...)` (or directly emit AuthFailure) |
| `handleAuthFailure(AuthFailureReason reason)` | Story 2.3 changes parameter to `EvisitorErrorClass` | Update one method signature + ~3 internal call sites + tests |
| `reauthenticate()` stub returning `AuthFailure(credentialsInvalid)` | Story 2.4 replaces with full `CredentialStore.loadCredentials() + EvisitorApiClient.login() + state transition` | Delete stub; add ~30 lines + 4 tests |
| `_shallowMap(AccountLockedOut → credentialsInvalid)` stop-gap | Story 2.5 introduces the real `LockedOut` transition + persistent `LockoutStore` | Delete stop-gap; `AccountLockedOut` becomes `LockedOut(retryAfter: ...)` |
| `LockedOut` variant with no producer | Story 2.5 adds the only producer (3 consecutive failures) and the `LockoutStore` persistence | New code in 2.5; no 2.1 surface change |
| `Authenticated.facilitiesLoaded: false` is the only emit | Epic 3 Story 3.2 emits `Authenticated(facilitiesLoaded: true)` after `FacilityNotifier` resolves | New code in 3.2; no 2.1 surface change |
| `BootCredentialsMissing → AuthFailure(credentialsInvalid)` mapping is unreachable | Story 3.1 makes `hasFacilityProfileProvider` non-stub (`appDatabase.facilitiesTable.count() > 0`) | New code in 3.1; no 2.1 surface change |
| `LoginNotifier` (Story 1.7) is independent of `AuthNotifier` | Future story migrates `LoginScreen.submit()` to call `authNotifier.login()` directly; `LoginNotifier` is deleted | One migration commit; ~50 test updates |
| Router's `redirect:` callback is empty | Story 2.3 adds the synchronous redirect reading `authNotifierProvider` | New code in 2.3; `BootGate` becomes pass-through or is deleted |
| `BootGate.goNamed('home')` imperative nav | Story 2.3 replaces with router redirect | Delete `_navigateOnce`; `BootGate` reduces to `BootLoadingScaffold` pass-through (or full deletion) |
| `AuthNotifier` outlives every async op (keepAlive) | Story 9.x (Telemetry) adds `auth_state_transition` events on every state change | New `ref.listen` on `authNotifierProvider` in TelemetryService bootstrap; no 2.1 surface change |

### References

- [Architecture §Auth state machine — sealed class definition (architecture-canonical 6-variant shape; 2.1 ships 7 with `Initial`)](../planning-artifacts/architecture.md)
- [Architecture §Riverpod 3 topology — `authNotifierProvider` global keepAlive scope](../planning-artifacts/architecture.md)
- [Architecture §QueuedInterceptor topology — Story 2.3's wiring (NOT 2.1's)](../planning-artifacts/architecture.md)
- [Architecture §Cross-component dependencies — `dioProvider` depends on `authNotifierProvider`; both initialized at app start (Story 2.3 wires)](../planning-artifacts/architecture.md)
- [Architecture §Anti-Pattern Reference — `notifier.state = X` from outside the notifier (AC6 enforces)](../planning-artifacts/architecture.md)
- [Architecture §Auth error routing — single entry point (AC4.3 — `handleAuthFailure` is the only mutator)](../planning-artifacts/architecture.md)
- [Architecture §No auth state in Drift — line 200](../planning-artifacts/architecture.md)
- [PRD §FR9 — Error classifier for session-dead variants (Story 2.2; consumed by 2.1's `handleAuthFailure` after Story 2.3)](../planning-artifacts/prd.md)
- [PRD §FR10 — Auto re-authentication with serialized concurrent requests (Stories 2.3 + 2.4 — 2.1 ships the FSM target)](../planning-artifacts/prd.md)
- [PRD §FR12 — Client-side circuit breaker (Story 2.5 — 2.1 ships the `LockedOut` variant with no producer)](../planning-artifacts/prd.md)
- [PRD §NFR-R7 — Exactly one concurrent login (Story 2.3 enforces; 2.1's `Authenticating` re-entrancy guard is the per-notifier piece)](../planning-artifacts/prd.md)
- [PRD §NFR-M2 — `dynamic` only with justification (sealed-class FSM eliminates dynamic dispatch)](../planning-artifacts/prd.md)
- [PRD §NFR-M7 — Compile-time exhaustive switch (sealed-class FSM is the proof)](../planning-artifacts/prd.md)
- [Epics §Story 2.1 — BDD acceptance criteria, exhaustive `SessionBootstrap → AuthState` transition table](../planning-artifacts/epics.md)
- [Epics §Epic 2 introduction — Resilient Auth Lifecycle, the 3-failure / 6-minute circuit breaker](../planning-artifacts/epics.md)
- [Story 1.3 — `Result<T, Failure>` + `AppError` sealed; `CredentialStore.{load,save,wipe}Credentials`](./1-3-security-primitives-dio-and-cert-pinning.md)
- [Story 1.7 — `EvisitorApiClient.login()` returns `Result<void, LoginFailure>`; `LoginFailure` sealed (5 variants)](./1-7-evisitor-login-and-live-credential-verification.md)
- [Story 1.7 §LoginNotifier — autoDispose-scoped, independent from AuthNotifier in 2.1](./1-7-evisitor-login-and-live-credential-verification.md)
- [Story 1.8 — `SessionBootstrap` sealed class (4 variants); `BootGate.goNamed('home')` imperative nav](./1-8-session-persistence-across-restarts.md)
- [Story 1.8 §Routing pipeline — order of evaluation; widget tree wrapping order](./1-8-session-persistence-across-restarts.md)
- [Story 1.8 §`SessionBootstrap` mapping comments — 1-to-1 mapping in `session_bootstrap.dart` lines 1–15](./1-8-session-persistence-across-restarts.md)
- [Story 1.9 — `LoginScreen` `replaceMode` extension (independent from `AuthNotifier` in 2.1; future story migrates)](./1-9-credential-re-entry-from-settings.md)
- [Epic 1 Retrospective §6 #2 — `SessionBootstrap → AuthState` transition table mandate (closed by AC3.4)](./epic-1-retro-2026-04-28.md)
- [Epic 1 Retrospective §6 #3 — Lockout persistence (deferred to Story 2.5)](./epic-1-retro-2026-04-28.md)
- [Epic 1 Retrospective Action A1 — per-task commits (reinforced — 6 tasks → 6 commits)](./epic-1-retro-2026-04-28.md)
- [Epic 1 Retrospective Action A2 — spec dry-run (applied; Riverpod 3 codegen shape verified)](./epic-1-retro-2026-04-28.md)
- [Epic 1 Retrospective Action A3 — story size red flag (mitigated; 6 tasks / 13 tests)](./epic-1-retro-2026-04-28.md)
- [Epic 1 Retrospective Action A4 — tautological-test self-check (applied to every test in AC7)](./epic-1-retro-2026-04-28.md)
- [Epic 1 Retrospective Action T1 — `ReentrantGuard` extraction (candidate for Story 2.4)](./epic-1-retro-2026-04-28.md)
- [Story 2.2 — `EvisitorErrorClass` enum + classifier; consumes `AuthFailureReason` indirectly via Story 2.3](../planning-artifacts/epics.md)
- [Story 2.3 — `AuthInterceptor` (`QueuedInterceptor` subclass); wires `dioProvider` + router redirect to `authNotifierProvider`](../planning-artifacts/epics.md)
- [Story 2.4 — Auto re-authentication; replaces 2.1's `reauthenticate()` stub](../planning-artifacts/epics.md)
- [Story 2.5 — Circuit breaker + persistent `LockoutStore`; replaces 2.1's `_shallowMap(AccountLockedOut → credentialsInvalid)` stop-gap](../planning-artifacts/epics.md)
- [Story 2.6 — Opportunistic auth check on foreground; calls `handleAuthFailure(sessionDead)` on session-dead detection](../planning-artifacts/epics.md)
- [Story 2.7 — `CredentialBanner` (MaterialBanner subclass); watches `authNotifierProvider`](../planning-artifacts/epics.md)
- [Story 2.8 — Credentials-missing recovery; routed to from `BootCredentialsMissing → AuthFailure(credentialsInvalid)`](../planning-artifacts/epics.md)
- [Story 2.9 — Auth-state view in Settings; watches `authNotifierProvider` + renders Croatian-localized chips](../planning-artifacts/epics.md)
- [Story 3.2 — Fetch & cache facilities; emits `Authenticated(facilitiesLoaded: true)` once cache resolves](../planning-artifacts/epics.md)
- [Story 9.3 — Telemetry call-site wiring; `auth_state_transition` events on every `AuthState` change](../planning-artifacts/epics.md)
- [CLAUDE.md §Security & Privacy — credentials in Keystore only, no auth state in Drift](../../CLAUDE.md)
- [CLAUDE.md §eVisitor API quirks — 3-cookie session contract; ASP.NET Forms Auth](../../CLAUDE.md)
- [.claude/rules/japanese-craftsmanship.md §Poka-yoke — sealed class + exhaustive switch make invalid states impossible](../../.claude/rules/japanese-craftsmanship.md)
- [.claude/rules/japanese-craftsmanship.md §Just-In-Time — defer Story 2.3/2.4/2.5 wiring; ship FSM target only](../../.claude/rules/japanese-craftsmanship.md)
- [`riverpod` 3.0.x — pub.dev — `@Riverpod(keepAlive: true)` annotation; `class extends _$ClassName` codegen shape](https://pub.dev/packages/riverpod_annotation)
- [`riverpod` 3.0.x — pub.dev — `Notifier<T>.build()` synchronous return; `ref.listen` for async dependencies](https://pub.dev/packages/riverpod)

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
