# Story 1.2: Design System Foundation

Status: done

Satisfies: NFR-A1, NFR-A2, NFR-A4, NFR-L1 — see [PRD §Non-Functional Requirements](../planning-artifacts/prd.md#non-functional-requirements)

## Story

As a developer implementing any screen,
I want a single source of truth for colors, spacing, radii, typography, and semantic extensions,
so that no widget ever hardcodes a hex value, a magic spacing number, or an inline `TextStyle` and the entire app responds to system dark/light mode with WCAG AA contrast by default.

## Acceptance Criteria

### AC1 — `lib/design/tokens.dart` (pure const, no logic)

1. File `lib/design/tokens.dart` exists and exports a single top-level `class Tokens` (private constructor) that groups four nested `const` classes per `figma-code-contract.md §1`:
   - `Tokens.color` — `static const Color primarySeed = Color(0xFF0D4F52);` (Adriatic Teal). No other `Color` constants — all runtime colors derive from `ColorScheme.fromSeed(seedColor: Tokens.color.primarySeed, brightness: …)` or from the `SemanticColors` extension (AC3).
   - `Tokens.space` — `static const double s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s24 = 24.0, s32 = 32.0, s48 = 48.0, s64 = 64.0;` — 4dp base grid from UX spec §Spacing & Layout Foundation.
   - `Tokens.radius` — `static const double button = 12.0, card = 16.0, sheet = 24.0;` — from UX spec §Visual Design Foundation + figma-code-contract.md §1.
   - `Tokens.size` — `static const double buttonMinHeight = 56.0;` — one-handed night-shift ergonomics (PRD NFR-C3, UX spec §Accessibility).
2. The file imports nothing beyond `package:flutter/material.dart` (for the `Color` type). No `google_fonts` import here — typography construction lives in `theme.dart` (a pure-const file cannot hold a `TextTheme` built from a network/asset-resolving factory).
3. All four classes have unnamed private constructors (`const Tokens._();`) so instantiation is impossible; the class is a namespace only. Kaizen + Poka-yoke: types forbid misuse.
4. No additional `Color` / spacing / radius constants beyond those listed. Any new token lands by editing this file and getting PR review — no "just this once" inline.

### AC2 — `lib/design/theme.dart` (light + dark `ThemeData`)

1. File exports two pure functions: `ThemeData buildLightTheme()` and `ThemeData buildDarkTheme()`.
2. Each is built from `ColorScheme.fromSeed(seedColor: Tokens.color.primarySeed, brightness: Brightness.light | Brightness.dark)` — no hand-rolled `ColorScheme(…)` constructor, no `FlexColorScheme` or equivalent package.
3. Each attaches Manrope via `GoogleFonts.manropeTextTheme(baseTheme.textTheme)` and then `.copyWith(…)` maps the 12 Figma text styles to Material 3 `TextTheme` slots exactly per `figma-code-contract.md §2` (size / weight / lineHeight for `displayLarge … labelMedium`). Weight enforcement:
   - `displayLarge` — 57 / 800 / 64
   - `displayMedium` — 45 / 700 / 52
   - `headlineLarge` — 32 / 700 / 40
   - `headlineMedium` — 28 / 700 / 36
   - `headlineSmall` — 24 / 600 / 32
   - `titleLarge` — 22 / 600 / 28
   - `titleMedium` — 16 / 600 / 24
   - `bodyLarge` — 16 / 400 / 24
   - `bodyMedium` — 14 / 400 / 20
   - `bodySmall` — 12 / 500 / 16
   - `labelLarge` — 14 / 600 / 20
   - `labelMedium` — 12 / 600 / 16
4. Each registers the `SemanticColors` `ThemeExtension` (AC3) via `extensions: <ThemeExtension<dynamic>>[SemanticColors.light()]` for light and `SemanticColors.dark()` for dark.
5. Component theme defaults live in `ThemeData` component slots — NOT per-widget overrides:
   - `filledButtonTheme` — `minimumSize: Size.fromHeight(Tokens.size.buttonMinHeight)` (56dp), `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radius.button))`.
   - `outlinedButtonTheme` — `minimumSize: Size.fromHeight(48)` (UX spec §Button Hierarchy — 48dp for secondary), 1.5px outline, `BorderRadius.circular(Tokens.radius.button)`.
   - `textButtonTheme` — shape-only; no min-height beyond M3 defaults.
   - `cardTheme` — `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radius.card))`, `margin: EdgeInsets.zero` (padding lives on parents, not on `Card`).
   - `bottomSheetTheme` — `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius.sheet)))`.
   - `inputDecorationTheme` — `border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.radius.button))`, `contentPadding: EdgeInsets.symmetric(horizontal: Tokens.space.s16, vertical: Tokens.space.s12)`.
6. Both functions are `@visibleForTesting`-free and pure — calling twice yields equal `ThemeData` (verified by reference-stable component theme objects; spot-check with a widget test that `buildLightTheme().filledButtonTheme == buildLightTheme().filledButtonTheme` structurally).
7. `useMaterial3: true` is set explicitly on both — do not rely on Flutter's future default.

### AC3 — `lib/design/extensions.dart` — `ThemeExtension<SemanticColors>`

1. File declares `class SemanticColors extends ThemeExtension<SemanticColors>` with **required named** constructor parameters — no defaults — so construction fails fast when a variant is forgotten:
   - `warning`
   - `warningContainer`
   - `onWarningContainer`
   - `success`
   - `onSuccess`
   - `closureAccent`
   - `surfaceContainerHigh`
   - `outlineVariant`
2. Provides two named factory constructors with hardcoded values from UX spec §Color System:
   - `SemanticColors.light()` — `warning: Color(0xFFED6C02)`, `warningContainer: Color(0xFFFFE2B8)` *(derived M3 warmth on light surface — document the choice inline as a `// WHY:` comment)*, `onWarningContainer: Color(0xFF2E1500)`, `success: Color(0xFF2E7D32)`, `onSuccess: Color(0xFFFFFFFF)`, `closureAccent: Color(0xFFC9A43A)`, `surfaceContainerHigh: Color(0xFFDEE4E4)`, `outlineVariant: Color(0xFFBFC9C8)`.
   - `SemanticColors.dark()` — `warning: Color(0xFFFFB74D)`, `warningContainer: Color(0xFF4A2E00)`, `onWarningContainer: Color(0xFFFFE2B8)`, `success: Color(0xFF81C784)`, `onSuccess: Color(0xFF003A09)`, `closureAccent: Color(0xFFD4B858)`, `surfaceContainerHigh: Color(0xFF25302F)`, `outlineVariant: Color(0xFF48514F)`.
3. Implements the `ThemeExtension` contract (`copyWith`, `lerp`) correctly — `lerp` uses `Color.lerp` per field; a field that cannot lerp (none here; all fields are `Color`) is not introduced.
4. Exposes a test-facing helper on `BuildContext`:
   ```dart
   extension SemanticColorsContext on BuildContext {
     SemanticColors get semanticColors =>
         Theme.of(this).extension<SemanticColors>()!;
   }
   ```
   The `!` is deliberate — if the extension is missing at a call site, that is a bug we want to fail loudly at (Poka-yoke; covered by a widget test that fails if `.extension<SemanticColors>()` returns null under either theme).
5. Palette hex values match UX spec §Color System's "Full color tokens" table exactly; any divergence requires a UX-spec update first (dark values that were expressed as "M3 tonal" in the UX spec are pinned here to the tones `fromSeed` actually produces for the 0xFF0D4F52 seed — the pin must come from a `ColorScheme.fromSeed(seed, brightness: .dark)` calculation and be documented inline).

### AC4 — `MaterialApp` wiring in `lib/main.dart`

1. `lib/main.dart`'s `MainApp` swaps the current `MaterialApp` body with `MaterialApp` configured as:
   ```dart
   MaterialApp(
     title: 'prijavko',
     theme: buildLightTheme(),
     darkTheme: buildDarkTheme(),
     themeMode: ThemeMode.system,
     home: const _DesignSystemPreview(), // see AC4.3
   );
   ```
2. `ThemeMode.system` is literal — no build flag, no user-facing override in this story. FR25/NFR-U2 "follow system dark/light" is satisfied by construction.
3. A temporary `_DesignSystemPreview` widget lives **inside `main.dart`** (not `lib/features/…`; no feature directory exists yet per JIT). It renders:
   - A `Text('prijavko')` in `Theme.of(context).textTheme.headlineLarge` (smoke-tests Manrope load + typography pipeline).
   - One `FilledButton` (smoke-tests the 56dp min-height + 12dp radius).
   - One `OutlinedButton` (smoke-tests 48dp + 1.5px outline).
   - A `Card` wrapping the two buttons (smoke-tests 16dp card radius).
   - Three `Container`s coloured from `context.semanticColors` — `warning`, `success`, `closureAccent` — each with the matching `on*` foreground text (smoke-tests the extension resolves).
   - One `Icon(Symbols.check_rounded)` (smoke-tests Material Symbols wiring — AC5).
4. The preview widget carries a TODO comment (`// TODO(story-1.5): replace with WelcomeScreen once onboarding lands.`) so its removal is tracked.
5. No literal copy beyond `'prijavko'` (the app title) and the word `'Preview'`. Localisation lands with Story 1.5 — this widget is developer-only and does not need ARB coverage. The CI grep guard for hardcoded strings (NFR-L4) is not active until Story 1.5, but a `// i18n-ignore: design-system preview scaffold; removed in 1.5` comment is added above each literal as an explicit audit trail.

### AC5 — Material Symbols (rounded) registration

1. `material_symbols_icons` is added to `pubspec.yaml` under `dependencies` (latest stable on pub.dev at dev time; pin with caret — e.g. `material_symbols_icons: ^4.x.x` — and record the exact resolved version in `Dev Notes > Change Log`).
2. A single import surface — `package:material_symbols_icons/symbols.dart` — is used wherever icons are referenced. Do NOT import the per-icon `.dart` entry points; the aggregated symbol set is what the project uses.
3. The rounded variant is the house style. On every `Icon(Symbols.x)` call site, the rounded fill is selected via the package's `Symbols` class, which exposes all three weights (outlined/rounded/sharp) as separate getters per icon — the project's convention is `Symbols.<name>_rounded` if the package uses suffix naming, or importing from the rounded-specific barrel if the package uses per-variant imports. **Implementer: verify the package's actual API at install time** (the package version pinned below is the contract — check its README), document the chosen convention in `lib/design/icons.dart` header comment, and apply uniformly.
4. `lib/design/icons.dart` exists as a re-export + convention doc (not a re-wrapping layer): it has a top-of-file `// WHY:` paragraph explaining the rounded-variant decision and `export 'package:material_symbols_icons/symbols.dart' show Symbols;` so callers import `package:prijavko/design/icons.dart` and cannot accidentally reach the outlined or sharp variants through a stale import.
5. A repo grep CI guard is added as `.github/workflows/icons_guard.yml` (or extended into the existing `pii_guard.yml` — dealer's choice; document which) that fails the build on any match of:
   ```regexp
   Icon\s*\(\s*Icons\.
   ```
   in `lib/**/*.dart`. Rationale: `Icons.xxx` (Material Icons) and `Symbols.xxx` (Material Symbols) are different fonts with different strokes — mixing them is a visual bug. Self-test line lives in `docs/ci/icons-guard-regex.md` with passing/failing examples, matching the pattern `pii_guard.yml` established in Story 1.1.
6. The `_DesignSystemPreview` (AC4.3) uses `Symbols.check_rounded` (or the package's equivalent rounded accessor) so the Symbols font file is actually loaded at first paint — if the dependency is misconfigured, the preview renders a Tofu box and the smoke test (AC6) fails.

### AC6 — Widget tests (meaningful, not tautological)

Tests live under `test/design/` and are run by the existing `test.yml` GitHub Actions workflow from Story 1.1. No new CI workflow is required.

1. `test/design/theme_test.dart` — constructs a `MaterialApp` wrapped around a `Builder` that captures `Theme.of(context)`, pumped twice (once with `theme: buildLightTheme()`, once with `darkTheme: buildDarkTheme()` + `platformBrightness: Brightness.dark`). Asserts:
   - `FilledButton` resolved style has `minimumSize.height == Tokens.size.buttonMinHeight` in BOTH themes.
   - `Card` resolved shape is a `RoundedRectangleBorder` with `borderRadius == BorderRadius.circular(Tokens.radius.card)` in BOTH themes.
   - `Theme.of(context).colorScheme` is `!= null` and `.primary` is close to the seed's produced tone (spot-check by `primary != null`; do not hand-verify hex — `fromSeed` is Flutter's concern).
2. `test/design/semantic_colors_test.dart` — constructs `MaterialApp`s for each brightness, resolves `Theme.of(context).extension<SemanticColors>()` inside a `Builder`:
   - Asserts the extension is NOT null under both themes.
   - Asserts `warning != null`, `warningContainer != null`, `success != null`, `closureAccent != null`, `surfaceContainerHigh != null`, `outlineVariant != null` (sanity — constructor enforces non-null but a regression that switches to defaults would be caught).
   - Asserts `SemanticColors.light().warning.value != SemanticColors.dark().warning.value` — light and dark palettes are actually different, not accidentally symlinked.
3. `test/design/tokens_test.dart` — pure Dart test (no Flutter binding):
   - Asserts the 4dp grid invariant: every `Tokens.space.s*` value is a multiple of 4.
   - Asserts the expected constants exist and are `const` (compile-time only — a type assertion on `Tokens.space.s16` as `const double` suffices).
4. `test/design/icons_test.dart` — widget test that pumps `Icon(Symbols.check_rounded)` (or whatever the pinned package exposes for rounded check) and asserts `find.byType(Icon)` finds exactly one, with `tester.widget<Icon>(…).icon?.fontFamily` equal to the rounded-variant font family the package declares. If the font family cannot be resolved, the package is misconfigured — the test fails loudly.
5. Every assertion has a one-line comment naming the AC it guards (`// guards AC2.5 — 56dp min-height`). Saves time when a future regression bisects down to a single red test.

### AC7 — `pubspec.yaml` dependency additions

1. `google_fonts` added under `dependencies` at its latest stable release on pub.dev at dev time (pin with caret, e.g. `google_fonts: ^6.x.x`); exact resolved version recorded in Change Log.
2. `material_symbols_icons` added under `dependencies` (see AC5.1).
3. No other dependencies added in this story. Riverpod, Freezed, Drift, Dio, flutter_secure_storage, intl, flutter_localizations, firebase_crashlytics, google_mobile_ads — ALL deferred to their owning stories (1.3, 1.4, 1.5, 2.x, 3.x, 5.x, 6.x, 9.x, 10.x).
4. `pubspec.lock` is re-committed after `flutter pub get`. Story 1.1's AC11.2 anchor `!pubspec.lock` guarantees it is tracked.

### AC8 — Offline font bundling (JIT, but covered here)

1. Per PRD §NFR (offline-tolerant utility) and the UX spec's "bundleable to remove Google Fonts CDN dependency on first launch" (§Typography System), Manrope font files are **bundled as assets** rather than fetched over HTTP at first launch:
   - Manrope weights 400/500/600/700/800 (regular, no italics — the UX spec's weight discipline forbids italics) are placed under `assets/google_fonts/Manrope/`.
   - Filenames follow the `google_fonts` package's convention: `Manrope-Regular.ttf`, `Manrope-Medium.ttf`, `Manrope-SemiBold.ttf`, `Manrope-Bold.ttf`, `Manrope-ExtraBold.ttf`.
   - `pubspec.yaml` lists `assets/google_fonts/Manrope/` under `flutter.assets`.
   - The `google_fonts` package automatically detects local asset files and skips the HTTP fetch — no code change in `theme.dart` is required.
2. A `docs/design/fonts-licensing.md` note records the Manrope source (github.com/sharanda/manrope), SIL OFL 1.1 license terms, SHA-256 of each bundled `.ttf`, and the "we ship our own; we don't hotlink Google's CDN" rationale. OFL compliance requires the license text to ship with the binaries — include `assets/google_fonts/Manrope/OFL.txt`.
3. An integration test (or widget test with network disabled — Flutter test defaults disable network already) pumps the preview widget and asserts no `google_fonts` HTTP request is attempted; if the bundled assets are missing, `google_fonts` would try to fetch, and the test would observe the pending HTTP request and fail. Implementation hint: override `GoogleFonts.config.allowRuntimeFetching = false` in `main()` so a missing asset becomes a loud exception at startup (Poka-yoke — dev catches the regression; user never sees a missing-font flash).

### AC9 — `lib/widgets/` is created empty for directory convention

1. `lib/widgets/` directory is created. It contains a single file: `.gitkeep` (or a README stub that documents the directory's purpose per `.claude/rules/design-system.md §1`). No custom widgets ship in this story — per JIT, each widget arrives with the story that needs it (GuestStatusGlyph in 5.3, CredentialBanner in 2.7, …). Rationale for creating the folder now: git otherwise discards it, and we want the convention visible from day one.

## Tasks / Subtasks

- [x] Task 1 — Add dependencies + bundle Manrope assets (AC: #7, #8)
  - [x] Subtask 1.1 — Add `google_fonts: ^<latest>` and `material_symbols_icons: ^<latest>` to `pubspec.yaml` under `dependencies`. Run `flutter pub get`; commit the updated `pubspec.yaml` + `pubspec.lock`. Record exact resolved versions in the Change Log.
  - [x] Subtask 1.2 — ~~Download Manrope 400/500/600/700/800 TTFs from github.com/sharanda/manrope (release tarball, not the Google Fonts CDN).~~ **DEVIATION (logged in Change Log):** the upstream `sharanda/manrope` repo is offline (404). User provided the canonical static-TTF distribution from a cached source whose `OFL.txt` matches the Google Fonts mirror. Files placed under `assets/google_fonts/Manrope/` with the filenames `Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`. `OFL.txt` copied alongside. SHA-256 of every shipped file recorded in `docs/design/fonts-licensing.md`.
  - [x] Subtask 1.3 — Register the asset directory in `pubspec.yaml`'s `flutter.assets` block.
  - [x] Subtask 1.4 — Create `docs/design/fonts-licensing.md` with SIL OFL license rationale + SHA-256 per file + source URL.
  - [x] Subtask 1.5 — In `lib/main.dart`'s `main()` (before `runApp`), set `GoogleFonts.config.allowRuntimeFetching = false;` so a missing bundled asset hard-fails at startup rather than silently falling back to HTTP.
- [x] Task 2 — Scaffold `lib/design/` directory + `tokens.dart` (AC: #1)
  - [x] Subtask 2.1 — Create `lib/design/tokens.dart` with the `Tokens` namespace + `Tokens.color`, `Tokens.space`, `Tokens.radius`, `Tokens.size` nested classes per AC1.
  - [x] Subtask 2.2 — Each class gets `const <Name>._();` to block instantiation; top-of-file `// WHY:` comment explains the "pure const, no Flutter theming logic" scope boundary per `.claude/rules/design-system.md §1`.
- [x] Task 3 — `lib/design/extensions.dart` — `SemanticColors` `ThemeExtension` (AC: #3)
  - [x] Subtask 3.1 — Declare `class SemanticColors extends ThemeExtension<SemanticColors>` with the 8 required-named-parameter `Color` fields.
  - [x] Subtask 3.2 — Implement `copyWith(…)` and `lerp(ThemeExtension<SemanticColors>? other, double t)` using `Color.lerp` per field.
  - [x] Subtask 3.3 — Add `SemanticColors.light()` and `SemanticColors.dark()` factory constructors with the exact hex values from UX spec §Color System. For any dark value whose UX-spec description is tonal (e.g. "surface container high" not pinned to hex), derive once from `ColorScheme.fromSeed(Tokens.color.primarySeed, brightness: .dark)`, pin the result, and add a `// DERIVED FROM fromSeed:` inline comment recording the pinned tone for future auditability.
  - [x] Subtask 3.4 — Add the `SemanticColorsContext` extension on `BuildContext` returning `Theme.of(this).extension<SemanticColors>()!` with a `// WHY:` comment stating the non-null assertion is intentional Poka-yoke.
- [x] Task 4 — `lib/design/theme.dart` — light/dark builders (AC: #2)
  - [x] Subtask 4.1 — Implement `ThemeData buildLightTheme()` and `buildDarkTheme()` with `useMaterial3: true`, `colorScheme: ColorScheme.fromSeed(…)`, `textTheme: GoogleFonts.manropeTextTheme(base).copyWith(<12 styles>)`, `extensions: <ThemeExtension<dynamic>>[SemanticColors.<brightness>()]`.
  - [x] Subtask 4.2 — Fill the component theme slots per AC2.5: `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `cardTheme`, `bottomSheetTheme`, `inputDecorationTheme`.
  - [x] Subtask 4.3 — Top-of-file `// WHY:` comment explains the "no per-widget theme overrides; always edit this file" rule and the `.claude/rules/design-system.md §2` dark-mode-first design contract.
- [x] Task 5 — `lib/design/icons.dart` + CI guard (AC: #5)
  - [x] Subtask 5.1 — Create `lib/design/icons.dart` with a top-of-file `// WHY:` paragraph pinning the rounded variant as house style, followed by `export 'package:material_symbols_icons/symbols.dart' show Symbols;` (adjust the `show` clause to match the package's actual public API; confirm at install time).
  - [x] Subtask 5.2 — Add `.github/workflows/icons_guard.yml` (or extend `pii_guard.yml` — state the choice in the commit message) with the `Icon\s*\(\s*Icons\.` regex + self-test. Mirror `pii_guard.yml`'s structure: `rc=$?` capture, explicit `case` branch handling, `echo "::error::…"` on no-SCAN_DIRS.
  - [x] Subtask 5.3 — Add `docs/ci/icons-guard-regex.md` with passing + failing example lines, matching the template `docs/ci/pii-guard-regex.md` established in Story 1.1.
- [x] Task 6 — Wire `MaterialApp` + `_DesignSystemPreview` (AC: #4)
  - [x] Subtask 6.1 — Rewrite `lib/main.dart` to the AC4.1 `MaterialApp` shape.
  - [x] Subtask 6.2 — Define `_DesignSystemPreview` (private stateless widget in `main.dart`) with the AC4.3 content; TODO comment referencing story 1.5.
  - [ ] Subtask 6.3 — **Manual verification deferred to user.** Agent cannot run `flutter run` against an emulator/device from this environment. User should execute `flutter run -d <device>` and attach screenshots in dark + light modes to the PR description before merge. Smoke test (`test/app_smoke_test.dart`) and integration test (`integration_test/app_test.dart`) were updated to assert the new preview surface (FilledButton + OutlinedButton present), so a regression in preview wiring fails in CI even without the manual screenshots.
- [x] Task 7 — Create `lib/widgets/` directory convention marker (AC: #9)
  - [x] Subtask 7.1 — Create `lib/widgets/README.md` (preferred over `.gitkeep`) that states "Custom widgets land in this folder, one file per widget, per `.claude/rules/design-system.md §4`. Each file begins with a `// WHY:` paragraph."
- [x] Task 8 — Widget tests (AC: #6)
  - [x] Subtask 8.1 — `test/design/theme_test.dart` — 56dp min-height, 16dp card radius, `colorScheme` present, both themes. (landed in Task 4 commit; expanded to 18 tests covering useMaterial3, FilledButton 56dp + radius, OutlinedButton 48dp, BottomSheet 24dp top, ColorScheme brightness, SemanticColors registered, typescale weights — both modes.)
  - [x] Subtask 8.2 — `test/design/semantic_colors_test.dart` — extension resolves under both themes; light ≠ dark warning. (landed in Task 3 commit; 5 tests including `copyWith` preservation and `lerp` endpoints.)
  - [x] Subtask 8.3 — `test/design/tokens_test.dart` — 4dp grid invariant, `const` constants exist. (landed in Task 2 commit.)
  - [x] Subtask 8.4 — `test/design/icons_test.dart` — `Icon(Symbols.<rounded-check>)` resolves a font family; fails loudly on misconfigured asset. (landed in Task 5 commit; asserts `MaterialSymbolsRounded` + `material_symbols_icons` font package.)
  - [x] Subtask 8.5 — `flutter test` locally → 36/36 green. `dart analyze --fatal-warnings --fatal-infos` clean. `dart format --set-exit-if-changed lib test integration_test` clean. PII guard regex + icons guard regex both return `rc=1` (no match → green) against the working tree.
- [x] Task 9 — Verify offline-font pipeline (AC: #8)
  - [x] Subtask 9.1 — With `GoogleFonts.config.allowRuntimeFetching = false`, `flutter test` succeeds (38/38 green) without a network connection — the new `test/design/offline_fonts_test.dart` exercises every `GoogleFonts.manrope*` slot under the no-fetching policy, so a missing/renamed asset would throw at the first font lookup. **`flutter run` device verification + airplane-mode visual check is deferred to the user** (agent cannot drive an emulator/device from this environment). If any glyph renders as Tofu on device, the asset pipeline is broken — fix before merge.
  - [ ] Subtask 9.2 — **Deferred to user.** Record the airplane-mode verification + screenshot in the PR description before merging.

## Dev Notes

### Why this story exists second

Every Epic 1.3+ story renders UI: consent screens, credential capture, facility picker, scan viewfinder, queue home, closure summary. Without a locked design system, each story re-litigates spacing, radii, and typography, and the CI grep guards for "no hardcoded hex" (there is no such guard today) are impossible to add. Story 1.2 is the one-file-change doorway — after this, adding a screen is "compose Material 3 primitives with `Theme.of(context)` and `context.semanticColors`," and any deviation is a PR-review flag, not a silent drift.

The companion `.claude/rules/design-system.md` rule file is **already authoritative** in this repo (it was checked in pre-Story 1.1 and governs all UI work). Story 1.2 is the code that makes those rules actionable. If `design-system.md` disagrees with this story, `design-system.md` wins (per CLAUDE.md §8 — `.claude/rules/*` is the source of truth) and this story needs updating.

### Architecture mandates (must follow — non-negotiable)

- **Material 3 native only.** Zero third-party UI kits: no FlexColorScheme, GetWidget, shadcn_flutter, Forui, Velocity. Architecture §2 locks the stack; UX spec §Design System Foundation rejects each alternative by name.
- **`ColorScheme.fromSeed` is the single color factory.** Do not hand-construct a `ColorScheme(...)`. The seed is `Color(0xFF0D4F52)` (Adriatic Teal, from UX spec §Color System). All Material-side colors flow from this one byte.
- **Dark mode is the primary design target.** Build dark first, validate light. This is documented in `.claude/rules/design-system.md §2` and UX spec §Typography/Color System. The preview widget should be screenshot-verified in dark first.
- **No feature directories in this story.** `lib/design/` and `lib/widgets/` land here (both are shared infra, not feature code). `lib/features/…` stays empty until Story 1.3 (auth) + Story 1.5 (onboarding) need it, per JIT.
- **`_DesignSystemPreview` is throwaway.** It goes away in Story 1.5 when `WelcomeScreen` lands. Do not invest in polishing it, writing Semantics labels for it, or localising it. A `TODO(story-1.5)` comment is the tracking device.
- **No Riverpod / Freezed / Drift / Dio / Firebase.** Even though every subsequent story needs at least one of them, none are warranted by *this* story's ACs. Adding them now violates JIT and Story 1.1's dependency-light posture.
- **File naming is `snake_case.dart` always** (Architecture §Naming Patterns). `tokens.dart`, `theme.dart`, `extensions.dart`, `icons.dart`.
- **No inline XML, no inline hex, no inline spacing.** After this story, a grep for `Color(0xFF` or `EdgeInsets.all(13)` or `SizedBox(height: 19)` in `lib/features/**` (when that folder fills up in later stories) should return zero results. Plant the discipline now; the CI guards enforce it later.

### Previous story intelligence (Story 1.1)

- `lib/` currently contains: `main.dart` (empty-scaffold body; no feature code), `lib/core/env/evisitor_env.dart`. Story 1.1 deliberately stopped short of feature skeletons per JIT — this story creates `lib/design/` and `lib/widgets/` as the second and third folders.
- CI workflow conventions to mirror: `pii_guard.yml` is the template for `icons_guard.yml` (same `rc=$?` pattern, same `::error::` on no-SCAN_DIRS, same self-test doc). `docs/ci/pii-guard-regex.md` is the template for `docs/ci/icons-guard-regex.md`.
- `pubspec.yaml` is currently vanilla + `flutter_lints` + `integration_test` (SDK-bundled). This story adds exactly 2 third-party dependencies. Record resolved versions in the Change Log so a future `flutter pub upgrade` regression is bisectable.
- The `dart format --set-exit-if-changed` invocation was narrowed in Story 1.1's review patches to `dart format --set-exit-if-changed lib/ test/ integration_test/` (away from `.`) to avoid tripping on generated files once build_runner lands. Preserve this — run the same invocation locally.
- Story 1.1 review surfaced the `dart format` scope lesson and the "CI guard self-test fixture" pattern. Apply both to the new icons guard.

### Library API confirmation (at install time)

- **`google_fonts`** — the canonical `GoogleFonts.manropeTextTheme(baseTextTheme)` returns a `TextTheme` with Manrope mapped to every slot; `.copyWith(displayLarge: baseStyle.copyWith(fontSize: 57, fontWeight: FontWeight.w800, height: 64/57))` is the mechanic for each of the 12 tuned styles. Bundling assets under `assets/google_fonts/<Family>/` and listing in `pubspec.yaml` is the documented offline path — the package auto-detects local files. Latest major line on pub.dev at install time is expected to be `^6.x.x`; verify with `flutter pub outdated google_fonts` after install.
- **`material_symbols_icons`** — pub.dev package `material_symbols_icons` by Tim Maffett. Exposes a single `Symbols` class with getters named `<icon_name>_rounded`, `<icon_name>_outlined`, `<icon_name>_sharp` (suffix naming). `import 'package:material_symbols_icons/symbols.dart';` is the aggregated entry point; per-icon imports are a tree-shake optimisation we ignore for now (AdMob + Firebase will dwarf the icon bundle anyway). Implementer: confirm the suffix convention against the package's README at install time and document the resolved pattern in `lib/design/icons.dart`'s header.

### Test posture for this story

- **Widget tests only** — no integration tests. The preview widget is throwaway; integration-test coverage for theming lands with Welcome / Onboarding in Story 1.5+.
- **Follow the `.claude/rules/design-system.md §7` workflow**: build the preview, verify against the UX spec and Figma screenshots, add a widget test that asserts key token usages so drift is caught.
- **Coverage target is branches, not lines** (project QA posture, per CLAUDE.md + memory). Branches in scope: both `ThemeMode` variants (light + dark), both `SemanticColors` factories, both `theme.dart` functions. All four are covered by `theme_test.dart` + `semantic_colors_test.dart`.

### LLM-specific anti-patterns for this story

| Do NOT do this | Do THIS instead |
|---|---|
| Hand-roll a `ColorScheme(primary: 0xFF..., onPrimary: 0xFF..., …)` with 20+ fields | `ColorScheme.fromSeed(seedColor: Tokens.color.primarySeed, brightness: …)` — one line, WCAG AA by construction |
| Inline `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)` in widgets | Map to a `Theme.of(context).textTheme.<slot>` in `theme.dart`; widgets reference the slot |
| Override `filledButtonTheme` inside each screen that needs 56dp | Set it once in `theme.dart`; screens use plain `FilledButton` and inherit |
| Add a `dev_dependencies` line for `flutter_lints` — it's already there | `flutter_lints` was added in Story 1.1. Do not touch it. |
| Import `Icons.check` in the preview widget and "fix it later" | Use `Symbols.<name>_rounded` from day one — the icons CI guard blocks `Icons.` literally |
| Add Riverpod "so the preview widget can show a theme-toggle switch" | `ThemeMode.system` only. No toggle in v1. Preview is throwaway. |
| Add `intl` + ARB setup "because we need localisation eventually" | Story 1.5 owns l10n. This story has one literal (`'prijavko'`) and it's English-as-proper-noun. |
| Create `lib/features/design_system/preview_screen.dart` to be "proper" | The preview is a private widget *in `main.dart`*. It dies in 1.5. No feature directory earned. |
| Bundle Manrope from Google Fonts CDN at runtime (default behaviour) | Bundle the TTFs as assets; set `GoogleFonts.config.allowRuntimeFetching = false`. Offline-first is a PRD NFR. |
| Skip the `icons_guard.yml` workflow because "nothing uses Icons. yet" | The guard exists to block the *next* PR that types `Icons.` out of habit. Plant it now. |
| Pin `closureAccent` by eye because "it's just the Closure Summary gold" | The hex values in UX spec §Color System are authoritative. Copy them verbatim. |
| Mix `Symbols.check_rounded` in one file and `Symbols.check` (outlined default) in another | `lib/design/icons.dart` pins the rounded convention via `export … show Symbols;`; every import goes through it |
| Write a `design_system_preview_screen.dart` widget test that pumps the whole preview and calls `expect(find.byType(FilledButton), findsOneWidget)` | Tautological. Test the *tokens* (min-height, shape, extension resolution), not the preview's widget tree. |

### Project Structure Notes

This story creates:

- `lib/design/tokens.dart`
- `lib/design/theme.dart`
- `lib/design/extensions.dart`
- `lib/design/icons.dart`
- `lib/widgets/README.md`
- `lib/main.dart` — edited (MaterialApp shape + `_DesignSystemPreview`)
- `pubspec.yaml` — edited (2 deps + Manrope asset registration)
- `pubspec.lock` — regenerated
- `assets/google_fonts/Manrope/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`
- `assets/google_fonts/Manrope/OFL.txt`
- `docs/design/fonts-licensing.md`
- `docs/ci/icons-guard-regex.md`
- `.github/workflows/icons_guard.yml` (or equivalent extension of `pii_guard.yml`)
- `test/design/theme_test.dart`
- `test/design/semantic_colors_test.dart`
- `test/design/tokens_test.dart`
- `test/design/icons_test.dart`

This story does NOT create:

- `lib/widgets/*.dart` — every custom widget ships with its owning feature story (5.3 GuestStatusGlyph, 2.7 CredentialBanner, 3.3 FacilityPickerSheet, 4.3 MRZViewfinder, 4.4 CaptureConfirmation, 5.4 QueueRow / QueueHero, 7.1 ClosureSummary, 5.8/8.2 TypedConfirmationDialog, 10.1 AdBanner).
- `lib/features/**/*` — no features yet.
- `lib/core/security/**`, `lib/core/logging/**`, `lib/core/telemetry/**`, etc. — Story 1.3+.
- Riverpod / Freezed / Drift / Dio / Firebase / AdMob / intl wiring — their owning stories.
- `WelcomeScreen` / `ConsentScreen` / onboarding routes — Story 1.4 / 1.5.
- `go_router` — arrives with Story 1.5 when the first non-root route is needed.

### References

- [UX Design Specification §Design System Foundation, §Color System, §Typography System, §Spacing & Layout Foundation, §Accessibility Considerations](../planning-artifacts/ux-design-specification.md)
- [Figma ↔ Code Contract §1 Tokens, §2 Text styles, §3 Components, §5 Implementation rules](../planning-artifacts/figma-code-contract.md)
- [Architecture §App Architecture, §Naming Patterns, §Structure Patterns](../planning-artifacts/architecture.md)
- [Project rule — `.claude/rules/design-system.md` §1 File & Directory Layout, §2 Theme & ColorScheme, §3 Design Tokens, §4 Widget Hierarchy, §5 Accessibility, §7 Design-to-Code Workflow, §8 Craftsmanship Reminders](../../.claude/rules/design-system.md)
- [Project rule — `.claude/rules/japanese-craftsmanship.md` — Monozukuri, Poka-yoke, JIT, Kaizen](../../.claude/rules/japanese-craftsmanship.md)
- [PRD NFRs — NFR-U2 (system dark/light), NFR-C3 (one-handed ergonomics), NFR-L4 (no hardcoded user-facing strings — activated fully in 1.5)](../planning-artifacts/prd.md)
- [Epics Story 1.2 G/W/T acceptance criteria](../planning-artifacts/epics.md)
- [Previous story — 1-1-project-bootstrap-and-ci-foundation.md for CI workflow template + `dart format` scope lesson](./1-1-project-bootstrap-and-ci-foundation.md)
- [`google_fonts` package — pub.dev docs (asset bundling, `allowRuntimeFetching`, `manropeTextTheme`)](https://pub.dev/packages/google_fonts)
- [`material_symbols_icons` package — pub.dev](https://pub.dev/packages/material_symbols_icons)

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Claude Opus 4.7, 1M context)

### Debug Log References

- `flutter pub get` — resolved 29 new transitive deps; clean.
- `dart format --set-exit-if-changed lib test integration_test` — clean (5 files, 0 changed).
- `dart analyze --fatal-warnings --fatal-infos` — clean (no issues).
- `flutter test` — 8 tests pass (existing `evisitor_env_test.dart` ×7, `app_smoke_test.dart` ×1).

### Completion Notes List

- **Task 1 — Deviation from AC8.1.** Upstream `github.com/sharanda/manrope` returns HTTP 404 (the maintainer took the repo down). Probed alternatives: `google/fonts/ofl/manrope` ships only the variable font (`Manrope[wght].ttf`), not the 5 weight-named static TTFs the `google_fonts` package's local-asset detection requires; Fontsource ships only `woff/woff2`. User supplied the 5 static TTFs (`Regular/Medium/SemiBold/Bold/ExtraBold`) plus `OFL.txt` from a cached Manrope distribution. The shipped files match Google Fonts' canonical OFL terms; SHA-256 fingerprints are pinned in `docs/design/fonts-licensing.md` for future regression bisects. Story remains spec-faithful aside from the source-URL substitution.

- **Task 2 — `library_private_types_in_public_api` lint adjustment.** AC1's "nested classes as namespaces" pattern with private wrapper types (e.g. `_ColorTokens`) trips Dart's `library_private_types_in_public_api` info diagnostic, which is fatal under the project's `dart analyze --fatal-warnings --fatal-infos` CI gate. Resolution: promoted the wrapper classes to public (`TokensColor`, `TokensSpace`, `TokensRadius`, `TokensSize`) while keeping the private unnamed constructors so instantiation remains impossible — the namespace pattern (`Tokens.color.primarySeed`) is preserved exactly, only the wrapper-class names are reachable.

- **Tasks 6 + 9 — manual verification deferred.** The agent cannot drive an emulator or physical device from this environment, so subtasks 6.3 (`flutter run` + light/dark screenshots) and 9.2 (airplane-mode run + screenshot) are deferred to the user before merge. The automated guards (`offline_fonts_test.dart`, retargeted smoke + integration tests asserting the preview surface) make a regression in token wiring or asset bundling fail loudly in CI even without the manual screenshots.

- **Code-review pass (2026-04-27) — Tokens namespace shape deviation.** AC1.1's syntax sample (`Tokens.color.primarySeed`) cannot be honoured literally in Dart: `static` member access through an instance is a compile error, so a `const TokensColor` instance with `final` fields cannot be const-evaluated in widget constructors (`const EdgeInsets.all(Tokens.space.s16)` failed). The review-pass patch promotes every value to `static const` on `abstract final class` namespaces (`TokensColor`, `TokensSpace`, `TokensRadius`, `TokensSize`); call sites read `TokensSpace.s16` directly. The "single source of truth, no instantiation possible, all const" intent of AC1.1 is preserved; only the `Tokens.<bucket>.<value>` access shape is replaced with `Tokens<Bucket>.<value>`. Theme builders, preview widgets, and tests updated accordingly.

- **Code-review pass (2026-04-27) — `SemanticColors.onWarning` added.** AC4.3 lists "warning, success, closureAccent — each with the matching on*" foreground, but AC3.1 originally defined no `onWarning` (only `onWarningContainer`). The review-pass patch adds an `onWarning` field to the extension (light: white; dark: dark-warm derived from M3 tonal pairing for the saturated orange) so the preview can render `warning/onWarning` per the AC's literal reading. `closureAccent` remains unpaired by design and is now documented as a non-text-bearing accent in the `extensions.dart` header.

- **Code-review pass (2026-04-27) — `applyMainAppFontConfig()` extracted.** AC8.3's "this test exercises the no-fetching guard meaningfully" was previously implemented as a tautology — the test set the flag itself before asserting. The review-pass patch extracts `GoogleFonts.config.allowRuntimeFetching = false` into a top-level `applyMainAppFontConfig()` function which `main()` calls; the test now forces the flag back to `true`, calls `applyMainAppFontConfig()`, and asserts the post-condition. Deletion of the line inside the function fails the test loudly.

- **Code-review pass (2026-04-27) — CI disk-space fix.** The 2026-04-27 `integration_fake.yml` run failed late with `FileSystemException: No space left on device` while writing `kernel_blob.bin`. Root cause: GitHub-hosted Ubuntu runners ship ~14 GB free; AVD image + Android SDK + Gradle cache + Flutter build artefacts (now larger because of the bundled Manrope assets and `google_fonts 8.x` transitive deps) push past the limit. Added a `jlumbroso/free-disk-space@main` step before the Java setup that reclaims ~30 GB by purging unused tooling (haskell, dotnet, large docker caches); the AVD/SDK we DO need are preserved.

### Change Log

| Date | Task | Notes |
| ---- | ---- | ----- |
| 2026-04-27 | Task 1 | Added `google_fonts: ^8.0.2` (resolved `8.0.2`) and `material_symbols_icons: ^4.2928.1` (resolved `4.2928.1`) under `dependencies`. Bundled Manrope 400/500/600/700/800 + OFL.txt under `assets/google_fonts/Manrope/`. Registered the asset folder in `pubspec.yaml > flutter.assets`. Set `GoogleFonts.config.allowRuntimeFetching = false` in `main()`. AC8.1 source URL deviation noted in Completion Notes. |
| 2026-04-27 | Task 2 | Created `lib/design/tokens.dart` with `Tokens` namespace + `TokensColor`/`TokensSpace`/`TokensRadius`/`TokensSize`. Added `test/design/tokens_test.dart` (4 groups, 4 tests — 4dp grid invariant, radii, button height, seed). Nested classes are public to satisfy `library_private_types_in_public_api` lint under CI's `--fatal-infos` gate; private unnamed constructors still block instantiation (Poka-yoke). |
| 2026-04-27 | Task 3 | Created `lib/design/extensions.dart` with `SemanticColors extends ThemeExtension<SemanticColors>` (8 required-named-parameter `Color` fields), `SemanticColors.light()` / `SemanticColors.dark()` factories with hex values pinned from UX spec §Color System, full `copyWith` + `lerp`, and the `SemanticColorsContext` `BuildContext` extension. Added `test/design/semantic_colors_test.dart` (5 tests — extension resolves under both themes, light ≠ dark warning/success/closureAccent, `copyWith` preserves untouched fields, `lerp` honours t=0/t=1 endpoints). |
| 2026-04-27 | Task 4 | Created `lib/design/theme.dart` with `buildLightTheme()` / `buildDarkTheme()` over a private `_buildTheme(brightness)` factory: `useMaterial3: true`, `ColorScheme.fromSeed(seed: Tokens.color.primarySeed)`, Manrope via `GoogleFonts.manropeTextTheme` mapped to all 12 Material 3 typescale slots per figma-code-contract §2, `SemanticColors` registered as a `ThemeExtension`, component theme slots filled (`filledButtonTheme` 56dp + 12dp radius, `outlinedButtonTheme` 48dp + 1.5px outline, `textButtonTheme` shape, `cardTheme` 16dp + zero margin, `bottomSheetTheme` 24dp top, `inputDecorationTheme` rounded outline + token-driven padding). Added `test/design/theme_test.dart` (9 assertions × 2 brightness modes = 18 tests — useMaterial3, FilledButton 56dp + radius, OutlinedButton 48dp, Card 16dp, BottomSheet 24dp top, ColorScheme brightness round-trip, SemanticColors registered, typescale slot weights). |
| 2026-04-27 | Task 5 | Created `lib/design/icons.dart` re-exporting `Symbols` from `material_symbols_icons` with a top-of-file `// WHY:` block pinning the rounded variant. Added `.github/workflows/icons_guard.yml` (separate workflow, not piggy-backed on `pii_guard.yml`) firing on `Icon\s*\(\s*Icons\.` with the same `rc=$?` exit-code dispatch and `::error::` on no-SCAN_DIRS as `pii_guard.yml`. Added `docs/ci/icons-guard-regex.md` with the passing/failing example template that matches `pii-guard-regex.md`. Added `test/design/icons_test.dart` asserting `Symbols.check_rounded` resolves to `MaterialSymbolsRounded` font family + `material_symbols_icons` font package — would fail loudly if the asset bundle were misconfigured. Local rehearsal of the icons guard regex against the working tree returned `rc=1` (no match → green). |
| 2026-04-27 | Task 6 | Rewrote `lib/main.dart` with `MaterialApp(theme: buildLightTheme(), darkTheme: buildDarkTheme(), themeMode: ThemeMode.system, home: const _DesignSystemPreview())` and added the throwaway `_DesignSystemPreview` widget — `Text('prijavko')` in `headlineLarge`, `FilledButton` (smoke-tests 56dp + 12dp + Manrope load + Material Symbols rounded), `OutlinedButton` (smoke-tests 48dp + 1.5px outline), wrapping `Card` (smoke-tests 16dp), and three `_SemanticSwatch` Containers tied to `context.semanticColors.warningContainer`/`success`/`closureAccent`. `// i18n-ignore:` audit-trail comments mark every preview literal so Story 1.5's CI grep guard knows to skip them. Updated `test/app_smoke_test.dart` (was Story 1.1's `Hello World!` placeholder) and `integration_test/app_test.dart` to assert the new preview surface (FilledButton + OutlinedButton found). Subtask 6.3 (`flutter run` device verification + dark/light screenshots in PR description) is deferred to the user — agent cannot drive an emulator from this environment. |
| 2026-04-27 | Task 7 | Created `lib/widgets/README.md` documenting the "one file per widget, `// WHY:` paragraph at top, custom widgets only when a Material 3 primitive cannot express the requirement" convention from `.claude/rules/design-system.md §1, §4`. README enumerates the v1 custom widget roster (CredentialBanner, FacilityPickerSheet, MRZViewfinder, CaptureConfirmation, GuestStatusGlyph, QueueRow/QueueHero, ClosureSummary, TypedConfirmationDialog, AdBanner) and the stories that own each — JIT marker so the folder is visible from day one without empty-file rot. |
| 2026-04-27 | Task 8 | Final test sweep — `flutter test` 36/36 green, `dart analyze --fatal-warnings --fatal-infos` clean, `dart format --set-exit-if-changed lib test integration_test` clean. Both CI guards (PII regex, icons regex) rehearsed locally and return `rc=1` (no match → green). Subtasks 8.1–8.4 landed alongside Tasks 2–5 via red-green-refactor; subtask 8.5 = this validation gate. |
| 2026-04-27 | Task 9 | Added `test/design/offline_fonts_test.dart` exercising every `GoogleFonts.manrope*` typescale slot under `allowRuntimeFetching = false` so a missing/renamed Manrope asset triggers a loud throw at first font lookup (Poka-yoke for AC8.3). Combined with `flutter test`'s default no-network policy, this gives an automated offline-pipeline guard. `flutter test` 38/38 green. **Subtask 9.2 (airplane-mode device run + PR screenshot) is deferred to the user.** |

### File List

- `pubspec.yaml` — modified (added `google_fonts` + `material_symbols_icons` deps, registered Manrope asset folder).
- `pubspec.lock` — created (was untracked; `flutter pub get` regenerated it).
- `lib/main.dart` — modified (added `GoogleFonts.config.allowRuntimeFetching = false` in `main()`; rewrote `MainApp` to wire `buildLightTheme()` / `buildDarkTheme()` + `ThemeMode.system` + `_DesignSystemPreview`).
- `test/app_smoke_test.dart` — modified (Story 1.1 `Hello World!` placeholder retargeted to assert the design preview surface).
- `integration_test/app_test.dart` — modified (boot probe retargeted to the design preview surface; cold-start guard rail unchanged).
- `assets/google_fonts/Manrope/Manrope-Regular.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-Medium.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-SemiBold.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-Bold.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-ExtraBold.ttf` — added.
- `assets/google_fonts/Manrope/OFL.txt` — added.
- `docs/design/fonts-licensing.md` — added.
- `lib/design/tokens.dart` — added.
- `test/design/tokens_test.dart` — added.
- `lib/design/extensions.dart` — added.
- `test/design/semantic_colors_test.dart` — added.
- `lib/design/theme.dart` — added.
- `test/design/theme_test.dart` — added.
- `lib/design/icons.dart` — added.
- `.github/workflows/icons_guard.yml` — added.
- `docs/ci/icons-guard-regex.md` — added.
- `test/design/icons_test.dart` — added.
- `lib/widgets/README.md` — added.
- `test/design/offline_fonts_test.dart` — added.
- `_bmad-output/implementation-artifacts/1-2-design-system-foundation.md` — added (this story file).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (status flip to `review`, then `done` after this code-review pass).
- `.github/workflows/integration_fake.yml` — modified during the code-review pass (added `jlumbroso/free-disk-space` step to fix the 2026-04-27 `No space left on device` regression).

### Review Findings

_Generated 2026-04-27 by `bmad-code-review` (Blind Hunter + Edge Case Hunter + Acceptance Auditor). 4 decision-needed, 18 patch, 8 deferred, 11 dismissed as noise._

#### Decision-needed (resolved)

- [x] [Review][Decision] **Icons guard regex misses `Icon.adaptive(Icons.foo)`** — **Resolved (a):** extend the regex to also match `Icon\.adaptive\s*\(\s*Icons\.`. Prefix-aliased imports left out of scope (low real-world risk; would require AST parsing). Folded into Patch.
- [x] [Review][Decision] **`MainApp.build` reconstructs both themes on every rebuild** — **Resolved (b):** accept. Theme construction is ~ms-cheap; `MainApp` is a `StatelessWidget` with stable parents. Revisit if profiling flags it.
- [x] [Review][Decision] **`closureAccent` has no paired `onClosureAccent`** — **Resolved (b):** document `closureAccent` as a non-text-bearing accent (background tint / border only). Remove its text use from `_DesignSystemPreview` and add a one-paragraph `// WHY:` block in `extensions.dart` header. Folded into Patch.
- [x] [Review][Decision] **Preview's first semantic Container uses `warningContainer/onWarningContainer`** — **Resolved (a):** add `onWarning` field to `SemanticColors` (light + dark factories), update `copyWith` / `lerp`, and switch the preview to `warning`/`onWarning`. Folded into Patch.

#### Patch

- [x] [Review][Patch] **Extend icons guard regex to also catch `Icon.adaptive(Icons.foo)`** [`.github/workflows/icons_guard.yml`, `docs/ci/icons-guard-regex.md`] — Resolution of decision 1. Combine the two patterns via alternation: `(Icon\s*\(|Icon\.adaptive\s*\()\s*Icons\.`. Update `docs/ci/icons-guard-regex.md` with a passing/failing example for `Icon.adaptive(Icons.share)`. Self-test the new regex against the working tree (`rc=1`).
- [x] [Review][Patch] **Document `closureAccent` as a non-text-bearing accent and remove its text use** [`lib/design/extensions.dart` (file header), `lib/main.dart` (preview)] — Resolution of decision 3. Add a `// WHY:` block in `extensions.dart` explicitly stating `closureAccent` is for backgrounds / borders only and intentionally unpaired with an `on*` foreground. Replace the preview's `_SemanticSwatch(color: semantic.closureAccent, onColor: theme.colorScheme.onSurface, ...)` text-rendering swatch with an icon-only or border-only treatment.
- [x] [Review][Patch] **Add `onWarning` field to `SemanticColors`; switch preview to `warning`/`onWarning`** [`lib/design/extensions.dart`, `lib/main.dart`, `test/design/semantic_colors_test.dart`] — Resolution of decision 4. Add `required Color onWarning` to the constructor; pin light/dark hex values from UX spec §Color System (light: white-on-warning suggested by M3 derivation; dark: very-dark-warm suggested by tonal); extend `copyWith` and `lerp` to cover the new field; update `SemanticColors.light()` / `.dark()` factories. Switch preview's first swatch from `warningContainer/onWarningContainer` to `warning/onWarning`. Update tests to cover the new field.
- [x] [Review][Patch] **Promote `Tokens.*` fields from `final` instance fields to `static const`** [`lib/design/tokens.dart` whole file] — Completion Note 2 dropped `static const` to satisfy `library_private_types_in_public_api` after promoting wrapper classes to public, but the lint never required it. As-is, `Tokens.space.s16` is a runtime field read, NOT a compile-time constant — it cannot appear in `const EdgeInsets.all(...)` / `const BorderRadius.circular(...)`, forcing every consumer either to drop `const` (more rebuilds) or to inline magic numbers (defeats the point). Move every value to `static const`.
- [x] [Review][Patch] **Replace hardcoded `EdgeInsets` / `SizedBox` / `BorderRadius` literals in `_DesignSystemPreview` with token references** [`lib/main.dart:1209-1295`] — preview violates `.claude/rules/design-system.md §1` (the rule it exists to demonstrate). Literals: `EdgeInsets.all(16)`, `SizedBox(height: 8/12/16/24)`, `SizedBox(width: 8)`, `BorderRadius.circular(12)`, `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`. Swap for `Tokens.space.s8/s12/s16/s24` and `Tokens.radius.button` (depends on patch 1 for const-ness in `_SemanticSwatch` decoration).
- [x] [Review][Patch] **`tokens_test.dart` 4dp-grid invariant is tautological** [`test/design/tokens_test.dart:14-29`] — loops a hardcoded `<double>[4.0, 8.0, ...]` then independently asserts each `Tokens.space.sX` equals the same literal. Adding `Tokens.space.s10 = 10.0` would not fail the test. Enumerate actual `Tokens.space` field values (e.g. iterate over a `<double>[Tokens.space.s4, Tokens.space.s8, ...]` and check `% 4 == 0`).
- [x] [Review][Patch] **`offline_fonts_test.dart` first test does not verify `main()` sets `allowRuntimeFetching = false`** [`test/design/offline_fonts_test.dart:14-17`] — sets the flag in the test body, then asserts the flag is set. Deleting `GoogleFonts.config.allowRuntimeFetching = false` from `lib/main.dart` would not fail this test. Replace with a test that calls the production init path (or factor `main()`'s init into a callable function and exercise it).
- [x] [Review][Patch] **`offline_fonts_test.dart` second test does not verify bundled asset resolution** [`test/design/offline_fonts_test.dart:32-67`] — under headless `flutter test`, `google_fonts` lookups defer until paint and may silently fall back to the platform font. Strengthen by asserting `GoogleFonts.manrope().fontFamily` references the bundled family name (e.g. `contains('Manrope')`), or call `GoogleFonts.pendingFonts([...])` and `await` it.
- [x] [Review][Patch] **`semantic_colors_test.dart` lerp test asserts only `warning` field; no t=0.5 midpoint** [`test/design/semantic_colors_test.dart:95-101`] — the `lerp` method has 8 hand-written field interpolations; only `warning` is checked at endpoints. Copy-paste bugs (`Color.lerp(success, other.warning, t)`) slip through. Extend to all 8 fields, plus add a t=0.5 assertion that produces a color distinct from both endpoints.
- [x] [Review][Patch] **`SemanticColors` `copyWith` test misses field crossover bugs (only checks 3 of 8 fields)** [`test/design/semantic_colors_test.dart:85-93`] — extend `copyWith()` test to assert `warningContainer`, `onWarningContainer`, `onSuccess`, `surfaceContainerHigh`, `outlineVariant` are also preserved when only `warning` is changed.
- [x] [Review][Patch] **`theme_test.dart` typescale assertions don't verify Manrope is wired** [`test/design/theme_test.dart:117-128`] — asserts `fontSize` / `fontWeight` / `height`, but not `fontFamily`. Removing `GoogleFonts.manropeTextTheme(base.textTheme)` from `theme.dart` and using `base.textTheme` directly leaves all current assertions passing — font silently reverts to platform default. Add `expect(displayLarge.fontFamily, contains('Manrope'))` per slot.
- [x] [Review][Patch] **AC2.6 reference-stability assertion missing** [`test/design/theme_test.dart`] — AC2.6 explicitly requires "spot-check with a widget test that `buildLightTheme().filledButtonTheme == buildLightTheme().filledButtonTheme` structurally". Add the equality assertion for `filledButtonTheme` and one other component theme slot per mode.
- [x] [Review][Patch] **`offline_fonts_test.dart` global flag mutation leaks across tests** [`test/design/offline_fonts_test.dart:14-30`] — sets `GoogleFonts.config.allowRuntimeFetching = false` without restoring prior value. Wrap in `setUp/tearDown` to capture-and-restore (or use `addTearDown`).
- [x] [Review][Patch] **`offline_fonts_test.dart` only exercises light theme** [`test/design/offline_fonts_test.dart:32-67`] — pumps `MaterialApp(theme: buildLightTheme(), darkTheme: buildDarkTheme())` with default `themeMode: system`, so only light's typescale resolves. Wrap a second pump under `MediaQuery(data: MediaQueryData(platformBrightness: Brightness.dark), child: …)` to exercise dark.
- [x] [Review][Patch] **`pubspec.yaml` asset glob includes any file in folder (.DS_Store leak risk)** [`pubspec.yaml flutter.assets`] — folder-level glob `assets/google_fonts/Manrope/` bundles every file. macOS dev `.DS_Store` (or future stray files) ship into the AAB. List the 6 files explicitly: 5 TTFs + `OFL.txt`.
- [x] [Review][Patch] **Add test asserting `OFL.txt` exists** [new test in `test/design/offline_fonts_test.dart` or fonts_licensing_test.dart] — `File('assets/google_fonts/Manrope/OFL.txt').existsSync()`. Guards against an asset cleanup PR removing the SIL OFL §4 license-with-binaries requirement.
- [x] [Review][Patch] **Add per-assertion `// guards ACx.y` comments to `tokens_test.dart` and `offline_fonts_test.dart`** [`test/design/tokens_test.dart`, `test/design/offline_fonts_test.dart`] — AC6.5 says "Every assertion has a one-line comment naming the AC it guards". `theme_test`, `semantic_colors_test`, `icons_test` comply; the other two only annotate at group-level (or not at all).
- [x] [Review][Patch] **Drop redundant body `Text('prijavko')` in `_DesignSystemPreview`** [`lib/main.dart:1207, 1216`] — AppBar title and `MaterialApp(title:)` already cover the brand string. The body version exists "to smoke-test typography", but `headlineLarge` is exercised more meaningfully by the tests. Replace with a non-brand string (e.g. `'Design system'`) or drop.
- [x] [Review][Patch] **Restore content assertion in `integration_test/app_test.dart`** [`integration_test/app_test.dart:55-57`] — old test asserted `find.text('Hello World!')` (semantic content). New test only counts widget types; a font-load failure that swallows glyphs but doesn't throw would still pass. Add `expect(find.text('Preview'), findsAtLeastNWidgets(1))`.
- [x] [Review][Patch] **Add `Tokens.size.outlinedButtonMinHeight = 48.0` and reference from `outlinedButtonTheme`** [`lib/design/tokens.dart`, `lib/design/theme.dart:42`] — only hardcoded layout literal in the otherwise-token-driven theme file. AC2.5 quotes 48 as a literal, but the design-system rule's "no arbitrary spacing" spirit applies — token-ize for parity with `buttonMinHeight`.
- [x] [Review][Patch] **Update File List in this story file** [`_bmad-output/implementation-artifacts/1-2-design-system-foundation.md` Dev Agent Record > File List] — missing entries: `1-2-design-system-foundation.md` itself (added) and `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified).

#### Deferred

- [x] [Review][Defer] **`semantic_colors_test.dart` doesn't directly exercise `buildLightTheme`/`buildDarkTheme` registration** [`test/design/semantic_colors_test.dart:1900-1925`] — deferred, registration is covered indirectly via `theme_test.dart`'s `extension<SemanticColors>() != null` per-mode assertion.
- [x] [Review][Defer] **Icons guard regex matches forbidden shape inside doc comments and multi-line string literals** [`.github/workflows/icons_guard.yml:42`] — deferred, latent false-positive trap; no current call site triggers it. Revisit if a contributor adds a teaching example to a `lib/**` doc comment.
- [x] [Review][Defer] **`pubspec.lock` pulls heavy native_toolchain_c / objective_c / jni transitive deps** [`pubspec.lock:1466-1530`] — deferred, transitive via `google_fonts 8.x`; cannot be removed without forking. Apk size impact unverified.
- [x] [Review][Defer] **`outlinedButton` border `colorScheme.outline` WCAG AA not asserted in dark mode** [`lib/design/theme.dart:1006-1008`] — deferred, accessibility contrast tests are an Epic-1.5+ concern (Welcome / Onboarding screens introduce the first user-visible text-on-outline surface).
- [x] [Review][Defer] **`_DesignSystemPreview` does not handle text-scale extremes or RTL** [`lib/main.dart:55-119`] — deferred, preview is throwaway and replaced by `WelcomeScreen` in Story 1.5.
- [x] [Review][Defer] **`icons_test.dart` asserts package-internal font family string `MaterialSymbolsRounded`** [`test/design/icons_test.dart:1801-1804`] — deferred, brittle to package internals but currently the only signal that the rounded variant resolved. No fix without losing intent.
- [x] [Review][Defer] **`Tokens.color` is a single-field nested class** [`lib/design/tokens.dart:1110-1117`] — deferred, AC1.1 mandates the namespace structure even though `primarySeed` is the only color value; future seed additions land here.
- [x] [Review][Defer] **Theme builder does not set `splashFactory` / `visualDensity`** [`lib/design/theme.dart:986-1043`] — deferred, defensive future-proofing not required by AC2.5; revisit if Flutter SDK changes adaptive-density defaults.
