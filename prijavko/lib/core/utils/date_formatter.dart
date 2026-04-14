/// eVisitor wire dates (facility-local semantics) vs audit [DateTime] (UTC in DB).
///
/// API dates are never stored as [DateTime] in SQLite — only YYYYMMDD / hh:mm strings.
abstract final class DateFormatter {
  /// Parses `YYYYMMDD`; returns null if invalid.
  static DateTime? parseYyyyMmDd(String? raw) {
    if (raw == null || raw.length != 8) {
      return null;
    }
    final int? y = int.tryParse(raw.substring(0, 4));
    final int? m = int.tryParse(raw.substring(4, 6));
    final int? d = int.tryParse(raw.substring(6, 8));
    if (y == null || m == null || d == null) {
      return null;
    }
    if (m < 1 || m > 12 || d < 1 || d > 31) {
      return null;
    }
    final DateTime parsed = DateTime.utc(y, m, d);
    if (parsed.year != y || parsed.month != m || parsed.day != d) {
      return null;
    }
    return parsed;
  }

  /// Formats the UTC calendar components of [value] as `YYYYMMDD` (no timezone shift).
  static String formatYyyyMmDdUtc(DateTime value) {
    final DateTime u = value.toUtc();
    final String y = u.year.toString().padLeft(4, '0');
    final String m = u.month.toString().padLeft(2, '0');
    final String d = u.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Croatian display: `dd.MM.yyyy.` (trailing dot per local convention).
  static String formatCroatianDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String dd = local.day.toString().padLeft(2, '0');
    final String mm = local.month.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year}.';
  }

  /// Validates `hh:mm` 24h.
  static bool isValidHhMm(String? raw) {
    if (raw == null || raw.length != 5 || raw[2] != ':') {
      return false;
    }
    final int? h = int.tryParse(raw.substring(0, 2));
    final int? m = int.tryParse(raw.substring(3, 5));
    if (h == null || m == null) {
      return false;
    }
    return h >= 0 && h < 24 && m >= 0 && m < 60;
  }
}
