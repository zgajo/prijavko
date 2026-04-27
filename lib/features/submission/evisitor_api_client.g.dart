// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evisitor_api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(evisitorApiClient)
const evisitorApiClientProvider = EvisitorApiClientProvider._();

final class EvisitorApiClientProvider
    extends
        $FunctionalProvider<
          EvisitorApiClient,
          EvisitorApiClient,
          EvisitorApiClient
        >
    with $Provider<EvisitorApiClient> {
  const EvisitorApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evisitorApiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evisitorApiClientHash();

  @$internal
  @override
  $ProviderElement<EvisitorApiClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EvisitorApiClient create(Ref ref) {
    return evisitorApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvisitorApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvisitorApiClient>(value),
    );
  }
}

String _$evisitorApiClientHash() => r'0e22313d82026cf25e36111a63f4696b6992ba9e';
