// WHY: Single source of truth for spacing, radii, sizes, and the seed color.
// Pure-const namespace per `.claude/rules/design-system.md §1` and Story 1.2
// AC1 — no Flutter theming logic, no `TextStyle` factories, no widgets.
// Theming logic lives in `theme.dart`; semantic colors that fall outside
// `ColorScheme.fromSeed` live in `extensions.dart`.
//
// Why no other `Color` constants here: every runtime brand color flows from
// `ColorScheme.fromSeed(seedColor: TokensColor.primarySeed, brightness: …)`
// in `theme.dart`. Adding a second `const Color(0xFF…)` here would invite
// drift between the seed and hand-picked tonals. Status palette (warning,
// success, closure-accent) is the documented exception and lives on the
// `SemanticColors` `ThemeExtension` in `extensions.dart`.
//
// Why `static const` fields on `abstract final class` namespaces:
// Story 1.2 AC1.1's syntax sample (`Tokens.color.primarySeed`) cannot be
// honoured literally — Dart does not allow `static` member access through
// an instance, so a `const TokensColor` instance with `final` fields
// cannot be const-evaluated in widget constructors (e.g.
// `const EdgeInsets.all(Tokens.space.s16)`). The fix promotes every value
// to `static const` on a category namespace class (`TokensColor`,
// `TokensSpace`, `TokensRadius`, `TokensSize`); call sites read
// `TokensSpace.s16` directly. `abstract final class` + private
// unnamed constructor blocks instantiation (Poka-yoke).

import 'package:flutter/material.dart' show Color;

abstract final class Tokens {
  Tokens._();
}

abstract final class TokensColor {
  TokensColor._();

  // WHY: Adriatic Teal — UX spec §Color System brand seed. All Material 3
  // surface/primary/secondary/tertiary tones derive from this single byte
  // via `ColorScheme.fromSeed`.
  static const Color primarySeed = Color(0xFF0D4F52);
}

abstract final class TokensSpace {
  TokensSpace._();

  // 4dp base grid — UX spec §Spacing & Layout Foundation.
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // WHY: Dart does not let you reflect over `static const` fields, so the
  // 4dp-grid invariant test (Story 1.2 AC6.3) iterates this canonical list
  // instead of a hardcoded copy of the literals — adding a value here is
  // the only sanctioned way to extend the grid, and adding e.g. `s10 = 10`
  // would fail the invariant immediately.
  static const List<double> values = <double>[
    s4,
    s8,
    s12,
    s16,
    s24,
    s32,
    s48,
    s64,
  ];
}

abstract final class TokensRadius {
  TokensRadius._();

  // UX spec §Visual Design Foundation + figma-code-contract.md §1.
  static const double button = 12.0;
  static const double card = 16.0;
  static const double sheet = 24.0;
}

abstract final class TokensSize {
  TokensSize._();

  // WHY: 56dp exceeds WCAG 44×44 (UX spec §Accessibility) and matches the
  // one-handed night-shift ergonomics constraint from PRD NFR-C3.
  static const double buttonMinHeight = 56.0;

  // WHY: Secondary actions de-emphasise via height before colour
  // (UX spec §Button Hierarchy). 48dp keeps WCAG 44×44 compliance while
  // creating a clear visual hierarchy below the 56dp primary buttons.
  static const double outlinedButtonMinHeight = 48.0;
}
