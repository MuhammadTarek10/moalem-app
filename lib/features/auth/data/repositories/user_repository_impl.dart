import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:moalem/features/auth/data/models/user_mapper.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  UserRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<User> getUser() async {
    final userModel = await _remoteDataSource.getUser();
    await _storageService.setString(
      AppKeys.user,
      jsonEncode(userModel.toJson()),
    );
    return userModel.toDomain();
  }

  @override
  Future<void> updateUser(User user) async {
    final userModel = user.toModel();
    final updatedUserModel = await _remoteDataSource.updateUser(userModel);
    await _storageService.setString(
      AppKeys.user,
      jsonEncode(updatedUserModel.toJson()),
    );
  }

  @override
  Future<void> deleteUser() {
    return _remoteDataSource.deleteUser();
  }
}
