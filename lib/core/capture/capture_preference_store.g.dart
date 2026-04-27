// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_preference_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(capturePreferenceStore)
const capturePreferenceStoreProvider = CapturePreferenceStoreProvider._();

final class CapturePreferenceStoreProvider
    extends
        $FunctionalProvider<
          CapturePreferenceStore,
          CapturePreferenceStore,
          CapturePreferenceStore
        >
    with $Provider<CapturePreferenceStore> {
  const CapturePreferenceStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'capturePreferenceStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$capturePreferenceStoreHash();

  @$internal
  @override
  $ProviderElement<CapturePreferenceStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CapturePreferenceStore create(Ref ref) {
    return capturePreferenceStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CapturePreferenceStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CapturePreferenceStore>(value),
    );
  }
}

String _$capturePreferenceStoreHash() =>
    r'77666de79c0884bfc2b738368aa4853552d980f3';
