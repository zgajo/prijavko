import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/l10n/app_localizations.dart';

void main() {
  testWidgets('loads English strings when locale is en', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            expect(l10n, isNotNull);
            return Text(l10n!.tabHome);
          },
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('loads Croatian strings when locale is hr', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            expect(l10n, isNotNull);
            return Text(l10n!.tabHome);
          },
        ),
      ),
    );

    expect(find.text('Početna'), findsOneWidget);
  });
}
