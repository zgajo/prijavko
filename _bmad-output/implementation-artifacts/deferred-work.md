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
