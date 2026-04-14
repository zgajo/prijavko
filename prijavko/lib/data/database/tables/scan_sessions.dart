import 'package:drift/drift.dart';

import 'facilities.dart';

@DataClassName('DbScanSession')
class ScanSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get facilityId => integer().references(Facilities, #id)();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get guestCount => integer()();
}
