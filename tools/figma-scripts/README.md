# Figma Build Scripts

Plugin API scripts that build the entire prijavko Figma file — variable
collections, text styles, components, and screens — from source code.
Re-runnable. The Figma file is a derivative artifact; these scripts are the
canonical source.

## Prerequisites

- Figma Desktop (free Starter plan works)
- Node.js ≥ 18
- [`silships/figma-cli`](https://github.com/silships/figma-cli) installed at
  `~/tools/figma-cli` (adjust path below if different)
- Figma file open with the **FigCli** plugin running in Safe Mode

## Connecting

In a terminal:
```sh
~/tools/figma-cli/bin/fig-start --safe
```

Then in Figma: Plugins → Development → FigCli → Run.

## Running a script

```sh
node ~/tools/figma-cli/src/index.js eval --file tools/figma-scripts/01-color-collection.js
```

Every script returns a JSON summary on stdout.

## Execution order (cold file → full build)

| # | Script | What it builds |
|---|---|---|
| 01 | color-collection | `color` variable collection (17 semantic dark-mode tokens) |
| 02 | spacing-radii-sizing | `spacing` (8), `radii` (3), `sizing` (1) collections |
| 03 | text-styles | 12 Manrope text styles (M3 scale +1 step on display/headline) |
| 04 | foundations-specimen | Visual specimen frame (swatches + type scale) |
| 05 | add-warning-container | Add `warningContainer` + `onWarningContainer` tokens |
| 06 | components-page-and-buttons | `Components` page + 3 button main components |
| 07 | card | `Card` component |
| 08 | guest-status-glyph | `GuestStatusGlyph` variant set (3 sizes × 5 states) |
| 08b | glyph-fix-layout | Grid-position the 15 glyph variants |
| 09 | credential-banner | `CredentialBanner` variant set (warning + info) |
| 10 | queue-row | `QueueRow` variant set (4 states) |
| 11 | queue-hero | `QueueHero` variant set (4 states) |
| 12 | remaining-custom | 6 custom components (CaptureConfirmation, ClosureSummary, FacilityPickerSheet, MRZViewfinder, TypedConfirmationDialog, AdBanner) |
| 13 | m3-primitives | 8 M3 primitives (TextField, Chip, Switch, ListTile, AlertDialog, LinearProgressIndicator, CircularProgressIndicator, SnackBar) |
| 14 | cosmetic-fixes | TextField vertical centering, ✗→× glyph, ListTile dot, specimen widening |
| 15 | screens | _superseded by 18_ |
| 16 | screen-text-overrides | _superseded by 18_ |
| 17 | tokens-and-fixes | OBRIŠI centering, `surfaceContainerHigh`, `outlineVariant`, QueueRow bg → surfaceContainerHigh |
| 18 | screens-v2 | Rebuild 11 screens with status bar, rich AppBar, doc-prefixed rows |
| 19 | queuerow-title-size | Drop QueueRow title from title/Large → title/Medium |
| 20 | icons-and-appbar | FacilityPickerSheet rows get 🏠, Welcome bullets get 📷/🔒/⚡, Facility Picker screen gets AppBar |
| 21 | login-fixes | TextField left-align + 🔒 icon on Login hint |
| 22 | hint-row-fix | Fix collapsed height on Login hint row |
| 23 | textfield-full-width | TextField inner field stretches to fill parent |
| 24 | entry-edit-screens | Manual Entry + Edit Guest screens |
| 25 | button-icons | 📷 / ⌨ / ↑ / ↗ icons into button labels on Home + Closure |
| 26 | capture-chrome | Add × close + "✓ 3 u redu" success chip to CaptureConfirmation |

Scripts 15 + 16 are kept for history; run 18 onward for the current state.

## Idempotency

Each script **should** be safely re-runnable:
- Collection/component creators reuse-if-exists, update values in place.
- Screen builders clear the `Screens` page before rebuilding.

Exceptions: some cosmetic-fix scripts mutate specific nodes by characters match
(e.g. "HR2184…") — they silently no-op if the text has drifted. Re-run the
upstream script that created the node.

## Why scripts, not manual Figma work

Figma Starter plan has no Dev Mode MCP. Manual edits can't be diffed, reviewed,
or replayed. Keeping everything in code gives us version control, consistency
across iterations, and a ground-truth source for implementation.

## Known limitations

- Starter plan = 1 mode per variable collection. Light-mode palette is not in
  Figma — lives only in code (`ColorScheme.fromSeed(brightness: .light)`).
- Gradient paints can't bind to variables → `ClosureSummary` gradient uses
  hardcoded hex values. Update manually if tokens change.
- Emoji render as monochrome glyphs in Manrope fallback (not Apple Color Emoji).
  Acceptable for this design.
