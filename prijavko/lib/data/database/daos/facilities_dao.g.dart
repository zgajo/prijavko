// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facilities_dao.dart';

// ignore_for_file: type=lint
mixin _$FacilitiesDaoMixin on DatabaseAccessor<AppDatabase> {
  $FacilitiesTable get facilities => attachedDatabase.facilities;
  FacilitiesDaoManager get managers => FacilitiesDaoManager(this);
}

class FacilitiesDaoManager {
  final _$FacilitiesDaoMixin _db;
  FacilitiesDaoManager(this._db);
  $$FacilitiesTableTableManager get facilities =>
      $$FacilitiesTableTableManager(_db.attachedDatabase, _db.facilities);
}
