// Story 1.2 AC6.4 — guards `lib/design/icons.dart` and the
// `material_symbols_icons` rounded-variant wiring.
//
// If the package's font asset is misconfigured (wrong family, missing
// asset declaration, dependency conflict), the resolved `IconData` would
// either point at the outlined family or fall back to nothing. The test
// asserts the rounded font family explicitly so a regression cannot
// land silently.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/design/icons.dart';

void main() {
  testWidgets(
    'Symbols.check_rounded resolves to MaterialSymbolsRounded font family',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Icon(Symbols.check_rounded))),
      );

      // guards AC5.3 — house style is the rounded variant; the package's
      // suffix-naming convention parks the rounded glyph in the
      // MaterialSymbolsRounded font family.
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Symbols.check_rounded);
      expect(iconWidget.icon!.fontFamily, 'MaterialSymbolsRounded');
      // guards AC5.4 — the icon resolves through the package's font
      // package (so the asset bundle pulls it in at compile time).
      expect(iconWidget.icon!.fontPackage, 'material_symbols_icons');
    },
  );
}
