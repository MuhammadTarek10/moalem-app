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
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? whatsappNumber,
    List<String>? subjects,
    String? governorate,
    String? educationalAdministration,
    List<String>? schools,
    List<String>? grades,
    String? licenseExpiresAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      subjects: subjects ?? this.subjects,
      governorate: governorate ?? this.governorate,
      educationalAdministration:
          educationalAdministration ?? this.educationalAdministration,
      schools: schools ?? this.schools,
      grades: grades ?? this.grades,
      licenseExpiresAt: licenseExpiresAt ?? this.licenseExpiresAt,
    );
  }
}
