// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(securityService)
const securityServiceProvider = SecurityServiceProvider._();

final class SecurityServiceProvider
    extends
        $FunctionalProvider<SecurityService, SecurityService, SecurityService>
    with $Provider<SecurityService> {
  const SecurityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'securityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$securityServiceHash();

  @$internal
  @override
  $ProviderElement<SecurityService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecurityService create(Ref ref) {
    return securityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecurityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecurityService>(value),
    );
  }
}

String _$securityServiceHash() => r'44fb3274808c2b02f904ba174d0cc6d21cf2da6b';

@ProviderFor(cookieJarDirectory)
const cookieJarDirectoryProvider = CookieJarDirectoryProvider._();

final class CookieJarDirectoryProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const CookieJarDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookieJarDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookieJarDirectoryHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return cookieJarDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$cookieJarDirectoryHash() =>
    r'5577e939c2c7c17767b4204ef13436d85d0f6967';

@ProviderFor(cookieJar)
const cookieJarProvider = CookieJarProvider._();

final class CookieJarProvider
    extends $FunctionalProvider<CookieJar, CookieJar, CookieJar>
    with $Provider<CookieJar> {
  const CookieJarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookieJarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookieJarHash();

  @$internal
  @override
  $ProviderElement<CookieJar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CookieJar create(Ref ref) {
    return cookieJar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookieJar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookieJar>(value),
    );
  }
}

String _$cookieJarHash() => r'8d5de651715ab6663d537dbfd886568b82b9805b';

@ProviderFor(dio)
const dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  const DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'535ba834d9cbe56a894b46c52f78e05d034444a3';
