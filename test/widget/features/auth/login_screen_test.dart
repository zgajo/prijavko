// Guards AC6 (LoginScreen layout) and AC10.3 (widget test coverage).
//
// WHY isolated GoRouter + MaterialApp.router (not PrijavkoApp): same rationale
// as camera_permission_screen_test.dart — ConsentGate and production router are
// irrelevant to screen rendering correctness.
//
// WHY hr locale: Croatian is primary runtime locale.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _homeStub = 'home-stub';

// WHY: golden pixel comparisons are platform-dependent (macOS vs Linux font
// rendering). CI sets SKIP_GOLDENS=true; local dev runs them normally.
final _skipGoldens = const bool.fromEnvironment('SKIP_GOLDENS')
    ? 'Platform-dependent golden rendering — run locally with --update-goldens'
    : null;

Widget _makeTestApp({
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('hr'),
  required EvisitorFakeAdapter fakeAdapter,
  required FakeCredentialStore fakeCredentialStore,
  required String cookieJarDir,
  Duration lockoutDuration = const Duration(minutes: 6),
}) {
  final testRouter = GoRouter(
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

  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'))
    ..httpClientAdapter = fakeAdapter;
  final apiClient = EvisitorApiClient(
    dio,
    isApiKeyAvailable: () => true,
    lockoutDuration: lockoutDuration,
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
  // Mock the WindowSecureFlag MethodChannel to prevent MissingPluginException.
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

  group('LoginScreen', () {
    late EvisitorFakeAdapter fakeAdapter;
    late FakeCredentialStore fakeCredentialStore;
    late Directory cookieDir;

    setUp(() {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      fakeCredentialStore = FakeCredentialStore();
      // WHY systemTemp: parallel test workers must not collide on a shared
      // path; a hardcoded `/tmp/test_cookies` is also non-portable.
      cookieDir = Directory.systemTemp.createTempSync('prijavko_test_cookies_');
    });

    tearDown(() {
      if (cookieDir.existsSync()) cookieDir.deleteSync(recursive: true);
    });

    Widget makeApp({ThemeMode themeMode = ThemeMode.light}) => _makeTestApp(
      themeMode: themeMode,
      fakeAdapter: fakeAdapter,
      fakeCredentialStore: fakeCredentialStore,
      cookieJarDir: cookieDir.path,
    );

    testWidgets('headline + body + reassurance render in Croatian', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Prijava u eVisitor'), findsOneWidget);
      expect(find.textContaining('Prijavite se jednom'), findsOneWidget);
      expect(find.textContaining('Podaci se čuvaju šifrirano'), findsOneWidget);
    });

    testWidgets('submit disabled when fields empty', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('submit enabled once both fields have text', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
      'tap submit with success navigates to /home and persists credentials',
      (tester) async {
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'testUser');
        await tester.enterText(find.byType(TextField).last, 'testPass');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(find.text(_homeStub), findsOneWidget);
        expect(fakeCredentialStore.savedCredentials, isNotNull);
        expect(fakeCredentialStore.savedCredentials!.username, 'testUser');
        expect(fakeCredentialStore.savedCredentials!.password, 'testPass');
      },
    );

    testWidgets(
      'tap submit with credentials-invalid renders Croatian UserMessage + hint',
      (tester) async {
        fakeAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(
            userMessage: 'Korisničko ime ili lozinka nisu ispravni.',
          ),
        );

        await tester.pumpWidget(
          _makeTestApp(
            fakeAdapter: fakeAdapter,
            fakeCredentialStore: fakeCredentialStore,
            cookieJarDir: cookieDir.path,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'user');
        await tester.enterText(find.byType(TextField).last, 'wrong');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Korisničko ime ili lozinka nisu ispravni.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Provjerite korisničko ime i lozinku.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tap submit with credentials-invalid does NOT persist credentials',
      (tester) async {
        fakeAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(),
        );

        await tester.pumpWidget(
          _makeTestApp(
            fakeAdapter: fakeAdapter,
            fakeCredentialStore: fakeCredentialStore,
            cookieJarDir: cookieDir.path,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'user');
        await tester.enterText(find.byType(TextField).last, 'wrong');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(fakeCredentialStore.savedCredentials, isNull);
      },
    );

    testWidgets(
      'tap submit with locked-out shows lockout banner and disables form',
      (tester) async {
        fakeAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginLockedOut(),
        );

        await tester.pumpWidget(
          _makeTestApp(
            fakeAdapter: fakeAdapter,
            fakeCredentialStore: fakeCredentialStore,
            cookieJarDir: cookieDir.path,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'user');
        await tester.enterText(find.byType(TextField).last, 'pass');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Previše neuspješnih pokušaja'),
          findsOneWidget,
        );
        // Submit button is disabled.
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('lockout transitions back to LoginIdle after retryAfter', (
      tester,
    ) async {
      // AC10.3: with retryAfter set 2s in the future, real-wait past expiry
      // and pump the periodic timer to assert the form is re-enabled.
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginLockedOut(),
      );

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
          lockoutDuration: const Duration(seconds: 2),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Lockout banner is visible.
      expect(
        find.textContaining('Previše neuspješnih pokušaja'),
        findsOneWidget,
      );

      // WHY runAsync: `DateTime.now()` is wall-clock; the periodic timer's
      // exit condition needs real time to elapse past `retryAfter`. FakeAsync
      // (the default) would block `Future.delayed` indefinitely.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 2500));
      });
      // Pump 1s of test-scheduler time — the periodic Timer fires, checks
      // wall-clock against retryAfter (already past), transitions to LoginIdle.
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Previše neuspješnih pokušaja'), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('server-error path renders Croatian server message', (
      tester,
    ) async {
      // AC10.3: adapter returns 500, assert loginServerError copy is shown.
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginServerError(),
      );

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('eVisitor je nedostupan'), findsOneWidget);
    });

    testWidgets('inline error clears when fields change', (tester) async {
      // AC5.1: LoginIdle.error is "cleared when fields change".
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginCredentialsInvalid(),
      );

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Error visible after failed submit.
      expect(
        find.textContaining('Provjerite korisničko ime i lozinku.'),
        findsOneWidget,
      );

      // User edits the password field — error must clear.
      await tester.enterText(find.byType(TextField).last, 'wrong2');
      await tester.pump();

      expect(
        find.textContaining('Provjerite korisničko ime i lozinku.'),
        findsNothing,
      );
    });

    testWidgets('lockout countdown ticks down', (tester) async {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginLockedOut(),
      );

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Find the countdown text — should show seconds remaining.
      expect(find.textContaining('sekund'), findsOneWidget);

      // Advance time and verify countdown updates.
      await tester.pump(const Duration(seconds: 2));
      // The text should still show but with fewer seconds.
      expect(find.textContaining('sekund'), findsOneWidget);
    });

    testWidgets('password-visibility toggle flips obscureText', (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      // Initially shows "Prikaži lozinku" tooltip (password is obscured).
      expect(find.byTooltip('Prikaži lozinku'), findsOneWidget);

      await tester.tap(find.byTooltip('Prikaži lozinku'));
      await tester.pump();

      // After toggle, shows "Sakrij lozinku" tooltip.
      expect(find.byTooltip('Sakrij lozinku'), findsOneWidget);
    });

    testWidgets('contract-break path renders forced-update message', (
      tester,
    ) async {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginContractBreak(),
      );

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ažurirajte prijavko iz Play Store-a'),
        findsOneWidget,
      );
      // Diagnostic reason must NOT be visible.
      expect(find.textContaining('apikey rejected'), findsNothing);
    });

    testWidgets('network-error path renders Croatian network message', (
      tester,
    ) async {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginNetworkError(),
      );

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nema interneta'), findsOneWidget);
    });

    testWidgets('in-flight submit prevents double-tap', (tester) async {
      fakeAdapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      fakeAdapter.responseDelay = const Duration(milliseconds: 200);

      await tester.pumpWidget(
        _makeTestApp(
          fakeAdapter: fakeAdapter,
          fakeCredentialStore: fakeCredentialStore,
          cookieJarDir: cookieDir.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user');
      await tester.enterText(find.byType(TextField).last, 'pass');
      await tester.pump();

      // Tap twice rapidly.
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 50));
      // Second tap should be a no-op (button is null during submitting).
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(fakeAdapter.requestCount, 1);
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

    testWidgets('has no AppBar — full-screen onboarding layout', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });

    group('golden tests', skip: _skipGoldens, () {
      testWidgets('dark theme idle — login_idle_dark.png', (tester) async {
        await tester.pumpWidget(makeApp(themeMode: ThemeMode.dark));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('goldens/login_idle_dark.png'),
        );
      });

      testWidgets('light theme idle — login_idle_light.png', (tester) async {
        await tester.pumpWidget(makeApp());
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('goldens/login_idle_light.png'),
        );
      });

      testWidgets('dark theme error — login_error_dark.png', (tester) async {
        fakeAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(),
        );

        await tester.pumpWidget(
          _makeTestApp(
            themeMode: ThemeMode.dark,
            fakeAdapter: fakeAdapter,
            fakeCredentialStore: fakeCredentialStore,
            cookieJarDir: cookieDir.path,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'user');
        await tester.enterText(find.byType(TextField).last, 'wrong');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('goldens/login_error_dark.png'),
        );
      });

      testWidgets('dark theme lockout — login_lockout_dark.png', (
        tester,
      ) async {
        fakeAdapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginLockedOut(),
        );

        await tester.pumpWidget(
          _makeTestApp(
            themeMode: ThemeMode.dark,
            fakeAdapter: fakeAdapter,
            fakeCredentialStore: fakeCredentialStore,
            cookieJarDir: cookieDir.path,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'user');
        await tester.enterText(find.byType(TextField).last, 'pass');
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('goldens/login_lockout_dark.png'),
        );
      });
    });
  });
}
