// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenModel _$TokenModelFromJson(Map<String, dynamic> json) => _TokenModel(
  accessToken: json['access_token'] as String?,
  refreshToken: json['refresh_token'] as String?,
);

Map<String, dynamic> _$TokenModelToJson(_TokenModel instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };
