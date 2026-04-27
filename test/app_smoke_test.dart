// Story 1.2 AC4 — smoke test that MainApp pumps the design-system
// preview without throwing. Replaces the Story 1.1 `Hello World!`
// fixture now that the real MaterialApp shape (light/dark themes,
// SemanticColors extension, Material Symbols rounded) is wired in.
// Re-targets when WelcomeScreen lands in Story 1.5.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/main.dart';

void main() {
  testWidgets('MainApp pumps without errors and renders the preview', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    // No ErrorWidget in the tree — tree build didn't throw.
    expect(find.byType(ErrorWidget), findsNothing);
    // The preview surface lands a FilledButton, an OutlinedButton, and
    // an Icon. If any token wiring or font asset were broken, the build
    // would either throw or render Tofu and the test would fail loud.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });
}
