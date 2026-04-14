import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/capture_tier.dart';
import '../models/guest_source.dart';
import '../models/guest_state.dart';
import 'converters/enum_converters.dart';
import 'daos/facilities_dao.dart';
import 'daos/guests_dao.dart';
import 'daos/scan_sessions_dao.dart';
import 'migrations/migration_strategy.dart';
import 'tables/credentials.dart';
import 'tables/facilities.dart';
import 'tables/guests.dart';
import 'tables/scan_sessions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Facilities, ScanSessions, Credentials, Guests],
  daos: [FacilitiesDao, GuestsDao, ScanSessionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory or temp executor for tests — one open per isolate.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => buildMigrationStrategy();

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dir.path, 'prijavko.sqlite'));
      return NativeDatabase(
        file,
        setup: (db) {
          db.execute('PRAGMA foreign_keys = ON;');
          db.execute('PRAGMA journal_mode = WAL;');
        },
      );
    });
  }
}
