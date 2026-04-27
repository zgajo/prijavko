// WHY: Pin the rounded variant of Material Symbols as the project's icon
// house style. `material_symbols_icons` exposes outlined/rounded/sharp
// per icon via suffix naming (`Symbols.check_rounded`,
// `Symbols.check_outlined`, `Symbols.check_sharp`). Mixing variants in
// the same UI is a visual inconsistency, so callers import this file —
// `package:prijavko/design/icons.dart` — and reach the package's
// `Symbols` class only through the re-export. The CI guard
// `.github/workflows/icons_guard.yml` blocks the related-but-different
// `Icons.<name>` API (Material Icons font, different stroke language
// from Material Symbols) at build time so a stale habit cannot land.
//
// Usage convention: always `Symbols.<name>_rounded`. Outlined and sharp
// getters are technically reachable through this re-export, but house
// style is rounded. PR review enforces the convention; the regex guard
// enforces only the cross-font collision.

export 'package:material_symbols_icons/symbols.dart' show Symbols;
