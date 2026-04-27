// WHY: Single ThemeData factory site. Every screen reads styling through
// `Theme.of(context)` and `context.semanticColors` — never hand-rolls a
// `TextStyle`, never overrides a button theme inline. If a future PR
// touches a theme value, the change lands in this file and is visible to
// the whole app at once.
//
// Why dark-mode is the primary design target (per `.claude/rules/design-system.md §2`
// and UX spec §Color System): hosts work night-shift check-ins, so the
// dark palette is the one that has to feel right. Light mode is the
// fallback. `MaterialApp.themeMode = ThemeMode.system` makes the device
// pick — never hardcode either side.
//
// Why `ColorScheme.fromSeed`: a single brand byte
// (`Tokens.color.primarySeed`) drives every surface, primary, secondary,
// and tertiary tone. WCAG AA contrast is satisfied by construction. We
// never call `ColorScheme(primary: …, onPrimary: …, …)` by hand — that
// path invites contrast regressions.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:prijavko/design/extensions.dart';
import 'package:prijavko/design/tokens.dart';

ThemeData buildLightTheme() => _buildTheme(Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Tokens.color.primarySeed,
    brightness: brightness,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
  final manropeText = GoogleFonts.manropeTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: _applyTypescale(manropeText),
    extensions: <ThemeExtension<dynamic>>[
      brightness == Brightness.dark
          ? SemanticColors.dark()
          : SemanticColors.light(),
    ],
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(Tokens.size.buttonMinHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        // WHY: 48dp for secondary actions per UX spec §Button Hierarchy —
        // primary/destructive get 56dp via filledButtonTheme; secondaries
        // de-emphasise through height before colour.
        minimumSize: const Size.fromHeight(48.0),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radius.button),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radius.button),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      // WHY: padding lives on parents; Card shapes the surface only.
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radius.card),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tokens.radius.sheet),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radius.button),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Tokens.space.s16,
        vertical: Tokens.space.s12,
      ),
    ),
  );
}

// WHY: 12 Material 3 typescale slots tuned per figma-code-contract.md §2.
// Italics excluded — UX spec §Typography forbids them for the host's
// reading context. Heights are expressed as `lineHeight / fontSize` so
// the Flutter `height` value matches the design tool's "line height in
// dp" intent.
TextTheme _applyTypescale(TextTheme base) {
  TextStyle? style(TextStyle? slot, double size, FontWeight weight, double lh) {
    return slot?.copyWith(
      fontSize: size,
      fontWeight: weight,
      height: lh / size,
    );
  }

  return base.copyWith(
    displayLarge: style(base.displayLarge, 57, FontWeight.w800, 64),
    displayMedium: style(base.displayMedium, 45, FontWeight.w700, 52),
    headlineLarge: style(base.headlineLarge, 32, FontWeight.w700, 40),
    headlineMedium: style(base.headlineMedium, 28, FontWeight.w700, 36),
    headlineSmall: style(base.headlineSmall, 24, FontWeight.w600, 32),
    titleLarge: style(base.titleLarge, 22, FontWeight.w600, 28),
    titleMedium: style(base.titleMedium, 16, FontWeight.w600, 24),
    bodyLarge: style(base.bodyLarge, 16, FontWeight.w400, 24),
    bodyMedium: style(base.bodyMedium, 14, FontWeight.w400, 20),
    bodySmall: style(base.bodySmall, 12, FontWeight.w500, 16),
    labelLarge: style(base.labelLarge, 14, FontWeight.w600, 20),
    labelMedium: style(base.labelMedium, 12, FontWeight.w600, 16),
  );
}
