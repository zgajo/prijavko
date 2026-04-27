// Story 1.2 AC4 — smoke test that MainApp pumps the design-system
// preview without throwing. Replaces the Story 1.1 `Hello World!`
// fixture now that the real MaterialApp shape (light/dark themes,
// SemanticColors extension, Material Symbols rounded) is wired in.
// Re-targets when WelcomeScreen lands in Story 1.5.
//
// Story 1.4: wrapped in ProviderScope because ConsentGate is a
// ConsumerStatefulWidget. consentServiceProvider is overridden with
// FakeConsentService(ConsentNotRequired) so the gate passes through
// to the child immediately, and no real UMP SDK call is made.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/main.dart';

import 'fakes/fake_consent_service.dart';

void main() {
  testWidgets('MainApp pumps without errors and renders the preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentServiceProvider.overrideWithValue(
            FakeConsentService(scriptedState: const ConsentNotRequired()),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    // No ErrorWidget in the tree — tree build didn't throw.
    expect(find.byType(ErrorWidget), findsNothing);
    // The preview surface lands a FilledButton, an OutlinedButton, and
    // at least one Material Symbol Icon. If any token wiring or font
    // asset were broken, the build would either throw or render Tofu
    // and the test would fail loud.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(Icon), findsAtLeastNWidgets(1));
  });
}
