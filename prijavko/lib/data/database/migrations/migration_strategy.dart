import 'package:drift/drift.dart';

/// Schema evolution: v1 is initial create; add `if (from < N)` steps for later versions.
MigrationStrategy buildMigrationStrategy() {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from >= to) {
        return;
      }
      // Example for future versions:
      // if (from < 2) { await m.addColumn(...); }
    },
  );
}
