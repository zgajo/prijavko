import 'package:drift/drift.dart';

import 'facilities.dart';

@DataClassName('DbCredential')
class Credentials extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get facilityId => integer().references(Facilities, #id)();

  TextColumn get encryptedUsername => text()();

  TextColumn get encryptedPassword => text()();

  DateTimeColumn get createdAt => dateTime()();
}
