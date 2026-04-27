# Story 1.9: Credential Re-Entry from Settings

Status: in-progress

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a host who changed my eVisitor password,
I want to re-enter my credentials from Settings without losing my facility context or queued guests,
so that I can recover from a password change without starting onboarding from scratch.

## Acceptance Criteria

### AC1 — Settings screen skeleton (entry point)

1. Create **`lib/features/settings/settings_screen.dart`** as a `ConsumerWidget` (no per-screen state needed today). The skeleton renders:
   - A standard `AppBar(title: Text(l10n.settingsTitle))` with the system back button (no custom leading).
   - A single `Material 3 ListTile` row labelled by `l10n.settingsReplaceCredentialsLabel` ("Zamijeni podatke za prijavu") with a leading `Symbols.lock_reset_rounded` icon and trailing chevron.
   - Tapping the tile calls `final updated = await context.pushNamed<bool>('replace-credentials');` then `if (!context.mounted) return; if (updated == true) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsCredentialsUpdatedSnackbar)));` per AC2.5.
2. **WHY `ConsumerWidget` (not `ConsumerStatefulWidget`)**: today the screen has no controllers, no async-load lifecycle, and no `ScaffoldMessenger` needs to outlive the build. The pushNamed → SnackBar choreography uses an inline async callback on the tile — no instance state required. Promote to `ConsumerStatefulWidget` only when a future story (Replace OIB, Your Data list with stream counts) introduces lifecycle concerns.
3. **No FLAG_SECURE on the Settings shell**: the Settings *list* contains no PII or credential text. The destructive `TypedConfirmationDialog` flows (Story 5.8 Replace OIB, Story 8.2 Delete All) and the credential re-entry flow (AC2 — owns its own `WindowSecureFlag.enable()`) handle their own protection. Adding FLAG_SECURE to the shell would propagate to every Settings sub-route the user navigates to and create false dependencies.
4. **JIT scope — what Settings does NOT show in this story**:
   - Auth state row (FR14) — Epic 2 Story 2.9.
   - "Privola za oglase" (re-open UMP form) tile — deferred from Story 1.4 review; **stays deferred**. Document re-deferral in `_bmad-output/implementation-artifacts/deferred-work.md` Story 1.4 entry: target story remains "future Settings expansion (1.9 only ships the credential re-entry tile per its AC)".
   - Replace active OIB — Story 5.8.
   - Your Data link → Delete All — Story 8.1 / 8.2.
   - Version + build chip — Story 9.4.
5. **List rendering**: a single `ListView(children: [ListTile(...)])` is fine. Do NOT pre-build a `SettingsTile` custom widget — there is exactly one tile in v1.0 today; abstraction without a second consumer is *Muri*. When Story 5.8 / 2.9 / 8.1 each add a tile, refactor in the story that lands the third.
6. **Layout/spacing**: respect design tokens — `ListView(padding: EdgeInsets.symmetric(vertical: TokensSpace.s8))`; the `ListTile` itself uses Material 3 defaults (`Theme.of(context).listTileTheme`). No hardcoded `EdgeInsets`, `Color`, `BorderRadius` per `.claude/rules/design-system.md` §1.

### AC2 — Re-entry route + LoginScreen `replaceMode` extension

1. Add a new GoRoute under `/settings`:
   ```dart
   GoRoute(
     path: 'replace-credentials',
     name: 'replace-credentials',
     builder: (context, state) => const LoginScreen(replaceMode: true),
   ),
   ```
2. **Modify `lib/features/auth/login_screen.dart`** to accept `final bool replaceMode;` and `final String? prefilledUsername;` constructor parameters (both default-construct safe — `replaceMode = false`, `prefilledUsername = null`). Story 1.7's deferred note ("LoginScreen accepts no constructor parameters that would block a future `LoginScreen({this.prefilledUsername, this.replaceMode = false})` extension") explicitly reserved this extension point — **honour it; do not branch into a new `CredentialReplaceScreen` widget**. Two screens that diverge by 30 lines is *Mura* (unevenness).
3. **Username pre-fill** (only when `replaceMode == true`):
   - In `_LoginScreenState.initState()`, after the existing `WindowSecureFlag.enable()` call, schedule a one-shot async load:
     ```dart
     if (widget.replaceMode) {
       _hydrateUsernameFromKeystore();
     }
     ```
   - Implementation:
     ```dart
     Future<void> _hydrateUsernameFromKeystore() async {
       final result = await ref.read(credentialStoreProvider).loadCredentials();
       if (!mounted) return;
       if (result is Ok<Credentials, StorageError>) {
         _usernameController.text = result.value.username;
         // WHY focus password (not username): username is pre-filled and
         // immutable in this flow's mental model — the host is *changing
         // password*, not username. Auto-focusing password matches the
         // typical "your username, new password" UX pattern (banking apps,
         // 2FA flows). The user can still edit username; we just do not
         // assume they want to.
         _passwordFocus.requestFocus();
       }
       // Err path is silently tolerated — the user re-types the username.
       // The next saveCredentials() will overwrite either way.
     }
     ```
   - **WHY `if (result is Ok<...>)` (not constructor pre-pass)**: forcing `pushNamed` to be `await`ed by the Settings tile while `loadCredentials()` resolves would block the route transition behind a Keystore round-trip. Loading inside `initState` lets the LoginScreen render its scaffold immediately and the username field populates within ~10ms.
4. **Replace banner** (only when `replaceMode == true`): render directly above `loginHeadline` (i.e., as the first child of the inner `Column` that wraps headline/body/fields):
   ```dart
   if (widget.replaceMode) ...[
     Container(
       padding: const EdgeInsets.all(TokensSpace.s12),
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surfaceContainerHigh,
         borderRadius: BorderRadius.circular(TokensSpace.s12),
         border: Border.all(
           color: Theme.of(context).colorScheme.outlineVariant,
         ),
       ),
       child: Row(
         children: [
           Icon(Symbols.info_rounded, size: 20),
           const SizedBox(width: TokensSpace.s12),
           Expanded(
             child: Text(
               l10n.replaceCredentialsBanner,
               style: theme.textTheme.bodyMedium,
             ),
           ),
         ],
       ),
     ),
     const SizedBox(height: TokensSpace.s24),
   ],
   ```
   - **WHY a plain `Container` (not `MaterialBanner`)**: `MaterialBanner` is the architecture-blessed widget for *transient surface-level system messages* (Epic 2's `CredentialBanner` for session-dead recovery). Re-entry is not a system event — it is the host's own initiated flow. Reusing `MaterialBanner` here would steal the auth-recovery affordance's affordance. Use a low-emphasis `surfaceContainerHigh` panel instead. Story 2.7's `CredentialBanner` will still be the *only* `MaterialBanner` subclass in `lib/`.
   - **WHY no semantic colour (warning/error)**: this is informational — facility/queue persistence is a *positive* affordance, not a warning. `surfaceContainerHigh` matches the design system's neutral panel pattern. `Symbols.info_rounded` (not `warning`) signals "informational" via shape redundancy per design-system rules §5.
5. **Submit-button label**: when `replaceMode == true`, render `l10n.replaceCredentialsSubmitButton` ("Spremi nove podatke") instead of `l10n.loginSubmitButton`. Same `FilledButton`, same disabled-when-empty logic, same `LoginSubmitting` spinner. **WHY a different label**: "Prijavi se" implies first-time login; re-entry semantics demand "Save". The Croatian copy aligns with the host's mental model — they are *replacing data*, not *signing in*.
6. **Headline + body in replace mode**: keep `loginHeadline` ("Prijava u eVisitor") **unchanged** — the eVisitor brand presence and form structure are familiar. The banner above already disambiguates the flow. Adding a separate `replaceCredentialsHeadline` is *Muri* (one ARB key per copy variant when the existing one reads fine in context).
7. **Success-path divergence**: `_maybeSubmit` after a successful login result currently calls `context.goNamed('home')`. Branch on `widget.replaceMode`:
   ```dart
   if (result is Ok) {
     if (widget.replaceMode) {
       context.pop(true); // returns to /settings; AC2.5 SnackBar fires there
     } else {
       context.goNamed('home');
     }
   }
   ```
   - **WHY `context.pop(true)` (not `goNamed('settings')`)**: the back-stack already has `/settings` underneath this route. `pop` is the documented go_router idiom for "I am done with this overlay, return its result to the parent". Using `goNamed` here would *push* a new `/settings` route on top, growing the stack on every successful re-entry — a slow leak.
   - **`bool` payload (`true`)**: signals "credentials were updated" so the parent screen can show the SnackBar without re-querying state. Pop with no payload (`null`) on cancel/back-gesture (handled by go_router's default back handling — no extra code needed).
8. **Failure path** (incorrect new credentials): no code change needed. `LoginNotifier._handleFailure` already updates `LoginState` to `LoginIdle(error: ...)` or `LoginLockedOut(retryAfter: ...)`. The existing inline error block (`_buildErrorOrLockoutBlock`) renders the Croatian failure copy. Story 1.7's reuse contract holds: same UX in both modes.
   - **AC3 invariant**: `LoginNotifier._handleSuccess` calls `saveCredentials` *only* on a successful API response. On any login failure, the Keystore is **never written**. Therefore "old Keystore values are retained" is satisfied by construction; no new code asserts it. Test AC6.3 verifies the invariant against any future regression.

### AC3 — Cookie-jar replacement semantics (no code change; document the contract)

1. The existing `CookieManager` interceptor in `dioProvider` reads `Set-Cookie` headers from the new login response and writes them via `saveFromResponse` on the same `cookieJarProvider` instance. eVisitor's three documented cookies (`authentication`, `affinity`, `language`) are all returned with `Set-Cookie` on every successful login per Story 1.7's fake-adapter fixture and per the live API contract.
2. **Naming-keyed replacement**: `PersistCookieJar.saveFromResponse` updates cookies by `(domain, path, name)` tuple. The new login's three cookies overwrite the old session's three cookies in place. Old cookies do **NOT** leak into the new session because the names collide.
3. **Edge case (intentionally not handled in v1.0)**: if a future eVisitor session ever issues a *fourth* cookie name that the previous session did not, the prior 3-cookie set would persist alongside. The 3-cookie contract is documented in `CLAUDE.md §eVisitor API` and the `_hasViableSessionCookies` helper (Story 1.8) hardcodes the `authentication` name as the load-bearing one. This is **not** a Story 1.9 concern; document the assumption in dev notes and move on. A pre-emptive `jar.deleteAll()` for the eVisitor host before re-login would over-engineer for a contract change that has not been observed in three years of the eVisitor API.
4. **WHY no `ref.invalidate(sessionBootstrapProvider)` after re-entry success**: bootstrap is a cold-start decision — its value is consumed once, on the first frame after `ConsentGate` resolves. The user is already inside the live app at this point; re-evaluating bootstrap would have no observable effect (BootGate's `_navigated` flag prevents re-navigation). Story 1.8's deferred note explicitly assigns the invalidation responsibility to **Epic 2 Story 2.x** (`AuthNotifier.login()`). Leave the existing `// TODO(story-2.x):` line untouched.

### AC4 — Home placeholder gear-icon entry point (interim — Epic 3 replaces)

1. `lib/app/router.dart`'s `/home` placeholder is currently `Scaffold(body: Center(child: Text('Home — Epic 3')))`. Story 1.9 needs the host to *reach* Settings to test the flow end-to-end. Modify the placeholder to add an `AppBar`:
   ```dart
   builder: (context, state) => Scaffold(
     appBar: AppBar(
       title: const Text('Home — Epic 3'), // i18n-ignore: placeholder
       actions: [
         IconButton(
           icon: const Icon(Symbols.settings_rounded),
           tooltip: AppLocalizations.of(context).settingsButtonTooltip,
           onPressed: () => context.pushNamed('settings'),
         ),
       ],
     ),
     body: const Center(child: Text('Home — Epic 3')),
   ),
   ```
2. Add the new top-level `GoRoute(path: '/settings', name: 'settings', ...)` with the `replace-credentials` sub-route per AC2.1. Top-level (not nested under `/onboarding`) because Settings is post-onboarding territory.
3. **WHY put the gear icon on the placeholder (not wait for Story 5.5 home assembly)**: the alternative — adding a deep-link or route-only access — leaves no UI affordance to verify the flow on an emulator. The placeholder already exists; adding an `AppBar` with a gear is two lines. When Story 5.5 builds the real `home_screen.dart`, the placeholder is **deleted entirely**, taking the gear with it; `home_screen.dart` ships its own gear in the same place per UX spec §AppBar (line 648). No migration cost.
4. **TODO annotation**: keep the existing `// TODO(story-3.x): replace placeholder with HomeScreen + AdBanner + queue` comment, but extend to:
   ```dart
   // TODO(story-5.5): replace placeholder with HomeScreen + AdBanner + queue;
   //   the gear-icon AppBar action below is interim and is owned by HomeScreen
   //   from Story 5.5 onwards (UX spec §AppBar).
   ```
5. **`AppLocalizations.of(context)` in the router builder**: this is fine — the `MaterialApp.router` has already wired `localizationsDelegates`. No `i18n-ignore` needed for the gear's tooltip; it goes in the ARB.

### AC5 — Back gesture preserves all state

1. **System back from `/settings/replace-credentials` → `/settings`**: go_router's default `pop` semantics handle this. No additional code.
2. **No state mutation occurs on the back path**: `LoginNotifier` is `autoDispose`-scoped (per Story 1.7 line 25 comment) — its disposal on screen-pop is harmless (the form state was per-screen and the host is abandoning unsaved input intentionally). `WindowSecureFlag.disable()` fires on `LoginScreen.dispose` — also harmless; the next FLAG_SECURE-bearing screen sets it again.
3. **Specifically NOT TOUCHED on back**:
   - `CredentialStore` — `saveCredentials` only ever runs in the success path (`_handleSuccess`), never on dispose.
   - `cookieJarProvider` — only written by Dio's `CookieManager` on a real `Set-Cookie` response.
   - `FacilitiesTable` — does not exist yet (Story 3.1).
   - `GuestEntriesTable` — does not exist yet (Story 5.1).
4. **Test AC6.4** asserts the invariant: pump replace-credentials route, type a new password but do not submit, simulate system back, assert the popped result is `null` AND the `FakeCredentialStore.savedCredentials` is unchanged from its seed.

### AC6 — Tests

1. **`test/widget/features/settings/settings_screen_test.dart`** — exercises the Settings shell:
   - **Renders the credential re-entry tile** with the Croatian label and the leading lock-reset icon. Pump in `hr` locale.
   - **Tapping the tile pushes `replace-credentials`** — assert `currentRoute.matches.last.matchedLocation == '/settings/replace-credentials'` after tap + `pumpAndSettle`.
   - **SnackBar fires after successful re-entry** — round-trip the flow: tap tile → fill form with valid creds → submit → assert SnackBar with `l10n.settingsCredentialsUpdatedSnackbar` is visible on the Settings screen after pop.
   - **No SnackBar on cancel/back** — tap tile → simulate system back → assert no SnackBar present, no error.

2. **`test/widget/features/auth/login_screen_replace_mode_test.dart`** (separate file from Story 1.7's existing `login_screen_test.dart` — keeps each test file scoped to one story):
   - **Username pre-filled from Keystore**: seed `FakeCredentialStore.savedCredentials = Credentials(username: 'host42', ...)` → pump `LoginScreen(replaceMode: true)` → after `pumpAndSettle`, assert the username `TextField`'s controller value equals `'host42'` AND the password `FocusNode.hasFocus` is `true`.
   - **Replace banner renders**: assert `find.text(l10n.replaceCredentialsBanner)` finds exactly one widget; the banner panel uses `surfaceContainerHigh` (assert via `find.byWidgetPredicate` matching the Container's decoration).
   - **Submit button reads "Spremi nove podatke"**: assert `find.text(l10n.replaceCredentialsSubmitButton)` exists; `find.text(l10n.loginSubmitButton)` is empty.
   - **Success-path navigation diverges**: pump with `replaceMode: true`, drive a successful login via `EvisitorFakeAdapter` → assert the route popped (current location is `/settings`, not `/home`) AND the popped result is `true`.
   - **Failure-path Keystore retained**: seed `savedCredentials = Credentials(username: 'host42', password: 'OLD-PWD', apiKey: 'k')`. Pump `replaceMode: true`. The fake adapter scripts a `400` Croatian-UserMessage failure on `Login`. Submit `host42` + `'WRONG-NEW'`. After `pumpAndSettle` assert `fakeCredentialStore.savedCredentials!.password == 'OLD-PWD'` (unchanged) AND the inline Croatian error renders.
   - **Default (non-replace) mode unchanged**: pump `LoginScreen(replaceMode: false)` → assert NO banner, submit-button reads `l10n.loginSubmitButton`, username field is **empty** (not auto-loaded), success navigates to `/home`. Story 1.7's regression guard.
   - **Lockout state survives mode**: drive 3 failed login attempts in `replaceMode: true` → assert `LoginLockedOut` UI renders identical to the non-replace case (the lockout block is mode-agnostic).

3. **`test/widget/features/auth/login_screen_test.dart` regression**: zero changes required. Add a single assertion to the existing "renders submit button" test that verifies `LoginScreen()` (default) still has no banner and no pre-fill — Poka-yoke against a future refactor that flips the `replaceMode` default.

4. **Routing test** — extend `test/app_smoke_test.dart` (Story 1.8 added the `BootGate` assertion there): add a single test that, given a fake-credentials-seeded boot, lands on `/home` placeholder and verifies the gear-icon `IconButton` is visible. Tapping it lands on `/settings`; the credential re-entry tile is visible.

5. **No new unit tests**: AC2's logic (pre-fill, banner toggle, submit-label toggle, success-pop) is widget-level. `LoginNotifier`'s save-only-on-success behaviour is already covered by Story 1.7's existing `login_notifier_test.dart`; no notifier change in 1.9 means no notifier-test addition.

6. **Test count delta**: 192 (Story 1.8 baseline) + ~10 new (5–6 in `login_screen_replace_mode_test`, 4 in `settings_screen_test`, 1 in app_smoke_test extension) → ~202. No regressions; Story 1.7's `login_screen_test.dart` count remains stable.

### AC7 — l10n strings

Add to **both** `lib/l10n/app_hr.arb` and `lib/l10n/app_en.arb`. Run `flutter gen-l10n` (project uses `generate: true` per Story 1.5 — generation is automatic on next `flutter run`/`flutter test`; explicit invocation is `dart run flutter_localizations:gen`).

| Key | Croatian (primary) | English (fallback) |
|---|---|---|
| `settingsTitle` | `Postavke` | `Settings` |
| `settingsButtonTooltip` | `Postavke` | `Settings` |
| `settingsReplaceCredentialsLabel` | `Zamijeni podatke za prijavu` | `Replace sign-in credentials` |
| `settingsCredentialsUpdatedSnackbar` | `Podaci ažurirani.` | `Credentials updated.` |
| `replaceCredentialsBanner` | `Zamjena podataka — stari objekti i nedoslani gosti ostaju.` | `Replacing credentials — facilities and undelivered guests stay.` |
| `replaceCredentialsSubmitButton` | `Spremi nove podatke` | `Save new credentials` |

- **Croatian copy is verbatim from epics §Story 1.9 ACs and from FR7 traceability** — do not paraphrase. The host expects the exact phrasing used in mobile-banking-style apps.
- **`@`-suffixed metadata**: each new key gets a `@<key>` description block in `app_en.arb` (the canonical descriptor file) per Story 1.5's convention.
- **Diacritics**: full Croatian (š/đ/č/ć/ž — no ASCII approximation) per UX-DR24.
- **No new placeholders**: all six strings are static — no `{count}`, no plural rules. Avoid `intl` plural complexity for static labels.

### AC8 — Validation gate

1. `flutter test` — all existing tests green + new replace-mode and Settings tests + app_smoke extension. Zero deletions.
2. `dart analyze --fatal-warnings --fatal-infos` — clean.
3. `dart format --set-exit-if-changed lib test integration_test` — clean.
4. **PII / credential grep guard**: `lib/features/settings/settings_screen.dart`, the new GoRoutes, and the modified `login_screen.dart` must contain zero references to `password` (the parameter name `password` in `_hydrateUsernameFromKeystore` is acceptable; *values* must never be string-interpolated into a log). Verify by hand-grep: `grep -rEn 'password|Credentials|apiKey' lib/features/settings/ lib/features/auth/login_screen.dart` returns only structural references (parameter names, type names, Keystore key constants), never `'password: $password'`-style interpolation.
5. **i18n literal-string guard**: `grep -rEn '"[A-Z][a-zšđčćž]' lib/features/settings/ lib/features/auth/login_screen.dart` returns only the existing Story 1.7 i18n-ignore cases (none should be added by 1.9). The placeholder `'Home — Epic 3'` retains its `i18n-ignore` comment in `router.dart`.
6. **Manual smoke against fake env** (`flutter run --dart-define=EVISITOR_ENV=fake`):
   - Cold start with no credentials → land on Welcome (Story 1.8 BootFreshFirstRun branch).
   - Sign in via Story 1.7's flow → lands on `/home` placeholder.
   - Tap gear icon → lands on Settings; "Zamijeni podatke za prijavu" tile visible.
   - Tap tile → land on `LoginScreen(replaceMode: true)`. Verify banner + pre-filled username + focused password.
   - Submit valid new password → returns to Settings with SnackBar "Podaci ažurirani."
   - Tap tile again → submit *wrong* password → inline Croatian error renders; press system back → returns to Settings with no SnackBar; reopen replace-credentials → username still pre-filled with the *original* (unchanged) value.
   - Force-stop the app and cold start: `BootGate` resolves `BootSessionLive` (cookies still valid via the most recent successful re-entry login) → lands directly on `/home`.

---

## Tasks / Subtasks

- [x] Task 1 — Settings screen skeleton + new routes (AC: #1, #4)
  - [x] Subtask 1.1 — Create `lib/features/settings/settings_screen.dart` per AC1.1–1.6.
  - [x] Subtask 1.2 — Add `/settings` (top-level, name: `'settings'`) and nested `replace-credentials` routes to `lib/app/router.dart` per AC2.1, AC4.2.
  - [x] Subtask 1.3 — Add gear-icon `AppBar` action to `/home` placeholder per AC4.1; update the existing TODO comment per AC4.4.
  - [x] Subtask 1.4 — Verify no other call site references the placeholder `Scaffold` body — only `router.dart` owns it (`grep -n 'Home — Epic 3' lib/`).

- [x] Task 2 — `LoginScreen` `replaceMode` extension (AC: #2)
  - [x] Subtask 2.1 — Add `final bool replaceMode;` and `final String? prefilledUsername;` constructor parameters with safe defaults per AC2.2. The `prefilledUsername` parameter is reserved for future (e.g. Story 2.8 credentials-missing recovery may pass a known-good username); Story 1.9 does not pass it but the ctor accepts it.
  - [x] Subtask 2.2 — Implement `_hydrateUsernameFromKeystore()` per AC2.3; gate behind `widget.replaceMode`.
  - [x] Subtask 2.3 — Render the replace banner above `loginHeadline` when `widget.replaceMode == true` per AC2.4.
  - [x] Subtask 2.4 — Branch the submit-button label between `loginSubmitButton` and `replaceCredentialsSubmitButton` per AC2.5.
  - [x] Subtask 2.5 — Branch `_maybeSubmit`'s success path: `context.pop(true)` in replace mode, `context.goNamed('home')` in default per AC2.7.
  - [x] Subtask 2.6 — Verify failure path is unchanged — `LoginNotifier._handleFailure` still routes to `LoginIdle(error)` / `LoginLockedOut(retryAfter)`; no Keystore write occurs (AC3 invariant).

- [x] Task 3 — l10n strings (AC: #7)
  - [x] Subtask 3.1 — Add the 6 new keys to `lib/l10n/app_en.arb` (with `@`-descriptor blocks).
  - [x] Subtask 3.2 — Add the 6 new keys to `lib/l10n/app_hr.arb` (Croatian copy verbatim).
  - [x] Subtask 3.3 — Run `flutter test` once to trigger l10n generation. Verify generated `lib/l10n/app_localizations*.dart` reflects the new getters.

- [x] Task 4 — Tests (AC: #6)
  - [x] Subtask 4.1 — `test/widget/features/settings/settings_screen_test.dart` — 4 cases per AC6.1. Reuse `_makeTestApp(...)` pattern from `test/widget/features/auth/login_screen_test.dart`; isolated `GoRouter` with `/settings`, `/settings/replace-credentials`, `/home`. Provider overrides: `credentialStoreProvider` (FakeCredentialStore), `dioProvider` (Dio + EvisitorFakeAdapter), `evisitorApiClientProvider`, `cookieJarDirectoryProvider`, `securityServiceProvider` (FakeSecurityService). Mock the `WindowSecureFlag` MethodChannel as in `login_screen_test.dart` lines 97–112.
  - [x] Subtask 4.2 — `test/widget/features/auth/login_screen_replace_mode_test.dart` — 7 cases per AC6.2. Same provider-override scaffolding as above.
  - [x] Subtask 4.3 — Update `test/widget/features/auth/login_screen_test.dart`'s "renders submit button" test with the regression assertion per AC6.3 (banner absent, pre-fill absent, default submit copy present in non-replace mode).
  - [x] Subtask 4.4 — Update `test/app_smoke_test.dart` per AC6.4 — 1 new test asserting gear-icon visibility on `/home` and Settings tile visibility after navigation.
  - [x] Subtask 4.5 — Run `flutter test` — all green; 204 total (192 baseline + 12 new); zero deletions.

- [x] Task 5 — Validation gate (AC: #8)
  - [x] Subtask 5.1 — `flutter test` — green (204/204).
  - [x] Subtask 5.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [x] Subtask 5.3 — `dart format --set-exit-if-changed lib test integration_test` — clean.
  - [x] Subtask 5.4 — PII grep guard per AC8.4 — clean (only structural references; no value interpolation).
  - [x] Subtask 5.5 — i18n literal-string guard per AC8.5 — clean (only comment lines hit).
  - [ ] Subtask 5.6 — Manual smoke against fake env per AC8.6 (deferred to user; emulator required).
  - [x] Subtask 5.7 — Update `_bmad-output/implementation-artifacts/deferred-work.md` per AC1.4 — re-defer the Story 1.4 ad-consent reopen tile to "future Settings expansion (1.9 ships only the credential re-entry tile per its AC)".

---

## Dev Notes

### Why this story is ninth

Story 1.7 made the *first* eVisitor login work; Story 1.8 made it the *only* login the host needs across cold starts. Story 1.9 makes that login *replaceable* without burning down everything else (facilities, queue, in-session OIB context). It is the load-bearing test that the Story 1.3 → 1.7 → 1.8 stack composes correctly under a credential mutation: write-replace into Keystore, write-replace into the cookie jar, no spillover into Drift (which holds nothing yet but will hold facilities by Story 3.1 and queue entries by Story 5.1). If 1.9 ships clean, every subsequent epic that adds Drift-backed state can rely on "credential changes never touch my table".

### Architecture mandates (non-negotiable)

- **Feature/core boundary**: `lib/features/settings/` is the right home (architecture line 687–691). The Settings screen does NOT import from `lib/features/auth/` directly — it routes via go_router's named route `'replace-credentials'`, which is declared in `lib/app/router.dart`. The Settings screen → LoginScreen coupling is route-level only.
- **`@riverpod` codegen only**: not applicable in this story — no new providers. `credentialStoreProvider` is consumed via `ref.read` in the existing `LoginNotifier`. The Settings screen reads no providers (it is a `ConsumerWidget` in form only because of the route-callback patterns; it could just as easily be `StatelessWidget` but `ConsumerWidget` future-proofs Story 2.9's auth-state row).
- **Drift-as-truth does NOT apply here** — this story creates no Drift tables and writes nothing to Drift. Facility/queue preservation is satisfied by *not touching* the (yet-to-exist) tables on either success or failure.
- **Result contract**: `loadCredentials()` and `saveCredentials()` already return `Result<_, StorageError>`. The pre-fill helper pattern-matches `is Ok<...>` — no thrown exceptions cross the LoginScreen boundary.
- **Single Dio instance**: Story 1.9 does not touch `dioProvider`. The cookie-replacement happens inside `CookieManager.onResponse` via the existing `cookieJarProvider` — same Dio, same jar, same intercept chain.
- **Dark mode primary**: Settings shell + replace banner build and verify dark first.
- **`mounted` check after async gaps**: `_hydrateUsernameFromKeystore` does `await ... if (!mounted) return;` before any `setState`/`text =`. Same convention as Story 1.7's `_maybeSubmit`.
- **`context.goNamed` not `context.go`**: per Story 1.6 retro patch — applies to the gear-icon `pushNamed('settings')` and the Settings tile `pushNamed('replace-credentials')`. Use `context.pop(true)` for the success return — `pop` does NOT have a `popNamed` variant (it pops by stack position, not by name).
- **`FLAG_SECURE` semantics**: the existing `WindowSecureFlag.enable()` in `LoginScreen.initState` covers replace mode by reuse. No additional FLAG_SECURE call needed. The Settings shell has no FLAG_SECURE per AC1.3 — the user only sees a single non-PII tile label.
- **Single-source test harness**: every new test file's `_makeTestApp` is a near-clone of `test/widget/features/auth/login_screen_test.dart`'s. **Do not** extract a shared `lib/test/test_app_harness.dart` in this story — three call sites (Story 1.7's existing, plus 1.9's two new) is below the duplication-pain threshold; abstraction would be *Muri*. Revisit when Story 5.5 (Home assembly) makes it five.

### Routing pipeline — order of evaluation (unchanged from Story 1.8)

The widget-tree wrapping order on cold start (outermost → innermost) is unchanged from Story 1.8: `ProviderScope` → `MaterialApp.router` → `ConsentGate` → `BootGate` → `Router`. Story 1.9 only adds new `GoRoute` nodes inside the `routerProvider` factory — no gate-layer change.

The new `/settings` route lives at the **top level** (sibling of `/home`, not nested under it). Why: Settings is post-onboarding territory and reachable from Home, but routing nesting in go_router maps to URL structure, not to UI back-stack. Top-level routes with `pushNamed` produce the back-stack semantics we want without forcing `/home/settings` URL paths.

### Cookie replacement — what happens in detail

When the host enters new credentials and `LoginNotifier.submit()` calls `EvisitorApiClient.login()`:

1. Dio sends `POST /Resources/AspNetFormsAuth/Authentication/Login` with the new `userName` + `password`. The request includes any *existing* cookies for the eVisitor host via `CookieManager.onRequest` — eVisitor's Login endpoint ignores them.
2. eVisitor responds `200 + body == true` with three `Set-Cookie` headers: `authentication=<new>; Path=/Resources/`, `affinity=<new>`, `language=<new>`.
3. `CookieManager.onResponse` (in the live Dio chain) reads the three `Set-Cookie` headers and calls `jar.saveFromResponse(...)` on each. `PersistCookieJar` updates by `(domain, path, name)` key — the new `authentication` cookie *replaces* the old one in place; same for `affinity` and `language`.
4. `LoginNotifier._handleSuccess` runs: `credStore.saveCredentials(username, password, evisitorApiKey)` — three Keystore writes; the new username/password *replace* the old via `flutter_secure_storage`'s overwrite semantics (Story 1.3 design).
5. `Result.Ok` returns to `LoginScreen._maybeSubmit` → `context.pop(true)`.
6. The Settings screen's `await context.pushNamed<bool>('replace-credentials')` resolves with `true`; SnackBar fires.

**No state is lost** because:
- `FacilitiesTable` does not exist yet (Story 3.1) — there is no facility row to invalidate.
- `GuestEntriesTable` does not exist yet (Story 5.1) — there is no queue row to invalidate.
- Neither Story 1.9 nor `LoginNotifier` ever calls `wipeCredentials()` or `jar.deleteAll(...)`. Only the Story 5.8 Replace-OIB flow and the Story 8.2 Delete-All flow hold that responsibility, and neither runs in 1.9's path.

### Previous story intelligence (Story 1.8)

- **`ConsumerStatefulWidget` widget-level lifecycle**: the existing `LoginScreen` is already `ConsumerStatefulWidget` (per Story 1.7); `replaceMode` reuses that lifecycle. No widget-shape change.
- **`_makeTestApp(...)` helper**: reuse the Story 1.7 / Story 1.8 pattern — isolated `GoRouter` with the routes the test exercises, full provider overrides. Mock the `WindowSecureFlag` MethodChannel in `setUp`.
- **`directives_ordering` lint** (Story 1.6 retro): package imports alphabetical in a single block. Apply to every new file (`settings_screen.dart`, both new test files).
- **`flutter_riverpod` import is required** in any file using `Ref` — applies to test fakes if any are added (none planned in 1.9).
- **`mounted` check after `addPostFrameCallback`**: same convention as Story 1.7's `_maybeSubmit` — `_hydrateUsernameFromKeystore` follows it.
- **Story 1.7 patch precedent**: state assignment after dispose. `LoginNotifier`'s `_disposed` flag (Story 1.7 lines 26–29) covers replace-mode submission paths identically.
- **Story 1.7 retro — `Directory.systemTemp.createTempSync(...)`**: not relevant to 1.9 directly (no PersistCookieJar test in this story), but if any new test instantiates a real cookie jar, the same temp-dir pattern applies.
- **Story 1.8 retro — `ref.read(routerProvider).goNamed()`**: applies *only* in `MaterialApp.router builder:` callbacks (e.g. inside `BootGate`). Inside route widgets — Settings, LoginScreen — `context.goNamed` / `context.pushNamed` / `context.pop` work normally because the build context has `InheritedGoRouter` in scope. Use the `context` form throughout 1.9.
- **Generated l10n**: `lib/l10n/app_localizations.dart` and per-locale variants regenerate on `flutter test` invocation (Story 1.5's `generate: true` setup). The deferred-work.md note from Story 1.5 (commit generated files) still applies — commit the regenerated files alongside the ARB diff.

### Result contract justification — why Settings screen is `ConsumerWidget`, not `StatelessWidget`

`ConsumerWidget` carries a `WidgetRef ref` parameter that this story does not use today. Two options:

1. **Ship as `StatelessWidget` today**, promote to `ConsumerWidget` when Story 2.9 wires the auth-state row.
2. **Ship as `ConsumerWidget` today**, accepting the unused `ref` parameter as a forward-looking choice.

Option 2 is the JIT-correct pick *only* because the migration cost is two characters (`Stateless` → `Consumer`); option 1's "wait" creates a 1-line diff churn the day Story 2.9 lands. The discipline cost is also two characters of cognitive overhead per future reader. A close call, but Riverpod 3 conventions in this codebase already favour `ConsumerWidget` as the default — every screen file in `lib/features/` is `Consumer*`. Mura (unevenness) wins the tie-break.

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| Create `CredentialReplaceScreen` as a sibling of `LoginScreen` | Extend `LoginScreen` with `replaceMode` per Story 1.7's reserved extension point (AC2.2) |
| Use `MaterialBanner` for the replace-mode banner | Plain `Container` with `surfaceContainerHigh` — `MaterialBanner` is reserved for Story 2.7's `CredentialBanner` (AC2.4 §WHY) |
| Call `jar.deleteAll()` before the new login submission | Cookies replace by name on the new `Set-Cookie` response — name collision is the contract (AC3.2) |
| Call `ref.invalidate(sessionBootstrapProvider)` after replace-success | Bootstrap is a cold-start decision; live re-entry has nothing to re-evaluate (AC3.4) |
| Use `context.goNamed('settings')` for the success return | `context.pop(true)` — go_router's documented pop-with-result idiom; `goNamed` would push a duplicate `/settings` (AC2.7 §WHY) |
| Add a separate `replaceCredentialsHeadline` ARB key | The banner above the existing headline disambiguates; reuse `loginHeadline` (AC2.6) |
| Auto-focus the username field in replace mode | Auto-focus the password — username is pre-filled (AC2.3 §WHY) |
| Add FLAG_SECURE to the Settings shell | Settings shell has no PII; FLAG_SECURE is per-window and propagating it pollutes future Settings sub-routes (AC1.3) |
| Promote the Settings screen to `ConsumerStatefulWidget` for a future Replace-OIB tile | YAGNI — `ConsumerWidget` is enough today; promote in the story that adds the lifecycle requirement (AC1.2) |
| Pre-build a `SettingsTile` custom widget for "the future N tiles" | One tile in v1.0 today; refactor to a custom widget when the third tile lands (AC1.5) |
| Add an `auth-state row`, `Replace OIB` tile, `Your Data` link, or `Privola za oglase` re-open in this story | Each is owned by a future story (Epic 2 Story 2.9, Story 5.8, Story 8.1, deferred from 1.4). Stay in scope (AC1.4) |
| Use `context.go('/settings')` from the `/home` placeholder gear icon | `context.pushNamed('settings')` — push (not replace) preserves the back-stack so the gear's back-gesture from Settings returns to Home (AC4.1) |
| Render the gear-icon `IconButton` with a hardcoded `Icons.settings` | `Symbols.settings_rounded` per design-system rules §3 (rounded variant is the house style) |
| Hand-format the SnackBar with `EdgeInsets.all(16)` or a custom `Container` | Material 3 `SnackBar` defaults are correct; do not override (AC1.6 + design-system §1) |
| Navigate from the LoginScreen success path *before* the Notifier resolves | `_maybeSubmit` already awaits `submit()` and then routes — keep that order (AC2.7) |
| Add an "Are you sure?" dialog before allowing re-entry | Re-entry is itself the confirmation; the success path requires the host to type a working password — that *is* the gate (UX-DR31: no confirmation dialogs in primary flows) |
| Wipe and re-create the cookie jar provider in the success path | The CookieManager's `Set-Cookie` write is the documented replacement vector (AC3.2) |
| Skip the `mounted` check after `await loadCredentials()` | Hot-restart and back-gesture during the ~10ms Keystore round-trip both unmount the screen mid-await; setState after dispose throws (AC2.3) |
| Add a `flutter_secure_storage` clear-and-rewrite sequence to "atomically" replace credentials | `saveCredentials` already overwrites by key (Story 1.3 design); a clear-then-write window introduces a race where the app is auth-less mid-flight |
| Modify `LoginNotifier` to take a `replaceMode` parameter | Notifier behaviour is identical in both modes; navigation differs at the *screen* level. Keep the notifier mode-agnostic (AC2.7) |

### Token and provider reference

| Provider | Type | Scope | Owner file | Touched by 1.9? |
|---|---|---|---|---|
| `credentialStoreProvider` | `Provider<CredentialStore>` | keepAlive | `lib/features/settings/credential_store.dart` | **Read** (loadCredentials in pre-fill; existing saveCredentials in success path) |
| `cookieJarProvider` | `Provider<CookieJar>` | keepAlive | `lib/app/providers.dart` | **Indirect**: live Dio's `CookieManager` writes new Set-Cookie via this jar |
| `dioProvider` | `Provider<Dio>` | keepAlive | `lib/app/providers.dart` | Unchanged shape; transitively used by `evisitorApiClientProvider` |
| `evisitorApiClientProvider` | `Provider<EvisitorApiClient>` | keepAlive | `lib/features/submission/evisitor_api_client.dart` | **Read** (login call in `LoginNotifier.submit` — same as Story 1.7) |
| `loginNotifierProvider` | `NotifierProvider<LoginNotifier, LoginState>` | autoDispose | `lib/features/auth/login_notifier.dart` | **Read** (existing — no shape change) |
| `routerProvider` | `Provider<GoRouter>` | keepAlive | `lib/app/router.dart` | **Modified**: adds `/settings` + `/settings/replace-credentials` routes; modifies `/home` builder for gear icon |
| `sessionBootstrapProvider` | `FutureProvider<SessionBootstrap>` | keepAlive | `lib/core/bootstrap/session_bootstrap_provider.dart` | **Untouched** — re-entry does not invalidate (AC3.4) |

### Project Structure Notes

**Files created:**
- `lib/features/settings/settings_screen.dart` — `ConsumerWidget` shell with one tile
- `test/widget/features/settings/settings_screen_test.dart` — 4 cases (AC6.1)
- `test/widget/features/auth/login_screen_replace_mode_test.dart` — 7 cases (AC6.2)

**Files modified:**
- `lib/features/auth/login_screen.dart` — add `replaceMode` + `prefilledUsername` ctor params; add `_hydrateUsernameFromKeystore`; banner panel above headline; submit-button label branch; success-path navigation branch
- `lib/app/router.dart` — add `/settings` and `/settings/replace-credentials` GoRoutes; modify `/home` placeholder builder to add gear-icon `AppBar` action
- `lib/l10n/app_en.arb` — 6 new keys (`settingsTitle`, `settingsButtonTooltip`, `settingsReplaceCredentialsLabel`, `settingsCredentialsUpdatedSnackbar`, `replaceCredentialsBanner`, `replaceCredentialsSubmitButton`) + `@<key>` descriptors
- `lib/l10n/app_hr.arb` — 6 new keys with Croatian copy verbatim from epics §Story 1.9 / FR7
- `lib/l10n/app_localizations*.dart` — regenerated via `generate: true`; commit
- `test/widget/features/auth/login_screen_test.dart` — single regression-guard assertion (AC6.3)
- `test/app_smoke_test.dart` — single new test (AC6.4)
- `_bmad-output/implementation-artifacts/deferred-work.md` — re-defer the Story 1.4 ad-consent reopen tile (AC1.4)

**This story does NOT create:**
- A new screen widget for replace-mode (extends LoginScreen instead per AC2.2)
- A new Riverpod provider (no auto-disposed `replaceCredentialsNotifier`; `LoginNotifier` is reused)
- A `CredentialBanner` widget — Story 2.7
- A `SettingsTile` custom widget — when 3rd tile lands (AC1.5)
- Any Drift table — explicit non-goal (AC3.3 doc)
- A test fake beyond Story 1.7's `FakeCredentialStore`
- A `ref.invalidate(sessionBootstrapProvider)` call site — AC3.4

### Deferred from previous stories relevant to this one

- **Story 1.4 deferred — "Privola za oglase" Settings tile**: the Settings shell ships in 1.9 but the ad-consent reopen tile remains deferred. Update the deferred-work.md entry to reflect that 1.9 only ships the credential re-entry tile (per its narrow AC), and re-target the ad-consent tile to a future "Settings expansion" story (likely paired with Story 10.1 closed-beta launch when the ad surface goes live).
- **Story 1.6 deferred — `restricted`/`limited` Android permission status fallback**: deferred entry currently reads "Address in Story 1.9 or a dedicated settings-screen remediation." 1.9 does NOT address this — Settings has no camera-permission row in v1.0. Re-defer to "future Settings camera-permission status row" (likely Epic 4 Story 4.5 area when scan-screen permission UX revisits).
- **Story 1.6 deferred — `openAppSettings()` return type widening**: not in 1.9's scope. Story 1.9 does not call `openAppSettings`. Re-defer.
- **Story 1.7 deferred — `LoginScreen` constructor extension point** (`{prefilledUsername, replaceMode}`): **THIS STORY closes that deferred item.** Update `deferred-work.md` accordingly during Subtask 5.7.
- **Story 1.8 deferred — `ref.invalidate(sessionBootstrapProvider)` on login success**: still deferred to Epic 2 Story 2.x (`AuthNotifier.login()`). 1.9 does NOT take this on (AC3.4 §WHY).

### Epic 2 / Epic 5 / Epic 8 consolidation contract — what future stories absorb

| Story 1.9 artifact | Future story successor | Migration cost |
|---|---|---|
| `LoginScreen.replaceMode` parameter | Subsumed by Story 2.7's `CredentialBanner` recovery flow + Story 2.8's credentials-missing recovery — both call into the same `replaceMode: true` rendering | Zero structural change; the parameter persists. Story 2.8 may pass `prefilledUsername` (the reserved 1.9 ctor param) when it knows the username from Drift but the Keystore was wiped |
| `settings_screen.dart` shell | Story 2.9 adds the auth-state row; Story 5.8 adds Replace OIB; Story 8.1 adds Your Data; Story 9.4 adds version chip | Each story extends the same `ListView`; no widget rewrite. Refactor to `SettingsTile` component when the *third* tile lands (likely Story 5.8 or 8.1) |
| Gear-icon `AppBar` action on `/home` placeholder | Story 5.5 builds the real `home_screen.dart` and ships its own gear (UX spec §AppBar line 648) | Delete the placeholder builder block entirely; Story 5.5 ships the replacement |
| `_hydrateUsernameFromKeystore` helper | Subsumed into `AuthNotifier.build()`'s pre-fill query (Story 2.1) | Move helper from screen to notifier; screen reads the prefilled value off `AuthState.replaceContext.username` |

### References

- [Architecture §App Architecture (Frontend) — feature folder layout, settings/](../planning-artifacts/architecture.md)
- [Architecture §Architectural Boundaries — feature dependency graph (settings has no inbound feature deps)](../planning-artifacts/architecture.md)
- [Architecture §Data boundary table — credentials in flutter_secure_storage; cookies in AES-GCM file; no auth in Drift](../planning-artifacts/architecture.md)
- [Architecture §External contract quirks — 3 cookies persisted ~14 days sliding via PersistCookieJar (AES-GCM encrypted at rest)](../planning-artifacts/architecture.md)
- [Architecture §Anti-Pattern Reference — `dynamic` without justification, autoDispose+ref.read race, BuildContext across async gaps](../planning-artifacts/architecture.md)
- [PRD §FR7 — Host can replace or re-enter credentials at any time from the Settings surface](../planning-artifacts/prd.md)
- [PRD §FR14.5 — Credentials-missing recovery preserving facility context (Epic 2 Story 2.8 — distinct from 1.9 happy-path replace)](../planning-artifacts/prd.md)
- [PRD §NFR-L1 — Croatian primary, English fallback; verbatim eVisitor UserMessage on failure](../planning-artifacts/prd.md)
- [PRD §NFR-S2 — Credentials live only in flutter_secure_storage; never in Drift, prefs, logs, or Crashlytics](../planning-artifacts/prd.md)
- [UX Spec §Settings accessible via gear icon, not cluttering primary flow](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Login flow — inline Croatian error directly under form, not transient banner](../planning-artifacts/ux-design-specification.md)
- [UX Spec §AppBar — gear icon top-right on Home (Story 5.5 owns the live home; 1.9 ships interim placeholder)](../planning-artifacts/ux-design-specification.md)
- [UX Spec §UX Consistency Hard Rules — UX-DR31 no confirmation dialogs in primary flows](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Localization & Copy — UX-DR24 full Croatian diacritics, sentence case, imperative CTAs](../planning-artifacts/ux-design-specification.md)
- [Epics §Story 1.9 — BDD acceptance criteria, Croatian copy verbatim](../planning-artifacts/epics.md)
- [Epics §FR7 traceability — Story 1.9 implements](../planning-artifacts/epics.md)
- [Epics §UX-DR22 — Settings assembly checklist (1.9 ships only the credential re-entry tile)](../planning-artifacts/epics.md)
- [Story 1.3 — SecurityService.init, EncryptedStorage, PersistCookieJar wiring](./1-3-security-primitives-dio-and-cert-pinning.md)
- [Story 1.4 — ConsentGate, deferred ad-consent reopen tile (re-deferred by 1.9)](./1-4-ump-cmp-eu-consent-surface.md)
- [Story 1.6 — Symbols.settings_rounded usage; context.goNamed convention](./1-6-camera-permission-with-manual-entry-fallback.md)
- [Story 1.7 — LoginScreen + LoginNotifier reuse contract; reserved ctor extension point closed by 1.9](./1-7-evisitor-login-and-live-credential-verification.md)
- [Story 1.7 §LoginScreen submit/save/navigate ordering](./1-7-evisitor-login-and-live-credential-verification.md)
- [Story 1.8 — sessionBootstrapProvider, BootGate, cookie viability check; not invalidated by 1.9](./1-8-session-persistence-across-restarts.md)
- [Story 1.8 §Cookie persistence verification — load-bearing assumption now extended to credential-replacement round-trip in production paths](./1-8-session-persistence-across-restarts.md)
- [Story 2.1 — AuthState sealed class; will subsume LoginState + replaceMode UI gating](../planning-artifacts/epics.md)
- [Story 2.7 — CredentialBanner; the architecture-blessed MaterialBanner subclass (1.9's banner is intentionally NOT one)](../planning-artifacts/epics.md)
- [Story 2.8 — Credentials-missing recovery; will pass `prefilledUsername` into LoginScreen via 1.9's reserved ctor param](../planning-artifacts/epics.md)
- [Story 2.9 — Auth-state row in Settings; first tile to extend the 1.9 Settings shell](../planning-artifacts/epics.md)
- [Story 3.1 — FacilitiesTable; AC's "facility profile preserved" becomes live the moment 3.1 ships](../planning-artifacts/epics.md)
- [Story 5.1 — GuestEntriesTable; AC's "queued guests preserved" becomes live the moment 5.1 ships](../planning-artifacts/epics.md)
- [Story 5.5 — Home screen assembly; replaces the placeholder `/home` and its interim gear-icon AppBar](../planning-artifacts/epics.md)
- [Story 5.8 — Replace active OIB; second Settings tile to extend the 1.9 shell](../planning-artifacts/epics.md)
- [Story 8.1 / 8.2 — Your Data + Delete All; third/fourth Settings tiles](../planning-artifacts/epics.md)
- [CLAUDE.md §Security & Privacy — credentials in Keystore only; no auth state in Drift; FLAG_SECURE on credential surfaces](../../CLAUDE.md)
- [CLAUDE.md §eVisitor API quirks — 3-cookie session contract; ASP.NET Forms Auth replacement semantics](../../CLAUDE.md)
- [.claude/rules/design-system.md §1 — never hardcode color/spacing/radius/text style](../../.claude/rules/design-system.md)
- [.claude/rules/design-system.md §3 — Symbols.* (rounded) is the house icon set](../../.claude/rules/design-system.md)
- [.claude/rules/design-system.md §4 — Material 3 primitives directly; custom widgets only when justified](../../.claude/rules/design-system.md)
- [.claude/rules/design-system.md §5 — minimum tap target 56×56dp; tooltip on every IconButton](../../.claude/rules/design-system.md)
- [`go_router` — pub.dev — pop with result idiom; pushNamed return type generic](https://pub.dev/packages/go_router)
- [`flutter_secure_storage` — pub.dev — write semantics overwrite by key](https://pub.dev/packages/flutter_secure_storage)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (Claude Sonnet 4.6)

### Debug Log References

- `tester.pageBack()` failed in settings_screen_test "no SnackBar on back" — LoginScreen has no AppBar so there is no UI back button; fixed to `tester.binding.handlePopRoute()` which simulates the hardware system back gesture.
- `prefer_const_constructors` infos on `Credentials(...)` constructor calls in 3 test files — fixed by adding `const` to all 6 sites; Freezed-generated const ctor supports this.
- `dart format` reformatted `router.dart`, `login_screen.dart`, `login_screen_replace_mode_test.dart` — accepted; no logic change.

### Completion Notes List

- Task 5.6 (manual smoke) deferred to user — emulator required; all automated gates passed.
- 204 tests total (192 Story 1.8 baseline + 12 new: 4 settings_screen_test + 7 login_screen_replace_mode_test + 1 app_smoke_test).
- `FakeCredentialStore.savedCredentials` assignment uses `const Credentials(...)` throughout test files per `prefer_const_constructors` lint.
- `tester.binding.handlePopRoute()` is the correct Flutter test idiom for system-back simulation when no UI back button exists (full-screen onboarding layout).

### File List

**Created:**
- `lib/features/settings/settings_screen.dart`
- `test/widget/features/settings/settings_screen_test.dart`
- `test/widget/features/auth/login_screen_replace_mode_test.dart`

**Modified:**
- `lib/features/auth/login_screen.dart`
- `lib/app/router.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hr.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_hr.dart`
- `test/widget/features/auth/login_screen_test.dart`
- `test/app_smoke_test.dart`
- `_bmad-output/implementation-artifacts/deferred-work.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Review Findings

_Code review on 2026-04-27 — 3 reviewer layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor). 13 patch / 5 deferred / 8 dismissed (1 decision-needed resolved → patch: remove `prefilledUsername`). Batch-applied 2026-04-28: 11 fixed, 2 skipped (judgment-required), 1 partial. Test count 204 → 206 (+2 new); all gates green._

**Patch**

- [x] [Review][Patch] Remove dead `prefilledUsername` ctor parameter (JIT — Story 2.8 reintroduces with its actual contract) [`lib/features/auth/login_screen.dart`]
- [x] [Review][Patch] `_hydrateUsernameFromKeystore` clobbers user-typed username and steals focus when Keystore read is slow — added `userIsInteracting` guard [`lib/features/auth/login_screen.dart`]
- [x] [Review][Patch] Double-tap on Settings tile pushes duplicate `replace-credentials` routes — converted to `ConsumerStatefulWidget` with `_navigating` flag [`lib/features/settings/settings_screen.dart`]
- [x] [Review][Patch] `context.pop(true)` lands on blank when route entered via deep link — added `canPop()` fallback to `goNamed('home')` [`lib/features/auth/login_screen.dart`]
- [x] [Review][Patch] AC6.2 banner test missing `surfaceContainerHigh` decoration assertion — added `find.byWidgetPredicate` decoration check [`test/widget/features/auth/login_screen_replace_mode_test.dart`]
- [x] [Review][Patch] No test exercises shallow-stack/deep-link entry — added `success-path falls back to /home when stack is shallow` test [`test/widget/features/auth/login_screen_replace_mode_test.dart`]
- [x] [Review][Patch] `'Home — Epic 3'` literal duplicated — extracted `_placeholderHomeText` const [`lib/app/router.dart`]
- [ ] [Review][Patch] Tests use literal Croatian strings instead of `l10n.<key>` getters — **skipped (judgment)**: project-wide convention uses literal copy in widget tests; auditor cited spec but applying narrowly to Story 1.9 would be inconsistent. Revisit in retro.
- [ ] [Review][Patch] AC6.2 lockout test doesn't drive 3 attempts or compare against non-replace baseline — **skipped (judgment)**: current test uses scripted `FakeLoginLockedOut`, "3 attempts" is production behaviour the fake shortcuts; non-replace lockout is already covered in `login_screen_test.dart`.
- [x] [Review][Patch] Success-path test doesn't assert popped `bool` payload nor `saveCredentials` call — **partial**: added `saveCredentials` assertion (`username: 'host42'`, `password: 'new-pass'`); popped-bool payload assertion not added (current stub-Settings design doesn't capture pop result; covered end-to-end by `settings_screen_test.dart` SnackBar test).
- [x] [Review][Patch] `WindowSecureFlag` MethodChannel mock state can bleed across test files — extracted to `test/helpers/window_secure_flag_mock.dart` [3 test files refactored]
- [x] [Review][Patch] No test asserts `clearError()` fires on field change in replace mode — added `typing in either field clears inline error after a failed re-entry` test [`test/widget/features/auth/login_screen_replace_mode_test.dart`]
- [x] [Review][Patch] `controller?.text, isEmpty` matcher passes when controller is `null` — `controller, isNotNull` then `controller!.text, isEmpty` in 3 sites [`test/widget/features/auth/login_screen_test.dart`, `test/widget/features/auth/login_screen_replace_mode_test.dart`]
- [x] [Review][Patch] Banner `Icon` not wrapped in `ExcludeSemantics` — wrapped [`lib/features/auth/login_screen.dart`]

**Deferred**

- [x] [Review][Defer] Story shipped as one squashed commit instead of one-commit-per-task — already pushed; cannot be retroactively split without rewriting published history. Raise in epic 1 retro.
- [x] [Review][Defer] `FakeCredentialStore.savedCredentials` cannot simulate `Err`/`StorageError` branch (no test for `_hydrateUsernameFromKeystore` failure path) — existing test-fake design; out of scope for Story 1.9.
- [x] [Review][Defer] LoginLockedOut state lost on back-gesture from replace mode — pre-existing Story 1.7 tech debt; Epic 2 Story 2.5 owns the circuit breaker.
- [x] [Review][Defer] Banner icon `size: 20` hardcoded — matches spec example AC2.4 verbatim but violates design-system rules §1; raise in Epic 1 retro to update spec example.
- [x] [Review][Defer] `app_smoke_test` overrides `cookieJarProvider` with in-memory `CookieJar()` not `PersistCookieJar` — test-scaffolding hygiene; not load-bearing today.
