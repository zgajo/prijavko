// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkFailure value)?  networkFailure,TResult Function( AuthFailure value)?  authFailure,TResult Function( ApiFailure value)?  apiFailure,TResult Function( ValidationFailure value)?  validationFailure,TResult Function( StorageFailure value)?  storageFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkFailure() when networkFailure != null:
return networkFailure(_that);case AuthFailure() when authFailure != null:
return authFailure(_that);case ApiFailure() when apiFailure != null:
return apiFailure(_that);case ValidationFailure() when validationFailure != null:
return validationFailure(_that);case StorageFailure() when storageFailure != null:
return storageFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkFailure value)  networkFailure,required TResult Function( AuthFailure value)  authFailure,required TResult Function( ApiFailure value)  apiFailure,required TResult Function( ValidationFailure value)  validationFailure,required TResult Function( StorageFailure value)  storageFailure,}){
final _that = this;
switch (_that) {
case NetworkFailure():
return networkFailure(_that);case AuthFailure():
return authFailure(_that);case ApiFailure():
return apiFailure(_that);case ValidationFailure():
return validationFailure(_that);case StorageFailure():
return storageFailure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkFailure value)?  networkFailure,TResult? Function( AuthFailure value)?  authFailure,TResult? Function( ApiFailure value)?  apiFailure,TResult? Function( ValidationFailure value)?  validationFailure,TResult? Function( StorageFailure value)?  storageFailure,}){
final _that = this;
switch (_that) {
case NetworkFailure() when networkFailure != null:
return networkFailure(_that);case AuthFailure() when authFailure != null:
return authFailure(_that);case ApiFailure() when apiFailure != null:
return apiFailure(_that);case ValidationFailure() when validationFailure != null:
return validationFailure(_that);case StorageFailure() when storageFailure != null:
return storageFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  networkFailure,TResult Function()?  authFailure,TResult Function( String userMessage)?  apiFailure,TResult Function( Map<String, String> fields)?  validationFailure,TResult Function()?  storageFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkFailure() when networkFailure != null:
return networkFailure();case AuthFailure() when authFailure != null:
return authFailure();case ApiFailure() when apiFailure != null:
return apiFailure(_that.userMessage);case ValidationFailure() when validationFailure != null:
return validationFailure(_that.fields);case StorageFailure() when storageFailure != null:
return storageFailure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  networkFailure,required TResult Function()  authFailure,required TResult Function( String userMessage)  apiFailure,required TResult Function( Map<String, String> fields)  validationFailure,required TResult Function()  storageFailure,}) {final _that = this;
switch (_that) {
case NetworkFailure():
return networkFailure();case AuthFailure():
return authFailure();case ApiFailure():
return apiFailure(_that.userMessage);case ValidationFailure():
return validationFailure(_that.fields);case StorageFailure():
return storageFailure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  networkFailure,TResult? Function()?  authFailure,TResult? Function( String userMessage)?  apiFailure,TResult? Function( Map<String, String> fields)?  validationFailure,TResult? Function()?  storageFailure,}) {final _that = this;
switch (_that) {
case NetworkFailure() when networkFailure != null:
return networkFailure();case AuthFailure() when authFailure != null:
return authFailure();case ApiFailure() when apiFailure != null:
return apiFailure(_that.userMessage);case ValidationFailure() when validationFailure != null:
return validationFailure(_that.fields);case StorageFailure() when storageFailure != null:
return storageFailure();case _:
  return null;

}
}

}

/// @nodoc


class NetworkFailure implements Failure {
  const NetworkFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.networkFailure()';
}


}




/// @nodoc


class AuthFailure implements Failure {
  const AuthFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.authFailure()';
}


}




/// @nodoc


class ApiFailure implements Failure {
  const ApiFailure(this.userMessage);
  

 final  String userMessage;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiFailureCopyWith<ApiFailure> get copyWith => _$ApiFailureCopyWithImpl<ApiFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiFailure&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage));
}


@override
int get hashCode => Object.hash(runtimeType,userMessage);

@override
String toString() {
  return 'Failure.apiFailure(userMessage: $userMessage)';
}


}

/// @nodoc
abstract mixin class $ApiFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ApiFailureCopyWith(ApiFailure value, $Res Function(ApiFailure) _then) = _$ApiFailureCopyWithImpl;
@useResult
$Res call({
 String userMessage
});




}
/// @nodoc
class _$ApiFailureCopyWithImpl<$Res>
    implements $ApiFailureCopyWith<$Res> {
  _$ApiFailureCopyWithImpl(this._self, this._then);

  final ApiFailure _self;
  final $Res Function(ApiFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userMessage = null,}) {
  return _then(ApiFailure(
null == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ValidationFailure implements Failure {
  const ValidationFailure(final  Map<String, String> fields): _fields = fields;
  

 final  Map<String, String> _fields;
 Map<String, String> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}


/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationFailureCopyWith<ValidationFailure> get copyWith => _$ValidationFailureCopyWithImpl<ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationFailure&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'Failure.validationFailure(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $ValidationFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ValidationFailureCopyWith(ValidationFailure value, $Res Function(ValidationFailure) _then) = _$ValidationFailureCopyWithImpl;
@useResult
$Res call({
 Map<String, String> fields
});




}
/// @nodoc
class _$ValidationFailureCopyWithImpl<$Res>
    implements $ValidationFailureCopyWith<$Res> {
  _$ValidationFailureCopyWithImpl(this._self, this._then);

  final ValidationFailure _self;
  final $Res Function(ValidationFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(ValidationFailure(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc


class StorageFailure implements Failure {
  const StorageFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.storageFailure()';
}


}




// dart format on
