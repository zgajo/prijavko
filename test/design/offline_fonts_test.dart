// Story 1.2 AC8.3 — guards the offline-font bundling pipeline.
//
// `applyMainAppFontConfig()` (called from `main()`) sets
// `GoogleFonts.config.allowRuntimeFetching = false`. With that flag, a
// missing bundled asset would make the very first `GoogleFonts.manrope*`
// call throw — the theme builder is invoked here, so a regression that
// drops an asset path or renames a `.ttf` lights up this test loud.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/main.dart';

void main() {
  // WHY: `GoogleFonts.config.allowRuntimeFetching` is a global static —
  // mutating it in one test leaks into the next under shared isolates.
  // Capture and restore so a future test that asserts the default-true
  // behaviour is not silently corrupted by ours.
  late bool originalAllowRuntimeFetching;

  setUp(() {
    originalAllowRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;
  });

  tearDown(() {
    GoogleFonts.config.allowRuntimeFetching = originalAllowRuntimeFetching;
  });

  test('applyMainAppFontConfig disables runtime CDN fetching', () {
    // guards AC8.1 — calls the same init function `main()` calls. Force a
    // non-default state first, then call the function and assert the
    // post-condition. If a refactor deletes the line inside
    // `applyMainAppFontConfig`, this test catches the regression
    // immediately rather than waiting for a host to see Tofu glyphs.
    GoogleFonts.config.allowRuntimeFetching = true;
    applyMainAppFontConfig();
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('OFL.txt ships alongside the Manrope binaries', () {
    // guards AC8.2 — SIL OFL 1.1 §4 requires the license to ship with the
    // font binaries. A future `flutter build` cleanup that "tidies up
    // unused assets" must not silently strip OFL.txt — fail loud here.
    final ofl = File('assets/google_fonts/Manrope/OFL.txt');
    expect(ofl.existsSync(), isTrue, reason: 'OFL.txt missing alongside .ttf');
  });

  testWidgets('buildLightTheme resolves Manrope offline', (tester) async {
    // guards AC8.3 — Flutter test defaults to no network; combined with
    // `allowRuntimeFetching = false`, a missing asset would throw at the
    // very first font lookup. The fontFamily assertion makes sure the
    // typescale actually went through `GoogleFonts.manropeTextTheme(...)`
    // and is not silently falling back to the platform default.
    applyMainAppFontConfig();

    late ThemeData captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (ctx) {
            captured = Theme.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // guards AC8.3 — every primary typescale slot resolves to a Manrope
    // font family string (google_fonts emits names like `Manrope_regular`).
    for (final style in <TextStyle?>[
      captured.textTheme.displayLarge,
      captured.textTheme.headlineLarge,
      captured.textTheme.bodyLarge,
      captured.textTheme.labelMedium,
    ]) {
      expect(style, isNotNull);
      expect(style!.fontFamily, contains('Manrope'));
    }
  });

  testWidgets('buildDarkTheme resolves Manrope offline', (tester) async {
    // guards AC8.3 — symmetric coverage for dark; the dark-mode-first
    // design contract demands that the dark typescale resolve assets
    // identically to light.
    applyMainAppFontConfig();

    late ThemeData captured;
    await tester.pumpWidget(
      MaterialApp(
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (ctx) {
            captured = Theme.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured.brightness, Brightness.dark);
    for (final style in <TextStyle?>[
      captured.textTheme.displayLarge,
      captured.textTheme.headlineLarge,
      captured.textTheme.bodyLarge,
      captured.textTheme.labelMedium,
    ]) {
      expect(style, isNotNull);
      expect(style!.fontFamily, contains('Manrope'));
    }
  });
}
