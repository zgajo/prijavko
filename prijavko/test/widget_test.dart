import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prijavko/app.dart';
import 'package:prijavko/core/connectivity/connectivity_provider.dart';
import 'package:prijavko/data/database/app_database.dart';
import 'package:prijavko/data/database/app_database_provider.dart';
import 'package:prijavko/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders onboarding when no facility (hr default)', (
    WidgetTester tester,
  ) async {
    final AppDatabase db = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (dynamic raw) {
            raw.execute('PRAGMA foreign_keys = ON;');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((Ref ref) => db),
          connectivityProvider.overrideWith((Ref ref) {
            return Stream<List<ConnectivityResult>>.value(<ConnectivityResult>[
              ConnectivityResult.wifi,
            ]);
          }),
        ],
        child: const PrijavkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
