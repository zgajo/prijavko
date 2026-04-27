// Story 1.2 AC6.1 — guards `lib/design/theme.dart`.
// Pumps a real `MaterialApp` and inspects the resolved component themes
// under both brightness modes. Avoids tautological assertions like
// "FilledButton finds one widget"; tests token wiring, not widget shape.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/design/extensions.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/design/tokens.dart';

void main() {
  Future<ThemeData> resolveTheme(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    late ThemeData captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Builder(
          builder: (ctx) {
            captured = Theme.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  for (final brightness in <Brightness>[Brightness.light, Brightness.dark]) {
    final modeName = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('useMaterial3 is true under $modeName theme', (tester) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      // guards AC2.7 — useMaterial3 is set explicitly on both themes.
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('FilledButton resolves 56dp min-height under $modeName', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      final size = theme.filledButtonTheme.style!.minimumSize!.resolve(
        <WidgetState>{},
      );
      // guards AC2.5 — filledButtonTheme min-height equals
      // Tokens.size.buttonMinHeight (56dp, PRD NFR-C3).
      expect(size!.height, Tokens.size.buttonMinHeight);
    });

    testWidgets('FilledButton resolves 12dp button radius under $modeName', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      final shape =
          theme.filledButtonTheme.style!.shape!.resolve(<WidgetState>{})
              as RoundedRectangleBorder;
      // guards AC2.5 — filled-button radius equals Tokens.radius.button.
      expect(shape.borderRadius, BorderRadius.circular(Tokens.radius.button));
    });

    testWidgets('OutlinedButton resolves 48dp min-height under $modeName', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      final size = theme.outlinedButtonTheme.style!.minimumSize!.resolve(
        <WidgetState>{},
      );
      // guards AC2.5 — secondary buttons de-emphasise via 48dp height.
      expect(size!.height, 48.0);
    });

    testWidgets('Card shape uses 16dp radius under $modeName', (tester) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      // guards AC2.5 — card radius equals Tokens.radius.card.
      expect(shape.borderRadius, BorderRadius.circular(Tokens.radius.card));
    });

    testWidgets('BottomSheet shape uses 24dp top radius under $modeName', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      final shape = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
      // guards AC2.5 — sheet radius equals Tokens.radius.sheet on top edges only.
      expect(
        shape.borderRadius,
        BorderRadius.vertical(top: Radius.circular(Tokens.radius.sheet)),
      );
    });

    testWidgets('ColorScheme is non-null and reports $modeName brightness', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      // guards AC2.2 — ColorScheme.fromSeed produces a populated scheme;
      // do not hand-verify hex (fromSeed's tonal output is Flutter's
      // concern), only that brightness round-trips.
      expect(theme.colorScheme.brightness, brightness);
      expect(theme.colorScheme.primary, isNotNull);
    });

    testWidgets('SemanticColors extension is registered under $modeName', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      // guards AC2.4 — both themes attach the SemanticColors extension.
      expect(theme.extension<SemanticColors>(), isNotNull);
    });

    testWidgets('TextTheme exposes Manrope-mapped slots under $modeName', (
      tester,
    ) async {
      final theme = await resolveTheme(tester, brightness: brightness);
      // guards AC2.3 — typescale weights match the Figma contract.
      expect(theme.textTheme.displayLarge!.fontSize, 57.0);
      expect(theme.textTheme.displayLarge!.fontWeight, FontWeight.w800);
      expect(theme.textTheme.bodyLarge!.fontSize, 16.0);
      expect(theme.textTheme.bodyLarge!.fontWeight, FontWeight.w400);
      expect(theme.textTheme.labelMedium!.fontSize, 12.0);
      expect(theme.textTheme.labelMedium!.fontWeight, FontWeight.w600);
    });
  }
}
