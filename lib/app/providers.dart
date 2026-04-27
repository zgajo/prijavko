import 'dart:io' show HttpClient, X509Certificate;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:prijavko/core/env/evisitor_env.dart';
import 'package:prijavko/core/security/cert_pins.dart';
import 'package:prijavko/core/security/encrypted_storage.dart';
import 'package:prijavko/core/security/security_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// Single source of truth for the eVisitor base URL across dioProvider and the
// bootstrap cookie check. A duplicate string would silently desync on a
// testApi → prod cutover.
String evisitorBaseUrl() => switch (evisitorEnv) {
  // WHY: baseUrl trailing slash — eVisitor's Rhetos API requires it.
  // Omitting it causes 301 redirects that dio may follow incorrectly.
  EvisitorEnv.prod => 'https://www.evisitor.hr/eVisitorRhetos_API/',
  EvisitorEnv.test => 'https://www.evisitor.hr/testApi/',
  EvisitorEnv.fake => 'http://localhost/',
};

// WHY: keepAlive — lifetime matches the app process; disposing would force
// TLS + Keystore re-init on every navigation.
@Riverpod(keepAlive: true)
SecurityService securityService(Ref ref) {
  // Deliberate Poka-yoke: forgetting the ProviderScope override crashes loudly
  // at startup rather than silently returning an uninitialized service.
  throw UnimplementedError(
    'securityServiceProvider must be overridden with an initialized '
    'SecurityService before ProviderScope is created. '
    'Call SecurityService().init() in main().',
  );
}

// WHY: keepAlive — same rationale as securityServiceProvider.
@Riverpod(keepAlive: true)
String cookieJarDirectory(Ref ref) {
  throw UnimplementedError(
    'cookieJarDirectoryProvider must be overridden with the resolved app '
    'documents path. Call path_provider.getApplicationDocumentsDirectory() '
    'in main().',
  );
}

// WHY keepAlive: same lifetime as dioProvider — the jar holds open file
// handles via EncryptedStorage. Disposing would close them mid-request.
// WHY CookieJar (interface) return type, not PersistCookieJar: fake env
// returns the in-memory base class. Consumers (CookieManager, bootstrap
// query) only need the interface.
@Riverpod(keepAlive: true)
CookieJar cookieJar(Ref ref) {
  if (evisitorEnv == EvisitorEnv.fake) {
    // CookieJar (in-memory) is sufficient for fake env — no persistence needed.
    return CookieJar();
  }

  final security = ref.watch(securityServiceProvider);
  final cookieDir = ref.watch(cookieJarDirectoryProvider);
  final storage = EncryptedStorage(cookieDir, security.encryptionHelper);
  // WHY: persistSession=true is required by the eVisitor auth contract —
  // the `authentication` cookie may be issued without `max-age` (session
  // cookie) and must survive process death so the host doesn't get
  // re-prompted on every cold start. ignoreExpires=false respects the
  // server's expiration so stale cookies don't paper over a real re-auth.
  return PersistCookieJar(
    storage: storage,
    persistSession: true,
    ignoreExpires: false,
  );
}

// WHY: keepAlive — single Dio instance is the sole audit point for cert
// pinning, cookie management, and future auth interceptor wiring.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: evisitorBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      // WHY: ImportTourists batches can be slow — a 60s extended receive path
      // is reserved for that call (Story 6.3) which will override the
      // per-request timeout on that specific Dio request via
      // Options(receiveTimeout: ...). The provider sets the default; the call
      // site overrides.
    ),
  );

  if (evisitorEnv != EvisitorEnv.fake) {
    final jar = ref.watch(cookieJarProvider);
    dio.interceptors.add(CookieManager(jar));

    // TODO(story-2.3): AuthInterceptor wires here.

    // Verify exact Dio 5.x API at install time — IOHttpClientAdapter is the
    // 5.x name (was DefaultHttpClientAdapter in 4.x).
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                CertPins.isTrustedCertificate(cert.der, host),
    );
  }
  // When evisitorEnv == EvisitorEnv.fake: no cookie jar, no cert pinning.
  // Tests override dioProvider with a Dio using EvisitorFakeAdapter.
  // baseUrl = 'http://localhost/' is unreachable; fake adapter intercepts first.

  return dio;
}
