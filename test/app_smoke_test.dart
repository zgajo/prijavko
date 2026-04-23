// Story 1.1 AC3.3 — smoke test so test.yml is green from commit #1.
//
// `flutter test` exits non-zero when the `test/` directory has no
// matching files, which would make the `test` workflow red before any
// real unit test exists. This smoke test establishes the minimum
// meaningful check (the root widget pumps without throwing) and earns
// its place until the first feature-level widget test lands.

import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/main.dart';

void main() {
  testWidgets('MainApp pumps without errors', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.byType(MainApp), findsOneWidget);
  });
}
