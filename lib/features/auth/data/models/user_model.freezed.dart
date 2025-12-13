// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

@JsonKey(name: '_id') String? get id; String? get email; String? get name;@JsonKey(name: 'whatsapp_number') String? get whatsappNumber; List<String> get subjects; String? get governorate;@JsonKey(name: 'educational_administration') String? get educationalAdministration; List<String> get schools; List<String> get grades;@JsonKey(name: 'license_expires_at') String? get licenseExpiresAt;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&const DeepCollectionEquality().equals(other.subjects, subjects)&&(identical(other.governorate, governorate) || other.governorate == governorate)&&(identical(other.educationalAdministration, educationalAdministration) || other.educationalAdministration == educationalAdministration)&&const DeepCollectionEquality().equals(other.schools, schools)&&const DeepCollectionEquality().equals(other.grades, grades)&&(identical(other.licenseExpiresAt, licenseExpiresAt) || other.licenseExpiresAt == licenseExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,name,whatsappNumber,const DeepCollectionEquality().hash(subjects),governorate,educationalAdministration,const DeepCollectionEquality().hash(schools),const DeepCollectionEquality().hash(grades),licenseExpiresAt);

@override
String toString() {
  return 'UserModel(id: $id, email: $email, name: $name, whatsappNumber: $whatsappNumber, subjects: $subjects, governorate: $governorate, educationalAdministration: $educationalAdministration, schools: $schools, grades: $grades, licenseExpiresAt: $licenseExpiresAt)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String? id, String? email, String? name,@JsonKey(name: 'whatsapp_number') String? whatsappNumber, List<String> subjects, String? governorate,@JsonKey(name: 'educational_administration') String? educationalAdministration, List<String> schools, List<String> grades,@JsonKey(name: 'license_expires_at') String? licenseExpiresAt
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? email = freezed,Object? name = freezed,Object? whatsappNumber = freezed,Object? subjects = null,Object? governorate = freezed,Object? educationalAdministration = freezed,Object? schools = null,Object? grades = null,Object? licenseExpiresAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,whatsappNumber: freezed == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String?,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,governorate: freezed == governorate ? _self.governorate : governorate // ignore: cast_nullable_to_non_nullable
as String?,educationalAdministration: freezed == educationalAdministration ? _self.educationalAdministration : educationalAdministration // ignore: cast_nullable_to_non_nullable
as String?,schools: null == schools ? _self.schools : schools // ignore: cast_nullable_to_non_nullable
as List<String>,grades: null == grades ? _self.grades : grades // ignore: cast_nullable_to_non_nullable
as List<String>,licenseExpiresAt: freezed == licenseExpiresAt ? _self.licenseExpiresAt : licenseExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String? email,  String? name, @JsonKey(name: 'whatsapp_number')  String? whatsappNumber,  List<String> subjects,  String? governorate, @JsonKey(name: 'educational_administration')  String? educationalAdministration,  List<String> schools,  List<String> grades, @JsonKey(name: 'license_expires_at')  String? licenseExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.email,_that.name,_that.whatsappNumber,_that.subjects,_that.governorate,_that.educationalAdministration,_that.schools,_that.grades,_that.licenseExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String? email,  String? name, @JsonKey(name: 'whatsapp_number')  String? whatsappNumber,  List<String> subjects,  String? governorate, @JsonKey(name: 'educational_administration')  String? educationalAdministration,  List<String> schools,  List<String> grades, @JsonKey(name: 'license_expires_at')  String? licenseExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.email,_that.name,_that.whatsappNumber,_that.subjects,_that.governorate,_that.educationalAdministration,_that.schools,_that.grades,_that.licenseExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String? id,  String? email,  String? name, @JsonKey(name: 'whatsapp_number')  String? whatsappNumber,  List<String> subjects,  String? governorate, @JsonKey(name: 'educational_administration')  String? educationalAdministration,  List<String> schools,  List<String> grades, @JsonKey(name: 'license_expires_at')  String? licenseExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.email,_that.name,_that.whatsappNumber,_that.subjects,_that.governorate,_that.educationalAdministration,_that.schools,_that.grades,_that.licenseExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({@JsonKey(name: '_id') this.id, this.email, this.name, @JsonKey(name: 'whatsapp_number') this.whatsappNumber, final  List<String> subjects = const [], this.governorate, @JsonKey(name: 'educational_administration') this.educationalAdministration, final  List<String> schools = const [], final  List<String> grades = const [], @JsonKey(name: 'license_expires_at') this.licenseExpiresAt}): _subjects = subjects,_schools = schools,_grades = grades;
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override@JsonKey(name: '_id') final  String? id;
@override final  String? email;
@override final  String? name;
@override@JsonKey(name: 'whatsapp_number') final  String? whatsappNumber;
 final  List<String> _subjects;
@override@JsonKey() List<String> get subjects {
  if (_subjects is EqualUnmodifiableListView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subjects);
}

@override final  String? governorate;
@override@JsonKey(name: 'educational_administration') final  String? educationalAdministration;
 final  List<String> _schools;
@override@JsonKey() List<String> get schools {
  if (_schools is EqualUnmodifiableListView) return _schools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_schools);
}

 final  List<String> _grades;
@override@JsonKey() List<String> get grades {
  if (_grades is EqualUnmodifiableListView) return _grades;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_grades);
}

@override@JsonKey(name: 'license_expires_at') final  String? licenseExpiresAt;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&const DeepCollectionEquality().equals(other._subjects, _subjects)&&(identical(other.governorate, governorate) || other.governorate == governorate)&&(identical(other.educationalAdministration, educationalAdministration) || other.educationalAdministration == educationalAdministration)&&const DeepCollectionEquality().equals(other._schools, _schools)&&const DeepCollectionEquality().equals(other._grades, _grades)&&(identical(other.licenseExpiresAt, licenseExpiresAt) || other.licenseExpiresAt == licenseExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,name,whatsappNumber,const DeepCollectionEquality().hash(_subjects),governorate,educationalAdministration,const DeepCollectionEquality().hash(_schools),const DeepCollectionEquality().hash(_grades),licenseExpiresAt);

@override
String toString() {
  return 'UserModel(id: $id, email: $email, name: $name, whatsappNumber: $whatsappNumber, subjects: $subjects, governorate: $governorate, educationalAdministration: $educationalAdministration, schools: $schools, grades: $grades, licenseExpiresAt: $licenseExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String? id, String? email, String? name,@JsonKey(name: 'whatsapp_number') String? whatsappNumber, List<String> subjects, String? governorate,@JsonKey(name: 'educational_administration') String? educationalAdministration, List<String> schools, List<String> grades,@JsonKey(name: 'license_expires_at') String? licenseExpiresAt
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? email = freezed,Object? name = freezed,Object? whatsappNumber = freezed,Object? subjects = null,Object? governorate = freezed,Object? educationalAdministration = freezed,Object? schools = null,Object? grades = null,Object? licenseExpiresAt = freezed,}) {
  return _then(_UserModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,whatsappNumber: freezed == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String?,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,governorate: freezed == governorate ? _self.governorate : governorate // ignore: cast_nullable_to_non_nullable
as String?,educationalAdministration: freezed == educationalAdministration ? _self.educationalAdministration : educationalAdministration // ignore: cast_nullable_to_non_nullable
as String?,schools: null == schools ? _self._schools : schools // ignore: cast_nullable_to_non_nullable
as List<String>,grades: null == grades ? _self._grades : grades // ignore: cast_nullable_to_non_nullable
as List<String>,licenseExpiresAt: freezed == licenseExpiresAt ? _self.licenseExpiresAt : licenseExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
