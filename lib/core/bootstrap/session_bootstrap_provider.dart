import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/facility/has_facility_profile.dart';
import 'package:prijavko/features/settings/credential_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_bootstrap_provider.g.dart';

// TODO(story-2.x): AuthNotifier.login() invalidates this provider on success.
// WHY keepAlive: the boot decision is immutable for the process lifetime.
// Recomputing on every ref.watch (which touches Keystore + filesystem) would
// be Muda. Story 2.x's AuthNotifier.login() will invalidate explicitly on
// successful login.
@Riverpod(keepAlive: true)
Future<SessionBootstrap> sessionBootstrap(Ref ref) async {
  final credentialStore = ref.watch(credentialStoreProvider);
  final jar = ref.watch(cookieJarProvider);

  // WHY `is Ok` without type params: bootstrap only needs to know whether
  // loading succeeded (boolean), not the secret payload. Using the raw `Ok`
  // check keeps this file free of credential-model identifiers (PII discipline
  // — AC10.4).
  final credentialsResult = await credentialStore.loadCredentials();
  final hasCredentials = credentialsResult is Ok;
  final hasFacilityProfile = await ref.watch(hasFacilityProfileProvider.future);

  if (!hasCredentials) {
    return hasFacilityProfile
        ? const BootCredentialsMissing()
        : const BootFreshFirstRun();
  }

  final hasViableCookies = await _hasViableSessionCookies(jar);
  return hasViableCookies
      ? const BootSessionLive()
      : const BootCookiesMissing();
}

Future<bool> _hasViableSessionCookies(CookieJar jar) async {
  // WHY this exact URL: PersistCookieJar's domain matching is keyed on
  // host + path. The eVisitor login endpoint sets cookies with Path=/Resources/
  // — matching anything under that path returns the auth cookies.
  final baseUrl = Uri.parse(evisitorBaseUrl());
  final cookieScopeUrl = baseUrl.replace(path: '/Resources/');
  final cookies = await jar.loadForRequest(cookieScopeUrl);
  // The 'authentication' cookie is the load-bearing one — 'affinity' and
  // 'language' do not carry session identity. If 'authentication' is absent
  // (or expired and pruned by ignoreExpires=false), session is not viable.
  return cookies.any(
    (Cookie c) => c.name == 'authentication' && c.value.trim().isNotEmpty,
  );
}
