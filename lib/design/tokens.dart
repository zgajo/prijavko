// WHY: Single source of truth for spacing, radii, sizes, and the seed color.
// Pure-const namespace per `.claude/rules/design-system.md §1` and Story 1.2
// AC1 — no Flutter theming logic, no `TextStyle` factories, no widgets.
// Theming logic lives in `theme.dart`; semantic colors that fall outside
// `ColorScheme.fromSeed` live in `extensions.dart`.
//
// Why no other `Color` constants here: every runtime brand color flows from
// `ColorScheme.fromSeed(seedColor: Tokens.color.primarySeed, brightness: …)`
// in `theme.dart`. Adding a second `const Color(0xFF…)` here would invite
// drift between the seed and hand-picked tonals. Status palette (warning,
// success, closure-accent) is the documented exception and lives on the
// `SemanticColors` `ThemeExtension` in `extensions.dart`.
//
// Why nested const-instance namespaces: each nested class is a namespace,
// not a real type users instantiate. Private unnamed constructors make
// instantiation impossible at compile time (Poka-yoke) — `Tokens.space`
// is used as a namespace prefix, never `TokensSpace()`.

import 'package:flutter/material.dart' show Color;

class Tokens {
  const Tokens._();

  static const TokensColor color = TokensColor._();
  static const TokensSpace space = TokensSpace._();
  static const TokensRadius radius = TokensRadius._();
  static const TokensSize size = TokensSize._();
}

class TokensColor {
  const TokensColor._();

  // WHY: Adriatic Teal — UX spec §Color System brand seed. All Material 3
  // surface/primary/secondary/tertiary tones derive from this single byte
  // via `ColorScheme.fromSeed`.
  final Color primarySeed = const Color(0xFF0D4F52);
}

class TokensSpace {
  const TokensSpace._();

  // 4dp base grid — UX spec §Spacing & Layout Foundation.
  final double s4 = 4.0;
  final double s8 = 8.0;
  final double s12 = 12.0;
  final double s16 = 16.0;
  final double s24 = 24.0;
  final double s32 = 32.0;
  final double s48 = 48.0;
  final double s64 = 64.0;
}

class TokensRadius {
  const TokensRadius._();

  // UX spec §Visual Design Foundation + figma-code-contract.md §1.
  final double button = 12.0;
  final double card = 16.0;
  final double sheet = 24.0;
}

class TokensSize {
  const TokensSize._();

  // WHY: 56dp exceeds WCAG 44×44 (UX spec §Accessibility) and matches the
  // one-handed night-shift ergonomics constraint from PRD NFR-C3.
  final double buttonMinHeight = 56.0;
}
