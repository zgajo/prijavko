// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$ScanSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FacilitiesTable get facilities => attachedDatabase.facilities;
  $ScanSessionsTable get scanSessions => attachedDatabase.scanSessions;
  ScanSessionsDaoManager get managers => ScanSessionsDaoManager(this);
}

class ScanSessionsDaoManager {
  final _$ScanSessionsDaoMixin _db;
  ScanSessionsDaoManager(this._db);
  $$FacilitiesTableTableManager get facilities =>
      $$FacilitiesTableTableManager(_db.attachedDatabase, _db.facilities);
  $$ScanSessionsTableTableManager get scanSessions =>
      $$ScanSessionsTableTableManager(_db.attachedDatabase, _db.scanSessions);
}
