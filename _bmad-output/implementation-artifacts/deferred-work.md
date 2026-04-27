# Deferred Work

Tracks items flagged during reviews that are real but not actionable in the story that surfaced them. Each entry links back to the source review.

## Deferred from: code review of story-1-1-project-bootstrap-and-ci-foundation (2026-04-24)

- PII grep regex bypassable by local-var assignment, alt log facades (`log.info`, `developer.log`, `Fimber`, `Talker`), and multiline-split interpolation. Grep is line-anchored and facade-enumerated. Complete fix requires PII wrapper types with `toString()` overrides (NFR-S7 type-level half, Epic 2+).
- `EVISITOR_ENV=fake` flag has no consumer branching in `lib/` yet. Consumer lands with Dio fake transport (Story 1.3+). Until then the enum resolves but nothing observes it.
- `build_aab.yml` does not emit `sha256sum app-release.aab` alongside the AAB artifact. Quality-of-life for correlating rebuilds with Play uploads; not spec-required.
- `.gitignore` anchor `!pubspec.lock` only un-ignores root-level. Nested `packages/*/pubspec.lock` remain ignored. Repo is single-module today; revisit if modularized.
- `.gitignore` retains Flutter-SDK template paths (`/bin/cache/`, `/dev/…`, `/packages/flutter/…`). User's deliberate choice — harmless no-ops in an app repo, but noise that could silently mask future files under those paths.
- `proguard-rules.pro` uses blanket `-keep class io.flutter.plugins.** { *; }` which defeats R8 tree-shaking. Spec accepts "class patterns from Drift's proguard guidance" — refine to per-plugin rules when the plugin actually imports (Stories 1.3+).
- Integration test asserts on literal English `'Hello World!'`. Will be replaced when l10n lands (Epic 1.2+).
- `CLAUDE.md -> AGENTS.md` symlink has no trailing newline; on Windows-clone (without developer mode) the symlink becomes a 9-byte file. Android-only project, Linux/Mac developers — accept for now.
- No `CODEOWNERS` file, no `docs/ci/branch-protection.md`. CI workflows are wired but merge policy (required status checks, review requirements) is not codified in the repo.
- `networkSecurityConfig` attribute merges into `src/debug` builds via manifest merger, preventing localhost HTTP to Dio fake fixture servers. Address in Story 1.3+ when the Dio fake lands (add `src/debug/res/xml/network_security_config.xml` permitting `10.0.2.2`).
- `actions/checkout@v4` defaults to `fetch-depth: 1`. Works today; becomes a trap the first time a workflow needs git history (changelog derivation, `git describe`).

## Deferred from: code review of story-1-2-design-system-foundation (2026-04-27)

- `semantic_colors_test.dart` doesn't directly exercise `buildLightTheme`/`buildDarkTheme` extension registration. Coverage is indirect via `theme_test.dart`'s `extension<SemanticColors>() != null` per-mode assertion. Direct test would close the gap.
- Icons guard regex (`Icon\s*\(\s*Icons\.`) matches forbidden shape if it appears inside a multi-line string literal or dartdoc code fence in `lib/**`. Latent false-positive trap; no current call site triggers it.
- `pubspec.lock` pulls heavy `native_toolchain_c`, `objective_c`, `jni`, `code_assets`, `record_use`, `path_provider_*` transitives via `google_fonts 8.x`. Cannot be removed without forking; apk size impact unverified.
- `outlinedButton` border uses `colorScheme.outline` directly. WCAG AA contrast vs dark surface is not asserted by any test. Accessibility test posture lands with Welcome / Onboarding (Story 1.5+) where outline-on-surface text first matters.
- `_DesignSystemPreview` does not handle `MediaQuery.textScaleFactor` extremes or RTL. Preview is throwaway and replaced by `WelcomeScreen` in Story 1.5; not worth hardening.
- `icons_test.dart` asserts package-internal font family string `MaterialSymbolsRounded`. Brittle to `material_symbols_icons` internals but currently the only signal that the rounded variant resolved.
- `Tokens.color` is a single-field nested class wrapping just `primarySeed`. Speculative scaffolding — AC1.1 mandates the namespace structure; future seed additions land here.
- Theme builder does not set `splashFactory` or `visualDensity` explicitly. Defensive future-proofing not required by AC2.5; revisit if Flutter SDK changes adaptive-density defaults.

## Deferred from: code review of story-1-4-ump-cmp-eu-consent-surface (2026-04-27)

- Settings list tile "Privola za oglase" is not wired in this story — Settings UI lands in Story 1.9. `ConsentService.showPrivacyOptionsForm()` and `isPrivacyOptionsRequired()` are exposed and ready for Story 1.9 to consume.
- Real-SDK integration test (UMP form on Android emulator with `DebugGeography.debugGeographyEea`) deferred to Story 10.1 canary test — requires emulator with Play Services and a valid AdMob test device ID; CI-fragile at this stage.
- Architecture doc line 673 still lists `lib/features/onboarding/consent_screen.dart`. Update to `lib/core/consent/consent_gate.dart` in a small follow-up PR or Story 1.5.
- `FakeConsentService` missing `showPrivacyOptionsForm` scripting — cannot test error path for `reopenPrivacyOptions()`. Add `scriptedPrivacyFormResult` param when Story 1.9 wires the Settings tile.
- No test for `reopenPrivacyOptions()` on `ConsentController` — method is unwired until Story 1.9; add test coverage when Settings tile is implemented.
- `requestNonPersonalizedAds_test.dart` uses `testWidgets` with unused `WidgetTester` parameter — should be plain `test()` with `ProviderContainer` for consistency with `consent_controller_test.dart`. Cleanup.
- ProGuard `-keep class com.google.android.gms.ads.**` is too broad — keeps entire Mobile Ads SDK from R8 tree-shaking. Refine to UMP-only classes when Story 10.1 lands and actual ad format usage is known.
- `docs/release-checklist.md` not CI-enforced — no automated guard against shipping sample AdMob App ID `ca-app-pub-3940256099942544~3347511713`. A CI grep for the sample ID in `AndroidManifest.xml` would be a real Poka-yoke.

## Deferred from: code review of story-1-3-security-primitives-dio-and-cert-pinning (2026-04-27)

- `EncryptedStorage` methods before `init` throw `LateInitializationError` from `late _currentDirectory`. PersistCookieJar always calls init first today; harden when a second caller appears.
- `SecurityService.init` re-entrancy: concurrent `init()` calls can pass the `_initialized` guard during the await window, generating two keys. Hot-restart edge case; revisit when AuthNotifier (Story 2.x) touches `init`.
- `EvisitorFakeAdapter` returns 200 for any path. Flesh out endpoint routing in Story 1.7 (login) and Story 6.3 (ImportTourists) per the existing TODO.
- Fake env compile-time guard for prod builds: assert `evisitorEnv != fake` in `kReleaseMode`. Wire when Story 10.x release-readiness lands.
- `cryptography_flutter` unmaintained (last release > 2 years). Evaluate replacement before Epic 5 (Drift PII column encryption) hardens dependence.
- `FakeFlutterSecureStorage` overrides only `read/write/delete`. Future tests calling `containsKey/readAll/deleteAll` will throw `MissingPluginException`; extend when needed.
- `integration_test/app_test.dart` `dioProvider` override is dead code today — no widget consumes `dioProvider` until first network-call screen (Story 1.7). Re-validate when WelcomeScreen or LoginScreen actually triggers the path.
- `SecurityService` corrupt stored AES-GCM key handling: Jidoka by AC9.4 WHY ("crashes visibly at launch"). Re-evaluate if real-world corrupt-state reports come in.

## Deferred from: code review of story-1-5-welcome-and-sensitive-data-disclosure (2026-04-27)

- Generated `app_localizations*.dart` committed to `lib/l10n/` — spec AC2.5 intended generated l10n files NOT committed, but modern Flutter with `generate: true` outputs to `lib/l10n/` not `.dart_tool/flutter_gen/`. Pragmatically correct to commit since they're in `lib/` and the import path is `package:prijavko/l10n/app_localizations.dart`. Revisit if Flutter changes output location back to `.dart_tool/`.
