// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanSession {

 int get id; int get facilityId; DateTime get startedAt; DateTime? get endedAt; int get guestCount;
/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanSessionCopyWith<ScanSession> get copyWith => _$ScanSessionCopyWithImpl<ScanSession>(this as ScanSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanSession&&(identical(other.id, id) || other.id == id)&&(identical(other.facilityId, facilityId) || other.facilityId == facilityId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.guestCount, guestCount) || other.guestCount == guestCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,facilityId,startedAt,endedAt,guestCount);

@override
String toString() {
  return 'ScanSession(id: $id, facilityId: $facilityId, startedAt: $startedAt, endedAt: $endedAt, guestCount: $guestCount)';
}


}

/// @nodoc
abstract mixin class $ScanSessionCopyWith<$Res>  {
  factory $ScanSessionCopyWith(ScanSession value, $Res Function(ScanSession) _then) = _$ScanSessionCopyWithImpl;
@useResult
$Res call({
 int id, int facilityId, DateTime startedAt, DateTime? endedAt, int guestCount
});




}
/// @nodoc
class _$ScanSessionCopyWithImpl<$Res>
    implements $ScanSessionCopyWith<$Res> {
  _$ScanSessionCopyWithImpl(this._self, this._then);

  final ScanSession _self;
  final $Res Function(ScanSession) _then;

/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? facilityId = null,Object? startedAt = null,Object? endedAt = freezed,Object? guestCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,facilityId: null == facilityId ? _self.facilityId : facilityId // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,guestCount: null == guestCount ? _self.guestCount : guestCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanSession].
extension ScanSessionPatterns on ScanSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanSession value)  $default,){
final _that = this;
switch (_that) {
case _ScanSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanSession value)?  $default,){
final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int facilityId,  DateTime startedAt,  DateTime? endedAt,  int guestCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
return $default(_that.id,_that.facilityId,_that.startedAt,_that.endedAt,_that.guestCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int facilityId,  DateTime startedAt,  DateTime? endedAt,  int guestCount)  $default,) {final _that = this;
switch (_that) {
case _ScanSession():
return $default(_that.id,_that.facilityId,_that.startedAt,_that.endedAt,_that.guestCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int facilityId,  DateTime startedAt,  DateTime? endedAt,  int guestCount)?  $default,) {final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
return $default(_that.id,_that.facilityId,_that.startedAt,_that.endedAt,_that.guestCount);case _:
  return null;

}
}

}

/// @nodoc


class _ScanSession implements ScanSession {
  const _ScanSession({required this.id, required this.facilityId, required this.startedAt, this.endedAt, required this.guestCount});
  

@override final  int id;
@override final  int facilityId;
@override final  DateTime startedAt;
@override final  DateTime? endedAt;
@override final  int guestCount;

/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanSessionCopyWith<_ScanSession> get copyWith => __$ScanSessionCopyWithImpl<_ScanSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanSession&&(identical(other.id, id) || other.id == id)&&(identical(other.facilityId, facilityId) || other.facilityId == facilityId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.guestCount, guestCount) || other.guestCount == guestCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,facilityId,startedAt,endedAt,guestCount);

@override
String toString() {
  return 'ScanSession(id: $id, facilityId: $facilityId, startedAt: $startedAt, endedAt: $endedAt, guestCount: $guestCount)';
}


}

/// @nodoc
abstract mixin class _$ScanSessionCopyWith<$Res> implements $ScanSessionCopyWith<$Res> {
  factory _$ScanSessionCopyWith(_ScanSession value, $Res Function(_ScanSession) _then) = __$ScanSessionCopyWithImpl;
@override @useResult
$Res call({
 int id, int facilityId, DateTime startedAt, DateTime? endedAt, int guestCount
});




}
/// @nodoc
class __$ScanSessionCopyWithImpl<$Res>
    implements _$ScanSessionCopyWith<$Res> {
  __$ScanSessionCopyWithImpl(this._self, this._then);

  final _ScanSession _self;
  final $Res Function(_ScanSession) _then;

/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? facilityId = null,Object? startedAt = null,Object? endedAt = freezed,Object? guestCount = null,}) {
  return _then(_ScanSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,facilityId: null == facilityId ? _self.facilityId : facilityId // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,guestCount: null == guestCount ? _self.guestCount : guestCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
