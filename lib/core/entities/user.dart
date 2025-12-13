class User {
  final String? id;
  final String? email;
  final String? name;
  final String? whatsappNumber;
  final List<String> subjects;
  final String? governorate;
  final String? educationalAdministration;
  final List<String> schools;
  final List<String> grades;
  final String? licenseExpiresAt;

  const User({
    this.id,
    this.email,
    this.name,
    this.whatsappNumber,
    this.subjects = const [],
    this.governorate,
    this.educationalAdministration,
    this.schools = const [],
    this.grades = const [],
    this.licenseExpiresAt,
  });
}
