# Figma ↔ Code Contract

Mapping between the prijavko Figma file and the Flutter codebase that will be
written in Story 1 onward. The Figma file is the **visual contract**; code
mirrors its tokens, components, and screens 1:1.

- Figma file lives on Starter plan → no Dev Mode MCP. Source of truth for
  re-generating Figma = [`tools/figma-scripts/`](../../tools/figma-scripts/).
- When Figma and this doc disagree, **Figma wins** (and this doc gets an
  update PR).
- When the UX spec and Figma disagree, **UX spec wins** (and Figma gets
  re-generated from an updated script).

---

## 1. Tokens → `lib/design/tokens.dart`

Single file. Pure `const` values. No Flutter imports beyond `Color` /
`TextStyle` types. Matches the `color`, `spacing`, `radii`, `sizing`
collections in Figma exactly.

| Figma collection | Code equivalent | Notes |
|---|---|---|
| `color` (17 dark-mode vars) | `class Tokens.color` (17 `Color` const) | Light-mode values **do not exist in Figma** (Starter plan limit) — derive from `ColorScheme.fromSeed(seedColor: Tokens.color.primarySeed, brightness: .light)` or hand-list in code per UX spec §Color System |
| `spacing` (`space-4 … space-64`) | `class Tokens.space { static const s4 = 4.0; … s64 = 64.0; }` | |
| `radii` (`radius-button`, `radius-card`, `radius-sheet`) | `class Tokens.radius { static const button = 12.0; card = 16.0; sheet = 24.0; }` | |
| `sizing` (`button-min-height=56`) | `class Tokens.size { static const buttonMinHeight = 56.0; }` | One-handed night-shift use (UX spec §tokens) |

**Seed color:** `primarySeed = Color(0xFF0D4F52)` — the Adriatic Teal seed.
Light-mode values derive from `ColorScheme.fromSeed(seedColor: primarySeed,
brightness: .light)`; dark values shipped in Figma match
`ColorScheme.fromSeed(..., brightness: .dark)` with minor UX-driven tweaks.

**Extra tokens not in M3 `ColorScheme`** (must use `ThemeExtension`):
- `warning`, `warningContainer`, `onWarningContainer`
- `success`, `onSuccess` (M3 uses `tertiary` — we keep explicit success for clarity)
- `closureAccent` (gold for Closure Summary only)
- `surfaceContainerHigh`, `outlineVariant` (M3 extended tonal)

---

## 2. Text styles → `lib/design/theme.dart`

`buildDarkTheme()` / `buildLightTheme()` each produce a `ThemeData` with
`textTheme` matching the 12 Figma styles.

| Figma text style | M3 `TextTheme` slot | Figma: size / weight / lineHeight |
|---|---|---|
| `display/Large`  | `displayLarge`  | 57 / 800 / 64 |
| `display/Medium` | `displayMedium` | 45 / 700 / 52 |
| `headline/Large` | `headlineLarge` | 32 / 700 / 40 |
| `headline/Medium`| `headlineMedium`| 28 / 700 / 36 |
| `headline/Small` | `headlineSmall` | 24 / 600 / 32 |
| `title/Large`    | `titleLarge`    | 22 / 600 / 28 |
| `title/Medium`   | `titleMedium`   | 16 / 600 / 24 |
| `body/Large`     | `bodyLarge`     | 16 / 400 / 24 |
| `body/Medium`    | `bodyMedium`    | 14 / 400 / 20 |
| `body/Small`     | `bodySmall`     | 12 / 500 / 16 |
| `label/Large`    | `labelLarge`    | 14 / 600 / 20 |
| `label/Medium`   | `labelMedium`   | 12 / 600 / 16 |

Font: **Manrope** via `google_fonts`. Weights 400/500/600/700/800.

---

## 3. Components

### Material 3 primitives — use native, no wrapping

Figma has these for design reference only. Code uses the Material widget
directly with `ThemeData` defaults.

| Figma component | Flutter widget | Where |
|---|---|---|
| `Button/Filled`      | `FilledButton`      | inline |
| `Button/Outlined`    | `OutlinedButton`    | inline |
| `Button/Text`        | `TextButton`        | inline |
| `Card`               | `Card`              | inline |
| `TextField`          | `TextField`         | inline |
| `Chip`               | `FilterChip` / `InputChip` | inline |
| `Switch`             | `Switch`            | inline |
| `ListTile`           | `ListTile`          | inline |
| `AlertDialog`        | `AlertDialog`       | inline |
| `LinearProgressIndicator` | `LinearProgressIndicator` | inline |
| `CircularProgressIndicator` | `CircularProgressIndicator` | inline |
| `SnackBar`           | `SnackBar` via `ScaffoldMessenger` | inline |

Theme these uniformly in `buildDarkTheme()` via component theme slots
(`filledButtonTheme`, `cardTheme`, etc.) — do NOT override per widget.

### Custom widgets — one file each under `lib/widgets/`

| Figma component | Flutter file | Why custom |
|---|---|---|
| `GuestStatusGlyph` (15 variants) | [lib/widgets/guest_status_glyph.dart](../../lib/widgets/guest_status_glyph.dart) | Sealed-enum state, 3 sizes, shape+color poka-yoke |
| `QueueRow` (4 variants) | [lib/widgets/queue_row.dart](../../lib/widgets/queue_row.dart) | Composes `GuestStatusGlyph`, PII-masked doc number, state-driven meta |
| `QueueHero` (4 variants) | [lib/widgets/queue_hero.dart](../../lib/widgets/queue_hero.dart) | At-a-glance count + meta, state-switched colors |
| `CredentialBanner` (warning + info) | [lib/widgets/credential_banner.dart](../../lib/widgets/credential_banner.dart) | `MaterialBanner` subclass, never-red rule |
| `FacilityPickerSheet` | [lib/widgets/facility_picker_sheet.dart](../../lib/widgets/facility_picker_sheet.dart) | "Zadnji" pill, tap-outside = cancel poka-yoke |
| `MRZViewfinder` | [lib/widgets/mrz_viewfinder.dart](../../lib/widgets/mrz_viewfinder.dart) | Reticle + corner anchors + counter chip + hint |
| `CaptureConfirmation` | [lib/widgets/capture_confirmation.dart](../../lib/widgets/capture_confirmation.dart) | 200ms fade-in / 400ms hold / 200ms fade-out |
| `ClosureSummary` | [lib/widgets/closure_summary.dart](../../lib/widgets/closure_summary.dart) | Signature moment; gradient + gold count |
| `TypedConfirmationDialog` | [lib/widgets/typed_confirmation_dialog.dart](../../lib/widgets/typed_confirmation_dialog.dart) | Typed-word poka-yoke for irreversible actions |
| `AdBanner` | [lib/widgets/ad_banner.dart](../../lib/widgets/ad_banner.dart) | AdMob wrapper, UMP gating, Home-only |

Every custom widget file MUST have a top-of-file doc comment explaining
**why** it exists (the M3 primitive it wraps and the constraint that forced
the wrap). Per `.claude/rules/design-system.md` §1.

---

## 4. Screens → `lib/features/<feature>/<name>_screen.dart`

Each Figma screen composes component instances. Each corresponds to a
Riverpod `ConsumerWidget` / `ConsumerStatefulWidget`.

| # | Figma screen | Flutter file |
|---|---|---|
| 01 | Welcome | [lib/features/onboarding/welcome_screen.dart](../../lib/features/onboarding/welcome_screen.dart) |
| 02 | Login | [lib/features/auth/login_screen.dart](../../lib/features/auth/login_screen.dart) |
| 03 | Facility Picker | `facility_picker_sheet.dart` (modal, not a screen) |
| 04 | Home · Empty fresh | [lib/features/home/home_screen.dart](../../lib/features/home/home_screen.dart) (empty state) |
| 05 | Home · Queued N | same file (non-empty state) |
| 06 | Home · Auth dead | same file (banner-active state) |
| 07 | Scan | [lib/features/scan/scan_screen.dart](../../lib/features/scan/scan_screen.dart) |
| 08 | Capture Confirmation | same file (post-scan overlay) |
| 09 | Send All Results | [lib/features/send/review_screen.dart](../../lib/features/send/review_screen.dart) |
| 10 | Closure Summary | [lib/features/closure/closure_summary_screen.dart](../../lib/features/closure/closure_summary_screen.dart) |
| 11 | Settings | [lib/features/settings/settings_screen.dart](../../lib/features/settings/settings_screen.dart) |
| 12 | Manual Entry | [lib/features/guest/guest_form_screen.dart](../../lib/features/guest/guest_form_screen.dart) (empty state) |
| 13 | Edit Guest | same file (pre-filled state) |

Where Figma shows multiple screens for the same underlying screen (states of
Home, variants of Scan), code collapses them into one `_Screen` with
state-driven rendering. One file, one route, multiple states.

---

## 5. Implementation rules (carried from `.claude/rules/design-system.md`)

- **Never hardcode** a color, spacing value, radius, or text style in a
  widget/screen file. Import from `tokens.dart` or read `Theme.of(context)`.
- **Dark mode is the design target** — build and verify dark first, then
  validate light.
- **Tap targets ≥ 56×56 dp** (exceeds WCAG 44; UX spec requirement).
- **All user-facing strings** go through `AppLocalizations` (ARB, hr primary).
  No literal Croatian / English in widget build methods.
- **Material Symbols rounded** as house icon style. Don't mix `Icons.xxx`
  with `Symbols.xxx`.
- **Custom widgets** get a `why` paragraph in the file header.

---

## 6. Known gaps Story 1 must close

- No `pubspec.yaml` yet — Flutter project hasn't been initialized.
- No `lib/` directory exists yet. All paths above are planned.
- Light-mode palette lives only in `ColorScheme.fromSeed` at runtime — if
  the PRD ever requires a Figma-verified light preview, upgrade to
  Professional and re-run `01-color-collection.js` with two modes.
- Gradient on `ClosureSummary` uses hardcoded hex values (gradient paints
  can't bind to variables). If tokens change, update
  `12-remaining-custom.js` and re-run.

---

## 7. Re-generating the Figma file

See [tools/figma-scripts/README.md](../../tools/figma-scripts/README.md).
Cold-build from an empty Figma file: run scripts 01-14, then 17-26. (Skip
the superseded 15-16.)
