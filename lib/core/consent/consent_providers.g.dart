// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$consentServiceHash() => r'f3655c28e77a6f9094cb3704585da815081b08f3';

/// See also [consentService].
@ProviderFor(consentService)
final consentServiceProvider = Provider<ConsentService>.internal(
  consentService,
  name: r'consentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$consentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConsentServiceRef = ProviderRef<ConsentService>;
String _$requestNonPersonalizedAdsHash() =>
    r'9a3acc3a689d55067e8d65fa819f41e92a1d38f8';

/// See also [requestNonPersonalizedAds].
@ProviderFor(requestNonPersonalizedAds)
final requestNonPersonalizedAdsProvider = Provider<bool>.internal(
  requestNonPersonalizedAds,
  name: r'requestNonPersonalizedAdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requestNonPersonalizedAdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RequestNonPersonalizedAdsRef = ProviderRef<bool>;
String _$consentControllerHash() => r'a0b607d86f2b59af813b031c06ea6b3397c6c794';

/// See also [ConsentController].
@ProviderFor(ConsentController)
final consentControllerProvider =
    NotifierProvider<ConsentController, ConsentState>.internal(
      ConsentController.new,
      name: r'consentControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$consentControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConsentController = Notifier<ConsentState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
