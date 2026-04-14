import 'package:drift/drift.dart';

@DataClassName('DbFacility')
class Facilities extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get facilityCode => text()();

  /// JSON blob: [FacilityDefaults] keys for defaults editor (Epic 2).
  TextColumn get defaults => text()();
}
