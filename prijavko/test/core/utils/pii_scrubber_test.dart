import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/utils/pii_scrubber.dart';

void main() {
  test('scrub replaces MRZ-like and digit runs', () {
    const s =
        'MRZ P12345678901234567890ABCDEFGH<1234567890123<45 name 123456789012';
    final String o = PiiScrubber.scrub(s);
    expect(o.contains('P123456789'), isFalse);
    expect(o, contains('<MRZ>'));
    expect(o, contains('<DIGITS>'));
  });

  test('scrub replaces extra secrets', () {
    final String o = PiiScrubber.scrub(
      'user:secret123 end',
      extraSecrets: <String>['secret123'],
    );
    expect(o, contains('<REDACTED>'));
    expect(o.contains('secret123'), isFalse);
  });
}
