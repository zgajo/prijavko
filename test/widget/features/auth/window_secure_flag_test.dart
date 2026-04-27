import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/security/window_secure_flag.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('WindowSecureFlag', () {
    final log = <String>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('hr.prijavko.window_secure'),
            (call) async {
              log.add(call.method);
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('hr.prijavko.window_secure'),
            null,
          );
    });

    test('enable invokes "enable" on channel', () async {
      await WindowSecureFlag.enable();
      expect(log, ['enable']);
    });

    test('disable invokes "disable" on channel', () async {
      await WindowSecureFlag.disable();
      expect(log, ['disable']);
    });

    test('enable then disable invokes both in order', () async {
      await WindowSecureFlag.enable();
      await WindowSecureFlag.disable();
      expect(log, ['enable', 'disable']);
    });
  });
}
