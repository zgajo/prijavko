// Guards AC4 (CameraPermissionScreen layout) and AC7.3 (widget test coverage).
//
// WHY isolated GoRouter + MaterialApp.router (not PrijavkoApp): same rationale
// as welcome_screen_test.dart — ConsentGate and production router are irrelevant
// to screen rendering correctness.
//
// WHY hr locale: Croatian is primary runtime locale. Tests assert Croatian
// strings to guard ARB key regressions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/core/capture/capture_preference.dart';
import 'package:prijavko/core/capture/capture_preference_store.dart';
import 'package:prijavko/core/permissions/permission_service_impl.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/features/onboarding/camera_permission_screen.dart';
import 'package:prijavko/l10n/app_localizations.dart';

import '../../../fakes/fake_capture_preference_store.dart';
import '../../../fakes/fake_permission_service.dart';

// Stub text for the login placeholder route — asserted after navigation.
const _loginStub = 'login-stub';

/// Creates a self-contained test app rooted at the camera-permission screen,
/// with provider overrides for PermissionService and CapturePreferenceStore.
Widget _makeTestApp({
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('hr'),
  required FakePermissionService fakePermission,
  required FakeCapturePreferenceStore fakeStore,
}) {
  final testRouter = GoRouter(
    initialLocation: '/onboarding/camera-permission',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        routes: [
          GoRoute(
            path: 'camera-permission',
            builder: (context, state) => const CameraPermissionScreen(),
          ),
          GoRoute(
            path: 'login',
            // i18n-ignore: test-only stub; not user-facing copy
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text(_loginStub))),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      permissionServiceProvider.overrideWithValue(fakePermission),
      capturePreferenceStoreProvider.overrideWithValue(fakeStore),
    ],
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
  group('CameraPermissionScreen', () {
    late FakePermissionService fakePermission;
    late FakeCapturePreferenceStore fakeStore;

    setUp(() {
      fakePermission = FakePermissionService(grantCamera: true);
      fakeStore = FakeCapturePreferenceStore();
    });

    Widget makeApp({ThemeMode themeMode = ThemeMode.light}) => _makeTestApp(
          themeMode: themeMode,
          fakePermission: fakePermission,
          fakeStore: fakeStore,
        );

    testWidgets('headline renders in Croatian', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Pristup kameri'), findsOneWidget);
    });

    testWidgets('rationale body renders', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('skeniranje MRZ koda'), findsOneWidget);
    });

    testWidgets('Allow button renders as FilledButton', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Dopusti pristup'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Skip button renders as OutlinedButton', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Preskoči — ručni unos'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets(
        'tapping Allow triggers permission request and navigates to login '
        'with CapturePreference.live on grant', (tester) async {
      fakePermission = FakePermissionService(grantCamera: true);
      fakeStore = FakeCapturePreferenceStore();

      await tester.pumpWidget(_makeTestApp(
        fakePermission: fakePermission,
        fakeStore: fakeStore,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dopusti pristup'));
      await tester.pumpAndSettle();

      expect(fakePermission.requestCameraCallCount, 1);
      expect(fakeStore.savedPreference, CapturePreference.live);
      expect(find.text(_loginStub), findsOneWidget);
    });

    testWidgets(
        'tapping Allow when permission denied saves manualOnly and navigates',
        (tester) async {
      fakePermission = FakePermissionService(grantCamera: false);
      fakeStore = FakeCapturePreferenceStore();

      await tester.pumpWidget(_makeTestApp(
        fakePermission: fakePermission,
        fakeStore: fakeStore,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dopusti pristup'));
      await tester.pumpAndSettle();

      expect(fakeStore.savedPreference, CapturePreference.manualOnly);
      expect(find.text(_loginStub), findsOneWidget);
    });

    testWidgets(
        'tapping Skip does NOT call requestCamera, saves manualOnly, navigates',
        (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preskoči — ručni unos'));
      await tester.pumpAndSettle();

      expect(fakePermission.requestCameraCallCount, 0,
          reason: 'Skip must not trigger the OS permission dialog');
      expect(fakeStore.savedPreference, CapturePreference.manualOnly);
      expect(find.text(_loginStub), findsOneWidget);
    });

    testWidgets('camera icon renders', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Symbols.photo_camera_rounded), findsOneWidget);
    });

    testWidgets('has no AppBar — full-screen onboarding layout', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('dark theme pumps without errors', (tester) async {
      await tester.pumpWidget(makeApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light theme pumps without errors', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    group('golden tests', () {
      testWidgets('dark theme — camera_permission_dark.png', (tester) async {
        await tester.pumpWidget(makeApp(themeMode: ThemeMode.dark));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(CameraPermissionScreen),
          matchesGoldenFile('goldens/camera_permission_dark.png'),
        );
      });

      testWidgets('light theme — camera_permission_light.png', (tester) async {
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(CameraPermissionScreen),
          matchesGoldenFile('goldens/camera_permission_light.png'),
        );
      });
    });
  });
}
