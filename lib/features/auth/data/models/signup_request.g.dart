// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignupRequest _$SignupRequestFromJson(
  Map<String, dynamic> json,
) => _SignupRequest(
  email: json['email'] as String,
  password: json['password'] as String,
  name: json['name'] as String,
  groupName: json['group_name'] as String?,
  subjects: (json['subjects'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  governorate: json['governorate'] as String,
  educationalAdministration: json['educational_administration'] as String,
  whatsappNumber: json['whatsapp_number'] as String,
  schools: (json['schools'] as List<dynamic>).map((e) => e as String).toList(),
  grades: (json['grades'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$SignupRequestToJson(_SignupRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'group_name': instance.groupName,
      'subjects': instance.subjects,
      'governorate': instance.governorate,
      'educational_administration': instance.educationalAdministration,
      'whatsapp_number': instance.whatsappNumber,
      'schools': instance.schools,
      'grades': instance.grades,
    };
