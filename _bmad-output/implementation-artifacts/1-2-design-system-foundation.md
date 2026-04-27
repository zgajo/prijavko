# Story 1.2: Design System Foundation

Status: in-progress

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
- [ ] Task 2 — Scaffold `lib/design/` directory + `tokens.dart` (AC: #1)
  - [ ] Subtask 2.1 — Create `lib/design/tokens.dart` with the `Tokens` namespace + `Tokens.color`, `Tokens.space`, `Tokens.radius`, `Tokens.size` nested classes per AC1.
  - [ ] Subtask 2.2 — Each class gets `const <Name>._();` to block instantiation; top-of-file `// WHY:` comment explains the "pure const, no Flutter theming logic" scope boundary per `.claude/rules/design-system.md §1`.
- [ ] Task 3 — `lib/design/extensions.dart` — `SemanticColors` `ThemeExtension` (AC: #3)
  - [ ] Subtask 3.1 — Declare `class SemanticColors extends ThemeExtension<SemanticColors>` with the 8 required-named-parameter `Color` fields.
  - [ ] Subtask 3.2 — Implement `copyWith(…)` and `lerp(ThemeExtension<SemanticColors>? other, double t)` using `Color.lerp` per field.
  - [ ] Subtask 3.3 — Add `SemanticColors.light()` and `SemanticColors.dark()` factory constructors with the exact hex values from UX spec §Color System. For any dark value whose UX-spec description is tonal (e.g. "surface container high" not pinned to hex), derive once from `ColorScheme.fromSeed(Tokens.color.primarySeed, brightness: .dark)`, pin the result, and add a `// DERIVED FROM fromSeed:` inline comment recording the pinned tone for future auditability.
  - [ ] Subtask 3.4 — Add the `SemanticColorsContext` extension on `BuildContext` returning `Theme.of(this).extension<SemanticColors>()!` with a `// WHY:` comment stating the non-null assertion is intentional Poka-yoke.
- [ ] Task 4 — `lib/design/theme.dart` — light/dark builders (AC: #2)
  - [ ] Subtask 4.1 — Implement `ThemeData buildLightTheme()` and `buildDarkTheme()` with `useMaterial3: true`, `colorScheme: ColorScheme.fromSeed(…)`, `textTheme: GoogleFonts.manropeTextTheme(base).copyWith(<12 styles>)`, `extensions: <ThemeExtension<dynamic>>[SemanticColors.<brightness>()]`.
  - [ ] Subtask 4.2 — Fill the component theme slots per AC2.5: `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `cardTheme`, `bottomSheetTheme`, `inputDecorationTheme`.
  - [ ] Subtask 4.3 — Top-of-file `// WHY:` comment explains the "no per-widget theme overrides; always edit this file" rule and the `.claude/rules/design-system.md §2` dark-mode-first design contract.
- [ ] Task 5 — `lib/design/icons.dart` + CI guard (AC: #5)
  - [ ] Subtask 5.1 — Create `lib/design/icons.dart` with a top-of-file `// WHY:` paragraph pinning the rounded variant as house style, followed by `export 'package:material_symbols_icons/symbols.dart' show Symbols;` (adjust the `show` clause to match the package's actual public API; confirm at install time).
  - [ ] Subtask 5.2 — Add `.github/workflows/icons_guard.yml` (or extend `pii_guard.yml` — state the choice in the commit message) with the `Icon\s*\(\s*Icons\.` regex + self-test. Mirror `pii_guard.yml`'s structure: `rc=$?` capture, explicit `case` branch handling, `echo "::error::…"` on no-SCAN_DIRS.
  - [ ] Subtask 5.3 — Add `docs/ci/icons-guard-regex.md` with passing + failing example lines, matching the template `docs/ci/pii-guard-regex.md` established in Story 1.1.
- [ ] Task 6 — Wire `MaterialApp` + `_DesignSystemPreview` (AC: #4)
  - [ ] Subtask 6.1 — Rewrite `lib/main.dart` to the AC4.1 `MaterialApp` shape.
  - [ ] Subtask 6.2 — Define `_DesignSystemPreview` (private stateless widget in `main.dart`) with the AC4.3 content; TODO comment referencing story 1.5.
  - [ ] Subtask 6.3 — Confirm `flutter run` launches the preview; dark/light visually inspected on device (emulator or real hardware) — capture one screenshot per mode, attach to the PR description (Monozukuri — evidence of execution, not just tests).
- [ ] Task 7 — Create `lib/widgets/` directory convention marker (AC: #9)
  - [ ] Subtask 7.1 — Create `lib/widgets/README.md` (preferred over `.gitkeep`) that states "Custom widgets land in this folder, one file per widget, per `.claude/rules/design-system.md §4`. Each file begins with a `// WHY:` paragraph."
- [ ] Task 8 — Widget tests (AC: #6)
  - [ ] Subtask 8.1 — `test/design/theme_test.dart` — 56dp min-height, 16dp card radius, `colorScheme` present, both themes.
  - [ ] Subtask 8.2 — `test/design/semantic_colors_test.dart` — extension resolves under both themes; light ≠ dark warning.
  - [ ] Subtask 8.3 — `test/design/tokens_test.dart` — 4dp grid invariant, `const` constants exist.
  - [ ] Subtask 8.4 — `test/design/icons_test.dart` — `Icon(Symbols.<rounded-check>)` resolves a font family; fails loudly on misconfigured asset.
  - [ ] Subtask 8.5 — Run `flutter test` locally → all green. Run `dart analyze --fatal-warnings --fatal-infos` and `dart format --set-exit-if-changed lib/ test/ integration_test/` → clean.
- [ ] Task 9 — Verify offline-font pipeline (AC: #8)
  - [ ] Subtask 9.1 — With `GoogleFonts.config.allowRuntimeFetching = false`, confirm `flutter test` + `flutter run` succeed without a network connection (toggle airplane mode on the test device; run the preview). If any glyph renders as Tofu, the asset pipeline is broken — fix before moving on.
  - [ ] Subtask 9.2 — Record the airplane-mode verification + screenshot in the PR description.

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

### Change Log

| Date | Task | Notes |
| ---- | ---- | ----- |
| 2026-04-27 | Task 1 | Added `google_fonts: ^8.0.2` (resolved `8.0.2`) and `material_symbols_icons: ^4.2928.1` (resolved `4.2928.1`) under `dependencies`. Bundled Manrope 400/500/600/700/800 + OFL.txt under `assets/google_fonts/Manrope/`. Registered the asset folder in `pubspec.yaml > flutter.assets`. Set `GoogleFonts.config.allowRuntimeFetching = false` in `main()`. AC8.1 source URL deviation noted in Completion Notes. |

### File List

- `pubspec.yaml` — modified (added `google_fonts` + `material_symbols_icons` deps, registered Manrope asset folder).
- `pubspec.lock` — created (was untracked; `flutter pub get` regenerated it).
- `lib/main.dart` — modified (added `GoogleFonts.config.allowRuntimeFetching = false` in `main()`).
- `assets/google_fonts/Manrope/Manrope-Regular.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-Medium.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-SemiBold.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-Bold.ttf` — added.
- `assets/google_fonts/Manrope/Manrope-ExtraBold.ttf` — added.
- `assets/google_fonts/Manrope/OFL.txt` — added.
- `docs/design/fonts-licensing.md` — added.
