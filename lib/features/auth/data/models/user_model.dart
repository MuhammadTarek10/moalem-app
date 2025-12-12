import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    String? id,
    String? email,
    String? name,
    @JsonKey(name: 'whatsapp_number') String? whatsappNumber,
    @Default([]) List<String> subjects,
    String? governorate,
    @JsonKey(name: 'educational_administration')
    String? educationalAdministration,
    @Default([]) List<String> schools,
    @Default([]) List<String> grades,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
