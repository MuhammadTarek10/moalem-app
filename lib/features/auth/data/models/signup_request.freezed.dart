// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signup_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignupRequest {

 String get email; String get password; String get name;@JsonKey(name: 'group_name') String? get groupName; List<String> get subjects; String get governorate;@JsonKey(name: 'educational_administration') String get educationalAdministration;@JsonKey(name: 'whatsapp_number') String get whatsappNumber; List<String> get schools; List<String>? get grades;
/// Create a copy of SignupRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignupRequestCopyWith<SignupRequest> get copyWith => _$SignupRequestCopyWithImpl<SignupRequest>(this as SignupRequest, _$identity);

  /// Serializes this SignupRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignupRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.name, name) || other.name == name)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&const DeepCollectionEquality().equals(other.subjects, subjects)&&(identical(other.governorate, governorate) || other.governorate == governorate)&&(identical(other.educationalAdministration, educationalAdministration) || other.educationalAdministration == educationalAdministration)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&const DeepCollectionEquality().equals(other.schools, schools)&&const DeepCollectionEquality().equals(other.grades, grades));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,name,groupName,const DeepCollectionEquality().hash(subjects),governorate,educationalAdministration,whatsappNumber,const DeepCollectionEquality().hash(schools),const DeepCollectionEquality().hash(grades));

@override
String toString() {
  return 'SignupRequest(email: $email, password: $password, name: $name, groupName: $groupName, subjects: $subjects, governorate: $governorate, educationalAdministration: $educationalAdministration, whatsappNumber: $whatsappNumber, schools: $schools, grades: $grades)';
}


}

/// @nodoc
abstract mixin class $SignupRequestCopyWith<$Res>  {
  factory $SignupRequestCopyWith(SignupRequest value, $Res Function(SignupRequest) _then) = _$SignupRequestCopyWithImpl;
@useResult
$Res call({
 String email, String password, String name,@JsonKey(name: 'group_name') String? groupName, List<String> subjects, String governorate,@JsonKey(name: 'educational_administration') String educationalAdministration,@JsonKey(name: 'whatsapp_number') String whatsappNumber, List<String> schools, List<String>? grades
});




}
/// @nodoc
class _$SignupRequestCopyWithImpl<$Res>
    implements $SignupRequestCopyWith<$Res> {
  _$SignupRequestCopyWithImpl(this._self, this._then);

  final SignupRequest _self;
  final $Res Function(SignupRequest) _then;

/// Create a copy of SignupRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? password = null,Object? name = null,Object? groupName = freezed,Object? subjects = null,Object? governorate = null,Object? educationalAdministration = null,Object? whatsappNumber = null,Object? schools = null,Object? grades = freezed,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,governorate: null == governorate ? _self.governorate : governorate // ignore: cast_nullable_to_non_nullable
as String,educationalAdministration: null == educationalAdministration ? _self.educationalAdministration : educationalAdministration // ignore: cast_nullable_to_non_nullable
as String,whatsappNumber: null == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String,schools: null == schools ? _self.schools : schools // ignore: cast_nullable_to_non_nullable
as List<String>,grades: freezed == grades ? _self.grades : grades // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SignupRequest].
extension SignupRequestPatterns on SignupRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignupRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignupRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignupRequest value)  $default,){
final _that = this;
switch (_that) {
case _SignupRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignupRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SignupRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String password,  String name, @JsonKey(name: 'group_name')  String? groupName,  List<String> subjects,  String governorate, @JsonKey(name: 'educational_administration')  String educationalAdministration, @JsonKey(name: 'whatsapp_number')  String whatsappNumber,  List<String> schools,  List<String>? grades)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignupRequest() when $default != null:
return $default(_that.email,_that.password,_that.name,_that.groupName,_that.subjects,_that.governorate,_that.educationalAdministration,_that.whatsappNumber,_that.schools,_that.grades);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String password,  String name, @JsonKey(name: 'group_name')  String? groupName,  List<String> subjects,  String governorate, @JsonKey(name: 'educational_administration')  String educationalAdministration, @JsonKey(name: 'whatsapp_number')  String whatsappNumber,  List<String> schools,  List<String>? grades)  $default,) {final _that = this;
switch (_that) {
case _SignupRequest():
return $default(_that.email,_that.password,_that.name,_that.groupName,_that.subjects,_that.governorate,_that.educationalAdministration,_that.whatsappNumber,_that.schools,_that.grades);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String password,  String name, @JsonKey(name: 'group_name')  String? groupName,  List<String> subjects,  String governorate, @JsonKey(name: 'educational_administration')  String educationalAdministration, @JsonKey(name: 'whatsapp_number')  String whatsappNumber,  List<String> schools,  List<String>? grades)?  $default,) {final _that = this;
switch (_that) {
case _SignupRequest() when $default != null:
return $default(_that.email,_that.password,_that.name,_that.groupName,_that.subjects,_that.governorate,_that.educationalAdministration,_that.whatsappNumber,_that.schools,_that.grades);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignupRequest implements SignupRequest {
  const _SignupRequest({required this.email, required this.password, required this.name, @JsonKey(name: 'group_name') this.groupName, required final  List<String> subjects, required this.governorate, @JsonKey(name: 'educational_administration') required this.educationalAdministration, @JsonKey(name: 'whatsapp_number') required this.whatsappNumber, required final  List<String> schools, final  List<String>? grades}): _subjects = subjects,_schools = schools,_grades = grades;
  factory _SignupRequest.fromJson(Map<String, dynamic> json) => _$SignupRequestFromJson(json);

@override final  String email;
@override final  String password;
@override final  String name;
@override@JsonKey(name: 'group_name') final  String? groupName;
 final  List<String> _subjects;
@override List<String> get subjects {
  if (_subjects is EqualUnmodifiableListView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subjects);
}

@override final  String governorate;
@override@JsonKey(name: 'educational_administration') final  String educationalAdministration;
@override@JsonKey(name: 'whatsapp_number') final  String whatsappNumber;
 final  List<String> _schools;
@override List<String> get schools {
  if (_schools is EqualUnmodifiableListView) return _schools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_schools);
}

 final  List<String>? _grades;
@override List<String>? get grades {
  final value = _grades;
  if (value == null) return null;
  if (_grades is EqualUnmodifiableListView) return _grades;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SignupRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignupRequestCopyWith<_SignupRequest> get copyWith => __$SignupRequestCopyWithImpl<_SignupRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignupRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignupRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.name, name) || other.name == name)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&const DeepCollectionEquality().equals(other._subjects, _subjects)&&(identical(other.governorate, governorate) || other.governorate == governorate)&&(identical(other.educationalAdministration, educationalAdministration) || other.educationalAdministration == educationalAdministration)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&const DeepCollectionEquality().equals(other._schools, _schools)&&const DeepCollectionEquality().equals(other._grades, _grades));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,name,groupName,const DeepCollectionEquality().hash(_subjects),governorate,educationalAdministration,whatsappNumber,const DeepCollectionEquality().hash(_schools),const DeepCollectionEquality().hash(_grades));

@override
String toString() {
  return 'SignupRequest(email: $email, password: $password, name: $name, groupName: $groupName, subjects: $subjects, governorate: $governorate, educationalAdministration: $educationalAdministration, whatsappNumber: $whatsappNumber, schools: $schools, grades: $grades)';
}


}

/// @nodoc
abstract mixin class _$SignupRequestCopyWith<$Res> implements $SignupRequestCopyWith<$Res> {
  factory _$SignupRequestCopyWith(_SignupRequest value, $Res Function(_SignupRequest) _then) = __$SignupRequestCopyWithImpl;
@override @useResult
$Res call({
 String email, String password, String name,@JsonKey(name: 'group_name') String? groupName, List<String> subjects, String governorate,@JsonKey(name: 'educational_administration') String educationalAdministration,@JsonKey(name: 'whatsapp_number') String whatsappNumber, List<String> schools, List<String>? grades
});




}
/// @nodoc
class __$SignupRequestCopyWithImpl<$Res>
    implements _$SignupRequestCopyWith<$Res> {
  __$SignupRequestCopyWithImpl(this._self, this._then);

  final _SignupRequest _self;
  final $Res Function(_SignupRequest) _then;

/// Create a copy of SignupRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? name = null,Object? groupName = freezed,Object? subjects = null,Object? governorate = null,Object? educationalAdministration = null,Object? whatsappNumber = null,Object? schools = null,Object? grades = freezed,}) {
  return _then(_SignupRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,governorate: null == governorate ? _self.governorate : governorate // ignore: cast_nullable_to_non_nullable
as String,educationalAdministration: null == educationalAdministration ? _self.educationalAdministration : educationalAdministration // ignore: cast_nullable_to_non_nullable
as String,whatsappNumber: null == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String,schools: null == schools ? _self._schools : schools // ignore: cast_nullable_to_non_nullable
as List<String>,grades: freezed == grades ? _self._grades : grades // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
