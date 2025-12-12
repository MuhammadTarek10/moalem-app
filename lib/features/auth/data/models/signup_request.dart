import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_request.freezed.dart';
part 'signup_request.g.dart';

@freezed
abstract class SignupRequest with _$SignupRequest {
  const factory SignupRequest({
    required String email,
    required String password,
    required String name,
    required List<String> subjects,
    required String governorate,
    @JsonKey(name: 'educational_administration')
    required String educationalAdministration,
    @JsonKey(name: 'whatsapp_number') required String whatsappNumber,
    required List<String> schools,
    required List<String> grades,
  }) = _SignupRequest;

  factory SignupRequest.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestFromJson(json);
}
