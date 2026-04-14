// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guests_dao.dart';

// ignore_for_file: type=lint
mixin _$GuestsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FacilitiesTable get facilities => attachedDatabase.facilities;
  $ScanSessionsTable get scanSessions => attachedDatabase.scanSessions;
  $GuestsTable get guests => attachedDatabase.guests;
  GuestsDaoManager get managers => GuestsDaoManager(this);
}

class GuestsDaoManager {
  final _$GuestsDaoMixin _db;
  GuestsDaoManager(this._db);
  $$FacilitiesTableTableManager get facilities =>
      $$FacilitiesTableTableManager(_db.attachedDatabase, _db.facilities);
  $$ScanSessionsTableTableManager get scanSessions =>
      $$ScanSessionsTableTableManager(_db.attachedDatabase, _db.scanSessions);
  $$GuestsTableTableManager get guests =>
      $$GuestsTableTableManager(_db.attachedDatabase, _db.guests);
}
