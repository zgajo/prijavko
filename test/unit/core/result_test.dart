// guards AC5.1 — sealed exhaustiveness
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/result/result.dart';

void main() {
  group('Result', () {
    test('Ok carries its value', () {
      const result = Ok<int, String>(42);
      expect(result.value, 42);
    });

    test('Err carries its error', () {
      const result = Err<int, String>('boom');
      expect(result.error, 'boom');
    });

    test('Ok and Err are const-constructible', () {
      const ok = Ok<int, String>(1);
      const err = Err<int, String>('e');
      expect(ok, isA<Ok<int, String>>());
      expect(err, isA<Err<int, String>>());
    });

    test('Dart 3 exhaustive switch compiles without default case', () {
      // This test proves at compile time that the switch is exhaustive.
      // If Result gains a third variant, this will fail to compile — Poka-yoke.
      Result<int, String> result = const Ok(7);
      final label = switch (result) {
        Ok(:final value) => 'ok:$value',
        Err(:final error) => 'err:$error',
      };
      expect(label, 'ok:7');

      // Use a fresh binding so the analyzer cannot narrow the static type.
      final Result<int, String> result2 = const Err('oops');
      final label2 = switch (result2) {
        Ok(:final value) => 'ok:$value',
        Err(:final error) => 'err:$error',
      };
      expect(label2, 'err:oops');
    });
  });
}
