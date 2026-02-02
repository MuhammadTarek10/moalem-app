// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_print_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrPrintState {

 AsyncValue<List<ClassEntity>> get classes; String? get selectedClassId; AsyncValue<List<StudentEntity>> get students; Set<String> get selectedStudentIds; bool get isExportingPdf; String? get exportMessage;
/// Create a copy of QrPrintState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrPrintStateCopyWith<QrPrintState> get copyWith => _$QrPrintStateCopyWithImpl<QrPrintState>(this as QrPrintState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrPrintState&&(identical(other.classes, classes) || other.classes == classes)&&(identical(other.selectedClassId, selectedClassId) || other.selectedClassId == selectedClassId)&&(identical(other.students, students) || other.students == students)&&const DeepCollectionEquality().equals(other.selectedStudentIds, selectedStudentIds)&&(identical(other.isExportingPdf, isExportingPdf) || other.isExportingPdf == isExportingPdf)&&(identical(other.exportMessage, exportMessage) || other.exportMessage == exportMessage));
}


@override
int get hashCode => Object.hash(runtimeType,classes,selectedClassId,students,const DeepCollectionEquality().hash(selectedStudentIds),isExportingPdf,exportMessage);

@override
String toString() {
  return 'QrPrintState(classes: $classes, selectedClassId: $selectedClassId, students: $students, selectedStudentIds: $selectedStudentIds, isExportingPdf: $isExportingPdf, exportMessage: $exportMessage)';
}


}

/// @nodoc
abstract mixin class $QrPrintStateCopyWith<$Res>  {
  factory $QrPrintStateCopyWith(QrPrintState value, $Res Function(QrPrintState) _then) = _$QrPrintStateCopyWithImpl;
@useResult
$Res call({
 AsyncValue<List<ClassEntity>> classes, String? selectedClassId, AsyncValue<List<StudentEntity>> students, Set<String> selectedStudentIds, bool isExportingPdf, String? exportMessage
});




}
/// @nodoc
class _$QrPrintStateCopyWithImpl<$Res>
    implements $QrPrintStateCopyWith<$Res> {
  _$QrPrintStateCopyWithImpl(this._self, this._then);

  final QrPrintState _self;
  final $Res Function(QrPrintState) _then;

/// Create a copy of QrPrintState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classes = null,Object? selectedClassId = freezed,Object? students = null,Object? selectedStudentIds = null,Object? isExportingPdf = null,Object? exportMessage = freezed,}) {
  return _then(_self.copyWith(
classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<ClassEntity>>,selectedClassId: freezed == selectedClassId ? _self.selectedClassId : selectedClassId // ignore: cast_nullable_to_non_nullable
as String?,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<StudentEntity>>,selectedStudentIds: null == selectedStudentIds ? _self.selectedStudentIds : selectedStudentIds // ignore: cast_nullable_to_non_nullable
as Set<String>,isExportingPdf: null == isExportingPdf ? _self.isExportingPdf : isExportingPdf // ignore: cast_nullable_to_non_nullable
as bool,exportMessage: freezed == exportMessage ? _self.exportMessage : exportMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QrPrintState].
extension QrPrintStatePatterns on QrPrintState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QrPrintState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QrPrintState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QrPrintState value)  $default,){
final _that = this;
switch (_that) {
case _QrPrintState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QrPrintState value)?  $default,){
final _that = this;
switch (_that) {
case _QrPrintState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AsyncValue<List<ClassEntity>> classes,  String? selectedClassId,  AsyncValue<List<StudentEntity>> students,  Set<String> selectedStudentIds,  bool isExportingPdf,  String? exportMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QrPrintState() when $default != null:
return $default(_that.classes,_that.selectedClassId,_that.students,_that.selectedStudentIds,_that.isExportingPdf,_that.exportMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AsyncValue<List<ClassEntity>> classes,  String? selectedClassId,  AsyncValue<List<StudentEntity>> students,  Set<String> selectedStudentIds,  bool isExportingPdf,  String? exportMessage)  $default,) {final _that = this;
switch (_that) {
case _QrPrintState():
return $default(_that.classes,_that.selectedClassId,_that.students,_that.selectedStudentIds,_that.isExportingPdf,_that.exportMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AsyncValue<List<ClassEntity>> classes,  String? selectedClassId,  AsyncValue<List<StudentEntity>> students,  Set<String> selectedStudentIds,  bool isExportingPdf,  String? exportMessage)?  $default,) {final _that = this;
switch (_that) {
case _QrPrintState() when $default != null:
return $default(_that.classes,_that.selectedClassId,_that.students,_that.selectedStudentIds,_that.isExportingPdf,_that.exportMessage);case _:
  return null;

}
}

}

/// @nodoc


class _QrPrintState implements QrPrintState {
  const _QrPrintState({this.classes = const AsyncLoading(), this.selectedClassId, this.students = const AsyncData([]), final  Set<String> selectedStudentIds = const <String>{}, this.isExportingPdf = false, this.exportMessage}): _selectedStudentIds = selectedStudentIds;
  

@override@JsonKey() final  AsyncValue<List<ClassEntity>> classes;
@override final  String? selectedClassId;
@override@JsonKey() final  AsyncValue<List<StudentEntity>> students;
 final  Set<String> _selectedStudentIds;
@override@JsonKey() Set<String> get selectedStudentIds {
  if (_selectedStudentIds is EqualUnmodifiableSetView) return _selectedStudentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedStudentIds);
}

@override@JsonKey() final  bool isExportingPdf;
@override final  String? exportMessage;

/// Create a copy of QrPrintState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QrPrintStateCopyWith<_QrPrintState> get copyWith => __$QrPrintStateCopyWithImpl<_QrPrintState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QrPrintState&&(identical(other.classes, classes) || other.classes == classes)&&(identical(other.selectedClassId, selectedClassId) || other.selectedClassId == selectedClassId)&&(identical(other.students, students) || other.students == students)&&const DeepCollectionEquality().equals(other._selectedStudentIds, _selectedStudentIds)&&(identical(other.isExportingPdf, isExportingPdf) || other.isExportingPdf == isExportingPdf)&&(identical(other.exportMessage, exportMessage) || other.exportMessage == exportMessage));
}


@override
int get hashCode => Object.hash(runtimeType,classes,selectedClassId,students,const DeepCollectionEquality().hash(_selectedStudentIds),isExportingPdf,exportMessage);

@override
String toString() {
  return 'QrPrintState(classes: $classes, selectedClassId: $selectedClassId, students: $students, selectedStudentIds: $selectedStudentIds, isExportingPdf: $isExportingPdf, exportMessage: $exportMessage)';
}


}

/// @nodoc
abstract mixin class _$QrPrintStateCopyWith<$Res> implements $QrPrintStateCopyWith<$Res> {
  factory _$QrPrintStateCopyWith(_QrPrintState value, $Res Function(_QrPrintState) _then) = __$QrPrintStateCopyWithImpl;
@override @useResult
$Res call({
 AsyncValue<List<ClassEntity>> classes, String? selectedClassId, AsyncValue<List<StudentEntity>> students, Set<String> selectedStudentIds, bool isExportingPdf, String? exportMessage
});




}
/// @nodoc
class __$QrPrintStateCopyWithImpl<$Res>
    implements _$QrPrintStateCopyWith<$Res> {
  __$QrPrintStateCopyWithImpl(this._self, this._then);

  final _QrPrintState _self;
  final $Res Function(_QrPrintState) _then;

/// Create a copy of QrPrintState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classes = null,Object? selectedClassId = freezed,Object? students = null,Object? selectedStudentIds = null,Object? isExportingPdf = null,Object? exportMessage = freezed,}) {
  return _then(_QrPrintState(
classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<ClassEntity>>,selectedClassId: freezed == selectedClassId ? _self.selectedClassId : selectedClassId // ignore: cast_nullable_to_non_nullable
as String?,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<StudentEntity>>,selectedStudentIds: null == selectedStudentIds ? _self._selectedStudentIds : selectedStudentIds // ignore: cast_nullable_to_non_nullable
as Set<String>,isExportingPdf: null == isExportingPdf ? _self.isExportingPdf : isExportingPdf // ignore: cast_nullable_to_non_nullable
as bool,exportMessage: freezed == exportMessage ? _self.exportMessage : exportMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
