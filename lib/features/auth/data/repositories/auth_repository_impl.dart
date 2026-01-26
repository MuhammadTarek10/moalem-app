import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/entities/tokens.dart';
import 'package:moalem/core/services/secure_storage_service.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:moalem/features/auth/data/models/signup_request.dart';
import 'package:moalem/features/auth/data/models/token_mapper.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';
import 'package:moalem/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final SecureStorageService _secureStorageService;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._storageService,
    this._secureStorageService,
  );

  @override
  Future<Tokens> signIn(String email, String password) async {
    final tokenModel = await _remoteDataSource.signIn(email, password);
    // Cache user data or token
    await _secureStorageService.write(
      key: AppKeys.accessToken,
      value: tokenModel.accessToken,
    );
    await _secureStorageService.write(
      key: AppKeys.refreshToken,
      value: tokenModel.refreshToken,
    );
    await _storageService.setBool(AppKeys.isLoggedIn, true);
    return tokenModel.toDomain();
  }

  @override
  Future<Tokens> signUp(SignupRequest request) async {
    // Cache the user data entered during signup immediately
    // This ensures we have the data (especially administration) even if the server response is incomplete
    final userModel = UserModel(
      email: request.email,
      name: request.name,
      whatsappNumber: request.whatsappNumber,
      subjects: request.subjects,
      governorate: request.governorate,
      educationalAdministration: request.educationalAdministration,
      schools: request.schools,
      grades: request.grades,
    );

    await _storageService.setString(
      AppKeys.user,
      jsonEncode(userModel.toJson()),
    );

    final tokenModel = await _remoteDataSource.signUp(request);
    // Cache user data or token
    await _secureStorageService.write(
      key: AppKeys.accessToken,
      value: tokenModel.accessToken,
    );
    await _secureStorageService.write(
      key: AppKeys.refreshToken,
      value: tokenModel.refreshToken,
    );
    await _storageService.setBool(AppKeys.isLoggedIn, true);
    return tokenModel.toDomain();
  }

  @override
  Future<void> signOut() async {
    await _storageService.remove(AppKeys.userId);
    await _storageService.setBool(AppKeys.isLoggedIn, false);
  }
}
