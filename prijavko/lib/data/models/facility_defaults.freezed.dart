// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'facility_defaults.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FacilityDefaults {

 String? get ttpaymentCategory; String? get arrivalOrganisation; String? get offeredServiceType; int get defaultStayDuration;
/// Create a copy of FacilityDefaults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FacilityDefaultsCopyWith<FacilityDefaults> get copyWith => _$FacilityDefaultsCopyWithImpl<FacilityDefaults>(this as FacilityDefaults, _$identity);

  /// Serializes this FacilityDefaults to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FacilityDefaults&&(identical(other.ttpaymentCategory, ttpaymentCategory) || other.ttpaymentCategory == ttpaymentCategory)&&(identical(other.arrivalOrganisation, arrivalOrganisation) || other.arrivalOrganisation == arrivalOrganisation)&&(identical(other.offeredServiceType, offeredServiceType) || other.offeredServiceType == offeredServiceType)&&(identical(other.defaultStayDuration, defaultStayDuration) || other.defaultStayDuration == defaultStayDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ttpaymentCategory,arrivalOrganisation,offeredServiceType,defaultStayDuration);

@override
String toString() {
  return 'FacilityDefaults(ttpaymentCategory: $ttpaymentCategory, arrivalOrganisation: $arrivalOrganisation, offeredServiceType: $offeredServiceType, defaultStayDuration: $defaultStayDuration)';
}


}

/// @nodoc
abstract mixin class $FacilityDefaultsCopyWith<$Res>  {
  factory $FacilityDefaultsCopyWith(FacilityDefaults value, $Res Function(FacilityDefaults) _then) = _$FacilityDefaultsCopyWithImpl;
@useResult
$Res call({
 String? ttpaymentCategory, String? arrivalOrganisation, String? offeredServiceType, int defaultStayDuration
});




}
/// @nodoc
class _$FacilityDefaultsCopyWithImpl<$Res>
    implements $FacilityDefaultsCopyWith<$Res> {
  _$FacilityDefaultsCopyWithImpl(this._self, this._then);

  final FacilityDefaults _self;
  final $Res Function(FacilityDefaults) _then;

/// Create a copy of FacilityDefaults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ttpaymentCategory = freezed,Object? arrivalOrganisation = freezed,Object? offeredServiceType = freezed,Object? defaultStayDuration = null,}) {
  return _then(_self.copyWith(
ttpaymentCategory: freezed == ttpaymentCategory ? _self.ttpaymentCategory : ttpaymentCategory // ignore: cast_nullable_to_non_nullable
as String?,arrivalOrganisation: freezed == arrivalOrganisation ? _self.arrivalOrganisation : arrivalOrganisation // ignore: cast_nullable_to_non_nullable
as String?,offeredServiceType: freezed == offeredServiceType ? _self.offeredServiceType : offeredServiceType // ignore: cast_nullable_to_non_nullable
as String?,defaultStayDuration: null == defaultStayDuration ? _self.defaultStayDuration : defaultStayDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FacilityDefaults].
extension FacilityDefaultsPatterns on FacilityDefaults {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FacilityDefaults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FacilityDefaults() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FacilityDefaults value)  $default,){
final _that = this;
switch (_that) {
case _FacilityDefaults():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FacilityDefaults value)?  $default,){
final _that = this;
switch (_that) {
case _FacilityDefaults() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? ttpaymentCategory,  String? arrivalOrganisation,  String? offeredServiceType,  int defaultStayDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FacilityDefaults() when $default != null:
return $default(_that.ttpaymentCategory,_that.arrivalOrganisation,_that.offeredServiceType,_that.defaultStayDuration);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? ttpaymentCategory,  String? arrivalOrganisation,  String? offeredServiceType,  int defaultStayDuration)  $default,) {final _that = this;
switch (_that) {
case _FacilityDefaults():
return $default(_that.ttpaymentCategory,_that.arrivalOrganisation,_that.offeredServiceType,_that.defaultStayDuration);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? ttpaymentCategory,  String? arrivalOrganisation,  String? offeredServiceType,  int defaultStayDuration)?  $default,) {final _that = this;
switch (_that) {
case _FacilityDefaults() when $default != null:
return $default(_that.ttpaymentCategory,_that.arrivalOrganisation,_that.offeredServiceType,_that.defaultStayDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FacilityDefaults implements FacilityDefaults {
  const _FacilityDefaults({this.ttpaymentCategory, this.arrivalOrganisation, this.offeredServiceType, this.defaultStayDuration = 1});
  factory _FacilityDefaults.fromJson(Map<String, dynamic> json) => _$FacilityDefaultsFromJson(json);

@override final  String? ttpaymentCategory;
@override final  String? arrivalOrganisation;
@override final  String? offeredServiceType;
@override@JsonKey() final  int defaultStayDuration;

/// Create a copy of FacilityDefaults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FacilityDefaultsCopyWith<_FacilityDefaults> get copyWith => __$FacilityDefaultsCopyWithImpl<_FacilityDefaults>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FacilityDefaultsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FacilityDefaults&&(identical(other.ttpaymentCategory, ttpaymentCategory) || other.ttpaymentCategory == ttpaymentCategory)&&(identical(other.arrivalOrganisation, arrivalOrganisation) || other.arrivalOrganisation == arrivalOrganisation)&&(identical(other.offeredServiceType, offeredServiceType) || other.offeredServiceType == offeredServiceType)&&(identical(other.defaultStayDuration, defaultStayDuration) || other.defaultStayDuration == defaultStayDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ttpaymentCategory,arrivalOrganisation,offeredServiceType,defaultStayDuration);

@override
String toString() {
  return 'FacilityDefaults(ttpaymentCategory: $ttpaymentCategory, arrivalOrganisation: $arrivalOrganisation, offeredServiceType: $offeredServiceType, defaultStayDuration: $defaultStayDuration)';
}


}

/// @nodoc
abstract mixin class _$FacilityDefaultsCopyWith<$Res> implements $FacilityDefaultsCopyWith<$Res> {
  factory _$FacilityDefaultsCopyWith(_FacilityDefaults value, $Res Function(_FacilityDefaults) _then) = __$FacilityDefaultsCopyWithImpl;
@override @useResult
$Res call({
 String? ttpaymentCategory, String? arrivalOrganisation, String? offeredServiceType, int defaultStayDuration
});




}
/// @nodoc
class __$FacilityDefaultsCopyWithImpl<$Res>
    implements _$FacilityDefaultsCopyWith<$Res> {
  __$FacilityDefaultsCopyWithImpl(this._self, this._then);

  final _FacilityDefaults _self;
  final $Res Function(_FacilityDefaults) _then;

/// Create a copy of FacilityDefaults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ttpaymentCategory = freezed,Object? arrivalOrganisation = freezed,Object? offeredServiceType = freezed,Object? defaultStayDuration = null,}) {
  return _then(_FacilityDefaults(
ttpaymentCategory: freezed == ttpaymentCategory ? _self.ttpaymentCategory : ttpaymentCategory // ignore: cast_nullable_to_non_nullable
as String?,arrivalOrganisation: freezed == arrivalOrganisation ? _self.arrivalOrganisation : arrivalOrganisation // ignore: cast_nullable_to_non_nullable
as String?,offeredServiceType: freezed == offeredServiceType ? _self.offeredServiceType : offeredServiceType // ignore: cast_nullable_to_non_nullable
as String?,defaultStayDuration: null == defaultStayDuration ? _self.defaultStayDuration : defaultStayDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
