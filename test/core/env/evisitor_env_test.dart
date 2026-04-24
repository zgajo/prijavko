import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/env/evisitor_env.dart';

// AC8.2 — the env getter must default to `prod` when no --dart-define is
// passed, and the parsing layer must resolve `test` / `fake` correctly when
// the build is invoked with `--dart-define=EVISITOR_ENV=…`. Dart defines are
// compile-time constants, so within a single test process only one ambient
// value can be observed; the two override cases are therefore driven through
// the pure resolver (`envFromDefine`) that the ambient getter delegates to.
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

    test('throws ArgumentError on an unknown raw value (Poka-yoke)', () {
      // A typo in CI (`stagging`, `fakee`) must stop the line rather than
      // silently collapsing to prod and shipping the wrong backend.
      expect(() => envFromDefine('staging'), throwsArgumentError);
    });
  });
}
