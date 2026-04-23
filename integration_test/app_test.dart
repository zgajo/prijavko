// Story 1.1 AC3.4 — boot probe for integration_fake.yml.
//
// Why this does NOT import `package:integration_test`: the
// integration_test binding expects a live device / emulator. On ubuntu
// CI without an Android emulator, `flutter test integration_test/` then
// fails with "no supported device". Running as a plain widget test in
// the `integration_test/` directory keeps the workflow command
// (`flutter test integration_test/ --dart-define=EVISITOR_ENV=fake`)
// unchanged while still exercising the full MaterialApp pumpWidget path
// headlessly.
//
// AC10 (cold-start p95 ≤ 2.5s measurement) is Task 9's job — this file
// exists from Task 3 as the minimum that makes the workflow green, and
// Task 9 will extend it with frame-timing instrumentation.

import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/main.dart';

void main() {
  testWidgets('app boots and paints its first frame', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.text('Hello World!'), findsOneWidget);
  });
}
