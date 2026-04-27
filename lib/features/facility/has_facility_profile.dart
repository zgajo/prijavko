// TODO(story-3.1): Replace this stub with the real implementation:
//   `appDatabase.facilitiesTable.count() > 0`
// Story 3.1 introduces FacilitiesTable in Drift. Until then, no facility
// profile can exist in the database, so this provider always returns false.
// Returning false collapses BootCredentialsMissing into BootFreshFirstRun
// for v1.0 — the only reachable branch today.
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_facility_profile.g.dart';

/// Stub: always false until Story 3.1 introduces FacilitiesTable.
// WHY keepAlive: trivially cached; the result is stable for the process lifetime.
@Riverpod(keepAlive: true)
Future<bool> hasFacilityProfile(Ref ref) async => false;
