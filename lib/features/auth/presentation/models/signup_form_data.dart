class SignupFormData {
  // Step 1 - Credentials
  String email;
  String password;
  String confirmPassword;
  bool agreeToTerms;

  // Step 2 - Profile Info
  String fullName;
  List<String> subjects;
  String whatsappNumber;

  // Step 3 - Location Info
  String? governorate;
  String? educationalAdministration;
  List<String> schools;

  SignupFormData({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.agreeToTerms = false,
    this.fullName = '',
    this.subjects = const [],
    this.whatsappNumber = '',
    this.governorate,
    this.educationalAdministration,
    this.schools = const [],
  });

  SignupFormData copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    bool? agreeToTerms,
    String? fullName,
    List<String>? subjects,
    String? whatsappNumber,
    String? governorate,
    String? educationalAdministration,
    List<String>? schools,
  }) {
    return SignupFormData(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      agreeToTerms: agreeToTerms ?? this.agreeToTerms,
      fullName: fullName ?? this.fullName,
      subjects: subjects ?? this.subjects,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      governorate: governorate ?? this.governorate,
      educationalAdministration:
          educationalAdministration ?? this.educationalAdministration,
      schools: schools ?? this.schools,
    );
  }
}
