import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility_defaults.freezed.dart';
part 'facility_defaults.g.dart';

/// Facility-level defaults stored as JSON on the [Facilities.defaults] blob.
@freezed
sealed class FacilityDefaults with _$FacilityDefaults {
  const factory FacilityDefaults({
    String? ttpaymentCategory,
    String? arrivalOrganisation,
    String? offeredServiceType,
    @Default(1) int defaultStayDuration,
  }) = _FacilityDefaults;

  factory FacilityDefaults.fromJson(Map<String, dynamic> json) =>
      _$FacilityDefaultsFromJson(json);
}
