import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/scan_sessions.dart';

part 'scan_sessions_dao.g.dart';

@DriftAccessor(tables: [ScanSessions])
class ScanSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$ScanSessionsDaoMixin {
  ScanSessionsDao(super.db);

  Future<List<DbScanSession>> get allSessions => select(scanSessions).get();

  Stream<List<DbScanSession>> watchAllSessions() =>
      select(scanSessions).watch();

  Stream<List<DbScanSession>> watchSessionsForFacility(int facilityId) =>
      (select(
        scanSessions,
      )..where((t) => t.facilityId.equals(facilityId))).watch();

  Future<DbScanSession?> getSessionById(int id) =>
      (select(scanSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertSession(ScanSessionsCompanion row) =>
      into(scanSessions).insert(row);

  Future<bool> updateSession(DbScanSession row) =>
      update(scanSessions).replace(row);

  Future<int> deleteSession(DbScanSession row) =>
      delete(scanSessions).delete(row);
}
