// WHY: All four consent providers live here rather than in lib/app/providers.dart
// because core/consent/ is feature-adjacent infrastructure. Keeping it
// self-contained mirrors core/security/ and improves testability — tests
// override consentServiceProvider without touching the app-level provider file.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prijavko/core/consent/consent_error.dart';
import 'package:prijavko/core/consent/consent_service.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_providers.g.dart';

// WHY: keepAlive — lifetime matches the app process; disposing would force a
// re-RPC to Google's UMP server and potentially re-present the consent form
// on every navigation. Consent state is process-lifetime infrastructure.
@Riverpod(keepAlive: true)
ConsentService consentService(Ref ref) => ConsentService();

// WHY: keepAlive — same rationale as consentServiceProvider. The controller
// holds the authoritative ConsentState for the entire process lifetime.
@Riverpod(keepAlive: true)
class ConsentController extends _$ConsentController {
  @override
  ConsentState build() => const ConsentLoading();

  Future<void> gather() async {
    state = const ConsentLoading();
    state = await ref.read(consentServiceProvider).gatherConsent();
  }

  Future<Result<void, ConsentError>> reopenPrivacyOptions() {
    return ref.read(consentServiceProvider).showPrivacyOptionsForm();
  }
}

// WHY: keepAlive — AdBanner (Story 10.1) reads this on every ad request.
// Disposing and recomputing would require re-watching ConsentController,
// which is already keepAlive — but a derived provider that disposes loses
// the cached bool, forcing an unnecessary extra computation pass.
//
// Safe default: true (non-personalized) when consent state is uncertain —
// better to show a non-personalized ad than to skip consent validation.
@Riverpod(keepAlive: true)
bool requestNonPersonalizedAds(Ref ref) {
  final consentState = ref.watch(consentControllerProvider);
  return switch (consentState) {
    ConsentObtained(:final requestNonPersonalizedAdsOnly) =>
      requestNonPersonalizedAdsOnly,
    ConsentNotRequired() => false,
    // Safe defaults: non-personalized when loading or failed.
    ConsentLoading() || ConsentFailed() => true,
  };
}
