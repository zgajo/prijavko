import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/utils/uuid_generator.dart';

void main() {
  test('UuidGenerator.nextV4 is lowercase hyphenated v4', () {
    final String u = UuidGenerator.nextV4();
    expect(
      u,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
