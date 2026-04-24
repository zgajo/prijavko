// Environment switch for which eVisitor backend the build targets (AC8).
//
// Why a pure resolver alongside the eager top-level constant:
//   `String.fromEnvironment` is a compile-time constant, so within a single
//   test process the ambient value can only observe whichever value the
//   harness compiled in. To keep AC8.2 (default + two --dart-define cases)
//   covered by a single `flutter test` invocation — instead of three
//   separate CI jobs — the parsing step is exposed as a pure function and
//   the ambient value delegates to it. The parser is also a Poka-yoke:
//   an unknown raw value (typo like `stagging`) throws at the boundary
//   rather than silently collapsing to `prod` and shipping the wrong
//   backend.
//
// Why resolve eagerly at top level (not lazily per getter call):
//   if the resolver throws on a malformed `--dart-define`, we want the
//   crash at program startup — a real Jidoka line-stop — not a lazy time
//   bomb that fires at the first getter read (which may be inside a
//   `catch` block, producing cascading `ArgumentError while handling
//   ArgumentError` failures).
//
// Why no flavors: architecture §2 locks environment switching to
// `--dart-define=EVISITOR_ENV=<prod|test|fake>`. Adding Gradle buildTypes
// beyond `debug` / `release` is an explicit rejection.

enum EvisitorEnv { prod, test, fake }

// Default is `prod` so an unprefixed release build cannot accidentally
// target the fake transport (AC8.1).
const String _rawEnv = String.fromEnvironment(
  'EVISITOR_ENV',
  defaultValue: 'prod',
);

/// Ambient resolved environment — the single source production code reads.
/// Resolved once at app startup; a malformed define crashes the program
/// at load time rather than at first read.
final EvisitorEnv evisitorEnv = envFromDefine(_rawEnv);

/// Pure resolver for a raw `EVISITOR_ENV` string.
///
/// Normalises whitespace and case before matching so CI typos like
/// `PROD`, `Test`, or a stray trailing space do not hard-crash a running
/// build. Empty string is treated as "no override supplied" and resolves
/// to [EvisitorEnv.prod] — mirrors the `String.fromEnvironment`
/// `defaultValue: 'prod'` contract for the ambient case where the CI
/// script passes `--dart-define=EVISITOR_ENV=` with an empty value.
///
/// Throws [ArgumentError] on an unknown non-empty value (delegated from
/// [Enum.values.byName]) — this is the Poka-yoke line-stop for CI typos
/// such as `stagging` or `fakee`.
EvisitorEnv envFromDefine(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) {
    return EvisitorEnv.prod;
  }
  return EvisitorEnv.values.byName(normalized);
}
