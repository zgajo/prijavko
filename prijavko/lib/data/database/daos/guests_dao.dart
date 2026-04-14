import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/guests.dart';

part 'guests_dao.g.dart';

@DriftAccessor(tables: [Guests])
class GuestsDao extends DatabaseAccessor<AppDatabase> with _$GuestsDaoMixin {
  GuestsDao(super.db);

  Future<List<DbGuest>> get allGuests => select(guests).get();

  Stream<List<DbGuest>> watchAllGuests() => select(guests).watch();

  Stream<List<DbGuest>> watchGuestsForFacility(int facilityId) =>
      (select(guests)..where((t) => t.facilityId.equals(facilityId))).watch();

  Future<DbGuest?> getGuestById(int id) =>
      (select(guests)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertGuest(GuestsCompanion row) => into(guests).insert(row);

  Future<bool> updateGuest(DbGuest row) => update(guests).replace(row);

  Future<int> deleteGuest(DbGuest row) => delete(guests).delete(row);
}
