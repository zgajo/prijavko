# Story 1.7: eVisitor Login & Live Credential Verification

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a host with an eVisitor account,
I want to enter my username and password once and have the app verify them against eVisitor,
so that I confirm credentials are correct before relying on them at the door, and subsequent sessions log me in automatically.

## Acceptance Criteria

### AC1 — Embedded API key plumbing (no UI field)

1. Create **`lib/core/env/evisitor_api_key.dart`** exposing a single top-level const:
   ```dart
   const String evisitorApiKey = String.fromEnvironment(
     'EVISITOR_API_KEY',
     defaultValue: '',
   );
   ```
   - **WHY single const file (not added to `evisitor_env.dart`)**: keeps the `EvisitorEnv` enum file focused on transport switching; the apikey is a credential-shaped secret that is *separate* from environment selection. A dev can run `--dart-define=EVISITOR_ENV=test` against a `prod` apikey, and vice-versa during the Week-1 spike.
   - **WHY `defaultValue: ''` (not throw)**: the `EVISITOR_ENV=fake` path bypasses the apikey entirely (the fake adapter ignores the field). A throwing default would break every integration test. Production hardness comes from the EvisitorApiClient — see AC2.4.
2. Document at the top of the file:
   - The Week-1 spike outcome the apikey scope depends on (vendor-wide vs per-account — UX spec §Login & Authentication Flow).
   - The build-time injection point: `flutter build appbundle --dart-define=EVISITOR_API_KEY=<key>`.
   - The forced-update trigger if the key is ever rotated (mirrors `cert_pins.dart` §Forced-update trigger date convention).
3. Do NOT log the apikey, do NOT add it to Crashlytics custom keys, do NOT add it to AppLogger (when AppLogger lands in Story 9.1 it must reject `evisitorApiKey` as a parameter at call sites — guard via PII grep, deferred to that story).

### AC2 — `EvisitorApiClient.login()` typed Dio wrapper

1. Create **`lib/features/submission/evisitor_api_client.dart`** as the **single entry point** for all eVisitor HTTP per architecture §Architectural Boundaries — External API boundary table. Story 1.7 ships only the `login()` method; Story 6.3 will add `importTourists()`; opportunistic auth check (`hello`) lands in Epic 2 Story 2.6.
2. Class shape:
   ```dart
   class EvisitorApiClient {
     EvisitorApiClient(this._dio);
     final Dio _dio;

     // Story 1.7 — POST /Resources/AspNetFormsAuth/Authentication/Login
     // Body: {userName, password, apikey, PersistCookie: true}
     // Success: 200 + body == true + Set-Cookie for authentication/affinity/language
     // Failure: 200 + {UserMessage, SystemMessage} | 200 + body == false | 400 + {…} | 401 | 403 | 5xx | network
     Future<Result<void, LoginFailure>> login({
       required String userName,
       required String password,
     }) async { … }
   }
   ```
3. **Body construction**: literal `Map<String, Object?>` — no Freezed DTO. The shape is fixed by Rhetos' `AuthenticationService.cs` and is not consumed by any other call site. Adding a Freezed model is Muri (overburden) for a 4-field one-shot payload.
   ```dart
   {
     'userName': userName,
     'password': password,
     'apikey': evisitorApiKey,
     'PersistCookie': true,
   }
   ```
   - **WHY `PersistCookie: true`**: per research §Login Handshake — without it, Rhetos issues a session cookie (no `Max-Age`) that is dropped when the cookie jar's in-memory state is discarded. Persistent cookies are load-bearing for Story 1.8 (Session Persistence Across Restarts).
4. **API-key sanity check at the call site, not in the const**:
   ```dart
   if (evisitorEnv != EvisitorEnv.fake && evisitorApiKey.isEmpty) {
     return const Err(LoginFailure.contractBreak(
       'EVISITOR_API_KEY missing for non-fake build',
     ));
   }
   ```
   - **WHY at the call site, not at startup**: a misconfigured release build is detected on the host's first login attempt — a clear failure path with a Croatian message — instead of an instant crash that looks like a Play Store install corruption.
5. **HTTPS-only**: rely on `dioProvider`'s baseUrl + `network_security_config.xml cleartextTrafficPermitted="false"` (Story 1.1 AC4.2). Do not set per-request schemes.
6. **Timeouts**: rely on the Dio defaults already wired in `providers.dart` (10s/30s/30s). No per-request override on the login endpoint.
7. **Cookie persistence is automatic**: the `CookieManager` interceptor in `dioProvider` reads `Set-Cookie` headers into the `PersistCookieJar` (Story 1.3). Story 1.7 must not call cookie APIs directly. A passing widget test in AC8 verifies cookies are present in the jar after a successful login.
8. **Riverpod provider**: register a `@riverpod` provider `evisitorApiClient(Ref ref) => EvisitorApiClient(ref.watch(dioProvider))` co-located in the same file (`evisitor_api_client.dart`). Use `keepAlive: true` — same lifetime rationale as `dioProvider`.

### AC3 — `LoginFailure` sealed class

1. Create **`lib/features/auth/login_failure.dart`** with a Dart 3 sealed class scoped to login outcomes only:
   ```dart
   sealed class LoginFailure {
     const LoginFailure();
   }
   final class CredentialsInvalid extends LoginFailure {
     const CredentialsInvalid({this.userMessage});
     final String? userMessage; // verbatim Croatian from eVisitor's UserMessage; null if absent
   }
   final class AccountLockedOut extends LoginFailure {
     const AccountLockedOut({required this.retryAfter});
     final DateTime retryAfter;
   }
   final class NetworkUnreachable extends LoginFailure {
     const NetworkUnreachable();
   }
   final class ServerError extends LoginFailure {
     const ServerError(this.statusCode);
     final int statusCode;
   }
   final class ContractBreak extends LoginFailure {
     const ContractBreak(this.reason);
     final String reason; // diagnostic only — never shown to user
   }
   ```
2. **WHY sealed (not enum)**: variants carry data (`retryAfter`, `userMessage`, `statusCode`). Compile-time exhaustive `switch` at the screen makes "I forgot to handle lockout" structurally impossible.
3. **WHY `LoginFailure` (not the architecture's `AuthFailureReason` enum)**: the architecture's full enum (`sessionDead | credentialsInvalid | lockedOut | network | contractBreak`) lands in Epic 2 Story 2.1 alongside `AuthState`. `sessionDead` is meaningless during the *first* login (there is no session yet to be dead). Story 1.7 ships the smaller, login-specific union. Epic 2 Story 2.2 (`EvisitorErrorClassifier`) subsumes both surfaces. Document the planned consolidation in a top-of-file comment.
4. **NO `toString()` override on `userMessage`**: it is a server-provided Croatian string by design, surfaced verbatim per NFR-L3. PII concern is non-applicable — `UserMessage` describes the rejection reason, not the user.

### AC4 — `LoginResponseClassifier` pure function

1. Create **`lib/features/auth/login_response_classifier.dart`** with a single pure function:
   ```dart
   LoginFailure? classifyLoginResponse({
     required Response<dynamic> response,
   }) { … }
   ```
   - Returns `null` ⇒ success (caller persists credentials, navigates).
   - Returns a `LoginFailure` ⇒ caller surfaces it.
2. **Decision tree (exhaustive, ordered):**
   - `statusCode == 200 && body == true` → `null` (success).
   - `statusCode == 200 && body == false` → `CredentialsInvalid(userMessage: null)` — Rhetos boolean-false return path (research §Failure mode on Login).
   - `statusCode == 200 && body is Map` with `SystemMessage` → inspect `SystemMessage` per regex table below.
   - `statusCode == 400 && body is Map` → inspect `SystemMessage`. Per architecture §External contract quirks: "HTTP 400 for unauthorized (Rhetos issue #182)".
   - `statusCode == 401 || statusCode == 403` → `CredentialsInvalid(userMessage: null)`. Standard rejection on the Login endpoint itself (not session-dead — there is no session yet).
   - `statusCode >= 500` → `ServerError(statusCode)`.
   - Anything else → `ContractBreak('unexpected statusCode=$status body=${body.runtimeType}')`.
3. **`SystemMessage` regex table** (case-insensitive, applied in order):
   | Pattern | Maps to | Source |
   |---|---|---|
   | `locked\|zaključan` | `AccountLockedOut(retryAfter: now + 6min)` | research §Croatian patterns |
   | `invalid\|nevažeć\|neispra\|netoč` | `CredentialsInvalid(userMessage: response['UserMessage'] as String?)` | research §Croatian patterns |
   | `api key\|not registered\|not registered or is deactivated` | `ContractBreak('apikey rejected')` | research §wiki failure example |
   | _none of the above_ | `CredentialsInvalid(userMessage: response['UserMessage'] as String?)` | safe default — surfaces the Croatian explanation verbatim |
4. **`retryAfter` for `AccountLockedOut`**: `DateTime.now().add(Duration(minutes: 6))`. Mirrors architecture §Circuit breaker — 6 minutes is the prijavko-side budget (stricter than Rhetos' 5 minutes). The classifier *does not* need access to a clock injection in Story 1.7 — `DateTime.now()` is acceptable; Epic 2 Story 2.2 will introduce a `Clock` seam when the circuit-breaker timer becomes a first-class concern.
5. **Pure function, no Dio import side-effects**: classifier accepts `Response<dynamic>` only; tests pass synthetic `Response` instances without spinning Dio. Pure-Dart unit tests, no widget tester.

### AC5 — `LoginState` + `LoginNotifier` (interim, scoped to login screen)

1. Create **`lib/features/auth/login_state.dart`** with a Dart 3 sealed class (3 variants):
   ```dart
   sealed class LoginState { const LoginState(); }
   final class LoginIdle extends LoginState {
     const LoginIdle({this.error});
     final LoginFailure? error; // surfaces last failure inline; cleared when fields change
   }
   final class LoginSubmitting extends LoginState { const LoginSubmitting(); }
   final class LoginLockedOut extends LoginState {
     const LoginLockedOut({required this.retryAfter});
     final DateTime retryAfter;
   }
   ```
   - No `LoginSuccess` variant: success drives a one-shot navigation, not a persistent UI state. Use `goRouter` `goNamed('home')` and let the route tree own the post-login screens.
2. Create **`lib/features/auth/login_notifier.dart`** as a `@riverpod` `Notifier<LoginState>` with **`autoDispose: true`** (default) — the form is a per-screen concern and must not leak failed attempts across navigation.
3. **`submit({username, password})` method**:
   - Guard: if current state is `LoginSubmitting` or `LoginLockedOut`, return early (Poka-yoke against the double-submit race fixed in story 1.6 retro).
   - Transition to `LoginSubmitting`.
   - Call `EvisitorApiClient.login(userName, password)`.
   - On `Ok(_)`:
     - Call `CredentialStore.saveCredentials(username, password, evisitorApiKey)` — **WHY also save apikey**: `CredentialStore`'s contract was set in Story 1.3 with `apiKey` as a required field. The apikey value is the same compile-time const — saving it preserves the existing API; future stories can re-evaluate whether to drop the field once the Week-1 spike confirms vendor-wide scope.
     - Navigate via `context.goNamed('home')` — the screen, not the notifier, calls `goNamed` (notifiers must not touch `BuildContext`). The notifier exposes a `Stream<LoginState>` change; the screen's `ref.listen` triggers navigation on `Ok`. **Tactical alternative**: notifier returns `Result<void, LoginFailure>` from `submit()` and the screen acts on the return value. Pick the return-value path — simpler, matches `welcome_screen.dart`'s direct `context.go()` pattern, no `ref.listen` plumbing.
   - On `Err(LoginFailure)`:
     - Variant-by-variant transition:
       - `AccountLockedOut(retryAfter)` → `LoginLockedOut(retryAfter)` and start a 1-second `Timer.periodic` to drive the countdown UI; on expiry, transition to `LoginIdle()`.
       - `_` (every other variant) → `LoginIdle(error: failure)`.
   - **Do not persist credentials on failure** (AC4 of the BDD: "no credentials or cookies are persisted on failure"). Cookies are auto-managed by Dio's `CookieManager` — verify that `EvisitorFakeAdapter` does NOT emit `Set-Cookie` on the failure cases (AC9.3).
4. **Provider wiring**: `@riverpod` (codegen). Story 1.6's `directives_ordering` lint lesson applies — `flutter_riverpod` import alphabetically with the rest, single block. Run `dart run build_runner build --delete-conflicting-outputs` after edits.
5. **Timer cleanup**: `LoginNotifier` keeps a `Timer? _lockoutTimer`. Override `dispose()` to cancel — Riverpod 2.x `Notifier` calls `dispose` on `autoDispose`. Without the cancel, a pending tick will call `setState` after disposal and crash widget tests.

### AC6 — `LoginScreen` widget

1. Create **`lib/features/auth/login_screen.dart`** as a `ConsumerStatefulWidget`.
   - **WHY `ConsumerStatefulWidget`**: holds two `TextEditingController`s, two `FocusNode`s, and the password-visibility toggle's `bool _obscure` — all lifecycle objects requiring `dispose()`. Mirrors `welcome_screen.dart`'s pattern.
2. **Layout** (per UX spec §Standard screen skeleton + UX spec §Login & Authentication Flow):
   ```
   Scaffold (no AppBar — full-screen onboarding, same as Welcome / CameraPermission)
   └── SafeArea
       └── Column(crossAxisAlignment: stretch)
           ├── Expanded
           │   └── SingleChildScrollView
           │       └── Padding (horizontal: TokensSpace.s16)
           │           └── Column(crossAxisAlignment: start)
           │               ├── SizedBox(height: TokensSpace.s64) ← emotional top margin
           │               ├── Text(headline, style: displayMedium)   ← "Prijava u eVisitor"
           │               ├── SizedBox(height: TokensSpace.s24)
           │               ├── Text(body, style: bodyLarge)            ← short rationale
           │               ├── SizedBox(height: TokensSpace.s32)
           │               ├── TextField (username)
           │               ├── SizedBox(height: TokensSpace.s16)
           │               ├── TextField (password, obscureText, suffix toggle)
           │               ├── SizedBox(height: TokensSpace.s16)
           │               ├── Text(reassurance, style: bodySmall)     ← Keystore reassurance
           │               ├── SizedBox(height: TokensSpace.s16)
           │               └── _ErrorOrLockoutBlock                    ← see AC6.7/8
           └── Padding (TokensSpace.s16 + s24 bottom gesture inset)
               └── FilledButton (full-width, "Prijavi se")
   ```
3. **Headline & body**: from `AppLocalizations.loginHeadline` / `AppLocalizations.loginBody` (AC9). `displayMedium` / `bodyLarge` per design system Story 1.2 typography map.
4. **Username `TextField`**:
   - `controller: _usernameController`
   - `autofillHints: const [AutofillHints.username]`
   - `keyboardType: TextInputType.text` (NOT `emailAddress` — eVisitor usernames are not email-shaped per research)
   - `textInputAction: TextInputAction.next`
   - `decoration: InputDecoration(labelText: l10n.loginUsernameLabel)`
   - `enabled: state is LoginIdle` (disabled while submitting or locked out)
   - **WHY no `Form` + `validator`**: validation logic is single-condition (`text.isEmpty`) and used only to gate the submit button. A `Form` is Muri for one screen with two fields and one button. The button's `onPressed` is null when either controller is empty — the form's role collapses into that null.
5. **Password `TextField`**:
   - `controller: _passwordController`
   - `obscureText: _obscure` (defaults to `true`)
   - `autofillHints: const [AutofillHints.password]`
   - `textInputAction: TextInputAction.done`
   - `onSubmitted: (_) => _maybeSubmit()` — IME "go" / "done" key triggers submit when both fields valid.
   - Suffix `IconButton` with `Symbols.visibility_rounded` / `Symbols.visibility_off_rounded`, `tooltip` from l10n. Toggling flips `_obscure` via `setState`.
   - `decoration: InputDecoration(labelText: l10n.loginPasswordLabel, suffixIcon: …)`
6. **Reassurance line**: `Text(l10n.loginReassurance, style: theme.textTheme.bodySmall)`. Includes the lock emoji per UX spec — emojis are user-visible characters and pass the project's "no emoji in code unless requested" rule because UX spec §Login screen explicitly prescribes "🔒 Podaci se čuvaju šifrirano u Android Keystore-u".
7. **Inline error block** (when `state is LoginIdle && state.error != null`): a `Padding` + `Text` block with `colorScheme.error` body. Compose the displayed string as:
   - For `CredentialsInvalid(userMessage: msg)`:
     - If `msg != null && msg.isNotEmpty` → `'$msg\n${l10n.loginCredentialsHint}'`
     - Else → `l10n.loginCredentialsHint`
   - For `NetworkUnreachable` → `l10n.loginNetworkError`
   - For `ServerError` → `l10n.loginServerError`
   - For `ContractBreak` → `l10n.loginContractBreakError` (do NOT surface the diagnostic `reason` to UI)
   - The two-line UserMessage + hint composition matches AC4 of the BDD: "the `UserMessage` (if present) is rendered in Croatian below the form **And** a prijavko-provided Croatian hint 'Provjerite korisničko ime i lozinku' is appended per NFR-L3".
8. **Lockout countdown block** (when `state is LoginLockedOut`):
   - Shows `l10n.loginLockoutMessage` + `l10n.loginLockoutCountdownSeconds(seconds)` where `seconds = state.retryAfter.difference(now).inSeconds.clamp(0, 360)`.
   - Drives a per-second rebuild via the timer in `LoginNotifier`. The screen `ref.watch`es `loginNotifierProvider`, so each state mutation rebuilds the block.
   - All form inputs and the submit button are disabled.
9. **Submit button**:
   - `FilledButton`, full-width via the outer `Padding` + `Column(crossAxisAlignment: stretch)`.
   - `onPressed` resolves to `null` if any of: `state is LoginSubmitting`, `state is LoginLockedOut`, `_usernameController.text.isEmpty`, `_passwordController.text.isEmpty`.
   - Else `onPressed: _maybeSubmit`.
   - Child: when `state is LoginSubmitting` → `SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.onPrimary))`. Otherwise `Text(l10n.loginSubmitButton)`.
10. **`_maybeSubmit()` handler**:
    - Calls `ref.read(loginNotifierProvider.notifier).submit(username: …, password: …)`. The notifier returns a `Future<Result<void, LoginFailure>>`.
    - On `Ok(_)`: `if (!mounted) return; context.goNamed('home');`.
    - On `Err(_)`: state is already updated by the notifier — UI rebuild handles the error display. No further action.
11. **No AppBar**: same reason as `WelcomeScreen` / `CameraPermissionScreen`.
12. **No ads**: per UX spec §Ad Placement — login is in the "no ads near sensitive inputs" list.
13. **Dark mode primary**: build and verify dark first.
14. **WCAG 2.1 AA**: `TextField` min height ≥ 56dp via Material 3 defaults; `FilledButton` already enforces 56dp via design system theme (Story 1.2 AC2.5). Suffix `IconButton` uses default 48×48 hit-test region — meets 48×48 requirement.
15. **Semantics**: `TextField`s carry their `labelText` to TalkBack automatically. The visibility toggle has a `tooltip` (Croatian) — Material `IconButton` exposes the tooltip as the semantics hint. The reassurance line is plain `Text` — read in document order.
16. **`FLAG_SECURE`** (per CLAUDE.md §Security & Privacy): the login screen displays credentials. Set `FLAG_SECURE` on entry and clear on exit. Implementation: a small `WindowSecureFlag` helper in `lib/core/security/window_secure_flag.dart`:
    ```dart
    @immutable
    class WindowSecureFlag {
      static const _channel = MethodChannel('hr.prijavko.window_secure');
      static Future<void> enable() => _channel.invokeMethod('enable');
      static Future<void> disable() => _channel.invokeMethod('disable');
    }
    ```
    + a 20-line `MainActivity.kt` `MethodChannel` handler calling `getWindow().setFlags(FLAG_SECURE, FLAG_SECURE)` / `clearFlags(FLAG_SECURE)`.
    - **Lifecycle hook**: in `LoginScreen.initState` call `WindowSecureFlag.enable()`; in `dispose` call `WindowSecureFlag.disable()`. Also disable on `WidgetsBindingObserver.didChangeAppLifecycleState(AppLifecycleState.paused)` to clear the flag if the host backgrounds away from the screen — otherwise the flag persists on subsequent screens and the host can't screenshot legitimate non-credential surfaces.
    - **Tests** for the lifecycle methods use a mocked `MethodChannel` — pure widget test, no real platform call.
    - This widget seam is reused by Story 4.x scan/review screens.

### AC7 — `EvisitorFakeAdapter` login wiring

1. Replace the Story 1.3 placeholder body of `test/fakes/evisitor_fake_adapter.dart` with login routing:
   ```dart
   class EvisitorFakeAdapter implements HttpClientAdapter {
     EvisitorFakeAdapter({this.scriptedLogin = const FakeLoginSuccess()});
     final FakeLoginScript scriptedLogin;
     // …
   }

   sealed class FakeLoginScript { const FakeLoginScript(); }
   final class FakeLoginSuccess extends FakeLoginScript { const FakeLoginSuccess(); }
   final class FakeLoginCredentialsInvalid extends FakeLoginScript {
     const FakeLoginCredentialsInvalid({this.userMessage = 'Korisničko ime ili lozinka nisu ispravni.'});
     final String userMessage;
   }
   final class FakeLoginLockedOut extends FakeLoginScript { const FakeLoginLockedOut(); }
   final class FakeLoginContractBreak extends FakeLoginScript {
     const FakeLoginContractBreak({this.userMessage});
     final String? userMessage;
   }
   final class FakeLoginNetworkError extends FakeLoginScript { const FakeLoginNetworkError(); }
   ```
2. **Routing**: in `fetch(options, …)`:
   - If `options.path.contains('/Authentication/Login')`:
     - Verify the request body contains `userName`, `password`, `apikey`, `PersistCookie: true`. Reject (return 400 with diagnostic `SystemMessage`) if any field missing — **Poka-yoke** against a future refactor that drops `PersistCookie`.
     - Branch on `scriptedLogin`:
       - `FakeLoginSuccess` → 200, body `'true'`, headers include three `set-cookie` entries:
         ```
         authentication=fake-auth-cookie-value; Path=/; HttpOnly; Secure; Max-Age=1209600
         affinity=fake-affinity-cookie-value; Path=/; Secure
         language=hr; Path=/; Max-Age=31536000
         ```
       - `FakeLoginCredentialsInvalid` → 200, body `{"UserMessage": <userMessage>, "SystemMessage": "Invalid credentials"}`, **no** `set-cookie` headers.
       - `FakeLoginLockedOut` → 200, body `{"UserMessage": "Korisnički račun je zaključan na 5 minuta.", "SystemMessage": "User is locked out"}`, **no** `set-cookie` headers.
       - `FakeLoginContractBreak` → 200, body `{"UserMessage": <userMessage>, "SystemMessage": "Application is not registered or is deactivated or API key has expired."}`, **no** `set-cookie` headers.
       - `FakeLoginNetworkError` → throw `DioException.connectionError(reason: 'connection reset by peer', requestOptions: options, error: SocketException('Connection reset'))`.
   - Else (any non-login path) → return the existing 200/empty response. Story 6.3 will add `ImportTourists` routing.
3. **Update the README block** at the top of `evisitor_fake_adapter.dart` per the BDD AC3:
   ```dart
   // To swap in a real eVisitor apikey:
   //   1. Obtain the key from HTZ (Hrvatska turistička zajednica) per the
   //      registration flow in PRD §FR5.
   //   2. Build with: flutter build appbundle \
   //        --dart-define=EVISITOR_ENV=prod \
   //        --dart-define=EVISITOR_API_KEY=<paste-key>
   //   3. Verify by running an integration test against testApi:
   //        flutter test --dart-define=EVISITOR_ENV=test \
   //                     --dart-define=EVISITOR_API_KEY=<test-key> \
   //                     integration_test/evisitor_login_canary_test.dart
   //      (Canary test scaffold deferred to Story 1.1 testapi-canary workflow.)
   ```
4. **Body parsing**: `RequestOptions.data` arrives as a `Map<String, Object?>`; serialize with `jsonEncode(data)` before reading via `jsonDecode` if the test wants to inspect bytes. In practice, `options.data` is the raw `Map` Dio accepted from the call — no JSON round-trip needed inside the adapter. Use `data['userName']` directly.
5. **Cookie header construction**: emit lowercase `'set-cookie'` keys as a `List<String>` per Dio's `Headers` contract. Per research §Cookie framing — the cookies must be **separately listed** as multiple `Set-Cookie` headers (not a single semicolon-joined string). `dio_cookie_manager` handles parsing.

### AC8 — Router updates

1. In `lib/app/router.dart`:
   - Replace the `/onboarding/login` placeholder body with `const LoginScreen()`. Remove the `TODO(story-1.7)` and `i18n-ignore` comments.
   - Add a sibling `/home` placeholder route at the **top level** (not under `/onboarding`):
     ```dart
     GoRoute(
       path: '/home',
       name: 'home',
       // TODO(story-3.x): replace placeholder with HomeScreen + AdBanner + queue
       // i18n-ignore: placeholder scaffold; replaced in Epic 3
       builder: (context, state) =>
           const Scaffold(body: Center(child: Text('Home — Epic 3'))),
     ),
     ```
   - **WHY top-level (not under `/onboarding`)**: post-login is the steady state of the app, not part of onboarding. Routing it under `/onboarding` would create a misleading hierarchy that `redirect` callbacks (Story 2.3+) would then have to special-case.
2. **Do not** add a redirect callback. The `// TODO(story-2.3)` line in `router.dart` is the deferred slot for that — leave it. Story 1.7 only adds the route node.

### AC9 — l10n strings

Add to **`lib/l10n/app_en.arb`**:
```json
"loginHeadline": "eVisitor Sign-In",
"@loginHeadline": { "description": "Login screen headline" },
"loginBody": "Sign in once with your eVisitor credentials. Subsequent sessions will sign in automatically.",
"@loginBody": { "description": "Login screen rationale beneath the headline" },
"loginUsernameLabel": "Username",
"@loginUsernameLabel": { "description": "Label for the username TextField" },
"loginPasswordLabel": "Password",
"@loginPasswordLabel": { "description": "Label for the password TextField" },
"loginPasswordToggleShow": "Show password",
"@loginPasswordToggleShow": { "description": "Tooltip for the password visibility toggle when password is hidden" },
"loginPasswordToggleHide": "Hide password",
"@loginPasswordToggleHide": { "description": "Tooltip for the password visibility toggle when password is visible" },
"loginReassurance": "🔒 Credentials are stored encrypted in Android Keystore.",
"@loginReassurance": { "description": "Reassurance line beneath the password field; includes lock emoji per UX spec §Login screen" },
"loginSubmitButton": "Sign in",
"@loginSubmitButton": { "description": "Primary CTA on login screen" },
"loginCredentialsHint": "Check your username and password.",
"@loginCredentialsHint": { "description": "Hint appended to invalid-credentials errors per NFR-L3" },
"loginNetworkError": "No internet. Try again.",
"@loginNetworkError": { "description": "Error displayed when login request fails due to network unreachability" },
"loginServerError": "eVisitor is unavailable. Try again later.",
"@loginServerError": { "description": "Error displayed on 5xx server response from eVisitor" },
"loginContractBreakError": "Update prijavko from Play Store and try again.",
"@loginContractBreakError": { "description": "Error displayed when login response shape is unrecognizable; will trigger forced-update flow in Story 9.4" },
"loginLockoutMessage": "Too many failed attempts — wait 6 minutes.",
"@loginLockoutMessage": { "description": "Lockout banner shown when login is blocked by client-side circuit breaker (or server-reported lockout)" },
"loginLockoutCountdownSeconds": "{seconds, plural, =1 {1 second remaining} other {{seconds} seconds remaining}}",
"@loginLockoutCountdownSeconds": {
  "description": "Plural countdown beneath the lockout message",
  "placeholders": { "seconds": { "type": "int", "format": "compact" } }
}
```

Add to **`lib/l10n/app_hr.arb`** (Croatian primary, full diacritics):
```json
"loginHeadline": "Prijava u eVisitor",
"loginBody": "Prijavite se jednom s eVisitor podacima. Sljedeće sesije se prijavljuju automatski.",
"loginUsernameLabel": "Korisničko ime",
"loginPasswordLabel": "Lozinka",
"loginPasswordToggleShow": "Prikaži lozinku",
"loginPasswordToggleHide": "Sakrij lozinku",
"loginReassurance": "🔒 Podaci se čuvaju šifrirano u Android Keystore-u",
"loginSubmitButton": "Prijavi se",
"loginCredentialsHint": "Provjerite korisničko ime i lozinku.",
"loginNetworkError": "Nema interneta. Pokušajte ponovno.",
"loginServerError": "eVisitor je nedostupan. Pokušajte kasnije.",
"loginContractBreakError": "Ažurirajte prijavko iz Play Store-a i pokušajte ponovno.",
"loginLockoutMessage": "Previše neuspješnih pokušaja — pričekajte 6 minuta.",
"loginLockoutCountdownSeconds": "{seconds, plural, =1 {Još 1 sekunda} =2 {Još {seconds} sekunde} =3 {Još {seconds} sekunde} =4 {Još {seconds} sekunde} other {Još {seconds} sekundi}}"
```

- **WHY plural form for Croatian seconds**: Croatian uses three plural forms (1, 2–4, 5+). The `=1 / =2 / =3 / =4 / other` shape covers the cases without depending on `intl`'s incomplete CLDR data for `hr`. Verified in Story 1.5's ARB conventions.
- Run `flutter gen-l10n`. Verify all 14 new getters appear on `AppLocalizations`.

### AC10 — Tests

1. **`test/unit/features/auth/login_response_classifier_test.dart`** — pure-Dart, no widgets:
   - 200 + `true` → returns `null` (success).
   - 200 + `false` → returns `CredentialsInvalid(userMessage: null)`.
   - 200 + `{UserMessage: 'Foo', SystemMessage: 'Invalid credentials'}` → returns `CredentialsInvalid(userMessage: 'Foo')`.
   - 200 + `{UserMessage: 'Bar', SystemMessage: 'User is locked out — wait 5 minutes'}` → returns `AccountLockedOut(retryAfter: ~now+6min)` (assert window with 1s tolerance).
   - 200 + `{UserMessage: null, SystemMessage: 'Application is not registered or is deactivated or API key has expired.'}` → returns `ContractBreak('apikey rejected')`.
   - 400 + `{UserMessage: 'X', SystemMessage: 'Neispravni podaci'}` → returns `CredentialsInvalid(userMessage: 'X')`.
   - 401 → returns `CredentialsInvalid(userMessage: null)`.
   - 403 → returns `CredentialsInvalid(userMessage: null)`.
   - 500 → returns `ServerError(500)`.
   - 502 → returns `ServerError(502)`.
   - 200 + `42` (unexpected scalar) → returns `ContractBreak(...)`.
   - 200 + `null` → returns `ContractBreak(...)`.
   - 200 + `{}` (empty Map, no SystemMessage) → returns `CredentialsInvalid(userMessage: null)` (default fallback per AC4.3 last row).
   - **Croatian regex coverage**: `SystemMessage: 'Korisnički račun zaključan'` → `AccountLockedOut`. `SystemMessage: 'Nevažeća lozinka'` → `CredentialsInvalid`.

2. **`test/unit/features/submission/evisitor_api_client_login_test.dart`** — uses `EvisitorFakeAdapter`, no widget tester:
   - **Test: success path persists cookies and returns Ok** — wire `Dio` with `IOHttpClientAdapter`-style cookie jar **identical** to `dioProvider`'s production wiring, attach `FakeLoginSuccess` adapter, call `login()`, assert `result is Ok`, assert all three cookies present in the jar via `jar.loadForRequest(Uri.parse('https://www.evisitor.hr/Resources/'))`.
   - **Test: success path posts the expected body** — capture `RequestOptions.data` in the fake adapter (expose a `lastRequest` getter) and assert `data['userName']`, `data['password']`, `data['apikey']`, `data['PersistCookie'] == true`.
   - **Test: credentials-invalid path returns Err(CredentialsInvalid) with userMessage** — `FakeLoginCredentialsInvalid(userMessage: 'Foo')`, call `login()`, assert `result is Err && (result.error as CredentialsInvalid).userMessage == 'Foo'`.
   - **Test: credentials-invalid path leaves cookie jar empty** — same fake, assert `jar.loadForRequest(...).isEmpty`.
   - **Test: locked-out path returns Err(AccountLockedOut)** with `retryAfter` ~6 min in the future.
   - **Test: contract-break path returns Err(ContractBreak)** with reason 'apikey rejected'.
   - **Test: network error path returns Err(NetworkUnreachable)** — assert no rethrow.
   - **Test: missing apikey in non-fake env returns Err(ContractBreak)** without making the HTTP call — verify `lastRequest == null` in the fake adapter. **NOTE**: `evisitorEnv` is a top-level final resolved at startup; tests cannot mutate it. Express this test by extracting the apikey check into a small overridable function (`_checkApiKeyAvailable()`) on `EvisitorApiClient` that defaults to reading the const but is `@visibleForTesting` overridable. Same `@visibleForTesting` pattern Story 1.3 used for `CertPins`.

3. **`test/widget/features/auth/login_screen_test.dart`** — mirror Story 1.6's `_makeTestApp` pattern with provider overrides for `dioProvider` (Dio + EvisitorFakeAdapter) and `credentialStoreProvider` (FakeCredentialStore — see fake below):
   - **Test: headline + body + reassurance render in Croatian**.
   - **Test: submit disabled when fields empty** — assert `FilledButton.onPressed == null` initially.
   - **Test: submit enabled once both fields have text** — type text, pump, assert `onPressed != null`.
   - **Test: tap submit with success path navigates to /home and persists credentials** — `FakeLoginSuccess` adapter, type text, tap, `pumpAndSettle`, assert home stub visible AND `fakeCredentialStore.savedCredentials` non-null with the typed username/password.
   - **Test: tap submit with credentials-invalid renders Croatian UserMessage + hint** — `FakeLoginCredentialsInvalid(userMessage: 'Korisničko ime ili lozinka nisu ispravni.')`, tap submit, assert both strings visible.
   - **Test: tap submit with credentials-invalid does NOT persist credentials** — assert `fakeCredentialStore.savedCredentials == null`.
   - **Test: tap submit with locked-out shows lockout banner and disables form** — `FakeLoginLockedOut`, assert `find.text(l10n.loginLockoutMessage)`, assert all three controls disabled, assert countdown text shows `~360 seconds remaining` (within 5s tolerance for test scheduler skew).
   - **Test: lockout countdown ticks down** — pump initial, `tester.pump(Duration(seconds: 5))`, assert seconds value decreased.
   - **Test: lockout transitions back to LoginIdle after retryAfter elapses** — set `retryAfter` to 2 seconds in the test, pump 3 seconds, assert form re-enabled and `LoginIdle` rendered.
   - **Test: password-visibility toggle flips obscureText** — find toggle by tooltip (`l10n.loginPasswordToggleShow`), tap, assert next tooltip is `loginPasswordToggleHide`.
   - **Test: server-error path renders generic Croatian server message** — adapter returns 500, assert `find.text(l10n.loginServerError)`.
   - **Test: contract-break path renders forced-update message** — adapter returns 200 + apikey-rejected envelope, assert `find.text(l10n.loginContractBreakError)`. Diagnostic `reason` must NOT be in the widget tree.
   - **Test: network-error path renders Croatian network message**.
   - **Test: in-flight submit prevents double-tap** — `FakeLoginSuccess` with a 100ms delayed adapter (extend the fake to optionally `await Future.delayed`). Tap twice rapidly, assert `requestCount == 1`. Mirrors story 1.6 retro Patch finding.
   - **Test: dark theme + light theme pump without errors**.
   - **Golden tests**: `goldens/login_idle_dark.png`, `goldens/login_idle_light.png`, `goldens/login_error_dark.png`, `goldens/login_lockout_dark.png` — generate via `flutter test --update-goldens`. Mirror Story 1.5's Ahem-font convention.
4. **`test/widget/features/auth/window_secure_flag_test.dart`** — small widget test that mounts `LoginScreen` with a mock `MethodChannel`, asserts `enable` is invoked on mount and `disable` on dispose. Use `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler` per Flutter platform-channel test convention.
5. **`test/fakes/fake_credential_store.dart`** — extends `CredentialStore` (concrete inheritance — note Story 1.6's deferred concern about `CapturePreferenceStore` lacking an interface; same pattern used here for consistency). Captures `savedCredentials`. Override `saveCredentials` and `loadCredentials` and `wipeCredentials` to in-memory.
   - **Add a `credentialStoreProvider` to the codebase if not present** — check first. If `CredentialStore` is currently constructed inline in `main.dart` or directly imported, expose it via a `@riverpod CredentialStore credentialStore(Ref ref) => CredentialStore()` provider in `lib/features/settings/credential_store.dart` so the login screen can read it via `ref.read`. **Do not** create a parallel provider if one already exists — grep `credentialStoreProvider` first.

### AC11 — Validation gate

1. `flutter test` — all tests green (existing 74 + new login tests + classifier tests + golden baselines committed).
2. `dart analyze --fatal-warnings --fatal-infos` — clean.
3. `dart format --set-exit-if-changed lib test integration_test` — clean.
4. **PII grep guard**: `lib/features/auth/login_screen.dart`, `lib/features/auth/login_notifier.dart`, `lib/features/submission/evisitor_api_client.dart` must contain **zero** references to `documentNumber`, `firstName`, `lastName`, `dateOfBirth`, `nationality`, `documentExpiry`, `mrzLine1`, `mrzLine2` in `print/debugPrint/AppLogger.*` calls. The screen handles credentials, not PII per the project's definition; credentials are guarded by NFR-S2 (no logging of credential values) — verify by hand-grep that **no log statement references `password`, `_passwordController`, `userName`, `_usernameController`, or `evisitorApiKey`**.
5. **i18n literal-string guard**: `grep -rn '"[A-Z][a-zšđčćž]' lib/features/auth/ lib/features/submission/evisitor_api_client.dart` returns empty (excluding doc comments and constants like the route paths).
6. **Icons guard**: no `Icons.*` usage. Visibility toggle uses `Symbols.visibility_rounded` / `Symbols.visibility_off_rounded` from `lib/design/icons.dart`.
7. **Manual smoke against fake env**: `flutter run -d emulator --dart-define=EVISITOR_ENV=fake` — flow through Welcome → CameraPermission → Login (default `FakeLoginSuccess`) → Home placeholder. Verify three cookies in jar via debug breakpoint.

---

## Tasks / Subtasks

- [x] Task 1 — Embedded API-key plumbing (AC: #1)
  - [x] Subtask 1.1 — Create `lib/core/env/evisitor_api_key.dart` with `evisitorApiKey` const + WHY-block doc comment per AC1.2.
  - [x] Subtask 1.2 — Verify no existing call site references the apikey path; grep `EVISITOR_API_KEY` and `apiKey` to ensure no conflicting const.

- [x] Task 2 — `LoginFailure` sealed class (AC: #3)
  - [x] Subtask 2.1 — Create `lib/features/auth/login_failure.dart` with the sealed class and 5 variants per AC3.1.
  - [x] Subtask 2.2 — Add top-of-file comment documenting the planned consolidation into Epic 2's `AuthFailureReason`.

- [x] Task 3 — `LoginResponseClassifier` pure function (AC: #4)
  - [x] Subtask 3.1 — Create `lib/features/auth/login_response_classifier.dart`.
  - [x] Subtask 3.2 — Implement decision tree per AC4.2 in declarative early-return shape (no nested `if`s).
  - [x] Subtask 3.3 — Implement `SystemMessage` regex matching per AC4.3 — case-insensitive, ordered.

- [x] Task 4 — `EvisitorApiClient.login()` (AC: #2)
  - [x] Subtask 4.1 — Create `lib/features/submission/evisitor_api_client.dart` per AC2.2.
  - [x] Subtask 4.2 — Implement `login()` returning `Result<void, LoginFailure>` — POST to `/Resources/AspNetFormsAuth/Authentication/Login`, classify response, map exceptions.
  - [x] Subtask 4.3 — Wrap `DioException` of type `connectionTimeout`/`connectionError`/`receiveTimeout` into `NetworkUnreachable`.
  - [x] Subtask 4.4 — Add `@visibleForTesting` apikey-availability seam per AC10 test 2.8.
  - [x] Subtask 4.5 — Add `@riverpod` provider `evisitorApiClient(Ref ref)`. Run `dart run build_runner build --delete-conflicting-outputs`.

- [x] Task 5 — `LoginState` + `LoginNotifier` (AC: #5)
  - [x] Subtask 5.1 — Create `lib/features/auth/login_state.dart` with the 3-variant sealed class.
  - [x] Subtask 5.2 — Create `lib/features/auth/login_notifier.dart` as `@riverpod` `Notifier<LoginState>` (autoDispose).
  - [x] Subtask 5.3 — Implement `submit({username, password})` returning `Result<void, LoginFailure>`. Persist credentials on `Ok` only.
  - [x] Subtask 5.4 — Implement timer-driven `LoginLockedOut` countdown with `ref.onDispose()` cleanup.
  - [x] Subtask 5.5 — `dart run build_runner build --delete-conflicting-outputs`. Commit generated `.g.dart`.

- [x] Task 6 — `WindowSecureFlag` + Android `MethodChannel` (AC: #6.16)
  - [x] Subtask 6.1 — Create `lib/core/security/window_secure_flag.dart` (Dart side).
  - [x] Subtask 6.2 — Add `MethodChannel` handler in `android/app/src/main/kotlin/.../MainActivity.kt` for `enable`/`disable` flag actions.
  - [x] Subtask 6.3 — Verify `MainActivity.kt` exists at the path; if not, create with the standard Flutter template + the channel handler.

- [x] Task 7 — l10n strings (AC: #9)
  - [x] Subtask 7.1 — Add 14 keys to `app_en.arb` per AC9.
  - [x] Subtask 7.2 — Add 14 values to `app_hr.arb`. Full Croatian diacritics; plural form for seconds uses ICU `few` category for 2–4.
  - [x] Subtask 7.3 — `flutter gen-l10n`. Verify 14 new getters appear.

- [x] Task 8 — `LoginScreen` widget (AC: #6)
  - [x] Subtask 8.1 — Create `lib/features/auth/login_screen.dart` as `ConsumerStatefulWidget` per AC6.1.
  - [x] Subtask 8.2 — Build the layout per AC6.2 with `displayMedium` headline, `bodyLarge` body, two `TextField`s, reassurance line, error/lockout block.
  - [x] Subtask 8.3 — Wire username `TextField` per AC6.4.
  - [x] Subtask 8.4 — Wire password `TextField` with visibility toggle per AC6.5.
  - [x] Subtask 8.5 — Wire submit `FilledButton` with disable conditions and `CircularProgressIndicator` for `LoginSubmitting` per AC6.9.
  - [x] Subtask 8.6 — Implement `_maybeSubmit()` per AC6.10 — `mounted` check after `await`.
  - [x] Subtask 8.7 — Wire error block + lockout block conditional rendering per AC6.7/8.
  - [x] Subtask 8.8 — Hook `WindowSecureFlag.enable()` in `initState`, `disable()` in `dispose`, and lifecycle-aware enable/disable on `AppLifecycleState.paused`/`resumed`.

- [x] Task 9 — `EvisitorFakeAdapter` login wiring (AC: #7)
  - [x] Subtask 9.1 — Add `FakeLoginScript` sealed class + 5 variants per AC7.1.
  - [x] Subtask 9.2 — Implement Login route in `fetch()` with branching per AC7.2.
  - [x] Subtask 9.3 — Verify request body `Poka-yoke` on `userName`/`password`/`apikey`/`PersistCookie`.
  - [x] Subtask 9.4 — Add `lastRequest` capture for tests that assert outbound payload shape.
  - [x] Subtask 9.5 — Add optional `responseDelay: Duration` for double-tap and locked-spinner tests.
  - [x] Subtask 9.6 — Update README block per AC7.3.

- [x] Task 10 — Router updates (AC: #8)
  - [x] Subtask 10.1 — Replace login placeholder with `LoginScreen` in `router.dart`.
  - [x] Subtask 10.2 — Add top-level `/home` placeholder route with `name: 'home'` per AC8.1.
  - [x] Subtask 10.3 — Remove `TODO(story-1.7)` and `i18n-ignore` comments from the login route.

- [x] Task 11 — `credentialStoreProvider` (AC: #10.5)
  - [x] Subtask 11.1 — No existing provider found. Added `@Riverpod(keepAlive: true) CredentialStore credentialStore(Ref ref)` to `lib/features/settings/credential_store.dart`. Ran codegen.
  - [x] Subtask 11.2 — N/A — no duplicate.

- [x] Task 12 — Tests (AC: #10)
  - [x] Subtask 12.1 — Created `test/unit/features/auth/login_response_classifier_test.dart` — 17 cases.
  - [x] Subtask 12.2 — Created `test/unit/features/submission/evisitor_api_client_login_test.dart` — 8 cases.
  - [x] Subtask 12.3 — Created `test/fakes/fake_credential_store.dart`.
  - [x] Subtask 12.4 — Created `test/widget/features/auth/login_screen_test.dart` — 19 cases + 4 golden baselines.
  - [x] Subtask 12.5 — Created `test/widget/features/auth/window_secure_flag_test.dart` — 3 cases.
  - [x] Subtask 12.6 — Verified smoke test — stops at WelcomeScreen, no `credentialStoreProvider` override needed.
  - [x] Subtask 12.7 — Verified integration test — existing `EvisitorFakeAdapter()` defaults to `FakeLoginSuccess`, no changes needed.
  - [x] Subtask 12.8 — 170 tests green, 0 failures.
  - [x] Subtask 12.9 — Generated golden baselines with `--update-goldens`. PNGs committed.

- [x] Task 13 — Validation gate (AC: #11)
  - [x] Subtask 13.1 — `flutter test` — 170 tests green.
  - [x] Subtask 13.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [x] Subtask 13.3 — `dart format --set-exit-if-changed lib test integration_test` — clean (8 files reformatted).
  - [x] Subtask 13.4 — i18n literal-string guard — clean.
  - [x] Subtask 13.5 — PII / credential log grep — zero matches.
  - [x] Subtask 13.6 — Icons guard — zero `Icons.*` usage.
  - [x] Subtask 13.7 — Manual smoke deferred to user (requires emulator).

---

## Dev Notes

### Why this story is seventh

Stories 1.1–1.6 built the scaffold, design system, security primitives, UMP consent, the Welcome and CameraPermission screens, and `CapturePreference` persistence. Story 1.7 is the **first network-touching screen** in the app — every prior story stayed local. It exercises the full Dio + cookie + cert-pin + Keystore credential pipeline that Stories 1.3 wired up but no widget consumed. It also introduces the **first interim domain types** (`LoginFailure`, `LoginState`) that Epic 2 will subsume into the production `AuthState` FSM. Treating this story as a stress test on the Story 1.3 plumbing is deliberate — Story 1.8 (Session Persistence) immediately rides on whatever 1.7 gets right.

### Architecture mandates (non-negotiable)

- **Feature-based folders**: `lib/features/auth/login_screen.dart` (per architecture line 443) and `lib/features/submission/evisitor_api_client.dart` (per architecture line 693). Crossing these is forbidden — login UI does not import from `submission/` directly except through the `evisitorApiClientProvider`.
- **No cross-feature imports beyond `core/`**: the login screen imports from `lib/core/`, `lib/design/`, `lib/l10n/`, and its own `lib/features/auth/` only. The notifier reads `evisitorApiClientProvider` and `credentialStoreProvider` via Riverpod — not direct imports.
- **`@riverpod` codegen only**: every new provider uses `@riverpod` annotation. No manual `Provider(...)`. Run `dart run build_runner build --delete-conflicting-outputs` after edits to `*_notifier.dart` / `*_api_client.dart`.
- **`autoDispose` by default**: `loginNotifierProvider` is `autoDispose` — failed attempts must not leak across navigation. `evisitorApiClientProvider` is `keepAlive: true` to share the single Dio instance.
- **Drift-as-truth does NOT apply here**: there is no Drift in Story 1.7. Credentials live in `flutter_secure_storage`, cookies in `PersistCookieJar`. Adding a Drift table for either is forbidden per architecture line 200 ("No auth state in Drift — ever") and architecture §Data boundary table.
- **Result contract**: `EvisitorApiClient.login()` returns `Result<void, LoginFailure>`. Exceptions are caught at the call site and wrapped — never propagated to the notifier or the widget.
- **Single Dio instance**: read `dioProvider` via `ref.watch` only. Do not construct a second Dio. Cert pinning, cookie management, and future auth interception all live on the single instance.
- **All UI strings via `AppLocalizations`**: zero literal Croatian/English strings in `build()`. Croatian primary, English fallback. Full diacritics. Story 1.5 retro lesson: the `' & '` connector violation taught us to inspect every interpolated string.
- **Dark mode primary**: build and verify dark first.
- **`context.goNamed` not `context.go`**: per Story 1.6 retro patch — named navigation surfaces route-tree regressions as compile/runtime assertions.
- **No ads on login**: per UX spec §Ad Placement.
- **48×48dp minimum touch targets**: TextFields and submit button exceed via Material 3 + design system theme.
- **No AppBar**: full-screen onboarding pattern (matches Welcome, CameraPermission).
- **`mounted` check after async gaps**: per architecture §BuildContext across async gaps and Story 1.5 / 1.6 retro lessons.
- **`FLAG_SECURE` on credential screens**: per CLAUDE.md §Security & Privacy. Implemented as `WindowSecureFlag` for reuse by Stories 4.x (scan/review).

### Result contract justification — why interim, not the architecture's `AuthFailure`

The architecture's `AuthFailureReason` enum (`sessionDead | credentialsInvalid | lockedOut | network | contractBreak`) lands in Epic 2 Story 2.1. Story 1.7 needs a result type today, but `sessionDead` is meaningless during *first* login — there is no session yet. Two options:

1. **Wait for Epic 2** and ship Story 1.7 without typed errors → violates the Result contract (NFR per CLAUDE.md), forces presentation-layer untyped error handling, breaks the pattern for *every* downstream story.
2. **Ship a story-scoped `LoginFailure`** that subsumes the same semantics minus the irrelevant `sessionDead` variant, and document the planned consolidation → preserves the contract; Epic 2 Story 2.2 (`EvisitorErrorClassifier`) absorbs the classifier and renames variants without breaking call sites if we expose `LoginFailure` as a typedef-free alias for `AuthFailure` from Epic 2 onward.

Option 2 is the JIT (Just-In-Time) choice — build only what Story 1.7 needs, keep the door open for Epic 2 to widen the surface. The top-of-file comment on `login_failure.dart` makes the migration path explicit.

### Previous story intelligence (Story 1.6)

- **`ConsumerStatefulWidget` is the onboarding-screen default**. Login is no exception — `TextEditingController`s and `FocusNode`s require `dispose()`.
- **Test pattern**: `_makeTestApp(...)` helper with isolated `GoRouter` + `MaterialApp.router` + provider overrides. Reuse this verbatim. Locale `hr`, `localizationsDelegates`, full theme.
- **Golden test pattern**: Ahem font, dark + light variants. Generate with `--update-goldens`. Commit PNGs under `test/widget/features/auth/goldens/`.
- **Codegen workflow**: `dart run build_runner build --delete-conflicting-outputs` after every `.dart` file with `@riverpod`. Generated `.g.dart` committed.
- **`directives_ordering` lint**: package imports alphabetical in a single block (no blank line separating prijavko imports from others). Story 1.6 retro caught this — apply to every new file.
- **`flutter_riverpod` import is required even with `riverpod_annotation`** — test VM compilation is stricter than `dart analyze`. Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` in any file using `Ref`.
- **Double-tap guard pattern**: in-flight flag in the notifier (not the widget) for newer screens. The notifier guards via `state is LoginSubmitting` early-return; the widget reflects state via the button's `onPressed: null` when disabled.
- **`CapturePreferenceStore` lacks an interface** (Story 1.6 deferred concern) — for `CredentialStore` we accept the same risk for parity until a second consumer needs the seam. Document in the test fake's header.
- **Story 1.6's `permanentlyDenied` SnackBar pattern**: the login screen does NOT need a SnackBar. Errors are inline (UX spec §Login flow shows the Croatian error directly under the form, not as a transient banner).
- **`shared_preferences` was added in 1.6** for `CapturePreference`. The login screen does NOT touch `shared_preferences` — credentials live in `flutter_secure_storage` (Keystore) only.

### Token and spacing reference (from `lib/design/tokens.dart`)

| Token | Value | Usage in login screen |
|---|---|---|
| `TokensSpace.s12` | 12dp | Reserved (vertical gaps between micro-elements if needed) |
| `TokensSpace.s16` | 16dp | Screen edge padding, gap between TextFields, reassurance line above & below |
| `TokensSpace.s24` | 24dp | Between headline and body, bottom gesture inset |
| `TokensSpace.s32` | 32dp | After body before first TextField |
| `TokensSpace.s64` | 64dp | Top margin (emotional spacing per UX spec) |
| `TokensSize.buttonMinHeight` | 56dp | FilledButton min-height (already enforced by theme) |

Typography (from `lib/design/theme.dart`):

| TextTheme slot | Use |
|---|---|
| `displayMedium` | Login headline ("Prijava u eVisitor") |
| `bodyLarge` | Body rationale + inline error text |
| `bodySmall` | Reassurance line ("🔒 Podaci…") + lockout countdown |
| `labelLarge` | Submit button text (default for `FilledButton.child: Text`) |

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| Construct a second `Dio` instance | Read `dioProvider` via `ref.watch` — single instance is the audit point |
| Build the apikey field into the UI | The apikey is an embedded `String.fromEnvironment` const; not user-input |
| Render `SystemMessage` to the user | Surface `UserMessage` (Croatian, user-facing). `SystemMessage` is diagnostic — log only when AppLogger lands (Story 9.1) |
| Use HTTP 401 alone to detect auth failure | Inspect both status code AND body — Rhetos returns 200+errorEnvelope and 400+SystemMessage paths (architecture §External contract quirks) |
| Translate `UserMessage` | Pass through verbatim (CLAUDE.md §eVisitor API quirks). Append the prijavko hint on a new line, do not replace |
| Skip the `mounted` check after `await login()` | Always `if (!mounted) return;` after every `await` before `goNamed` |
| Use `context.go('/home')` | Use `context.goNamed('home')` per Story 1.6 retro (named navigation surfaces route-tree regressions) |
| Catch DioException without classifying | Convert via `_classifyDioException` to a `LoginFailure` variant — every error path is typed |
| Persist credentials on failure | Save only on `Result.Ok` — AC4 of the BDD is explicit |
| Add a Drift table for credentials | Architecture line 200 forbids it. Credentials live in `flutter_secure_storage` only |
| Add a Freezed DTO for the login body | Map literal — Muri for a 4-field one-shot payload |
| Implement password strength validation | eVisitor enforces server-side; client-side validation is Muri and fails to recognize valid eVisitor passwords (research §spike-gated unknowns) |
| Auto-trim username whitespace | Don't — user-supplied; let eVisitor reject if invalid. Auto-trim hides typos behind a silent normalization |
| Re-render Croatian error in English in dark mode | Use a single `Text` per error variant — locale handling is `MaterialApp`-level |
| Skip `FLAG_SECURE` because "tests don't need it" | Add it. The `MethodChannel` is mocked in widget tests; production behavior is non-negotiable per CLAUDE.md §Security |
| Use `Icons.visibility` | `Symbols.visibility_rounded` from `lib/design/icons.dart` (icons guard CI rule) |
| Skip golden tests | Story 1.5 / 1.6 pattern: dark + light + key state goldens (idle, error, lockout) |
| Hard-code 6 minutes in the screen | The duration belongs to `LoginResponseClassifier` (one source of truth) — the screen reads `state.retryAfter` |
| Set `retryAfter` from the server's `Retry-After` header | Rhetos doesn't emit `Retry-After`. Use the prijavko-side 6-minute budget per architecture §Circuit breaker |
| Keep failed login attempts on the screen via `keepAlive: true` | `autoDispose` — leaving the screen clears the form, the in-flight flag, and any error state. Returning to the screen starts fresh |
| Use the architecture's `AuthFailureReason` enum (Epic 2 territory) | Use `LoginFailure` sealed class scoped to this story; consolidate in Epic 2 Story 2.2 |
| Skip the `EvisitorFakeAdapter` rewiring because "the test bypasses it" | Production builds with `--dart-define=EVISITOR_ENV=fake` go through it too — the README block is load-bearing for `flutter run` smoke testing |
| Build a separate Dio for tests with no cookie jar | The cookie persistence test in AC10.2 specifically needs the production-shape Dio so cookie wiring drift is caught |

### eVisitor login response shapes — concrete reference

Success:
```http
HTTP/1.1 200 OK
Content-Type: application/json
Set-Cookie: authentication=…; HttpOnly; Secure; Max-Age=1209600
Set-Cookie: affinity=…; Secure
Set-Cookie: language=hr; Max-Age=31536000

true
```

Credentials invalid (Rhetos 200 + envelope path):
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"UserMessage": "Korisničko ime ili lozinka nisu ispravni.", "SystemMessage": "Invalid credentials"}
```

Credentials invalid (Rhetos boolean false path — observed in the wild):
```http
HTTP/1.1 200 OK

false
```

Server-side lockout:
```http
HTTP/1.1 200 OK

{"UserMessage": "Korisnički račun je zaključan na 5 minuta.", "SystemMessage": "User is locked out"}
```

API-key contract break (wiki documented):
```http
HTTP/1.1 200 OK

{"UserMessage": null, "SystemMessage": "Application is not registered or is deactivated or API key has expired."}
```

400-not-401 case (architecture §External contract quirks — Rhetos issue #182):
```http
HTTP/1.1 400 Bad Request

{"UserMessage": "Neispravni podaci", "SystemMessage": "Validation failed"}
```

Source: research §Login Handshake — Concrete Sequence + research §Failure mode on Login.

### Cookie persistence verification — the load-bearing assertion

AC2.7 says cookies are auto-managed by Dio's `CookieManager`. The single test that proves this — and that catches any future regression where someone replaces the cookie jar with an in-memory variant — is:

```dart
test('login success persists three cookies to the cookie jar', () async {
  final tempDir = await Directory.systemTemp.createTemp('cookie_jar_test_');
  addTearDown(() => tempDir.deleteSync(recursive: true));
  // Wire Dio EXACTLY like dioProvider — encrypted PersistCookieJar + fake adapter
  final security = FakeSecurityService();
  await security.init();
  final storage = EncryptedStorage(tempDir.path, security.encryptionHelper);
  final jar = PersistCookieJar(storage: storage, persistSession: true);
  final dio = Dio()
    ..interceptors.add(CookieManager(jar))
    ..httpClientAdapter = EvisitorFakeAdapter(scriptedLogin: const FakeLoginSuccess());
  final client = EvisitorApiClient(dio);

  final result = await client.login(userName: 'foo', password: 'bar');

  expect(result, isA<Ok<void, LoginFailure>>());
  final cookies = await jar.loadForRequest(Uri.parse('https://www.evisitor.hr/Resources/'));
  expect(cookies.map((c) => c.name).toSet(),
    containsAll({'authentication', 'affinity', 'language'}));
});
```

The same shape with `FakeLoginCredentialsInvalid` asserts `cookies.isEmpty`.

### Settings re-entry contract (Story 1.9)

Story 1.9 will add a "Zamijeni podatke za prijavu" Settings tile that:
1. Routes to a *modified* login screen with username pre-filled from Keystore and password empty + focused.
2. On success, overwrites the Keystore values via `CredentialStore.saveCredentials`.
3. Preserves facility rows and queue rows untouched.

Story 1.7 prepares the screen, the notifier, and the API client that Story 1.9 reuses. To stay JIT, Story 1.7 does NOT add the pre-fill / banner logic — that's Story 1.9's scope. But Story 1.7's `LoginScreen` accepts no constructor parameters that would block a future `LoginScreen({this.prefilledUsername, this.replaceMode = false})` extension.

### Epic 2 consolidation contract — what Stories 2.1, 2.2, 2.3 will absorb

| Story 1.7 artifact | Epic 2 successor | Migration cost |
|---|---|---|
| `LoginFailure` sealed class | `AuthFailureReason` enum (Story 2.1) — variants superset | Add `sessionDead`, rename if needed; provide a `toLoginFailure` extension during the transition |
| `LoginResponseClassifier.classifyLoginResponse` | `EvisitorErrorClassifier.classify` (Story 2.2) — pure function over `DioException`, not just `Response` | Wrap; the login-specific classifier becomes a private helper |
| `LoginNotifier` (autoDispose, screen-scoped) | `AuthNotifier` (Story 2.1, keepAlive, app-scoped) — emits `AuthState` | LoginNotifier becomes a thin adapter over `AuthNotifier.login()`; the screen's `submit` button calls `authNotifier.login(creds)` |
| `EvisitorApiClient.login()` | unchanged (Story 2.x extends with `helloCheck()` for opportunistic auth, `logout()`) | Additive |
| Story 1.7's local 6-minute lockout timer | `AuthNotifier`'s circuit breaker (Story 2.5) | Replace per-screen timer with notifier-driven `AuthState.lockedOut(retryAfter)` watch |

Document the migration plan as a one-line `// TODO(story-2.x):` annotation on each of these surfaces — same convention as Story 1.3's `// TODO(story-2.3): AuthInterceptor wires here.` in `providers.dart`.

### Project Structure Notes

**Directories created by this story:**
- `lib/features/auth/` — first auth-feature directory; Epic 2 will populate further with `auth_state.dart`, `auth_notifier.dart`, `auth_interceptor.dart`.
- `lib/features/submission/` — first submission-feature directory; Epic 6 will populate with `import_tourists_builder.dart`, `send_all_notifier.dart`, etc.
- `test/widget/features/auth/` — login screen widget tests + goldens.
- `test/unit/features/auth/` — classifier unit tests.
- `test/unit/features/submission/` — API client unit tests.

**Files created:**
- `lib/core/env/evisitor_api_key.dart` — embedded apikey const + WHY block
- `lib/core/security/window_secure_flag.dart` — Dart side of FLAG_SECURE
- `lib/features/auth/login_failure.dart` — sealed class, 5 variants
- `lib/features/auth/login_response_classifier.dart` — pure classifier
- `lib/features/auth/login_state.dart` — sealed class, 3 variants
- `lib/features/auth/login_notifier.dart` — `@riverpod` Notifier
- `lib/features/auth/login_notifier.g.dart` — generated, committed
- `lib/features/auth/login_screen.dart` — ConsumerStatefulWidget
- `lib/features/submission/evisitor_api_client.dart` — typed Dio wrapper + `@riverpod` provider
- `lib/features/submission/evisitor_api_client.g.dart` — generated, committed
- `test/fakes/fake_credential_store.dart` — captures saved credentials in-memory
- `test/unit/features/auth/login_response_classifier_test.dart`
- `test/unit/features/submission/evisitor_api_client_login_test.dart`
- `test/widget/features/auth/login_screen_test.dart`
- `test/widget/features/auth/window_secure_flag_test.dart`
- `test/widget/features/auth/goldens/login_idle_dark.png` — golden baseline
- `test/widget/features/auth/goldens/login_idle_light.png` — golden baseline
- `test/widget/features/auth/goldens/login_error_dark.png` — golden baseline
- `test/widget/features/auth/goldens/login_lockout_dark.png` — golden baseline

**Files modified:**
- `test/fakes/evisitor_fake_adapter.dart` — login routing (replaces 200/empty placeholder)
- `lib/app/router.dart` — placeholder replaced with `LoginScreen`; `/home` placeholder added
- `lib/l10n/app_en.arb` — 14 new keys
- `lib/l10n/app_hr.arb` — 14 new values
- `lib/l10n/app_localizations.dart` — regenerated
- `lib/l10n/app_localizations_en.dart` — regenerated
- `lib/l10n/app_localizations_hr.dart` — regenerated
- `lib/features/settings/credential_store.dart` — add `@riverpod credentialStore` provider if absent
- `lib/features/settings/credential_store.g.dart` — created/regenerated
- `android/app/src/main/kotlin/.../MainActivity.kt` — add `MethodChannel` handler for `hr.prijavko.window_secure`
- `test/app_smoke_test.dart` — add `credentialStoreProvider` override if smoke flow now reaches login
- `integration_test/app_test.dart` — verify the existing fake-adapter override still satisfies the login route

**This story does NOT create:**
- `lib/features/auth/auth_state.dart` — Epic 2 Story 2.1
- `lib/features/auth/auth_notifier.dart` — Epic 2 Story 2.1
- `lib/features/auth/auth_interceptor.dart` — Epic 2 Story 2.3
- `lib/features/submission/import_tourists_builder.dart` — Story 6.2
- `lib/features/facility/` — Epic 3
- `lib/features/queue/` — Epic 5
- A Settings re-entry path — Story 1.9
- Forced-update banner UI — Story 9.4 (the `loginContractBreakError` string lays the groundwork)

### Deferred from previous stories relevant to this one

- **Architecture line 673**: still lists `lib/features/onboarding/consent_screen.dart` (consent landed in `lib/core/consent/`) — discrepancy logged in `deferred-work.md` Story 1.4 entry. Do NOT modify the architecture doc in this story.
- **`EvisitorFakeAdapter` placeholder** (deferred from Story 1.3): "returns 200 for any path. Flesh out endpoint routing in Story 1.7 (login) and Story 6.3 (ImportTourists) per the existing TODO." — **THIS STORY closes that deferred item**. Update `deferred-work.md` accordingly during Subtask 9.6.
- **`integration_test/app_test.dart` `dioProvider` override** (deferred from Story 1.3): "dead code today — no widget consumes `dioProvider` until first network-call screen (Story 1.7). Re-validate when WelcomeScreen or LoginScreen actually triggers the path." — **THIS STORY validates that override path**. Subtask 12.7 covers verification.
- **`SecurityService.init` re-entrancy** (deferred from Story 1.3): hot-restart edge case. Login flow does not stress this — re-evaluation deferred to Epic 2.
- **`FakeFlutterSecureStorage` extension** (deferred from Story 1.3): the credential store fake here uses `FakeFlutterSecureStorage` if needed; if `containsKey/readAll/deleteAll` are required, extend the fake in this story.
- **`outlinedButton` WCAG contrast** (deferred from Story 1.2): login screen does not introduce a new outlined button — submit is `FilledButton`. Defer remains.
- **`CapturePreferenceStore` interface seam** (deferred from Story 1.6): `CredentialStore` mirrors the same concrete-only pattern in this story for parity. If a second consumer of `CredentialStore` appears (Story 1.9 re-entry), revisit then.
- **`openAppSettings()` return value** (deferred from Story 1.6): not consumed in this story.

### References

- [Architecture §External contract quirks — 3 cookies, HTTP 400 unauthorized, /Date/ format](../planning-artifacts/architecture.md)
- [Architecture §Architectural Boundaries — features/submission as eVisitor entry point](../planning-artifacts/architecture.md#architectural-boundaries)
- [Architecture §QueuedInterceptor topology — single concurrent re-auth invariant](../planning-artifacts/architecture.md)
- [Architecture §Circuit breaker — 3 failures / 6-minute open](../planning-artifacts/architecture.md)
- [Architecture §Project Structure — features/auth/, features/submission/](../planning-artifacts/architecture.md)
- [Architecture §Data boundary table — credentials in flutter_secure_storage; cookies in AES-GCM file; no auth in Drift](../planning-artifacts/architecture.md)
- [Architecture §Naming Patterns — snake_case files, PascalCase classes, named routes](../planning-artifacts/architecture.md)
- [Architecture §BuildContext across async gaps — always check mounted](../planning-artifacts/architecture.md)
- [PRD §FR5 — host enters and stores eVisitor credentials](../planning-artifacts/prd.md)
- [PRD §FR8–FR14 — auth lifecycle (Epic 2 territory; FR8 starts in Story 1.8)](../planning-artifacts/prd.md)
- [PRD §NFR-S2 — credentials never logged](../planning-artifacts/prd.md)
- [PRD §NFR-S3 — credentials in flutter_secure_storage with Keystore-backed AES/GCM](../planning-artifacts/prd.md)
- [PRD §NFR-L3 — Croatian-primary error surfacing; UserMessage verbatim + prijavko hint](../planning-artifacts/prd.md)
- [PRD §NFR-S1 — FLAG_SECURE on credential / PII screens](../planning-artifacts/prd.md)
- [UX Spec §Journey 1 — Login & Authentication Flow + facility picker post-login routing](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Login screen — username + password + reassurance line + single CTA](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Ad Placement — no ads on login](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Standard Screen Skeleton — SafeArea + scrollable + bottom CTA + gesture inset](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Typography — displayMedium / bodyLarge / bodySmall slots](../planning-artifacts/ux-design-specification.md)
- [UX Spec §API key handling — embedded build-time, Week-1 spike confirms scope](../planning-artifacts/ux-design-specification.md)
- [Epics §Story 1.7 — BDD acceptance criteria, EVISITOR_API_KEY embedding](../planning-artifacts/epics.md)
- [Epics §FR5 + FR9–FR12 traceability — Story 1.7 inputs](../planning-artifacts/epics.md)
- [Research §Authentication Surface — POST /Resources/AspNetFormsAuth/Authentication/Login](../planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md)
- [Research §Login Handshake — request body shape, success cookies, failure envelope](../planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md)
- [Research §Failure mode on Login — wiki documented 200+SystemMessage example](../planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md)
- [Research §Cookie framing — three Set-Cookie headers, semicolon separator on Cookie:](../planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md)
- [Research §Cookie TTL — 14-day sliding default per ASP.NET Core Identity](../planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md)
- [Research §Croatian regex patterns — locked|zaključan, invalid|nevažeć|neispra](../planning-artifacts/research/technical-evisitor-auth-lifecycle-research-2026-04-22.md)
- [Story 1.3 — Dio + cert pinning + cookie jar + CredentialStore + EncryptedStorage](./1-3-security-primitives-dio-and-cert-pinning.md)
- [Story 1.5 — WelcomeScreen pattern, ARB conventions, golden test pattern, _makeTestApp helper](./1-5-welcome-and-sensitive-data-disclosure.md)
- [Story 1.6 — CameraPermission patterns, double-tap guard, mounted check after async, code review patches](./1-6-camera-permission-with-manual-entry-fallback.md)
- [Story 1.8 (next) — Session Persistence Across Restarts; consumes the cookie jar + credentials saved here](../planning-artifacts/epics.md)
- [Story 1.9 — Settings re-entry; reuses LoginScreen with prefilled username and replaceMode flag](../planning-artifacts/epics.md)
- [Story 2.1 — AuthState sealed class; subsumes LoginFailure / LoginState](../planning-artifacts/epics.md)
- [Story 2.2 — EvisitorErrorClassifier; subsumes LoginResponseClassifier](../planning-artifacts/epics.md)
- [Story 2.3 — AuthInterceptor; wires the post-login session-dead recovery](../planning-artifacts/epics.md)
- [Story 2.5 — Circuit breaker; replaces the per-screen 6-minute lockout timer](../planning-artifacts/epics.md)
- [Story 6.3 — EvisitorApiClient.importTourists; second method on the same client](../planning-artifacts/epics.md)
- [Story 9.1 — AppLogger; will assert that login_screen / api_client / notifier emit zero PII / credential log lines](../planning-artifacts/epics.md)
- [Story 9.4 — MinVersionChecker + ForceUpdateBanner; consumes the contractBreak error path](../planning-artifacts/epics.md)
- [CLAUDE.md §Security & Privacy — FLAG_SECURE, credentials in Keystore only](../../CLAUDE.md)
- [CLAUDE.md §eVisitor API quirks — UserMessage verbatim, status code alone insufficient](../../CLAUDE.md)
- [`dio_cookie_manager` — pub.dev](https://pub.dev/packages/dio_cookie_manager)
- [Rhetos.AspNetFormsAuth/AuthenticationService.cs — login source](https://github.com/Rhetos/AspNetFormsAuth/blob/master/src/Rhetos.AspNetFormsAuth/AuthenticationService.cs)

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Riverpod 2.x codegen uses `ref.onDispose()` in `build()`, not overridable `dispose()` — fixed LoginNotifier accordingly.
- Croatian ARB plural: `=3`/`=4` not valid ICU plural cases; used `few` category for 2-4 (CLDR handles Croatian).
- `evisitorApiKey` is empty in test env (no `--dart-define`); all tests override `isApiKeyAvailable` or `evisitorApiClientProvider`.

### Completion Notes List

- All 13 tasks complete, all 170 tests green, zero regressions.
- 51 new tests added: 17 classifier, 8 API client, 19 widget, 3 WindowSecureFlag, 4 golden baselines.
- `credentialStoreProvider` added to `credential_store.dart` (keepAlive — consistent with dioProvider pattern).
- `evisitorApiClientProvider` added with keepAlive.
- LoginNotifier uses `ref.onDispose(_cancelTimer)` per Riverpod 2.x codegen pattern (not overridable `dispose()`).
- Croatian plural for lockout countdown uses ICU `few` category (covers 2-4), not individual `=2/=3/=4` which gen-l10n rejects.
- FLAG_SECURE wired via MethodChannel; lifecycle-aware (paused/resumed) to avoid blocking screenshots on non-credential screens.

### Change Log

- 2026-04-27: Story 1.7 implementation complete — all 13 tasks, 170 tests green.

### File List

**New files:**
- `lib/core/env/evisitor_api_key.dart`
- `lib/core/security/window_secure_flag.dart`
- `lib/features/auth/login_failure.dart`
- `lib/features/auth/login_response_classifier.dart`
- `lib/features/auth/login_state.dart`
- `lib/features/auth/login_notifier.dart`
- `lib/features/auth/login_notifier.g.dart`
- `lib/features/auth/login_screen.dart`
- `lib/features/submission/evisitor_api_client.dart`
- `lib/features/submission/evisitor_api_client.g.dart`
- `test/fakes/fake_credential_store.dart`
- `test/unit/features/auth/login_response_classifier_test.dart`
- `test/unit/features/submission/evisitor_api_client_login_test.dart`
- `test/widget/features/auth/login_screen_test.dart`
- `test/widget/features/auth/window_secure_flag_test.dart`
- `test/widget/features/auth/goldens/login_idle_dark.png`
- `test/widget/features/auth/goldens/login_idle_light.png`
- `test/widget/features/auth/goldens/login_error_dark.png`
- `test/widget/features/auth/goldens/login_lockout_dark.png`

**Modified files:**
- `lib/app/router.dart` — login placeholder → LoginScreen; added /home route
- `lib/features/settings/credential_store.dart` — added @riverpod credentialStoreProvider
- `lib/features/settings/credential_store.g.dart` — regenerated
- `lib/l10n/app_en.arb` — 14 new login keys
- `lib/l10n/app_hr.arb` — 14 new Croatian values
- `lib/l10n/app_localizations.dart` — regenerated
- `lib/l10n/app_localizations_en.dart` — regenerated
- `lib/l10n/app_localizations_hr.dart` — regenerated
- `test/fakes/evisitor_fake_adapter.dart` — login routing (replaces 200/empty placeholder)
- `android/app/src/main/kotlin/hr/prijavko/prijavko/MainActivity.kt` — FLAG_SECURE MethodChannel handler
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — story status → in-progress
