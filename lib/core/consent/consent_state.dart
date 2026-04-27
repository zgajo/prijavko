// WHY: UMP's native ConsentStatus enum has 4 values (unknown, required,
// notRequired, obtained). We collapse `unknown` and the in-flight RPC into a
// single ConsentLoading because the UI never needs to distinguish them.
// ConsentObtained carries requestNonPersonalizedAdsOnly derived from
// ConsentInformation.canRequestAds() — AdBanner (Story 10.1) reads only
// this state, never the SDK directly.
sealed class ConsentState {
  const ConsentState();
}

final class ConsentLoading extends ConsentState {
  const ConsentLoading();
}

final class ConsentObtained extends ConsentState {
  const ConsentObtained({required this.requestNonPersonalizedAdsOnly});

  final bool requestNonPersonalizedAdsOnly;
}

final class ConsentNotRequired extends ConsentState {
  const ConsentNotRequired();
}

final class ConsentFailed extends ConsentState {
  const ConsentFailed(this.reason);

  final ConsentFailureReason reason;
}

// WHY: Failure must be a Poka-yoke barrier — without consent the app proceeds,
// but ConsentFailed.network triggers a retry on next app launch (UMP caches
// consent state on success). The SDK's raw int errorCode is intentionally NOT
// exposed; downstream code pattern-matches on this enum.
//
// Mapping from UMP Android SDK errorCode integers (google_mobile_ads 8.x):
//   network       — errorCode 1 (INTERNET_ERROR)
//   internalError — errorCode 0 (INTERNAL_ERROR), 2 (INVALID_OPERATION),
//                   3 (VERSION_UPDATE_REQUIRED), 5 (TIME_OUT),
//                   6 (MESSAGE_ALREADY_PRESENTED)
//   invalidPublisherHash — errorCode 7 (APP_NOT_CONFIGURED)
//
// Note: google_mobile_ads 8.x removed the FormErrorCode enum from 5.x; errorCode
// is now a plain int. The mapping above replaces the AC4.6 FormErrorCode mapping.
enum ConsentFailureReason {
  /// Network failure — UMP RPC could not reach Google servers.
  network,

  /// Internal SDK or plugin error — invalid operation, timeout, etc.
  internalError,

  /// Publisher/app configuration error — incorrect or missing AdMob App ID.
  invalidPublisherHash,
}
