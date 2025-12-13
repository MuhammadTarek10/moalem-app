// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['_id'] as String?,
  email: json['email'] as String?,
  name: json['name'] as String?,
  whatsappNumber: json['whatsapp_number'] as String?,
  subjects:
      (json['subjects'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  governorate: json['governorate'] as String?,
  educationalAdministration: json['educational_administration'] as String?,
  schools:
      (json['schools'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  grades:
      (json['grades'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  licenseExpiresAt: json['license_expires_at'] as String?,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'whatsapp_number': instance.whatsappNumber,
      'subjects': instance.subjects,
      'governorate': instance.governorate,
      'educational_administration': instance.educationalAdministration,
      'schools': instance.schools,
      'grades': instance.grades,
      'license_expires_at': instance.licenseExpiresAt,
    };
