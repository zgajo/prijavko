import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('parseYyyyMmDd parses valid input', () {
      final DateTime? d = DateFormatter.parseYyyyMmDd('20260414');
      expect(d, DateTime.utc(2026, 4, 14));
    });

    test('parseYyyyMmDd returns null for bad input', () {
      expect(DateFormatter.parseYyyyMmDd(null), isNull);
      expect(DateFormatter.parseYyyyMmDd('20261'), isNull);
      expect(DateFormatter.parseYyyyMmDd('20261301'), isNull);
    });

    test('parseYyyyMmDd returns null for nonexistent calendar dates', () {
      expect(DateFormatter.parseYyyyMmDd('20260230'), isNull);
      expect(DateFormatter.parseYyyyMmDd('20260231'), isNull);
      expect(DateFormatter.parseYyyyMmDd('20260431'), isNull);
      expect(DateFormatter.parseYyyyMmDd('20250229'), isNull);
    });

    test('formatYyyyMmDdUtc uses UTC calendar date', () {
      expect(
        DateFormatter.formatYyyyMmDdUtc(DateTime.utc(2026, 4, 14)),
        '20260414',
      );
    });

    test('formatCroatianDate uses local calendar', () {
      final String s = DateFormatter.formatCroatianDate(
        DateTime.utc(2026, 4, 14),
      );
      expect(s, matches(RegExp(r'^\d{2}\.\d{2}\.2026\.$')));
    });

    test('isValidHhMm', () {
      expect(DateFormatter.isValidHhMm('18:30'), isTrue);
      expect(DateFormatter.isValidHhMm('25:00'), isFalse);
      expect(DateFormatter.isValidHhMm(null), isFalse);
    });
  });
}
