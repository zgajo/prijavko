// Story 1.8: added credentialStoreProvider + cookieJarProvider overrides.
// BootGate (new in Story 1.8) watches sessionBootstrapProvider which depends
// on both. Without overrides, credentialStore hits FlutterSecureStorage
// platform channel in the test VM — causing pumpAndSettle to time out.
// FakeCredentialStore (no credentials seeded) → BootFreshFirstRun →
// no navigation → WelcomeScreen stays visible (existing assertion holds).
//
// Story 1.5: updated from MainApp + design-system preview to PrijavkoApp +
// WelcomeScreen. The ConsentGate is now inside app.dart's builder callback
// (MaterialApp.router has no home: param). FakeConsentService(ConsentNotRequired)
// bypasses the real UMP SDK so the gate passes through immediately.
//
// Story 1.4: wrapped in ProviderScope because ConsentGate is a
// ConsumerStatefulWidget. consentServiceProvider is overridden with
// FakeConsentService(ConsentNotRequired) so the gate passes through
// to the child immediately, and no real UMP SDK call is made.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/app/app.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/features/settings/credential_store.dart';

import 'fakes/fake_consent_service.dart';
import 'fakes/fake_credential_store.dart';
import 'fakes/fake_security_service.dart';

void main() {
  testWidgets('PrijavkoApp pumps without errors and renders WelcomeScreen', (
    tester,
  ) async {
    // No credentials seeded → BootFreshFirstRun → no navigation → WelcomeScreen.
    final fakeCredentialStore = FakeCredentialStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Required because securityServiceProvider throws by design when
          // not overridden (Poka-yoke guard in providers.dart).
          securityServiceProvider.overrideWithValue(FakeSecurityService()),
          cookieJarDirectoryProvider.overrideWithValue('/tmp/test_cookies'),
          consentServiceProvider.overrideWithValue(
            FakeConsentService(scriptedState: const ConsentNotRequired()),
          ),
          credentialStoreProvider.overrideWithValue(fakeCredentialStore),
          // In-memory jar — no credentials → no authentication cookie →
          // bootstrap resolves BootFreshFirstRun.
          cookieJarProvider.overrideWithValue(CookieJar()),
        ],
        child: const PrijavkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // No ErrorWidget in the tree — tree build didn't throw.
    expect(find.byType(ErrorWidget), findsNothing);
    // Welcome screen headline is visible — confirms routing + localization work.
    // Croatian is the device locale in test; falls back to English if not.
    expect(find.textContaining('Prijavko'), findsAtLeastNWidgets(1));
  });
}
