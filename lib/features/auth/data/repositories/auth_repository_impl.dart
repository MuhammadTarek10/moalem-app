import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:moalem/features/auth/data/models/user_mapper.dart';
import 'package:moalem/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  AuthRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<User> signIn(String email, String password) async {
    final userModel = await _remoteDataSource.signIn(email, password);
    // Cache user data or token
    await _storageService.setString(AppKeys.userId, userModel.id);
    await _storageService.setBool(AppKeys.isLoggedIn, true);
    return userModel.toDomain();
  }

  @override
  Future<User> signUp(String name, String email, String password) async {
    final userModel = await _remoteDataSource.signUp(name, email, password);
    // Cache user data or token
    await _storageService.setString(AppKeys.userId, userModel.id);
    await _storageService.setBool(AppKeys.isLoggedIn, true);
    return userModel.toDomain();
  }

  @override
  Future<void> logout() async {
    await _storageService.remove(AppKeys.userId);
    await _storageService.setBool(AppKeys.isLoggedIn, false);
  }
}
