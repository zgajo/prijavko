// WHY this test exists: Poka-yoke against an early replacement of the stub
// that ships before FacilitiesTable (Story 3.1) is wired. If someone replaces
// hasFacilityProfileProvider before Story 3.1 ships, this test will fail and
// prompt the investigation.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/features/facility/has_facility_profile.dart';

void main() {
  test('hasFacilityProfileProvider returns false until Story 3.1', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(hasFacilityProfileProvider.future);
    expect(result, isFalse);
  });
}
