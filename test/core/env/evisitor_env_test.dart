import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/env/evisitor_env.dart';

// AC8.2 — the env must default to `prod` when no --dart-define is passed,
// and the parsing layer must resolve `test` / `fake` correctly when the
// build is invoked with `--dart-define=EVISITOR_ENV=…`. Dart defines are
// compile-time constants, so within a single test process only one ambient
// value can be observed; the two override cases are therefore driven
// through the pure resolver (`envFromDefine`) that the ambient constant
// delegates to at startup.
void main() {
  group('EvisitorEnv', () {
    test('defaults to prod when no EVISITOR_ENV dart-define is passed', () {
      expect(evisitorEnv, EvisitorEnv.prod);
    });

    test('resolves EVISITOR_ENV=test to EvisitorEnv.test', () {
      expect(envFromDefine('test'), EvisitorEnv.test);
    });

    test('resolves EVISITOR_ENV=fake to EvisitorEnv.fake', () {
      expect(envFromDefine('fake'), EvisitorEnv.fake);
    });

    test('resolves an empty value to prod (matches defaultValue contract)', () {
      // A CI script that writes `--dart-define=EVISITOR_ENV=` with an empty
      // RHS must not crash the app; the ambient default is prod.
      expect(envFromDefine(''), EvisitorEnv.prod);
    });

    test('trims whitespace around the raw value', () {
      expect(envFromDefine(' prod '), EvisitorEnv.prod);
      expect(envFromDefine('\tfake\n'), EvisitorEnv.fake);
    });

    test('is case-insensitive — PROD / Test / FAKE all resolve', () {
      // CI typo surface: if a shell scripts the value through `tr` or
      // `awk`, case may drift. byName is case-sensitive, so we normalise.
      expect(envFromDefine('PROD'), EvisitorEnv.prod);
      expect(envFromDefine('Test'), EvisitorEnv.test);
      expect(envFromDefine('FAKE'), EvisitorEnv.fake);
    });

    test('throws ArgumentError on an unknown raw value (Poka-yoke)', () {
      // A typo in CI (`stagging`, `fakee`) must stop the line rather than
      // silently collapsing to prod and shipping the wrong backend.
      expect(() => envFromDefine('staging'), throwsArgumentError);
      expect(() => envFromDefine('fakee'), throwsArgumentError);
    });
  });
}
