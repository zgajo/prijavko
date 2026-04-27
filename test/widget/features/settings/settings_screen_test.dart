// Guards AC6.1 (SettingsScreen layout and navigation) and AC1.1–1.6.
//
// WHY isolated GoRouter (not PrijavkoApp): ConsentGate and BootGate are
// irrelevant to screen rendering correctness — same rationale as
// login_screen_test.dart and camera_permission_screen_test.dart.
//
// WHY hr locale: Croatian is the primary runtime locale.
// WHY dark ThemeMode: dark is the primary design target (design-system rules §2).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/features/auth/login_screen.dart';
import 'package:prijavko/features/settings/credential_store.dart';
import 'package:prijavko/features/settings/settings_screen.dart';
import 'package:prijavko/features/submission/evisitor_api_client.dart';
import 'package:prijavko/l10n/app_localizations.dart';

import '../../../fakes/evisitor_fake_adapter.dart';
import '../../../fakes/fake_credential_store.dart';
import '../../../fakes/fake_security_service.dart';

Widget _makeTestApp({
  required EvisitorFakeAdapter fakeAdapter,
  required FakeCredentialStore fakeCredentialStore,
  required String cookieJarDir,
  ThemeMode themeMode = ThemeMode.dark,
  Locale locale = const Locale('hr'),
}) {
  final testRouter = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'replace-credentials',
            name: 'replace-credentials',
            builder: (context, state) => const LoginScreen(replaceMode: true),
          ),
        ],
      ),
    ],
  );

  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'))
    ..httpClientAdapter = fakeAdapter;
  final apiClient = EvisitorApiClient(
    dio,
    isApiKeyAvailable: () => true,
    lockoutDuration: const Duration(minutes: 6),
  );

  return ProviderScope(
    overrides: [
      securityServiceProvider.overrideWithValue(FakeSecurityService()),
      cookieJarDirectoryProvider.overrideWithValue(cookieJarDir),
      dioProvider.overrideWithValue(dio),
      evisitorApiClientProvider.overrideWithValue(apiClient),
      credentialStoreProvider.overrideWithValue(fakeCredentialStore),
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
  // Mock the WindowSecureFlag MethodChannel: LoginScreen (replace-credentials
  // sub-route) calls FLAG_SECURE on init. Without the mock, tests navigating
  // into that route throw MissingPluginException.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('hr.prijavko.window_secure'),
          (call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('hr.prijavko.window_secure'),
          null,
        );
  });

  group('SettingsScreen', () {
    late EvisitorFakeAdapter fakeAdapter;
    late FakeCredentialStore fakeCredentialStore;
    late Directory cookieDir;

    setUp(() {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      fakeCredentialStore = FakeCredentialStore();
      cookieDir = Directory.systemTemp.createTempSync(
        'prijavko_settings_test_cookies_',
      );
    });

    tearDown(() {
      if (cookieDir.existsSync()) cookieDir.deleteSync(recursive: true);
    });

    Widget makeApp() => _makeTestApp(
      fakeAdapter: fakeAdapter,
      fakeCredentialStore: fakeCredentialStore,
      cookieJarDir: cookieDir.path,
    );

    testWidgets(
      'renders credential re-entry tile with Croatian label and lock-reset icon',
      (tester) async {
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        expect(find.text('Zamijeni podatke za prijavu'), findsOneWidget);
        expect(find.byIcon(Symbols.lock_reset_rounded), findsOneWidget);
      },
    );

    testWidgets('tapping tile navigates to replace-credentials', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zamijeni podatke za prijavu'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('SnackBar fires after successful credential re-entry', (
      tester,
    ) async {
      // Seed credentials so the replace-mode banner pre-fills the username.
      fakeCredentialStore.savedCredentials = const Credentials(
        username: 'host42',
        password: 'old-pwd',
        apiKey: 'test-key',
      );

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Navigate to replace-credentials.
      await tester.tap(find.text('Zamijeni podatke za prijavu'));
      await tester.pumpAndSettle();

      // Username is pre-filled; enter new password and submit.
      await tester.enterText(find.byType(TextField).at(1), 'new-pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Popped back to /settings; SnackBar with success message visible.
      expect(find.text('Podaci ažurirani.'), findsOneWidget);
    });

    testWidgets('no SnackBar when user cancels with system back', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zamijeni podatke za prijavu'));
      await tester.pumpAndSettle();

      // LoginScreen has no AppBar, so there is no UI back button. Simulate the
      // system back gesture via handlePopRoute(), which is the documented
      // Flutter test approach for hardware-back-button simulation.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Podaci ažurirani.'), findsNothing);
    });
  });
}
