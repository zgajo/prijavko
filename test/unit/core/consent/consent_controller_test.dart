// guards AC5.1, AC5.2
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';

import '../../../fakes/fake_consent_service.dart';

void main() {
  group('ConsentController', () {
    ProviderContainer makeContainer(FakeConsentService fakeService) {
      return ProviderContainer(
        overrides: [consentServiceProvider.overrideWithValue(fakeService)],
      );
    }

    test('initial state is ConsentLoading', () {
      final container = makeContainer(
        FakeConsentService(scriptedState: const ConsentLoading()),
      );
      addTearDown(container.dispose);

      expect(container.read(consentControllerProvider), isA<ConsentLoading>());
    });

    test('state becomes ConsentObtained after gather() resolves', () async {
      const scripted = ConsentObtained(requestNonPersonalizedAdsOnly: false);
      final container = makeContainer(
        FakeConsentService(scriptedState: scripted),
      );
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.notifier).gather();

      expect(container.read(consentControllerProvider), scripted);
    });

    test('state becomes ConsentNotRequired after gather() resolves', () async {
      final container = makeContainer(
        FakeConsentService(scriptedState: const ConsentNotRequired()),
      );
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.notifier).gather();

      expect(
        container.read(consentControllerProvider),
        isA<ConsentNotRequired>(),
      );
    });

    test(
      'state becomes ConsentFailed(network) after gather() resolves',
      () async {
        const scripted = ConsentFailed(ConsentFailureReason.network);
        final container = makeContainer(
          FakeConsentService(scriptedState: scripted),
        );
        addTearDown(container.dispose);

        await container.read(consentControllerProvider.notifier).gather();

        final result = container.read(consentControllerProvider);
        expect(result, isA<ConsentFailed>());
        expect((result as ConsentFailed).reason, ConsentFailureReason.network);
      },
    );
  });
}
