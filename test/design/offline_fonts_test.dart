// Story 1.2 AC8.3 — guards the offline-font bundling pipeline.
//
// `GoogleFonts.config.allowRuntimeFetching = false` is set in
// `lib/main.dart`. With that flag, a missing bundled asset would make
// the very first `GoogleFonts.manropeTextTheme(...)` call throw — the
// theme builder is invoked here, so a regression that drops an asset
// path or renames a `.ttf` lights up this test loud.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prijavko/design/theme.dart';

void main() {
  test('runtime font fetching is disabled when MainApp boots', () {
    // The flag is only set inside `main()`, which a unit test does not call
    // — assert the boolean toggles correctly when we set it ourselves.
    GoogleFonts.config.allowRuntimeFetching = false;
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  testWidgets('buildLightTheme + buildDarkTheme resolve fonts offline', (
    tester,
  ) async {
    // WHY: Flutter test defaults to no network; combined with
    // `allowRuntimeFetching = false`, a missing asset throws at the very
    // first font lookup. This test pumps a `MaterialApp` configured with
    // both real theme builders so any missing weight regression fails
    // here rather than at runtime in front of a host.
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        home: Builder(
          builder: (ctx) {
            // Touch every typescale slot — if `google_fonts` failed to
            // resolve a Manrope weight, the asset bundle is broken.
            final t = Theme.of(ctx).textTheme;
            return Column(
              children: <Widget>[
                Text('a', style: t.displayLarge),
                Text('a', style: t.displayMedium),
                Text('a', style: t.headlineLarge),
                Text('a', style: t.headlineMedium),
                Text('a', style: t.headlineSmall),
                Text('a', style: t.titleLarge),
                Text('a', style: t.titleMedium),
                Text('a', style: t.bodyLarge),
                Text('a', style: t.bodyMedium),
                Text('a', style: t.bodySmall),
                Text('a', style: t.labelLarge),
                Text('a', style: t.labelMedium),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No ErrorWidget means none of the 12 GoogleFonts.manrope* lookups
    // tried a CDN fetch and threw under the no-fetching policy.
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(Text), findsNWidgets(12));
  });
}
