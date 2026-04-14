import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/data/database/app_database.dart';
import 'package:prijavko/data/models/capture_tier.dart';
import 'package:prijavko/data/models/guest_source.dart';
import 'package:prijavko/data/models/guest_state.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (dynamic raw) {
          raw.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('facilitiesDao insert, list, and watch', () async {
    expect(await db.facilitiesDao.allFacilities, isEmpty);

    final int id = await db.facilitiesDao.insertFacility(
      FacilitiesCompanion.insert(
        name: 'Test facility',
        facilityCode: 'FAC1',
        defaults: '{}',
      ),
    );

    final List<DbFacility> rows = await db.facilitiesDao.allFacilities;
    expect(rows, hasLength(1));
    expect(rows.single.id, id);

    final List<DbFacility> fromWatch = await db.facilitiesDao
        .watchAllFacilities()
        .first;
    expect(fromWatch, hasLength(1));
  });

  test('guestsDao insert with FK and watchGuestsForFacility', () async {
    final int facilityId = await db.facilitiesDao.insertFacility(
      FacilitiesCompanion.insert(
        name: 'Test facility',
        facilityCode: 'FAC2',
        defaults: '{}',
      ),
    );

    final DateTime createdAt = DateTime.utc(2026, 4, 14, 12);

    await db.guestsDao.insertGuest(
      GuestsCompanion.insert(
        guid: '550e8400-e29b-41d4-a716-446655440000',
        facilityId: facilityId,
        state: GuestState.captured,
        captureTier: CaptureTier.mrz,
        source: GuestSource.local,
        stayFromDate: '20260414',
        stayFromTime: '14:00',
        foreseenStayUntilDate: '20260420',
        foreseenStayUntilTime: '10:00',
        documentType: 'P',
        documentNumber: 'AB123456',
        touristName: 'Ivo',
        touristSurname: 'Ivić',
        gender: 'M',
        countryOfBirth: 'HR',
        cityOfBirth: 'Zagreb',
        dateOfBirth: '19900101',
        citizenship: 'HR',
        countryOfResidence: 'HR',
        cityOfResidence: 'Zagreb',
        ttPaymentCategory: 'cat',
        arrivalOrganisation: 'org',
        offeredServiceType: 'svc',
        createdAt: createdAt,
      ),
    );

    final List<DbGuest> all = await db.guestsDao.allGuests;
    expect(all, hasLength(1));
    expect(all.single.state, GuestState.captured);

    final List<DbGuest> scoped = await db.guestsDao
        .watchGuestsForFacility(facilityId)
        .first;
    expect(scoped, hasLength(1));
  });

  test('scanSessionsDao roundtrip', () async {
    final int facilityId = await db.facilitiesDao.insertFacility(
      FacilitiesCompanion.insert(
        name: 'F',
        facilityCode: 'FAC3',
        defaults: '{}',
      ),
    );

    final DateTime started = DateTime.utc(2026, 1, 1, 8);
    await db.scanSessionsDao.insertSession(
      ScanSessionsCompanion.insert(
        facilityId: facilityId,
        startedAt: started,
        guestCount: 0,
      ),
    );

    final List<DbScanSession> rows = await db.scanSessionsDao.allSessions;
    expect(rows, hasLength(1));
    expect(rows.single.guestCount, 0);
  });

  test('scanSessionsDao watchAllSessions and watchSessionsForFacility', () async {
    final int facilityA = await db.facilitiesDao.insertFacility(
      FacilitiesCompanion.insert(
        name: 'A',
        facilityCode: 'FAC4',
        defaults: '{}',
      ),
    );
    final int facilityB = await db.facilitiesDao.insertFacility(
      FacilitiesCompanion.insert(
        name: 'B',
        facilityCode: 'FAC5',
        defaults: '{}',
      ),
    );

    await db.scanSessionsDao.insertSession(
      ScanSessionsCompanion.insert(
        facilityId: facilityA,
        startedAt: DateTime.utc(2026, 5, 1, 9),
        guestCount: 1,
      ),
    );
    await db.scanSessionsDao.insertSession(
      ScanSessionsCompanion.insert(
        facilityId: facilityB,
        startedAt: DateTime.utc(2026, 5, 2, 9),
        guestCount: 2,
      ),
    );

    final List<DbScanSession> allWatched =
        await db.scanSessionsDao.watchAllSessions().first;
    expect(allWatched, hasLength(2));

    final List<DbScanSession> forA = await db.scanSessionsDao
        .watchSessionsForFacility(facilityA)
        .first;
    expect(forA, hasLength(1));
    expect(forA.single.facilityId, facilityA);
    expect(forA.single.guestCount, 1);
  });
}
