import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/app/router.dart';
import 'package:prijavko/core/bootstrap/boot_gate.dart';
import 'package:prijavko/core/bootstrap/boot_loading_scaffold.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap_provider.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/features/settings/credential_store.dart';

import '../../../fakes/fake_consent_service.dart';
import '../../../fakes/fake_credential_store.dart';
import '../../../fakes/fake_security_service.dart';

// Builds a minimal app with go_router + BootGate wired in builder + shared
// overrides. Mirrors the app.dart structure: builder wraps child with BootGate.
//
// WHY routerProvider override: BootGate calls ref.read(routerProvider) to
// navigate. In tests, routerProvider must return the same GoRouter instance
// that MaterialApp.router uses — otherwise goNamed() navigates an orphaned
// router that doesn't update the widget tree.
Widget _makeBootApp({
  required SessionBootstrap boot,
  bool delayed = false,
}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'welcome',
        // i18n-ignore: test stub
        builder: (_, __) => const Scaffold(body: Text('WelcomeScreen')),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        // i18n-ignore: test stub
        builder: (_, __) => const Scaffold(body: Text('HomeScreen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      securityServiceProvider.overrideWithValue(FakeSecurityService()),
      cookieJarDirectoryProvider.overrideWithValue('/tmp/boot_gate_test'),
      consentServiceProvider.overrideWithValue(
        FakeConsentService(scriptedState: const ConsentNotRequired()),
      ),
      credentialStoreProvider.overrideWithValue(FakeCredentialStore()),
      cookieJarProvider.overrideWithValue(CookieJar()),
      // Override routerProvider so BootGate's ref.read(routerProvider) returns
      // the same instance used by MaterialApp.router.
      routerProvider.overrideWithValue(router),
      if (!delayed)
        sessionBootstrapProvider.overrideWith((_) async => boot)
      else
        // Delayed override — stays Loading for one pump then resolves.
        sessionBootstrapProvider.overrideWith(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => boot),
        ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      // Mirror app.dart: BootGate wraps the router child so it gates routing.
      builder: (context, child) =>
          BootGate(child: child ?? const SizedBox.shrink()),
    ),
  );
}

void main() {
  group('BootGate widget', () {
    testWidgets('BootFreshFirstRun — no navigation; WelcomeScreen visible',
        (tester) async {
      await tester.pumpWidget(
        _makeBootApp(boot: const BootFreshFirstRun()),
      );
      await tester.pumpAndSettle();

      expect(find.text('WelcomeScreen'), findsOneWidget);
      expect(find.text('HomeScreen'), findsNothing);
    });

    testWidgets('BootSessionLive — navigates to home; HomeScreen visible',
        (tester) async {
      await tester.pumpWidget(
        _makeBootApp(boot: const BootSessionLive()),
      );
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
      expect(find.text('WelcomeScreen'), findsNothing);
    });

    testWidgets(
        'BootCookiesMissing — navigates to home (Epic 2 CredentialBanner recovers)',
        (tester) async {
      await tester.pumpWidget(
        _makeBootApp(boot: const BootCookiesMissing()),
      );
      await tester.pumpAndSettle();

      // AC5.3: cookies-missing maps to home, not back to login.
      expect(find.text('HomeScreen'), findsOneWidget);
      expect(find.text('WelcomeScreen'), findsNothing);
    });

    testWidgets(
        'BootCredentialsMissing — no navigation; no crash; stays on WelcomeScreen',
        (tester) async {
      // TODO(story-2.8): When Story 2.8 lands, this branches to
      // credentials-missing-recovery screen instead. For now: debugPrint +
      // no goNamed (v1.0 unreachable until Story 3.1 makes profiles writable).
      await tester.pumpWidget(
        _makeBootApp(boot: const BootCredentialsMissing()),
      );
      await tester.pumpAndSettle();

      // Must NOT crash — the TODO placeholder must not throw.
      expect(tester.takeException(), isNull);
      expect(find.text('WelcomeScreen'), findsOneWidget);
    });

    testWidgets('loading state shows BootLoadingScaffold', (tester) async {
      await tester.pumpWidget(
        _makeBootApp(boot: const BootFreshFirstRun(), delayed: true),
      );
      // Initial pump — provider is still loading (Future.delayed pending).
      await tester.pump();

      expect(find.byType(BootLoadingScaffold), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the pending 100ms timer so the test completes cleanly.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    });

    testWidgets('no double-navigation on rebuild', (tester) async {
      // Pump twice; goNamed must be called exactly once (not twice).
      // Verified indirectly: HomeScreen appears exactly once with no errors.
      await tester.pumpWidget(
        _makeBootApp(boot: const BootSessionLive()),
      );
      await tester.pump();
      await tester.pump(); // second pump — simulate rebuild
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
