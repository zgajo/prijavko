// Story 1.1 AC3.3 — smoke test so test.yml is green from commit #1.
//
// `flutter test` exits non-zero when the `test/` directory has no
// matching files, which would make the `test` workflow red before any
// real unit test exists. This smoke test establishes the minimum
// meaningful check (the root widget pumps without an ErrorWidget and
// paints the `--empty` scaffold text) and earns its place until the
// first feature-level widget test lands in Story 1.2+.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/main.dart';

void main() {
  testWidgets('MainApp pumps and paints the scaffold without errors', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    // No ErrorWidget in the tree — tree build didn't throw.
    expect(find.byType(ErrorWidget), findsNothing);
    // `--empty` emits a `Hello World!` Center(Text). This assertion is
    // temporary — it moves to the app shell's landing-screen fixture
    // once Story 1.2 lands real UI.
    expect(find.text('Hello World!'), findsOneWidget);
  });
}
