import 'package:freezed_annotation/freezed_annotation.dart';

import 'facility_defaults.dart';

part 'facility.freezed.dart';

/// Domain facility profile (mirrors Drift [Facilities] row; JSON holds [defaults]).
@freezed
sealed class Facility with _$Facility {
  const factory Facility({
    required int id,
    required String name,
    required String facilityCode,
    required FacilityDefaults defaults,
  }) = _Facility;
}
