import 'package:flutter_test/flutter_test.dart';

import 'package:prijavko/app.dart';

void main() {
  testWidgets('renders placeholder shell with localized title (hr default)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PrijavkoApp());
    // Brand name; Croatian and English ARBs use the same product name.
    expect(find.text('Prijavko'), findsNWidgets(2));
  });
}
