// WHY: ConsentService is the sole entry point to the UMP SDK. No feature
// outside lib/core/consent/ may import package:google_mobile_ads/... .
// Architectural Boundary parallels SecurityService → flutter_secure_storage
// and ApiClient → Dio.
//
// API note (google_mobile_ads 8.0.0 vs story spec 6.x):
//   - FormErrorCode enum was removed; FormError.errorCode is now int.
//   - ConsentForm.loadAndShowConsentFormIfRequired and showPrivacyOptionsForm
//     are Future<void> functions that invoke their callback before completing,
//     so we can await them and read the error from a captured variable rather
//     than nesting Completers.
//   - ConsentInformation methods (canRequestAds, getConsentStatus, reset,
//     getPrivacyOptionsRequirementStatus) are all Future-returning.
//
// WHY: ConsentInformation exposes IAB TCF strings in raw form — they contain
// device-fingerprinting bits. Never log them. ConsentState is the only object
// that may cross the logging boundary.
import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:meta/meta.dart';
import 'package:prijavko/core/consent/consent_error.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/core/result/result.dart';

// TODO(story-1.9): render "Privola za oglase" ListTile gated on isPrivacyOptionsRequired()
// TODO(story-1.9): add settingsAdConsentTile ARB key to lib/l10n/app_hr.arb and app_en.arb (AC11.4)
abstract interface class ConsentService {
  factory ConsentService() = _DefaultConsentService;

  Future<ConsentState> gatherConsent();

  Future<Result<void, ConsentError>> showPrivacyOptionsForm();

  Future<bool> isPrivacyOptionsRequired();

  @visibleForTesting
  Future<void> reset();
}

final class _DefaultConsentService implements ConsentService {
  @override
  Future<ConsentState> gatherConsent() async {
    final params = ConsentRequestParameters();
    final completer = Completer<ConsentState>();

    // WHY: requestConsentInfoUpdate can throw synchronously if the SDK is in
    // a bad state (e.g. missing Play Services). Without this guard the
    // Completer never completes and the caller hangs forever.
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            FormError? formErr;
            await ConsentForm.loadAndShowConsentFormIfRequired(
              (FormError? error) => formErr = error,
            );

            if (completer.isCompleted) return;

            if (formErr != null) {
              completer.complete(ConsentFailed(_classifyFormError(formErr!)));
              return;
            }

            final canRequest = await ConsentInformation.instance
                .canRequestAds();
            final status = await ConsentInformation.instance.getConsentStatus();

            if (completer.isCompleted) return;

            if (status == ConsentStatus.notRequired) {
              completer.complete(const ConsentNotRequired());
            } else {
              // WHY: the || status == ConsentStatus.required guard is a
              // Poka-yoke — if the SDK returns canRequestAds() == true while
              // status is still 'required' (a plausible edge case after form
              // dismissal without consent), we default to non-personalized.
              completer.complete(
                ConsentObtained(
                  requestNonPersonalizedAdsOnly:
                      !canRequest || status == ConsentStatus.required,
                ),
              );
            }
          } catch (_) {
            if (!completer.isCompleted) {
              completer.complete(
                const ConsentFailed(ConsentFailureReason.internalError),
              );
            }
          }
        },
        (FormError error) {
          if (!completer.isCompleted) {
            completer.complete(ConsentFailed(_classifyFormError(error)));
          }
        },
      );
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(
          const ConsentFailed(ConsentFailureReason.internalError),
        );
      }
    }

    return completer.future;
  }

  // TODO(story-1.9): wire to "Privola za oglase" Settings list tile
  @override
  Future<Result<void, ConsentError>> showPrivacyOptionsForm() async {
    FormError? formErr;
    await ConsentForm.showPrivacyOptionsForm(
      (FormError? error) => formErr = error,
    );
    if (formErr != null) {
      return Err(ConsentFormError(_classifyFormError(formErr!)));
    }
    return const Ok(null);
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  @override
  @visibleForTesting
  Future<void> reset() => ConsentInformation.instance.reset();

  // Maps UMP Android SDK integer error codes to ConsentFailureReason.
  // Error code reference: https://developers.google.com/admob/ump/android/api/
  //   reference/com/google/android/ump/FormError.ErrorCode
  ConsentFailureReason _classifyFormError(FormError error) {
    return switch (error.errorCode) {
      1 => ConsentFailureReason.network, // INTERNET_ERROR
      7 => ConsentFailureReason.invalidPublisherHash, // APP_NOT_CONFIGURED
      _ => ConsentFailureReason.internalError, // 0=INTERNAL, 2=INVALID_OP, etc.
    };
  }
}
