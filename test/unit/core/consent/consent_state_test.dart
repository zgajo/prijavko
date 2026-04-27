// guards AC3.1
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/consent/consent_state.dart';

void main() {
  group('ConsentState variants', () {
    test('ConsentLoading is const-constructible', () {
      const state = ConsentLoading();
      expect(state, isA<ConsentState>());
    });

    test(
      'ConsentObtained is const-constructible with requestNonPersonalizedAdsOnly',
      () {
        const state = ConsentObtained(requestNonPersonalizedAdsOnly: true);
        expect(state, isA<ConsentState>());
        expect(state.requestNonPersonalizedAdsOnly, isTrue);

        const state2 = ConsentObtained(requestNonPersonalizedAdsOnly: false);
        expect(state2.requestNonPersonalizedAdsOnly, isFalse);
      },
    );

    test('ConsentNotRequired is const-constructible', () {
      const state = ConsentNotRequired();
      expect(state, isA<ConsentState>());
    });

    test('ConsentFailed carries ConsentFailureReason', () {
      for (final reason in ConsentFailureReason.values) {
        final state = ConsentFailed(reason);
        expect(state, isA<ConsentState>());
        expect(state.reason, equals(reason));
      }
    });

    test('exhaustive switch over ConsentState compiles without default', () {
      ConsentState state = const ConsentLoading();
      // Dart 3 exhaustive switch — compiler enforces all branches.
      final label = switch (state) {
        ConsentLoading() => 'loading',
        ConsentObtained() => 'obtained',
        ConsentNotRequired() => 'notRequired',
        ConsentFailed() => 'failed',
      };
      expect(label, equals('loading'));
    });

    test(
      'ConsentFailureReason has exactly network, internalError, invalidPublisherHash',
      () {
        expect(
          ConsentFailureReason.values,
          containsAll([
            ConsentFailureReason.network,
            ConsentFailureReason.internalError,
            ConsentFailureReason.invalidPublisherHash,
          ]),
        );
        expect(ConsentFailureReason.values.length, equals(3));
      },
    );
  });
}
