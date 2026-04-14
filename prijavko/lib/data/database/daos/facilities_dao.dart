import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/facilities.dart';

part 'facilities_dao.g.dart';

@DriftAccessor(tables: [Facilities])
class FacilitiesDao extends DatabaseAccessor<AppDatabase>
    with _$FacilitiesDaoMixin {
  FacilitiesDao(super.db);

  Future<List<DbFacility>> get allFacilities => select(facilities).get();

  Stream<List<DbFacility>> watchAllFacilities() => select(facilities).watch();

  Future<DbFacility?> getFacilityById(int id) =>
      (select(facilities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertFacility(FacilitiesCompanion row) =>
      into(facilities).insert(row);

  Future<bool> updateFacility(DbFacility row) =>
      update(facilities).replace(row);

  Future<int> deleteFacility(DbFacility row) => delete(facilities).delete(row);
}
