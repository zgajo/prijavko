import 'package:flutter/material.dart';

import 'queue_theme_extension.dart';

/// Single teal seed for light and dark so palettes stay aligned (no mode drift).
const Color _appSeedColor = Colors.teal;

/// Material 3 light theme: [ColorScheme.fromSeed] + shared component themes.
ThemeData buildLightTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _appSeedColor,
    brightness: Brightness.light,
  );
  return _buildAppTheme(scheme);
}

/// Material 3 dark theme: same seed as [buildLightTheme].
ThemeData buildDarkTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _appSeedColor,
    brightness: Brightness.dark,
  );
  return _buildAppTheme(scheme);
}

ThemeData _buildAppTheme(ColorScheme colorScheme) {
  final AppQueueTheme queueTheme = AppQueueTheme.fromColorScheme(colorScheme);

  final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    ),
  );

  final FilledButtonThemeData filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  final NavigationBarThemeData navigationBarTheme = NavigationBarThemeData(
    backgroundColor: colorScheme.surfaceContainer,
    indicatorColor: colorScheme.secondaryContainer,
  );

  final ChipThemeData chipTheme = ChipThemeData(
    backgroundColor: colorScheme.surfaceContainerHigh,
    deleteIconColor: colorScheme.onSurfaceVariant,
    disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
    labelStyle: TextStyle(color: colorScheme.onSurface),
    secondaryLabelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[queueTheme],
    inputDecorationTheme: inputDecorationTheme,
    filledButtonTheme: filledButtonTheme,
    navigationBarTheme: navigationBarTheme,
    chipTheme: chipTheme,
  );
}
