// Guards AC6.2 (LoginScreen replaceMode behavior) — kept in a separate file
// from login_screen_test.dart so each file is scoped to its own story.
//
// WHY isolated GoRouter: same rationale as login_screen_test.dart.
// WHY hr locale: Croatian is the primary runtime locale.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/design/theme.dart';
import 'package:prijavko/features/auth/login_screen.dart';
import 'package:prijavko/features/settings/credential_store.dart';
import 'package:prijavko/features/submission/evisitor_api_client.dart';
import 'package:prijavko/l10n/app_localizations.dart';

import '../../../fakes/evisitor_fake_adapter.dart';
import '../../../fakes/fake_credential_store.dart';
import '../../../fakes/fake_security_service.dart';
import '../../../helpers/window_secure_flag_mock.dart';

const _settingsStub = 'settings-stub';
const _homeStub = 'home-stub';

Widget _makeTestApp({
  required EvisitorFakeAdapter fakeAdapter,
  required FakeCredentialStore fakeCredentialStore,
  required String cookieJarDir,
  bool replaceMode = true,
  ThemeMode themeMode = ThemeMode.dark,
  Locale locale = const Locale('hr'),
}) {
  final GoRouter testRouter;

  if (replaceMode) {
    testRouter = GoRouter(
      initialLocation: '/settings/replace-credentials',
      routes: [
        GoRoute(
          path: '/settings',
          name: 'settings',
          // i18n-ignore: test-only stub
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text(_settingsStub))),
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
  } else {
    testRouter = GoRouter(
      initialLocation: '/onboarding/login',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(
              path: 'login',
              name: 'login',
              builder: (context, state) => const LoginScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          // i18n-ignore: test-only stub
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text(_homeStub))),
        ),
      ],
    );
  }

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
  setUp(setUpWindowSecureFlagMock);
  tearDown(tearDownWindowSecureFlagMock);

  group('LoginScreen replaceMode', () {
    late EvisitorFakeAdapter fakeAdapter;
    late FakeCredentialStore fakeCredentialStore;
    late Directory cookieDir;

    setUp(() {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      fakeCredentialStore = FakeCredentialStore();
      cookieDir = Directory.systemTemp.createTempSync(
        'prijavko_replace_test_cookies_',
      );
    });

    tearDown(() {
      if (cookieDir.existsSync()) cookieDir.deleteSync(recursive: true);
    });

    Widget makeApp({EvisitorFakeAdapter? adapter}) => _makeTestApp(
      fakeAdapter: adapter ?? fakeAdapter,
      fakeCredentialStore: fakeCredentialStore,
      cookieJarDir: cookieDir.path,
    );

    testWidgets(
      'username pre-filled from keystore and password field focused',
      (tester) async {
        fakeCredentialStore.savedCredentials = const Credentials(
          username: 'host42',
          password: 'old-pwd',
          apiKey: 'test-key',
        );

        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        final usernameField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(usernameField.controller, isNotNull);
        expect(usernameField.controller!.text, 'host42');

        final passwordField = tester.widget<TextField>(
          find.byType(TextField).at(1),
        );
        expect(passwordField.focusNode, isNotNull);
        expect(passwordField.focusNode!.hasFocus, isTrue);
      },
    );

    testWidgets('replace banner renders with surfaceContainerHigh decoration', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Zamjena podataka — stari objekti i nedoslani gosti ostaju.'),
        findsOneWidget,
      );

      // AC2.4 Poka-yoke: panel must use the neutral surfaceContainerHigh tone,
      // NOT a MaterialBanner (which is reserved for Story 2.7 CredentialBanner).
      // Asserting the decoration colour catches a future regression to
      // MaterialBanner or to a semantic colour (warning/error).
      final ctx = tester.element(find.byType(LoginScreen));
      final expectedColor = Theme.of(ctx).colorScheme.surfaceContainerHigh;
      expect(
        find.byWidgetPredicate((w) {
          if (w is! Container) return false;
          final dec = w.decoration;
          return dec is BoxDecoration && dec.color == expectedColor;
        }),
        findsOneWidget,
      );
    });

    testWidgets('submit button shows replace credentials copy', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Spremi nove podatke'), findsOneWidget);
      expect(find.text('Prijavi se'), findsNothing);
    });

    testWidgets('success-path pops to /settings (not /home)', (tester) async {
      fakeCredentialStore.savedCredentials = const Credentials(
        username: 'host42',
        password: 'old-pwd',
        apiKey: 'test-key',
      );

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Username pre-filled; enter new password.
      await tester.enterText(find.byType(TextField).at(1), 'new-pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Popped back to /settings stub — NOT /home.
      expect(find.text(_settingsStub), findsOneWidget);
      expect(find.text(_homeStub), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);

      // Keystore was overwritten with the new password (AC3 happy-path
      // counterpart to the failure-path retention test).
      expect(fakeCredentialStore.savedCredentials, isNotNull);
      expect(fakeCredentialStore.savedCredentials!.username, 'host42');
      expect(fakeCredentialStore.savedCredentials!.password, 'new-pass');
    });

    testWidgets(
      'failure path leaves Keystore unchanged and shows inline error',
      (tester) async {
        fakeCredentialStore.savedCredentials = const Credentials(
          username: 'host42',
          password: 'OLD-PWD',
          apiKey: 'test-key',
        );

        final failAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(
            userMessage: 'Korisničko ime ili lozinka nisu ispravni.',
          ),
        );

        await tester.pumpWidget(makeApp(adapter: failAdapter));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(1), 'WRONG-NEW');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Keystore password is unchanged.
        expect(fakeCredentialStore.savedCredentials!.password, 'OLD-PWD');
        // Inline Croatian error is visible.
        expect(
          find.textContaining('Korisničko ime ili lozinka nisu ispravni.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'default mode: no banner, empty username, correct label, success to /home',
      (tester) async {
        await tester.pumpWidget(
          _makeTestApp(
            fakeAdapter: fakeAdapter,
            fakeCredentialStore: fakeCredentialStore,
            cookieJarDir: cookieDir.path,
            replaceMode: false,
          ),
        );
        await tester.pumpAndSettle();

        // No replace banner.
        expect(find.textContaining('Zamjena podataka'), findsNothing);
        // Username field empty — no pre-fill in default mode.
        final usernameField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(usernameField.controller, isNotNull);
        expect(usernameField.controller!.text, isEmpty);
        // Submit button has default Croatian label.
        expect(find.text('Prijavi se'), findsOneWidget);
        expect(find.text('Spremi nove podatke'), findsNothing);

        // Success navigates to /home (not /settings).
        await tester.enterText(find.byType(TextField).first, 'user');
        await tester.enterText(find.byType(TextField).at(1), 'pass');
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(find.text(_homeStub), findsOneWidget);
      },
    );

    testWidgets(
      'success-path falls back to /home when stack is shallow (deep link)',
      (tester) async {
        // Custom router with NO /settings parent — simulates a deep-link entry
        // straight into /replace-credentials. context.canPop() returns false
        // here; the success-path must fall back to context.goNamed('home')
        // instead of a no-op pop that would eject the host to the launcher.
        final deepLinkRouter = GoRouter(
          initialLocation: '/replace-credentials',
          routes: [
            GoRoute(
              path: '/replace-credentials',
              name: 'replace-credentials',
              builder: (context, state) => const LoginScreen(replaceMode: true),
            ),
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text(_homeStub))),
            ),
          ],
        );

        fakeCredentialStore.savedCredentials = const Credentials(
          username: 'host42',
          password: 'old-pwd',
          apiKey: 'test-key',
        );

        final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'))
          ..httpClientAdapter = fakeAdapter;
        final apiClient = EvisitorApiClient(
          dio,
          isApiKeyAvailable: () => true,
          lockoutDuration: const Duration(minutes: 6),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              securityServiceProvider.overrideWithValue(FakeSecurityService()),
              cookieJarDirectoryProvider.overrideWithValue(cookieDir.path),
              dioProvider.overrideWithValue(dio),
              evisitorApiClientProvider.overrideWithValue(apiClient),
              credentialStoreProvider.overrideWithValue(fakeCredentialStore),
            ],
            child: MaterialApp.router(
              routerConfig: deepLinkRouter,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('hr'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(1), 'new-pass');
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Landed on /home — NOT stuck on LoginScreen, NOT ejected to launcher.
        expect(find.text(_homeStub), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets(
      'typing in either field clears inline error after a failed re-entry',
      (tester) async {
        fakeCredentialStore.savedCredentials = const Credentials(
          username: 'host42',
          password: 'OLD-PWD',
          apiKey: 'test-key',
        );

        final failAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(
            userMessage: 'Korisničko ime ili lozinka nisu ispravni.',
          ),
        );

        await tester.pumpWidget(makeApp(adapter: failAdapter));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(1), 'WRONG-NEW');
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Error is showing.
        expect(
          find.textContaining('Korisničko ime ili lozinka nisu ispravni.'),
          findsOneWidget,
        );

        // AC5.1 in replace mode: typing into the password field clears the
        // inline error (LoginNotifier.clearError).
        await tester.enterText(find.byType(TextField).at(1), 'NEW-ATTEMPT');
        await tester.pump();

        expect(
          find.textContaining('Korisničko ime ili lozinka nisu ispravni.'),
          findsNothing,
        );
      },
    );

    testWidgets('lockout state renders identically in replace mode', (
      tester,
    ) async {
      final lockoutAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginLockedOut(),
      );

      fakeCredentialStore.savedCredentials = const Credentials(
        username: 'host42',
        password: 'old-pwd',
        apiKey: 'test-key',
      );

      await tester.pumpWidget(makeApp(adapter: lockoutAdapter));
      await tester.pumpAndSettle();

      // Username pre-filled; enter a password to enable submit.
      await tester.enterText(find.byType(TextField).at(1), 'any-pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Previše neuspješnih pokušaja'),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
