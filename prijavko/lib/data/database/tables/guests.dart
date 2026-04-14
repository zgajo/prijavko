import 'package:drift/drift.dart';

import '../converters/enum_converters.dart';
import 'facilities.dart';
import 'scan_sessions.dart';

@TableIndex(name: 'idx_guests_facility_id', columns: {#facilityId})
@TableIndex(name: 'idx_guests_state', columns: {#state})
@TableIndex(name: 'idx_guests_submitted_at', columns: {#submittedAt})
@TableIndex(name: 'idx_guests_created_at', columns: {#createdAt})
@DataClassName('DbGuest')
class Guests extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get guid => text()();

  IntColumn get facilityId => integer().references(Facilities, #id)();

  IntColumn get sessionId =>
      integer().nullable().references(ScanSessions, #id)();

  IntColumn get state => integer().map(const GuestStateConverter())();

  IntColumn get captureTier => integer().map(const CaptureTierConverter())();

  IntColumn get source => integer().map(const GuestSourceConverter())();

  TextColumn get stayFromDate => text()();

  TextColumn get stayFromTime => text()();

  TextColumn get foreseenStayUntilDate => text()();

  TextColumn get foreseenStayUntilTime => text()();

  TextColumn get documentType => text()();

  TextColumn get documentNumber => text()();

  TextColumn get touristName => text()();

  TextColumn get touristSurname => text()();

  TextColumn get touristMiddleName => text().nullable()();

  TextColumn get gender => text()();

  TextColumn get countryOfBirth => text()();

  TextColumn get cityOfBirth => text()();

  TextColumn get dateOfBirth => text()();

  TextColumn get citizenship => text()();

  TextColumn get countryOfResidence => text()();

  TextColumn get cityOfResidence => text()();

  TextColumn get residenceAddress => text().nullable()();

  TextColumn get touristEmail => text().nullable()();

  TextColumn get touristTelephone => text().nullable()();

  TextColumn get accommodationUnitType => text().nullable()();

  TextColumn get ttPaymentCategory => text()();

  TextColumn get arrivalOrganisation => text()();

  TextColumn get offeredServiceType => text()();

  TextColumn get borderCrossing => text().nullable()();

  TextColumn get passageDate => text().nullable()();

  TextColumn get eVisitorResponse => text().nullable()();

  TextColumn get errorMessage => text().nullable()();

  BoolColumn get isTerminalFailure => boolean().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get confirmedAt => dateTime().nullable()();

  DateTimeColumn get submittedAt => dateTime().nullable()();
}
