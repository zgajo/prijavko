import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/env/evisitor_env.dart';

// AC8.2 — the env getter must default to `prod` when no --dart-define is
// passed and must resolve `test` and `fake` correctly when overridden via
// the dart-define harness (CI uses this to drive integration_fake.yml and
// testapi_canary.yml deterministically).
//
// Dart defines cannot be set at runtime inside the test process, so the
// two override cases are verified by pushing the raw string through the
// same resolver path the top-level getter uses (see `envFromDefine`).
void main() {
  group('EvisitorEnv', () {
    test('defaults to prod when no EVISITOR_ENV dart-define is passed', () {
      // No dart-define is set when running `flutter test` without
      // --dart-define, so the ambient getter must report prod.
      expect(evisitorEnv, EvisitorEnv.prod);
    });

    test('resolves EVISITOR_ENV=test to EvisitorEnv.test', () {
      expect(envFromDefine('test'), EvisitorEnv.test);
    });

    test('resolves EVISITOR_ENV=fake to EvisitorEnv.fake', () {
      expect(envFromDefine('fake'), EvisitorEnv.fake);
    });

    test('resolves EVISITOR_ENV=prod to EvisitorEnv.prod', () {
      expect(envFromDefine('prod'), EvisitorEnv.prod);
    });

    test('throws ArgumentError for unknown values', () {
      expect(() => envFromDefine('staging'), throwsArgumentError);
    });
  });
}
