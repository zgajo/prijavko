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
