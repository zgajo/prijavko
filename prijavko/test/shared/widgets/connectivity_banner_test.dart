import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prijavko/core/connectivity/connectivity_provider.dart';
import 'package:prijavko/core/l10n/app_localizations.dart';
import 'package:prijavko/shared/widgets/connectivity_banner.dart';

void main() {
  testWidgets('shows localized offline text when stream reports none', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((Ref ref) {
            return Stream<List<ConnectivityResult>>.value(
              const <ConnectivityResult>[ConnectivityResult.none],
            );
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(body: ConnectivityBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No network connection'), findsOneWidget);
  });

  testWidgets('shows offline strip when connectivity stream errors (fail-safe)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWithValue(
            AsyncValue<List<ConnectivityResult>>.error(
              Exception('plugin'),
              StackTrace.empty,
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(body: ConnectivityBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No network connection'), findsOneWidget);
  });

  testWidgets('hides banner when online', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((Ref ref) {
            return Stream<List<ConnectivityResult>>.value(
              const <ConnectivityResult>[ConnectivityResult.wifi],
            );
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(body: ConnectivityBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No network connection'), findsNothing);
  });
}
