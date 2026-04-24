// Environment switch for which eVisitor backend the build targets (AC8).
//
// Why a pure resolver alongside the ambient getter:
//   `String.fromEnvironment` is a compile-time constant, so within a single
//   test process the ambient getter can only observe whichever value the
//   harness compiled in. To keep AC8.2 (default + two --dart-define cases)
//   covered by a single `flutter test` invocation — instead of three
//   separate CI jobs — the parsing step is exposed as a pure function and
//   the ambient getter delegates to it. This also makes the parser a
//   Poka-yoke: an unknown raw value (typo like `stagging`) throws at the
//   boundary rather than silently collapsing to `prod` and shipping the
//   wrong backend.
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
EvisitorEnv get evisitorEnv => envFromDefine(_rawEnv);

/// Pure resolver for a raw `EVISITOR_ENV` string. Throws [ArgumentError]
/// on unknown values (delegated from [Enum.values.byName]) — this is the
/// Poka-yoke line-stop for CI typos.
EvisitorEnv envFromDefine(String raw) => EvisitorEnv.values.byName(raw);
