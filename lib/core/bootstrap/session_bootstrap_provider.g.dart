// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_bootstrap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionBootstrap)
const sessionBootstrapProvider = SessionBootstrapProvider._();

final class SessionBootstrapProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionBootstrap>,
          SessionBootstrap,
          FutureOr<SessionBootstrap>
        >
    with $FutureModifier<SessionBootstrap>, $FutureProvider<SessionBootstrap> {
  const SessionBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionBootstrapHash();

  @$internal
  @override
  $FutureProviderElement<SessionBootstrap> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionBootstrap> create(Ref ref) {
    return sessionBootstrap(ref);
  }
}

String _$sessionBootstrapHash() => r'2d2f59a97713ad5cbb65a73f37791e3ba2a8dcc8';
