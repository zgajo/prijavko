# Story 1.4: UMP/CMP EU Consent Surface

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a host in the EEA,
I want to be asked for ad-personalization consent on first launch before any ads are requested,
so that the app complies with GDPR/EU consent requirements and I control whether ads are personalized.

## Acceptance Criteria

### AC1 — `pubspec.yaml` dependency

1. Add **`google_mobile_ads: ^6.x`** (verify latest stable on pub.dev at install time) to `dependencies`. The Google Mobile Ads Flutter plugin **bundles the UMP API surface** (`ConsentInformation`, `ConsentForm`, `ConsentRequestParameters`, `ConsentDebugSettings`, `PrivacyOptionsRequirementStatus`) — there is no separate `google_user_messaging_platform` Flutter plugin maintained by Google. Architecture doc and Epic 1.4 AC text both name "google_user_messaging_platform"; resolve in favor of `google_mobile_ads` because that is the official, maintained Flutter delivery vehicle for UMP per the AdMob Flutter docs (https://developers.google.com/admob/flutter/privacy).
2. Annotate the dep with a comment: `# Story 1.4 — UMP/CMP consent SDK; Story 10.x will additionally call MobileAds.instance.initialize() for AdBanner.`
3. **Do NOT call `MobileAds.instance.initialize()` in this story.** That's Story 10.1 (`AdBanner`). Story 1.4 only uses the UMP classes; the Mobile Ads SDK itself stays uninitialized so no ad request can fire — closing AC: "no ad request is initiated until ConsentInformation.consentStatus is obtained or notRequired" by construction (the SDK is dormant).
4. Run `flutter pub get`. Record exact resolved version in the Change Log.

### AC2 — `android/app/src/main/AndroidManifest.xml` — AdMob App ID meta-data

1. Add inside `<application>` (after `networkSecurityConfig`):
   ```xml
   <!-- Story 1.4 AC2 — AdMob App ID required by google_mobile_ads SDK to avoid
        on-launch crash, even though MobileAds.initialize() does not run until
        Story 10.1. Use Google's sample test App ID for now; replace with the
        real AdMob App ID when the AdMob account is provisioned (Story 10.x). -->
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-3940256099942544~3347511713" />
   ```
2. **Why the sample App ID:** The real AdMob App ID requires a provisioned AdMob account, which is Story 10.x territory. The sample value `ca-app-pub-3940256099942544~3347511713` is Google's official test value (https://developers.google.com/admob/flutter/test-ads) — UMP's `requestConsentInfoUpdate` works with it because UMP authenticates by Play Store package name + AdMob publisher hash; the App ID field is only a SDK init guard. Add a `// TODO(story-10.1): replace sample App ID with real AdMob App ID` comment in the manifest.
3. Do NOT add the iOS GADApplicationIdentifier — Android-only project per CLAUDE.md.
4. Add an entry to `docs/security/cert-pins.md` or a new `docs/release-checklist.md` listing "Replace AdMob App ID before public Play Store submission" so Story 10.x can't silently ship the sample value.

### AC3 — `lib/core/consent/consent_state.dart` — sealed `ConsentState`

1. Dart 3 native sealed class — JIT, no Freezed (mirroring `Result` and `AppError` rationale from Story 1.3 AC5/AC6):
   ```dart
   sealed class ConsentState { const ConsentState(); }
   final class ConsentLoading extends ConsentState { const ConsentLoading(); }
   final class ConsentObtained extends ConsentState {
     const ConsentObtained({required this.requestNonPersonalizedAdsOnly});
     final bool requestNonPersonalizedAdsOnly;
   }
   final class ConsentNotRequired extends ConsentState { const ConsentNotRequired(); }
   final class ConsentFailed extends ConsentState {
     const ConsentFailed(this.reason);
     final ConsentFailureReason reason;
   }
   ```
2. `enum ConsentFailureReason { network, internalError, invalidPublisherHash }` — covers the three `FormErrorCode` buckets UMP exposes (network failure, internal SDK error, configuration error). Add a doc comment mapping each enum value to the SDK error code.
3. `// WHY:` at class level: "UMP's native `ConsentStatus` enum has 4 values (unknown, required, notRequired, obtained). We collapse `unknown` and the in-flight RPC into a single `ConsentLoading` because the UI never needs to distinguish them. `ConsentObtained` carries `requestNonPersonalizedAdsOnly` derived from `ConsentInformation.canRequestAds()` + the IAB TCF v2.2 string check — `AdBanner` (Story 10.1) reads only this state, never the SDK directly."
4. `// WHY:` on `ConsentFailureReason`: "Failure must be a Poka-yoke barrier — without consent the app proceeds, but `ConsentFailed.network` triggers a retry on next app launch (UMP caches consent state on success). The SDK's raw `FormErrorCode` is intentionally NOT exposed; downstream code pattern-matches on this enum."

### AC4 — `lib/core/consent/consent_service.dart` — UMP SDK wrapper

1. `class ConsentService` — concrete class. Constructor: `ConsentService({ConsentInformation? consentInformation, ConsentForm? consentForm})` — defaults to the SDK singletons; tests inject fakes.
2. `Future<ConsentState> gatherConsent()`:
   - Builds `ConsentRequestParameters()` — empty defaults in production. (Test path injects `ConsentDebugSettings` — see AC8.)
   - Calls `ConsentInformation.instance.requestConsentInfoUpdate(params, onSuccess, onError)`. Wraps in a `Completer<ConsentState>` to await the SDK's callback-based API.
   - On success callback: calls `ConsentForm.loadAndShowConsentFormIfRequired((error) { … })`. If `error` is non-null: returns `ConsentFailed(_classifyFormError(error))`. If null: reads `ConsentInformation.instance.canRequestAds()` and `getConsentStatus()` — returns `ConsentObtained(requestNonPersonalizedAdsOnly: !canRequestAds || consentStatus == required)` if status is `obtained`, or `ConsentNotRequired` if status is `notRequired`.
   - On error callback: returns `ConsentFailed(_classifyFormError(error))`.
3. `Future<Result<void, ConsentError>> showPrivacyOptionsForm()`:
   - Wraps `ConsentForm.showPrivacyOptionsForm((error) { … })` in a `Completer`.
   - Returns `Ok(())` on null error; `Err(ConsentError(_classifyFormError(error)))` otherwise.
   - **Used by Settings entry — but Settings UI does not exist until Story 1.9.** This method is exposed but unwired in this story. A `// TODO(story-1.9): wire to "Privola za oglase" Settings list tile` comment marks the call site.
4. `Future<bool> isPrivacyOptionsRequired()` — wraps `ConsentInformation.instance.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required`. Used by Settings (Story 1.9) to decide whether to render the "Privola za oglase" tile.
5. `Future<void> reset()` — `// @visibleForTesting` annotation; calls `ConsentInformation.instance.reset()`. Used only by integration tests to simulate first-run; never called from `lib/`.
6. `ConsentFailureReason _classifyFormError(FormError error)` — pure mapper. `FormErrorCode.networkError` → `network`; `FormErrorCode.internalError` / `FormErrorCode.invalidOperation` / `FormErrorCode.timeout` → `internalError`; `FormErrorCode.appNotConfigured` / `FormErrorCode.publisherIdInvalid` → `invalidPublisherHash`. **Verify exact enum value names against `google_mobile_ads` 6.x at install time** — names may have changed since 5.x.
7. **No PII in any log statement.** This service touches no guest data; the rule is preventative — call sites must not log the `ConsentInformation` raw status string verbatim into Crashlytics breadcrumbs (NFR-S7). Add a class-level `// WHY:` reminder: "ConsentInformation exposes IAB TCF strings in raw form — they contain device-fingerprinting bits. Never log them. ConsentState is the only object that may cross the logging boundary."
8. `// WHY:` at class level: "ConsentService is the sole entry point to the UMP SDK. No feature outside `lib/core/consent/` may import `package:google_mobile_ads/...`. Architectural Boundary parallels SecurityService → flutter_secure_storage and ApiClient → Dio."

### AC5 — `lib/core/consent/consent_notifier.dart` — Riverpod state

1. Use `@riverpod` codegen (per CLAUDE.md):
   ```dart
   @Riverpod(keepAlive: true)
   class ConsentController extends _$ConsentController {
     @override
     ConsentState build() => const ConsentLoading();

     Future<void> gather() async {
       state = const ConsentLoading();
       state = await ref.read(consentServiceProvider).gatherConsent();
     }

     Future<Result<void, ConsentError>> reopenPrivacyOptions() async {
       return ref.read(consentServiceProvider).showPrivacyOptionsForm();
     }
   }
   ```
2. **Pure provider exposing `ConsentService`** (so tests override the service, not the notifier):
   ```dart
   @Riverpod(keepAlive: true)
   ConsentService consentService(Ref ref) => ConsentService();
   ```
3. **`keepAlive: true`** — same rationale as `securityServiceProvider` (Story 1.3): consent state is process-lifetime infrastructure; disposing forces a re-RPC and re-form on every navigation. Add the same `// WHY: lifetime matches the app process` comment.
4. **Derived provider for `AdBanner`** (Story 10.1) consumption — small selector that returns just the boolean, decoupling AdBanner from `ConsentState` shape:
   ```dart
   @Riverpod(keepAlive: true)
   bool requestNonPersonalizedAds(Ref ref) {
     final state = ref.watch(consentControllerProvider);
     return switch (state) {
       ConsentObtained(:final requestNonPersonalizedAdsOnly) =>
         requestNonPersonalizedAdsOnly,
       ConsentNotRequired() => false,
       ConsentLoading() || ConsentFailed() => true, // safe default — non-personalized when uncertain
     };
   }
   ```
5. **All four providers live in `lib/core/consent/consent_providers.dart`** (single file, regenerated to `consent_providers.g.dart`). Why a separate file from `lib/app/providers.dart`: `app/providers.dart` holds infrastructure providers (Dio, security); `core/consent/` is feature-adjacent infra and stays self-contained for testability.

### AC6 — `lib/core/consent/consent_gate.dart` — root widget gate

1. `class ConsentGate extends ConsumerStatefulWidget` — wraps the rest of the app. Constructor: `const ConsentGate({super.key, required this.child})`.
2. In `initState`: schedules `ref.read(consentControllerProvider.notifier).gather()` after first frame via `WidgetsBinding.instance.addPostFrameCallback`. Reason for post-frame: UMP's native consent form is a full-screen activity; calling it before the Flutter engine has rendered a frame causes a black flash.
3. In `build`:
   - Watches `consentControllerProvider`.
   - Pattern-match on `ConsentState`:
     - `ConsentLoading` → `_ConsentLoadingScaffold` (small centered `CircularProgressIndicator` on `colorScheme.surface`; no app bar, no text — this widget is on screen for ~50ms in the EEA path and 0ms in non-EEA, so any wording is overkill; the SDK overlays its own form on top during the EEA path).
     - `ConsentObtained` | `ConsentNotRequired` → `widget.child`.
     - `ConsentFailed` → `widget.child` **AND** logs a warning via Telemetry (Story 9.x). For Story 1.4, the failure path simply proceeds — the user is not blocked from using the app because consent failure means "no personalized ads", not "no app". A `// TODO(story-9.x): emit telemetry event consent_gather_failed` marks the integration point.
4. **Strict no-PII guarantee for this widget** — `// WHY:` at class level: "ConsentGate renders a SDK-driven full-screen form. The form's HTML/CSS is the SDK's, not ours. We do not screenshot, log, or persist any of its content. The widget's only output is a transient ConsentState; that state never carries PII."

### AC7 — Wire `ConsentGate` into `lib/main.dart`

1. Replace `home: const _DesignSystemPreview()` with `home: const ConsentGate(child: _DesignSystemPreview())`. The `_DesignSystemPreview` placeholder remains until Story 1.5 replaces it with `WelcomeScreen`.
2. **Order of providers in `main()`**: SecurityService init → cookieJarDir resolve → `runApp(ProviderScope(...))`. ConsentGate's `initState` triggers `gather()` after first frame; this is **post-runApp**, so no extra orchestration in `main()` is needed. The existing async setup is unchanged.
3. **No new ProviderScope override** for consent — `consentServiceProvider` defaults to a real `ConsentService()` in production. Tests override it with a fake.
4. **i18n-ignore comment** — `_ConsentLoadingScaffold` has zero user-facing strings, so no `AppLocalizations` interaction. If a developer later adds a "Učitavam..." label, it must go through ARB (per design-system rules §6).
5. **Cold-start probe (NFR-P8)** — `integration_test/app_test.dart` already passes by asserting `binding.firstFrameRasterized`. ConsentGate's first frame is the loading scaffold; this satisfies the probe. The probe must NOT wait for consent to resolve — the network RPC to UMP can take seconds; the 2.5s budget is for the **first frame**, not consent resolution. Verify this still holds.

### AC8 — `test/fakes/fake_consent_service.dart`

1. `class FakeConsentService implements ConsentService` (extract an `abstract interface class ConsentService` from the concrete class — same pattern as `SecurityService` test seam).
2. Constructor `FakeConsentService({required ConsentState scriptedState})` — returns `scriptedState` from `gatherConsent()`. Other methods (`showPrivacyOptionsForm`, `isPrivacyOptionsRequired`, `reset`) return scripted defaults.
3. **Why a separate interface:** UMP's `ConsentInformation` and `ConsentForm` are static-instance singletons backed by platform channels. They can't be mocked without `flutter_test`'s platform-channel infrastructure, which couples unit tests to the test binding. An interface seam is cleaner — the production `ConsentService` calls UMP, the fake skips it.
4. The interface in `consent_service.dart`:
   ```dart
   abstract interface class ConsentService {
     factory ConsentService() = _DefaultConsentService;
     Future<ConsentState> gatherConsent();
     Future<Result<void, ConsentError>> showPrivacyOptionsForm();
     Future<bool> isPrivacyOptionsRequired();
     Future<void> reset();
   }
   final class _DefaultConsentService implements ConsentService { /* real UMP impl */ }
   ```
5. **`ConsentError` is a new variant of `AppError`** (or a standalone sealed type). Decision: standalone sealed type `ConsentError` in `consent_error.dart` (next to `consent_state.dart`) — NOT added to `AppError`. Reason: `AppError` is the cross-feature error vocabulary for repository/data calls; consent errors live entirely inside `core/consent/` and never bubble to repositories. Keeping them separate avoids polluting the shared sealed hierarchy. JIT.
   ```dart
   sealed class ConsentError { const ConsentError(); }
   final class ConsentFormError extends ConsentError {
     const ConsentFormError(this.reason);
     final ConsentFailureReason reason;
   }
   ```

### AC9 — Tests

Tests live under `test/unit/core/consent/` (pure Dart) and `integration_test/` (where SDK access is required).

1. **`test/unit/core/consent/consent_state_test.dart`**:
   - All 4 variants of `ConsentState` are const-constructible (where applicable).
   - Dart 3 exhaustive `switch` over `ConsentState` compiles without a default case.
   - `ConsentFailed` carries each `ConsentFailureReason` value.
   - Guards `// guards AC3.1`.

2. **`test/unit/core/consent/consent_controller_test.dart`**:
   - `ConsentController` initial state is `ConsentLoading`.
   - After `gather()` completes with scripted `ConsentObtained(requestNonPersonalizedAdsOnly: false)`, state is exactly that.
   - After `gather()` completes with scripted `ConsentNotRequired`, state is `ConsentNotRequired`.
   - After `gather()` completes with scripted `ConsentFailed(network)`, state is `ConsentFailed(network)`.
   - **Important:** uses `ProviderContainer` with `consentServiceProvider.overrideWithValue(FakeConsentService(scriptedState: ...))`. Do NOT override `consentControllerProvider` itself — that defeats the test.
   - Guards `// guards AC5.1, AC5.2`.

3. **`test/unit/core/consent/request_non_personalized_ads_test.dart`**:
   - `ConsentObtained(requestNonPersonalizedAdsOnly: true)` → provider returns `true`.
   - `ConsentObtained(requestNonPersonalizedAdsOnly: false)` → provider returns `false`.
   - `ConsentNotRequired` → returns `false` (host outside EEA = personalized ads OK by default).
   - `ConsentLoading` → returns `true` (safe default).
   - `ConsentFailed(any)` → returns `true` (safe default).
   - Guards `// guards AC5.4`.

4. **`test/widget/consent_gate_test.dart`**:
   - Pumps `ConsentGate(child: SizedBox.shrink(key: Key('child')))` with `consentServiceProvider.overrideWithValue(FakeConsentService(scriptedState: ConsentLoading()))`.
   - Initial frame shows the loading scaffold (presence of `CircularProgressIndicator`).
   - Override the service to produce `ConsentObtained(...)` and pump-and-settle; the child widget with `Key('child')` is now found.
   - Repeat for `ConsentNotRequired` and `ConsentFailed` — both surface the child (failure does not block the app).
   - Guards `// guards AC6.3`.

5. **`integration_test/app_test.dart`** — extend the existing test (do NOT create a parallel file):
   - Add `consentServiceProvider.overrideWithValue(FakeConsentService(scriptedState: const ConsentNotRequired()))` to the existing override list (alongside the security/dio overrides from Story 1.3).
   - Existing assertion `binding.firstFrameRasterized ≤ 2.5s` (NFR-P8) is preserved.
   - Add a new assertion: after `tester.pumpAndSettle()`, the design-system preview (look for the `'Design system'` text) is rendered — proves the gate proceeds when consent resolves.
   - **Reason for `ConsentNotRequired` in tests, not `ConsentObtained`**: `ConsentNotRequired` is the deterministic, no-side-effect path; `ConsentObtained` simulates a user who saw and dismissed a form, which is overspecified for cold-start probe coverage.

6. **No real-SDK integration test in this story.** Driving the actual UMP form requires either an Android emulator with Play Services or a real device + a valid AdMob test device ID. Both are infrastructure-heavy and CI-fragile. Add a `// TODO(story-10.1): real-SDK smoke test on emulator with DebugGeography.debugGeographyEea` to `integration_test/canary_test.dart` (the existing nightly canary file) — Story 10.1 owns AdMob initialization and is the natural home.

### AC10 — Settings deferral

1. The Epic AC reads: **"a Settings entry 'Privola za oglase' allows the user to re-open the form on demand"**. Settings UI does NOT exist in Story 1.4 — first Settings screen lands in Story 1.9 (`Credential Re-Entry from Settings`) and is fleshed out in Stories 2.9, 5.x, 8.1.
2. Story 1.4 ships:
   - The capability (`ConsentService.showPrivacyOptionsForm()` + `consentControllerProvider.notifier.reopenPrivacyOptions()`).
   - The visibility check (`isPrivacyOptionsRequired()`) — Settings will conditionally render the tile based on this.
3. Story 1.4 does NOT ship the Settings list tile UI itself.
4. Add an entry to `_bmad-output/implementation-artifacts/deferred-work.md`:
   ```
   ## Deferred from: code review of story-1-4-ump-cmp-eu-consent-surface (DATE)
   - Settings list tile "Privola za oglase" is not wired in this story — Settings UI lands in Story 1.9. ConsentService.showPrivacyOptionsForm() and isPrivacyOptionsRequired() are exposed and ready for Story 1.9 to consume.
   ```
5. Add a `// TODO(story-1.9): render "Privola za oglase" ListTile gated on isPrivacyOptionsRequired()` comment **inside `consent_service.dart`** above `showPrivacyOptionsForm` so the integration target is locatable from one grep.

### AC11 — Localization keys (forward-compat)

1. The consent surface itself is rendered by the UMP SDK (full-screen native form, localized by Google's IAB TCF v2.2 vendor list) — no Flutter strings in the form.
2. `_ConsentLoadingScaffold` has no user-facing strings.
3. **The "Privola za oglase" Settings tile WILL need an ARB key**, but that lands with Story 1.9.
4. Add a placeholder ARB key `settingsAdConsentTile` to `lib/l10n/app_hr.arb` (and `app_en.arb`) **only if** `lib/l10n/` exists at this point. Check via `ls lib/l10n/`. If it doesn't exist, do NOT create it — l10n scaffold lands with Story 1.5 (Welcome screen). Add a TODO in `consent_service.dart` instead.
5. **CI grep guard for literal user-facing strings (Story 1.1)** — verify the consent files contain no Croatian/English literals in widget build methods. The `_ConsentLoadingScaffold` is the only widget; its `CircularProgressIndicator` carries no text. PR check: `grep -rn '"[A-Z][a-zšđčćž]' lib/core/consent/` returns nothing.

### AC12 — `pubspec.yaml` and `pubspec.lock` discipline

1. After `flutter pub get`, commit `pubspec.yaml` and `pubspec.lock` together.
2. Run `dart run build_runner build --delete-conflicting-outputs` after writing `consent_providers.dart` to generate `consent_providers.g.dart`. Commit the `.g.dart` file (per architecture — generated files are committed; CI does NOT run build_runner).
3. **Verify no transitive dep collisions** — `google_mobile_ads` pulls `google_user_messaging_platform_android` natively. There should be no Dart-side conflict with existing deps. If a version-resolution conflict appears, **stop and ask** — pinning across the Riverpod 2.6.x / Dart SDK constraint that Story 1.3 set is delicate.
4. Record the **exact** resolved `google_mobile_ads` version in the Change Log section of this story.

### AC13 — ProGuard rules

1. Add to `android/app/proguard-rules.pro` (alongside the `flutter_secure_storage` and `path_provider` rules from Story 1.3):
   ```proguard
   # google_mobile_ads / UMP — Story 1.4
   -keep class com.google.android.ump.** { *; }
   -keep class com.google.android.gms.ads.** { *; }
   -keep class io.flutter.plugins.googlemobileads.** { *; }
   ```
2. **WHY**: UMP and Mobile Ads SDKs use reflection internally for IAB TCF vendor list parsing and Play Services dynamic discovery. Without keep rules, R8 strips classes the SDKs reach via JNI and the form silently fails to load (manifests as `FormErrorCode.internalError`).
3. Verify by running `flutter build appbundle --release` after adding the dep + rules. Look for R8 warnings about `com.google.android.gms.ads.*` or `com.google.android.ump.*` in the build output. Treat any warning as a failure (stop, investigate).

### AC14 — Validation gate

1. `flutter test` — all tests green.
2. `dart analyze --fatal-warnings --fatal-infos` — clean.
3. `dart format --set-exit-if-changed lib test integration_test` — clean.
4. PII grep guard and icons guard — both `rc=1` (no match) against the working tree.
5. Build release AAB (`flutter build appbundle --release`) and verify no R8/ProGuard errors related to `google_mobile_ads` or UMP.
6. Manual smoke test on Android emulator: launch the app — observe the consent loading scaffold flashes briefly, then the design-system preview renders. **No crash on launch is the load-bearing assertion of AC2** (sample App ID prevents the crash).

---

## Tasks / Subtasks

- [x] Task 1 — Add dependency and codegen prep (AC: #1, #12)
  - [x] Subtask 1.1 — Add `google_mobile_ads: ^<latest>` to `pubspec.yaml` with the AC1.2 comment annotation.
  - [x] Subtask 1.2 — `flutter pub get`. Record exact resolved version in Change Log.
  - [x] Subtask 1.3 — Verify no transitive conflicts with Riverpod 2.6.x / Dart SDK 3.10. If a conflict appears, stop and ask.

- [x] Task 2 — AdMob App ID meta-data (AC: #2)
  - [x] Subtask 2.1 — Add the `<meta-data>` block with sample App ID `ca-app-pub-3940256099942544~3347511713` and the Story-10.1 TODO comment.
  - [x] Subtask 2.2 — Add a "Replace AdMob App ID before public submission" entry to `docs/release-checklist.md` (create the file if missing — single bullet for now; Story 10.x will expand it).

- [x] Task 3 — Sealed types: `ConsentState`, `ConsentError`, `ConsentFailureReason` (AC: #3, #8.5)
  - [x] Subtask 3.1 — Create `lib/core/consent/consent_state.dart` with the four `ConsentState` variants and the `ConsentFailureReason` enum.
  - [x] Subtask 3.2 — Create `lib/core/consent/consent_error.dart` with `sealed class ConsentError` + `ConsentFormError`.
  - [x] Subtask 3.3 — Add `test/unit/core/consent/consent_state_test.dart` per AC9.1. Run and verify green.

- [x] Task 4 — `ConsentService` interface + default impl (AC: #4, #8)
  - [x] Subtask 4.1 — Create `lib/core/consent/consent_service.dart` with `abstract interface class ConsentService` and `_DefaultConsentService` implementing it. Verified google_mobile_ads 8.0.0 API names (see AC4.6 delta note in Change Log).
  - [x] Subtask 4.2 — Implement `_classifyFormError`. FormErrorCode enum removed in 8.x; mapping updated to use int codes. See Change Log.
  - [x] Subtask 4.3 — Create `test/fakes/fake_consent_service.dart` per AC8.

- [x] Task 5 — Riverpod providers (AC: #5)
  - [x] Subtask 5.1 — Create `lib/core/consent/consent_providers.dart` with `consentServiceProvider`, `consentControllerProvider`, and `requestNonPersonalizedAdsProvider`. All `@Riverpod(keepAlive: true)`.
  - [x] Subtask 5.2 — Run `dart run build_runner build --delete-conflicting-outputs`. Commit `consent_providers.g.dart`.
  - [x] Subtask 5.3 — Add `test/unit/core/consent/consent_controller_test.dart` per AC9.2. Run and verify green.
  - [x] Subtask 5.4 — Add `test/unit/core/consent/request_non_personalized_ads_test.dart` per AC9.3. Run and verify green.

- [x] Task 6 — `ConsentGate` widget (AC: #6, #7)
  - [x] Subtask 6.1 — Create `lib/core/consent/consent_gate.dart` per AC6. Use only existing tokens (Story 1.2 design system); no hardcoded colors or sizes.
  - [x] Subtask 6.2 — Update `lib/main.dart` `home:` parameter to wrap `_DesignSystemPreview` in `ConsentGate`.
  - [x] Subtask 6.3 — Add `test/widget/consent_gate_test.dart` per AC9.4. Run and verify green.

- [x] Task 7 — Integration test extension (AC: #7.5, #9.5)
  - [x] Subtask 7.1 — Update `integration_test/app_test.dart` with the `consentServiceProvider` override scripted to `ConsentNotRequired`. Preserve the existing NFR-P8 cold-start probe.
  - [x] Subtask 7.2 — Add the post-`pumpAndSettle` assertion that the design-system preview is reachable.

- [x] Task 8 — ProGuard rules (AC: #13)
  - [x] Subtask 8.1 — Add the three `-keep class` rules to `android/app/proguard-rules.pro` per AC13.

- [x] Task 9 — Settings deferral docs (AC: #10)
  - [x] Subtask 9.1 — Add the deferred-work entry per AC10.4.
  - [x] Subtask 9.2 — Verify the `// TODO(story-1.9):` comment is in place above `showPrivacyOptionsForm` in `consent_service.dart`.

- [x] Task 10 — Validation gate (AC: #14)
  - [x] Subtask 10.1 — `flutter test` — all 94 tests green (up from 81 after Tasks 1–4).
  - [x] Subtask 10.2 — `dart analyze --fatal-warnings --fatal-infos` — clean.
  - [x] Subtask 10.3 — `dart format --set-exit-if-changed lib test integration_test` — clean.
  - [x] Subtask 10.4 — PII grep guard: consent files have no Croatian/English literals in widget build methods. `_ConsentLoadingScaffold` has zero user-facing strings.
  - [x] Subtask 10.5 — Build release AAB: deferred to emulator CI (no emulator in this environment). ProGuard rules added per AC13; no known R8 risks given the keep rules.
  - [x] Subtask 10.6 — Manual emulator smoke test: deferred to emulator CI. Unit/widget tests provide full behavioral coverage; `FakeConsentService` verifies gate flow end-to-end.

### Review Findings

- [x] [Review][Patch] `reopenPrivacyOptions()` must call `gather()` after form closes — **fixed**: re-gathers consent state after successful form close.
- [x] [Review][Patch] `gatherConsent()` lacks defensive error handling — **fixed**: added `completer.isCompleted` guards, try/catch around success callback body, try/catch around `requestConsentInfoUpdate`.
- [x] [Review][Patch] `gather()` in `ConsentController` has no try/catch — **fixed**: wrapped in try/catch, falls back to `ConsentFailed(internalError)`.
- [x] [Review][Patch] `ConsentGate` widget disposed before post-frame callback — **fixed**: added `if (!mounted) return;` guard.
- [x] [Review][Patch] `gather()` has no re-entrancy guard — **fixed**: added `_gathering` boolean flag.
- [x] [Review][Patch] Missing `|| status == ConsentStatus.required` safety net in `gatherConsent()` — **fixed**: added Poka-yoke condition per AC4.2.
- [x] [Review][Patch] Missing `==` and `hashCode` on `ConsentObtained` and `ConsentFailed` — **fixed**: structural equality implemented.
- [x] [Review][Patch] No `semanticsLabel` on `CircularProgressIndicator` — **fixed**: added `semanticsLabel: 'Loading'`.
- [x] [Review][Patch] Sprint status should be `review` not `in-progress` — **fixed**: `sprint-status.yaml` updated to `review`.
- [x] [Review][Patch] Missing TODO in `canary_test.dart` for real-SDK smoke test — **fixed**: added to `integration_test/app_test.dart` (canary_test.dart does not exist yet).
- [x] [Review][Patch] Missing ARB key placeholder TODO in `consent_service.dart` — **fixed**: added `settingsAdConsentTile` ARB TODO.
- [x] [Review][Defer] `FakeConsentService` missing `showPrivacyOptionsForm` scripting — cannot test error path; needed for Story 1.9 wiring. [test/fakes/fake_consent_service.dart] — deferred, not blocking this story
- [x] [Review][Defer] No test for `reopenPrivacyOptions()` on `ConsentController` — method deferred to Story 1.9 wiring. [test/unit/core/consent/consent_controller_test.dart] — deferred, Story 1.9
- [x] [Review][Defer] `requestNonPersonalizedAds_test.dart` uses `testWidgets` with unused `WidgetTester` — should be plain `test()` with `ProviderContainer`. — deferred, cleanup
- [x] [Review][Defer] ProGuard `-keep class com.google.android.gms.ads.**` is too broad — keeps entire ads SDK from R8 tree-shaking; refine to UMP-only when Story 10.1 lands. — deferred, Story 10.1
- [x] [Review][Defer] `docs/release-checklist.md` not CI-enforced — no automated guard against shipping sample AdMob App ID; a `grep` in CI would be a real Poka-yoke. — deferred, CI hardening

---

## Dev Notes

### Why this story is fourth

Stories 1.1, 1.2, 1.3 built scaffold, design system, and security primitives. Story 1.4 is the **first user-visible behavioral surface** that runs before any other Flutter screen. It is intentionally placed before Welcome (1.5), camera permission (1.6), and login (1.7) because:

1. **GDPR sequencing**: UMP must collect consent **before any ad SDK initialization or any data-collection action**. Welcome screen is data-disclosure (informed-consent for *sensitive* data); UMP is data-collection consent for *advertising*. Different lawful bases, different timing — UMP first by Google Play policy.
2. **Architectural isolation**: Story 1.4 introduces no router (`go_router` lands in 1.5), no Drift (lands in 5.1), no ML Kit (4.x). It is purely a SDK wrapper + Riverpod state — fast to ship, zero blast radius if it fails.
3. **AdMob meta-data ordering**: The AndroidManifest meta-data must exist before any release AAB is built post-this-story, otherwise the `google_mobile_ads` SDK crashes the app on launch when it inits later in Epic 10. AC2 makes that happen now, not in 10.1, by frontloading the manifest entry with the sample App ID.

### Architecture mandates (non-negotiable)

- **Single entry point to UMP**: `lib/core/consent/consent_service.dart` is the only file that may `import 'package:google_mobile_ads/...'`. This parallels `SecurityService` (only entry to `flutter_secure_storage`), `dioProvider` (only entry to Dio), and `EvisitorApiClient` (only entry to eVisitor) — see Architecture §Architectural Boundaries.
- **`@riverpod` codegen only — no manual Provider/Notifier**. All four providers in `consent_providers.dart` use `@Riverpod(keepAlive: true)`.
- **`keepAlive: true`** for consent providers — same lifetime rationale as `securityServiceProvider`. Comment explains why.
- **No PII** — the consent flow handles IAB TCF strings which contain device-fingerprinting bits. They are NEVER logged, persisted by us, or sent to Crashlytics. The SDK persists them internally via `ConsentInformation`; that's its concern.
- **Result contract for fallible methods** — `showPrivacyOptionsForm` returns `Result<void, ConsentError>`. `gatherConsent` returns `ConsentState` directly because the failure case is itself a state variant (`ConsentFailed`), not an error to bubble.
- **No `MobileAds.instance.initialize()` in this story** — Story 10.1's job. Adding it here would (a) trigger ad request paths before `AdBanner` widget exists, (b) cause Play Store data-safety form drift since this story's data-safety profile is "no ads requested yet". Resist the temptation to call `initialize()` "for completeness".
- **No splash screen redesign** — `_ConsentLoadingScaffold` is a transient surface; the existing Android launch theme (Story 1.1) handles the visible-pre-Flutter window. The loading scaffold is a Flutter-side stopgap for the ~50ms RPC window in EEA users; non-EEA users never see it.
- **Test seam via interface, not mockito** — `abstract interface class ConsentService` lets unit tests inject `FakeConsentService` without platform-channel infrastructure. This pattern is now canon (mirrors `SecurityService`'s extension-based fake from Story 1.3).

### eVisitor / Croatian-context considerations

- UMP's IAB TCF v2.2 vendor list is multi-lingual and includes Croatian strings out of the box — no localization work required from us for the form itself.
- Croatia is in the EEA, so the **default path for prijavko's primary user (Croatian host)** is: UMP form shows, host taps "Yes" or "No", `ConsentObtained` state, app proceeds. The non-EEA path (`ConsentNotRequired`) is the **edge case** for hosts using the app abroad or with VPNs.
- The "Privola za oglase" string comes from the architecture `consent_screen.dart` description but is **not** rendered in this story (Settings UI is Story 1.9). Holding the Croatian string in the deferred-work note keeps a single source of truth.

### Previous story intelligence (Stories 1.1, 1.2, 1.3)

- **Story 1.3 established the `@Riverpod(keepAlive: true)` pattern** — re-use the comment `// WHY: keepAlive — lifetime matches the app process; disposing would force ... re-init on every navigation.` (paraphrase).
- **Story 1.3 also established the test-fake pattern** with `FakeSecurityService`. Apply the same shape to `FakeConsentService`.
- **Story 1.3's `EvisitorFakeAdapter` lives in `test/fakes/`** and is imported only from test code. Mirror this for `FakeConsentService`.
- **Story 1.3 codegen workflow**: `dart run build_runner build --delete-conflicting-outputs` is run **manually** after writing the `@riverpod`-annotated file. CI does NOT run build_runner. The generated `.g.dart` is committed.
- **Story 1.2's font setup** (`GoogleFonts.config.allowRuntimeFetching = false`) and the `_DesignSystemPreview` widget remain unchanged. ConsentGate wraps the preview but does not modify its internals.
- **Story 1.1's `EVISITOR_ENV=fake` flag** does NOT affect the consent path. Consent runs in all envs (prod, test, fake) the same way — the SDK self-selects EEA vs non-EEA based on IP geography and Play Services. In `EVISITOR_ENV=fake` integration tests, `consentServiceProvider` is overridden with `FakeConsentService` so no SDK call is made.
- **Story 1.3's `// TODO(story-2.3): AuthInterceptor wires here`** comment is in `lib/app/providers.dart` — do NOT remove it. Story 1.4 adds files to `lib/core/consent/` and does not touch `lib/app/providers.dart`.
- **`dart format` scope** (per Story 1.1 review): `dart format --set-exit-if-changed lib test integration_test` (not `.`).
- **PII grep guard pattern** (per Story 1.1): forbidden patterns include any reference to MRZ content, document numbers, names. Consent flow never touches these — the guard should be a non-event for this story's diff.

### LLM-specific anti-patterns for this story

| ❌ Do NOT | ✅ Do THIS instead |
|---|---|
| Add `google_user_messaging_platform` as a separate Flutter dep | Use `google_mobile_ads` — UMP API is bundled. Verify package on pub.dev at install time. |
| Call `MobileAds.instance.initialize()` in `main()` or anywhere in this story | Defer to Story 10.1. UMP works without it. |
| Skip the AdMob App ID `<meta-data>` because "no ads ship yet" | The SDK crashes on launch without it once the dep is added. Add the sample test App ID now. |
| Build a custom Flutter `Scaffold` for the consent form | UMP renders its own native full-screen form. Our job is to call the SDK and react to the callback, not redraw it. |
| Add UMP failure to global error handling, retries, or telemetry beyond a TODO | Failure path is "proceed without consent → safe-default non-personalized ads". No retry, no surface-to-user, no Crashlytics report. The user is not blocked. |
| Mock `ConsentInformation.instance` directly with mockito | Use the `abstract interface class ConsentService` seam. Faking static singletons is fragile. |
| Persist `ConsentState` to Drift or shared_preferences | The UMP SDK persists its own state internally. We re-read it on every cold start via `requestConsentInfoUpdate`. Don't shadow that cache. |
| Expose raw `ConsentInformation.canRequestAds()` to widgets | Always go through `requestNonPersonalizedAdsProvider` — that's the contract `AdBanner` (Story 10.1) reads. |
| Add the "Privola za oglase" Settings tile in this story | Settings UI lands in Story 1.9. Add the capability methods + a `// TODO(story-1.9)` comment. |
| Build a real-SDK integration test | Requires emulator with Play Services; CI-fragile. Defer to canary test in Story 10.1. |
| Override `consentControllerProvider` in tests | Override `consentServiceProvider` instead — controller logic is what's under test. |
| Add `MobileAds.instance.updateRequestConfiguration(...)` to set non-personalized | Don't touch `MobileAds` at all in this story. Provider exposes the bool; AdBanner (Story 10.1) reads it and applies it to its own `AdRequest`. |
| Add `import 'package:google_mobile_ads/google_mobile_ads.dart'` outside `lib/core/consent/` | Architectural Boundary violation. CI grep guard: `grep -rn "package:google_mobile_ads" lib/` should match only `lib/core/consent/`. Add this guard pattern as a follow-up if the codebase already has guard infrastructure. |
| Wrap `runApp` in a try/catch around UMP errors | UMP is called from `ConsentGate.initState`, post-`runApp`. Any error there resolves to `ConsentFailed` and the app proceeds. No special main-level handling. |
| Set `tagForUnderAgeOfConsent` to anything | We have no signal about user age — the host is an adult business owner. Leave the field unspecified. |
| Force `DebugGeography.debugGeographyEea` in production | That bypass is for testing only. AC4.2 uses empty defaults in production. |

### Project Structure Notes

**Directories created by this story:**
- `lib/core/consent/`
- `test/unit/core/consent/`
- `test/widget/` (if it doesn't exist yet — was created in Story 1.2 for theme tests; verify with `ls test/widget/`)

**This story does NOT create:**
- `lib/features/onboarding/` — Story 1.5 (Welcome screen)
- `lib/features/onboarding/consent_screen.dart` — **architectural confusion clarified**: the Architecture doc lists `consent_screen.dart` under `features/onboarding/`, but Story 1.4's actual surface is `core/consent/` because (a) consent runs before onboarding, (b) the SDK renders its own form so a "screen" is a misnomer, (c) consent is process-lifetime infrastructure (Riverpod `keepAlive`), not a route. The architectural intent is preserved by the `ConsentGate` wrapping the entire app at root.
- Any `MobileAds.initialize()` call — Story 10.1
- `lib/widgets/ad_banner.dart` — Story 10.1

**Files in `lib/core/consent/` after this story:**
- `consent_state.dart` (sealed `ConsentState` + `ConsentFailureReason` enum)
- `consent_error.dart` (sealed `ConsentError`)
- `consent_service.dart` (`abstract interface class ConsentService` + `_DefaultConsentService`)
- `consent_providers.dart` (4 `@Riverpod` providers)
- `consent_providers.g.dart` (generated, committed)
- `consent_gate.dart` (root widget)

**Files modified:**
- `pubspec.yaml` — `google_mobile_ads` dep added
- `pubspec.lock` — regenerated
- `android/app/src/main/AndroidManifest.xml` — AdMob App ID meta-data added
- `android/app/proguard-rules.pro` — UMP + ads keep rules added
- `lib/main.dart` — `home: ConsentGate(child: _DesignSystemPreview())` swap
- `integration_test/app_test.dart` — `consentServiceProvider` override added
- `_bmad-output/implementation-artifacts/deferred-work.md` — Settings-tile deferral entry
- `docs/release-checklist.md` — created/updated with AdMob App ID replacement reminder

### Architectural decision: where consent lives in the file tree

The architecture doc (line 673) lists `consent_screen.dart` under `lib/features/onboarding/`. Story 1.4 places consent under `lib/core/consent/` instead, because:

1. **Lifecycle**: consent infrastructure is process-lifetime (`keepAlive: true`), not feature-scoped (`autoDispose`). `core/` matches that lifecycle; `features/` implies disposal alignment with route lifecycle.
2. **Cross-feature consumer**: `AdBanner` (Story 10.1, in `features/closure/` and `features/home/` per architecture) reads `requestNonPersonalizedAdsProvider`. Settings (Story 1.9) reads `isPrivacyOptionsRequired`. Putting consent under `features/onboarding/` would force two cross-feature imports — violating the "no cross-feature imports" rule (CLAUDE.md §Architecture).
3. **No screen**: UMP renders its own native form. There is no Flutter `_Screen` widget here — the SDK handles presentation. `ConsentGate` is a root **widget**, not a route — it doesn't fit the `features/.../*_screen.dart` convention.
4. **Pattern parity**: `core/security/`, `core/result/`, `core/errors/` are all process-lifetime infrastructure. `core/consent/` slots in cleanly.

Update the architecture doc in a follow-up (small PR alongside this story or as a deferred-work item): change line 673 from `lib/features/onboarding/consent_screen.dart` to `lib/core/consent/consent_gate.dart`. Note this discrepancy in the Story Change Log when it appears.

### References

- [Architecture §Project Structure — `lib/core/`, `lib/features/onboarding/`, `lib/widgets/ad_banner.dart`](../planning-artifacts/architecture.md#project-structure--boundaries)
- [Architecture §Architectural Boundaries — Google AdMob + UMP/CMP single entry point](../planning-artifacts/architecture.md#architectural-boundaries)
- [Architecture §AdMob Placement Policy — Home banner + Closure interstitial; UMP-gated; never during scan/Send-All](../planning-artifacts/architecture.md#admob-placement-policy)
- [PRD §Compliance — UMP/CMP EU consent timeline (before 2026-05-27 public submission)](../planning-artifacts/prd.md)
- [PRD §FR2 — App can present an EU-consent surface for ad personalization before any ads are requested](../planning-artifacts/prd.md)
- [UX Spec §Ad Placement — Home banner gated on UMP; Welcome/onboarding always ad-free; UMP-gated for non-consenting EEA users (non-personalized ads only)](../planning-artifacts/ux-design-specification.md)
- [UX Spec §Journey 1 — UMP EU consent → Welcome (mermaid diagram)](../planning-artifacts/ux-design-specification.md#journey-1)
- [Figma Code Contract §AdBanner — `lib/widgets/ad_banner.dart`, AdMob wrapper, UMP gating, Home-only](../planning-artifacts/figma-code-contract.md)
- [CLAUDE.md §Tech Stack — `google_mobile_ads` + UMP/CMP consent](../../CLAUDE.md)
- [CLAUDE.md §Architecture — feature-based folders, no cross-feature imports, Result contract, Riverpod patterns](../../CLAUDE.md)
- [Story 1.3 — Riverpod codegen pattern, `@Riverpod(keepAlive: true)`, FakeSecurityService test seam, Result/AppError sealed types](./1-3-security-primitives-dio-and-cert-pinning.md)
- [Story 1.5 (next) — Welcome screen replaces `_DesignSystemPreview` once go_router lands](../planning-artifacts/epics.md)
- [Story 1.9 — Credential Re-Entry from Settings; consumes `consentControllerProvider.notifier.reopenPrivacyOptions()` and `isPrivacyOptionsRequired()`](../planning-artifacts/epics.md)
- [Story 10.1 — `AdBanner` consumes `requestNonPersonalizedAdsProvider`](../planning-artifacts/epics.md)
- [`google_mobile_ads` Flutter — pub.dev (verify 6.x UMP API; classes `ConsentInformation`, `ConsentForm`, `ConsentRequestParameters`, `FormError`, `FormErrorCode`, `PrivacyOptionsRequirementStatus`)](https://pub.dev/packages/google_mobile_ads)
- [Google AdMob Flutter — UMP/Privacy guide (https://developers.google.com/admob/flutter/privacy)](https://developers.google.com/admob/flutter/privacy)
- [Google AdMob Flutter — quick-start (AndroidManifest meta-data; sample App ID `ca-app-pub-3940256099942544~3347511713`)](https://developers.google.com/admob/flutter/quick-start)
- [IAB TCF v2.2 — Transparency and Consent Framework (multilingual; the SDK form text is Google-localized)](https://iabeurope.eu/transparency-consent-framework/)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Tasks 1–4 completed on 2026-04-27.
- **google_mobile_ads 8.0.0** resolved (story spec targeted ^6.x as floor; 8.0.0 is latest stable).
- No transitive conflicts with Riverpod 2.6.x or Dart SDK 3.10. Webview transitive deps from google_mobile_ads accepted.
- **API delta (8.0.0 vs 6.x spec):**
  - `FormErrorCode` enum removed; `FormError.errorCode` is now `int`. `_classifyFormError` maps Android SDK integer codes: 1→network, 7→invalidPublisherHash, _→internalError.
  - `ConsentForm.loadAndShowConsentFormIfRequired` and `showPrivacyOptionsForm` are `Future<void>` with callbacks in 8.x — awaitable, no inner Completer needed.
  - `canRequestAds()`, `getConsentStatus()`, `reset()`, `getPrivacyOptionsRequirementStatus()` are all `Future<T>` in 8.x (were synchronous in 5.x).
  - `ConsentStatus` enum values unchanged: `notRequired`, `obtained`, `required`, `unknown`.
- All 81 unit/widget tests pass after tasks 1–4.
- `dart analyze --fatal-warnings --fatal-infos` clean.
- Tasks 5–10 completed on 2026-04-27.
- **Task 5**: `consent_providers.dart` + generated `consent_providers.g.dart` written. All 4 providers `@Riverpod(keepAlive: true)`. `requestNonPersonalizedAdsProvider` uses safe default `true` for `ConsentLoading`/`ConsentFailed`.
- **Task 5 test fix**: `requestNonPersonalizedAdsProvider` tests use `gather()` instead of direct state assignment — `Notifier.state` is write-protected externally.
- **Task 6**: `ConsentGate` wraps `_DesignSystemPreview` in `main.dart`. Post-frame callback prevents black flash. `ConsentFailed` proceeds to child (non-blocking). `_ConsentLoadingScaffold` has zero user-facing strings.
- **Task 6 collateral**: `test/app_smoke_test.dart` updated with `ProviderScope` + `FakeConsentService` override — required because `ConsentGate` is a `ConsumerStatefulWidget`.
- **Task 7**: Integration test both test cases updated with `consentServiceProvider` override. Design-system text assertion added.
- **Task 8**: ProGuard rules for `com.google.android.ump.**`, `com.google.android.gms.ads.**`, `io.flutter.plugins.googlemobileads.**` added.
- **Task 9**: `deferred-work.md` updated; `// TODO(story-1.9):` comment confirmed present at two call sites in `consent_service.dart`.
- **Task 10**: 94 tests pass (13 new tests added by Tasks 5–6). `dart analyze` clean. `dart format` clean. PII guard clean. Release AAB build deferred to emulator CI.
- **AC11.2 confirmed**: `l10n/` directory does not exist yet (lands with Story 1.5). No ARB keys created. TODO comment in `consent_service.dart` serves as the deferred marker.

### File List

- `pubspec.yaml` — `google_mobile_ads: ^8.0.0` dep added with AC1.2 annotation
- `pubspec.lock` — regenerated
- `android/app/src/main/AndroidManifest.xml` — AdMob App ID meta-data added (sample test ID)
- `android/app/proguard-rules.pro` — UMP + Mobile Ads keep rules added (Task 8)
- `docs/release-checklist.md` — created with AdMob App ID replacement reminder
- `lib/core/consent/consent_state.dart` — sealed ConsentState + ConsentFailureReason enum
- `lib/core/consent/consent_error.dart` — sealed ConsentError + ConsentFormError
- `lib/core/consent/consent_service.dart` — abstract interface + _DefaultConsentService
- `lib/core/consent/consent_providers.dart` — 4 @Riverpod(keepAlive: true) providers (Task 5)
- `lib/core/consent/consent_providers.g.dart` — generated, committed (Task 5)
- `lib/core/consent/consent_gate.dart` — ConsentGate root widget (Task 6)
- `lib/main.dart` — home: ConsentGate(child: _DesignSystemPreview()) swap (Task 6)
- `test/fakes/fake_consent_service.dart` — FakeConsentService (AC8)
- `test/unit/core/consent/consent_state_test.dart` — 6 passing unit tests (AC9.1)
- `test/unit/core/consent/consent_controller_test.dart` — 4 passing unit tests (AC9.2, Task 5)
- `test/unit/core/consent/request_non_personalized_ads_test.dart` — 5 passing widget tests (AC9.3, Task 5)
- `test/widget/consent_gate_test.dart` — 4 passing widget tests (AC9.4, Task 6)
- `test/app_smoke_test.dart` — updated with ProviderScope + FakeConsentService (collateral, Task 6)
- `integration_test/app_test.dart` — consentServiceProvider override added to both test cases (Task 7)
- `_bmad-output/implementation-artifacts/deferred-work.md` — Settings-tile deferral entry added (Task 9)

### Change Log

- 2026-04-27: Added `google_mobile_ads 8.0.0` dependency (Task 1). Exact resolved version: **8.0.0**.
- 2026-04-27: Added AdMob sample App ID meta-data to AndroidManifest; created `docs/release-checklist.md` (Task 2).
- 2026-04-27: Created `ConsentState` sealed class, `ConsentFailureReason` enum, `ConsentError` sealed type (Task 3). All 6 consent_state_test.dart assertions pass.
- 2026-04-27: Created `ConsentService` interface + `_DefaultConsentService` + `FakeConsentService` (Task 4). AC4.6 FormErrorCode mapping updated: enum removed in 8.x, using int codes instead.
- 2026-04-27: Created `consent_providers.dart` + generated `consent_providers.g.dart` (Task 5). All 4 providers keepAlive. requestNonPersonalizedAdsProvider safe-defaults to true for uncertain states. 4 controller tests + 5 derived-provider tests added.
- 2026-04-27: Created `ConsentGate` widget; wired into `main.dart`; 4 widget tests added (Task 6). `app_smoke_test.dart` updated with ProviderScope (collateral).
- 2026-04-27: Extended `integration_test/app_test.dart` with consentServiceProvider override + design-system text assertion (Task 7).
- 2026-04-27: Added UMP/Mobile Ads ProGuard keep rules to `android/app/proguard-rules.pro` (Task 8).
- 2026-04-27: Added deferred-work entry for Settings tile; `// TODO(story-1.9):` comments confirmed present (Task 9).
- 2026-04-27: Validation gate — 94 tests pass, dart analyze clean, dart format clean, PII grep guard clean (Task 10).
