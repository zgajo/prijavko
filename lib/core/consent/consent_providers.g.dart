// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(consentService)
const consentServiceProvider = ConsentServiceProvider._();

final class ConsentServiceProvider
    extends $FunctionalProvider<ConsentService, ConsentService, ConsentService>
    with $Provider<ConsentService> {
  const ConsentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentServiceHash();

  @$internal
  @override
  $ProviderElement<ConsentService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConsentService create(Ref ref) {
    return consentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsentService>(value),
    );
  }
}

String _$consentServiceHash() => r'f3655c28e77a6f9094cb3704585da815081b08f3';

@ProviderFor(ConsentController)
const consentControllerProvider = ConsentControllerProvider._();

final class ConsentControllerProvider
    extends $NotifierProvider<ConsentController, ConsentState> {
  const ConsentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentControllerHash();

  @$internal
  @override
  ConsentController create() => ConsentController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsentState>(value),
    );
  }
}

String _$consentControllerHash() => r'a0b607d86f2b59af813b031c06ea6b3397c6c794';

abstract class _$ConsentController extends $Notifier<ConsentState> {
  ConsentState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ConsentState, ConsentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConsentState, ConsentState>,
              ConsentState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(requestNonPersonalizedAds)
const requestNonPersonalizedAdsProvider = RequestNonPersonalizedAdsProvider._();

final class RequestNonPersonalizedAdsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  const RequestNonPersonalizedAdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestNonPersonalizedAdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestNonPersonalizedAdsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return requestNonPersonalizedAds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$requestNonPersonalizedAdsHash() =>
    r'9a3acc3a689d55067e8d65fa819f41e92a1d38f8';
