# `lib/widgets/`

Custom widgets land in this folder, **one file per widget**, named
`PascalCase.dart` per `.claude/rules/design-system.md §1`.

## When a custom widget is warranted

Material 3 primitives + `Theme.of(context)` + `context.semanticColors`
cover everything standard. A custom widget is justified **only** when a
concrete, named requirement cannot be expressed by composing primitives
+ `ThemeData`. Per `.claude/rules/design-system.md §4`, the v1 list is
small and scope-limited:

| File (story) | Why it earns its place |
| --- | --- |
| `CredentialBanner.dart` (2.7) | `MaterialBanner` styled for auth-expired state with a one-tap re-auth action — a stateful banner the M3 primitive does not express on its own. |
| `FacilityPickerSheet.dart` (3.3) | Bottom-sheet flow with neutral-app per-session enforcement (Epic 3 architecture). |
| `MRZViewfinder.dart` (4.3) | Camera overlay rectangle aligned with MRZ aspect ratio + capture countdown. |
| `CaptureConfirmation.dart` (4.4) | Post-scan field-confirmation overlay. |
| `GuestStatusGlyph.dart` (5.3) | 3-tier (queued/sending/confirmed) status icon — primitive `Icon` cannot express the tri-state semantic in a single glyph. |
| `QueueRow.dart` / `QueueHero.dart` (5.4) | Queue list row + hero callout for the home surface. |
| `ClosureSummary.dart` (7.1) | The signature moment — gold-accented summary card. |
| `TypedConfirmationDialog.dart` (5.8 / 8.2) | "Type WIPE to confirm" destructive-action dialog. |
| `AdBanner.dart` (10.1) | UMP/CMP-aware AdMob host. |

Each file begins with a `// WHY:` paragraph stating the Material 3
primitive it wraps and the specific constraint that forced the wrap.
Without that paragraph, the file should not exist.

## What does NOT live here

- One-off screen layouts. Those go in `lib/features/<feature>/<name>_screen.dart`.
- Tokens, theming, semantic-colour extensions, or icon re-exports — see
  [`lib/design/`](../design/).
- Throwaway dev/preview surfaces — those live next to `main.dart` and
  carry a TODO referencing the story that retires them.

## Empty for now

This directory is intentionally empty in Story 1.2. Per JIT, each custom
widget arrives with the story that needs it. Creating the folder with
this README marks the convention from day one and keeps git from
discarding the empty path.
