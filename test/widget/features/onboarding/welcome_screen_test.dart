// guards AC5 (WelcomeScreen layout) and AC7.1 (widget test coverage).
//
// WHY a test GoRouter (not PrijavkoApp): widget tests should isolate the
// screen under test. Using PrijavkoApp pulls in ConsentGate, the production
// router, and MaterialApp.router's full stack — all irrelevant to whether
// WelcomeScreen renders its disclosure content correctly. A minimal
// GoRouter + MaterialApp.router gives us exactly the navigation surface
// the screen depends on, nothing more (Muri: avoid overburden).
//
// WHY locale: Locale('hr'): Croatian is the primary runtime locale per
// PRD §GDPR Transparency. Tests assert on Croatian strings to guard against
// ARB key regressions; English fallback is covered by the smoke test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/features/onboarding/welcome_screen.dart';
import 'package:prijavko/l10n/app_localizations.dart';

// Placeholder text used by the camera-permission stub route.
// Using a constant avoids brittle magic strings in multiple assertions.
const _cameraPermissionPlaceholder = 'camera-permission-stub';

/// Creates a self-contained test app that renders WelcomeScreen as the
/// initial route, with a stub camera-permission route for navigation tests.
///
/// [themeMode] defaults to light; pass [ThemeMode.dark] for dark-mode tests.
Widget _makeTestApp({
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('hr'),
}) {
  // Build inside the helper so each test gets a fresh GoRouter instance
  // (GoRouter is stateful — sharing across tests pollutes navigation state).
  final testRouter = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'camera-permission',
            // i18n-ignore: test-only stub; not user-facing copy
            builder: (context, state) => const Scaffold(
              body: Center(child: Text(_cameraPermissionPlaceholder)),
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: testRouter,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    ),
  );
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders Croatian headline', (tester) async {
      // guards AC5.3 — headline uses AppLocalizations.welcomeHeadline,
      // style displayMedium. Croatian locale confirms ARB wiring.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Dobrodošli u Prijavko'), findsOneWidget);
    });

    testWidgets('renders body text containing passport disclosure', (
      tester,
    ) async {
      // guards AC5.4 — body rendered via AppLocalizations.welcomeBody.
      // Partial match avoids brittleness if wording is refined in future ARB.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('skenira putovnice'), findsOneWidget);
    });

    testWidgets('renders Privacy Policy link in Croatian', (tester) async {
      // guards AC5.4 — welcomePrivacyPolicyLink key present in ARB and wired.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Pravila privatnosti'), findsOneWidget);
    });

    testWidgets('renders Terms of Service link in Croatian', (tester) async {
      // guards AC5.4 — welcomeTermsOfServiceLink key present in ARB and wired.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Uvjeti korištenja'), findsOneWidget);
    });

    testWidgets('renders Nastavi FilledButton', (tester) async {
      // guards AC5.7 — CTA is FilledButton with welcomeContinueButton text.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Nastavi'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('tapping Nastavi navigates to camera-permission route', (
      tester,
    ) async {
      // guards AC5.7 — onPressed calls context.go('/onboarding/camera-permission').
      // Verifies the stub route is reached, confirming go_router wiring.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nastavi'));
      await tester.pumpAndSettle();

      expect(find.text(_cameraPermissionPlaceholder), findsOneWidget);
      // Welcome screen headline must no longer be visible after navigation.
      expect(find.text('Dobrodošli u Prijavko'), findsNothing);
    });

    testWidgets('dark theme pumps without overflow or render errors', (
      tester,
    ) async {
      // guards AC5.12 — dark-mode-first design contract.
      // pumpAndSettle reveals any overflow exceptions that would surface at
      // runtime on a dark-mode device.
      await tester.pumpWidget(_makeTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light theme pumps without overflow or render errors', (
      tester,
    ) async {
      // guards AC5.12 — symmetric coverage for light theme.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('has no AppBar — full-screen onboarding layout', (
      tester,
    ) async {
      // guards AC5.8 — no back navigation from the root onboarding route.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('privacy and terms links have Semantics with link: true', (
      tester,
    ) async {
      // guards AC5.11 — TalkBack accessibility: Semantics.link = true is set
      // on both inline link spans so screen readers announce them as links.
      await tester.pumpWidget(_makeTestApp());
      await tester.pumpAndSettle();

      // Collect all Semantics widgets in the tree and filter for link: true.
      // WidgetSpan wraps each link in a Semantics(link: true) widget —
      // verifying they exist confirms the accessibility contract is met.
      final linkSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.link == true)
          .toList();

      // Privacy Policy and Terms of Service — two link Semantics required.
      expect(
        linkSemantics.length,
        greaterThanOrEqualTo(2),
        reason:
            'Expected at least two Semantics(link: true) for the '
            'Privacy Policy and Terms of Service links',
      );
    });

    group('golden tests', () {
      // WHY goldens: catching visual regressions in layout, color, and
      // typography that unit assertions cannot express (e.g. spacing drift,
      // link underline color, theme colour mismatch). Baseline images are
      // generated with `flutter test --update-goldens` and committed.
      //
      // WHY no custom FontLoader: the test VM uses the bundled Ahem font.
      // Golden images are primarily regression guards for layout geometry —
      // not font rendering fidelity, which is covered by offline_fonts_test.
      // Consistent Ahem rendering is deterministic across CI machines.

      testWidgets('dark theme — welcome_dark.png', (tester) async {
        await tester.pumpWidget(_makeTestApp(themeMode: ThemeMode.dark));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(WelcomeScreen),
          matchesGoldenFile('goldens/welcome_dark.png'),
        );
      });

      testWidgets('light theme — welcome_light.png', (tester) async {
        await tester.pumpWidget(_makeTestApp());
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(WelcomeScreen),
          matchesGoldenFile('goldens/welcome_light.png'),
        );
      });
    });
  });
}
