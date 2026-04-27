// guards AC5.4
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';

import '../../../fakes/fake_consent_service.dart';

void main() {
  group('requestNonPersonalizedAdsProvider', () {
    // Drives gather() on the controller and reads the derived bool provider.
    // WHY: Can't set Notifier.state externally — it's write-protected. We instead
    // inject a FakeConsentService and call gather() to settle the controller state.
    Future<bool> readProvider(
      WidgetTester tester,
      ConsentState scriptedState,
    ) async {
      final container = ProviderContainer(
        overrides: [
          consentServiceProvider.overrideWithValue(
            FakeConsentService(scriptedState: scriptedState),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.notifier).gather();
      return container.read(requestNonPersonalizedAdsProvider);
    }

    testWidgets('ConsentObtained(requestNonPersonalizedAdsOnly: true) → true', (
      tester,
    ) async {
      expect(
        await readProvider(
          tester,
          const ConsentObtained(requestNonPersonalizedAdsOnly: true),
        ),
        isTrue,
      );
    });

    testWidgets(
      'ConsentObtained(requestNonPersonalizedAdsOnly: false) → false',
      (tester) async {
        expect(
          await readProvider(
            tester,
            const ConsentObtained(requestNonPersonalizedAdsOnly: false),
          ),
          isFalse,
        );
      },
    );

    testWidgets('ConsentNotRequired → false (outside EEA = personalized OK)', (
      tester,
    ) async {
      expect(await readProvider(tester, const ConsentNotRequired()), isFalse);
    });

    testWidgets('ConsentLoading → true (safe default while uncertain)', (
      tester,
    ) async {
      // FakeConsentService returning ConsentLoading keeps the controller in
      // ConsentLoading after gather() resolves (since gather() returns that state).
      final container = ProviderContainer(
        overrides: [
          consentServiceProvider.overrideWithValue(
            FakeConsentService(scriptedState: const ConsentLoading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.notifier).gather();

      // Controller is ConsentLoading → derived provider must return true.
      expect(container.read(requestNonPersonalizedAdsProvider), isTrue);
    });

    testWidgets('ConsentFailed(any) → true (safe default on failure)', (
      tester,
    ) async {
      for (final reason in ConsentFailureReason.values) {
        expect(
          await readProvider(tester, ConsentFailed(reason)),
          isTrue,
          reason: 'Expected true for ConsentFailed($reason)',
        );
      }
    });
  });
}
