# Design System Rules — Flutter / Material 3

Encodes the design system decisions already committed in
`_bmad-output/planning-artifacts/ux-design-specification.md`. These rules are
authoritative for any UI work in the `lib/` tree. When the UX spec and these
rules disagree, the UX spec wins (and these rules need updating).

Context: prijavko is an Android-only Flutter 3.x app. Stack pre-committed
(architecture.md): Material 3 native, `google_fonts`, Riverpod 3, no
third-party UI kit. Figma MCP is **not** available (Starter plan — no Dev
Mode). Design translation happens manually from the UX spec + screenshots,
not via MCP tooling.

---

## 1. File & Directory Layout

- **Design tokens** live in `lib/design/tokens.dart` — pure `const` values
  only, no logic, no Flutter imports beyond `dart:ui` / `flutter/material.dart`
  for `Color` and `TextStyle` types.
- **Theme builders** live in `lib/design/theme.dart` — exports
  `buildLightTheme()` and `buildDarkTheme()`, both derived from `tokens.dart`.
- **Theme extensions** live in `lib/design/extensions.dart` — e.g.
  `ThemeExtension<SemanticColors>` for status colors that Material 3
  `ColorScheme` does not cover (warning, info).
- **Custom widgets** live in `lib/widgets/` — one file per widget,
  `PascalCase.dart`. Each file has a top-of-file doc comment explaining *why*
  this widget exists (what Material 3 primitive it wraps and why a plain
  primitive was insufficient).
- **Screens** live in `lib/features/<feature>/<screen>_screen.dart` — Riverpod
  `ConsumerWidget` or `ConsumerStatefulWidget`, never stateful on its own.
- IMPORTANT: **Never hardcode a color, spacing value, radius, or text style in
  a widget/screen file.** Always import from `lib/design/tokens.dart` or
  consume via `Theme.of(context)` / `Theme.of(context).extension<...>()`.

## 2. Theme & ColorScheme

- Light and dark themes are **both** built via `ColorScheme.fromSeed(seedColor:
  Tokens.primarySeed, brightness: ...)`. Do not construct `ColorScheme`
  manually — `fromSeed` produces the full tonal palette with WCAG AA contrast
  by default.
- The seed color lives in `tokens.dart` as `primarySeed` (single source).
  Changing the brand color = one-line edit.
- Dark mode is the **default design target** (per UX spec — night-shift host
  use case). Always design and test dark first, then validate light. Both
  must ship.
- `MaterialApp.themeMode: ThemeMode.system` — never hardcode `light` or
  `dark`. User's device preference wins.
- Component defaults (e.g. `FilledButton` min height, `Card` shape) go in
  `ThemeData`'s component theme slots (`filledButtonTheme`, `cardTheme`,
  etc.), not per-widget overrides.

## 3. Design Tokens (from UX spec §tokens)

Encode these as `const` fields in `tokens.dart`:

- **Spacing grid**: 4dp base → `space1=4, space2=8, space3=12, space4=16,
  space6=24, space8=32, space12=48`. No arbitrary `EdgeInsets.all(13)`.
- **Radii**: `radiusButton=12, radiusCard=16, radiusSheet=24`.
- **Button min height**: `buttonMinHeight=56` (one-handed night-shift use).
- **Typography**: `GoogleFonts.interTextTheme(...)` (or Manrope — decide once,
  lock in). Material 3 typescale with +1 step on display/headline.
- **Semantic colors** (beyond Material 3): `warning`, `info` — exposed via
  `ThemeExtension<SemanticColors>`. `success` and `error` come from
  `ColorScheme.tertiary` / `ColorScheme.error` — do not duplicate.
- **Icon set**: Material Symbols rounded. Register via
  `google_fonts`/`material_symbols_icons` in one place; use `Symbols.xxx`
  everywhere, not `Icons.xxx` (rounded variant is the house style).

## 4. Widget Hierarchy — Material 3 First

Use Material 3 primitives **directly** for everything standard. Custom
widgets exist only when a primitive cannot express prijavko-specific
behavior.

**Use Material 3 directly (do not wrap):**
`FilledButton`, `OutlinedButton`, `TextButton`, `TextField`, `Scaffold`,
`AppBar`, `Card`, `ListTile`, `Switch`, `Checkbox`, `Radio`, `Dialog`,
`BottomSheet`, `SnackBar`, `NavigationBar`, `NavigationRail`,
`ProgressIndicator`, `Chip`.

**Custom widgets (per UX spec — ~5 total, scope-limited):**
- `CredentialBanner` — MaterialBanner styled for auth-expired state + one-tap
  re-auth action.
- `GuestProgressTile` — per-guest row with 3-tier pipeline state
  (queued / sending / confirmed) indicator.
- Add new custom widgets only when a concrete requirement cannot be solved
  by composing primitives + `ThemeData`. Every new custom widget needs a
  one-paragraph "why" in the file header.

IMPORTANT: Do **not** introduce a third-party UI kit (FlexColorScheme,
GetWidget, shadcn_flutter clones, etc.). The stack decision is locked:
Material 3 + custom theme.

## 5. Accessibility (non-negotiable)

- Minimum tap target: 56×56 dp (exceeds WCAG 44×44 — UX spec requirement
  for gloved/tired hands).
- Text contrast: WCAG AA (`ColorScheme.fromSeed` gives this by default —
  do not override `onSurface` / `onPrimary` colors manually).
- Every `IconButton` / `InkWell` / gesture detector needs a `Semantics`
  label or `tooltip`. No silent tap targets.
- Dynamic type: respect system text scale. Use `Theme.of(context).textTheme`
  styles — never raw `TextStyle(fontSize: 16)`.

## 6. Localization

- All user-facing strings go through `AppLocalizations` (ARB files,
  `flutter gen-l10n`). Croatian (`hr`) is primary; English (`en`) is
  fallback.
- IMPORTANT: No literal Croatian or English strings in widget build methods.
  CI grep guard (per NFR-L4) will block the commit.
- Material Symbols + Material 3 component labels are already localized via
  `MaterialLocalizations` — include `GlobalMaterialLocalizations.delegate`
  in `MaterialApp.localizationsDelegates`.

## 7. Design-to-Code Workflow (manual, no Figma MCP)

Starter Figma → no Dev Mode MCP. Workflow:

1. Read the relevant section of `ux-design-specification.md` for the screen
   being built.
2. If a Figma mockup exists, export the screenshot manually and reference it
   in the implementation PR.
3. Build screen from Material 3 primitives + tokens. Never copy pixel values
   from Figma inspection — always round to the spacing grid (§3).
4. Validate against the UX spec's emotional journey and interaction notes,
   not against Figma measurements.
5. Add a widget test asserting the key token usages (`FilledButton` minimum
   height, `Card` shape) so drift gets caught.

## 8. Craftsmanship Reminders (reinforce `.claude/rules/japanese-craftsmanship.md`)

- **Omotenashi**: every custom widget's file header explains *why* it
  exists — the Material 3 primitive it wraps and the specific constraint
  that forced the wrap.
- **Poka-yoke**: make invalid theme states impossible. Prefer
  `ThemeExtension` with required named parameters over loose maps of
  colors.
- **JIT**: do not build a widget for a screen not yet in the current
  sprint. Tokens and theme come first; custom widgets come when the
  requiring screen does.
- **Kaizen**: if you touch a screen and spot a hardcoded `EdgeInsets`,
  `Color`, or `BorderRadius`, replace it with the token in the same PR.
  Do not defer to a "theme cleanup sprint."
