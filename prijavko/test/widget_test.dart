import 'package:flutter_test/flutter_test.dart';

import 'package:prijavko/app.dart';

void main() {
  testWidgets('renders placeholder shell with title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PrijavkoApp());
    expect(find.text('Prijavko'), findsNWidgets(2));
  });
}
