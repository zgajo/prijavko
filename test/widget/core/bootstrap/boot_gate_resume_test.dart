// WHY this test exists: a future agent might "fix" the resume case by
// invalidating sessionBootstrapProvider on AppLifecycleState.resumed — silently
// breaking the AC6 invariant (Story 1.8). This test is the Poka-yoke that
// catches that regression before it ships.
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/app/router.dart';
import 'package:prijavko/core/bootstrap/boot_gate.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap_provider.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/features/settings/credential_store.dart';

import '../../../fakes/fake_consent_service.dart';
import '../../../fakes/fake_credential_store.dart';
import '../../../fakes/fake_security_service.dart';

void main() {
  testWidgets(
    'sessionBootstrapProvider resolves exactly once across pause/resume lifecycle',
    (tester) async {
      var resolveCount = 0;

      final testRouter = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            name: 'welcome',
            // i18n-ignore: test stub
            builder: (_, _) => const Scaffold(body: Text('WelcomeScreen')),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            // i18n-ignore: test stub
            builder: (_, _) => const Scaffold(body: Text('HomeScreen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityServiceProvider.overrideWithValue(FakeSecurityService()),
            cookieJarDirectoryProvider.overrideWithValue('/tmp/resume_test'),
            consentServiceProvider.overrideWithValue(
              FakeConsentService(scriptedState: const ConsentNotRequired()),
            ),
            credentialStoreProvider.overrideWithValue(FakeCredentialStore()),
            cookieJarProvider.overrideWithValue(CookieJar()),
            routerProvider.overrideWithValue(testRouter),
            sessionBootstrapProvider.overrideWith((_) async {
              resolveCount++;
              return const BootSessionLive();
            }),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
            builder: (context, child) =>
                BootGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Provider resolved once — home is visible.
      expect(resolveCount, equals(1));
      expect(find.text('HomeScreen'), findsOneWidget);

      // Simulate pause → resume lifecycle events.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // keepAlive + no WidgetsBindingObserver invalidation → provider resolves
      // exactly once total. A regression (provider invalidated on resume) would
      // increment resolveCount to 2.
      expect(resolveCount, equals(1));
    },
  );
}
