import 'package:moalem/core/entities/user.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';

extension UserMapper on UserModel {
  User toDomain() {
    return User(
      id: id,
      email: email,
      name: name,
      whatsappNumber: whatsappNumber,
      subjects: subjects,
      governorate: governorate,
      educationalAdministration: educationalAdministration,
      schools: schools,
      grades: grades,
      licenseExpiresAt: licenseExpiresAt,
    );
  }
}

extension UserMapperToModel on User {
  UserModel toModel() {
    return UserModel(
      id: id,
      email: email,
      name: name,
      whatsappNumber: whatsappNumber,
      subjects: subjects,
      governorate: governorate,
      educationalAdministration: educationalAdministration,
      schools: schools,
      grades: grades,
      licenseExpiresAt: licenseExpiresAt,
    );
  }
}
