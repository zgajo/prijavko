// guards AC6.3
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/consent/consent_gate.dart';
import 'package:prijavko/core/consent/consent_providers.dart';
import 'package:prijavko/core/consent/consent_state.dart';
import 'package:prijavko/design/theme.dart';

import '../fakes/fake_consent_service.dart';

Widget _makeTestApp({required ConsentState scriptedState}) {
  return ProviderScope(
    overrides: [
      consentServiceProvider.overrideWithValue(
        FakeConsentService(scriptedState: scriptedState),
      ),
    ],
    child: MaterialApp(
      theme: buildLightTheme(),
      home: const ConsentGate(child: SizedBox.shrink(key: Key('child'))),
    ),
  );
}

void main() {
  group('ConsentGate', () {
    testWidgets(
      'shows loading scaffold (CircularProgressIndicator) while ConsentLoading',
      (tester) async {
        await tester.pumpWidget(
          _makeTestApp(scriptedState: const ConsentLoading()),
        );
        // First frame: ConsentGate's initial build() state is ConsentLoading
        // (build() is called before the post-frame gather() fires).
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byKey(const Key('child')), findsNothing);
      },
    );

    testWidgets('surfaces child after ConsentObtained resolves', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeTestApp(
          scriptedState: const ConsentObtained(
            requestNonPersonalizedAdsOnly: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('child')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('surfaces child after ConsentNotRequired resolves', (
      tester,
    ) async {
      await tester.pumpWidget(
        _makeTestApp(scriptedState: const ConsentNotRequired()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets(
      'surfaces child even on ConsentFailed — failure does not block the app',
      (tester) async {
        await tester.pumpWidget(
          _makeTestApp(
            scriptedState: const ConsentFailed(ConsentFailureReason.network),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('child')), findsOneWidget);
      },
    );
  });
}
