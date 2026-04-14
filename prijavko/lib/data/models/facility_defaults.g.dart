// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility_defaults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FacilityDefaults _$FacilityDefaultsFromJson(Map<String, dynamic> json) =>
    _FacilityDefaults(
      ttpaymentCategory: json['ttpaymentCategory'] as String?,
      arrivalOrganisation: json['arrivalOrganisation'] as String?,
      offeredServiceType: json['offeredServiceType'] as String?,
      defaultStayDuration: (json['defaultStayDuration'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$FacilityDefaultsToJson(_FacilityDefaults instance) =>
    <String, dynamic>{
      'ttpaymentCategory': instance.ttpaymentCategory,
      'arrivalOrganisation': instance.arrivalOrganisation,
      'offeredServiceType': instance.offeredServiceType,
      'defaultStayDuration': instance.defaultStayDuration,
    };
