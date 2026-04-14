/// Sanitizes dynamic strings before logs / non-PII telemetry (NFR18 prep).
///
/// Covers structured patterns (MRZ-like lines, long digit runs, UUIDs). Human names,
/// short document numbers, and other context-specific strings are not inferred—pass
/// them via [extraSecrets] at the call site until a dedicated follow-up adds richer rules.
abstract final class PiiScrubber {
  static final RegExp _mrzLike = RegExp(r'[A-Z0-9<]{20,}');
  static final RegExp _longDigitRuns = RegExp(r'\d{6,}');
  static final RegExp _uuidLike = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  /// Removes MRZ-like runs, long digit sequences, UUIDs, and optional [extraSecrets].
  static String scrub(
    String input, {
    Iterable<String> extraSecrets = const [],
  }) {
    String o = input;
    o = o.replaceAll(_mrzLike, '<MRZ>');
    o = o.replaceAll(_longDigitRuns, '<DIGITS>');
    o = o.replaceAll(_uuidLike, '<UUID>');
    for (final String s in extraSecrets) {
      if (s.isEmpty) {
        continue;
      }
      o = o.replaceAll(s, '<REDACTED>');
    }
    return o;
  }
}
