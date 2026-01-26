import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/services/storage_service.dart';
import 'package:moalem/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:moalem/features/auth/data/models/user_mapper.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  UserRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<User> getUser() async {
    final user = _storageService.getString(AppKeys.user);
    if (user != null) {
      return UserModel.fromJson(jsonDecode(user)).toDomain();
    }
    return refreshUser();
  }

  @override
  Future<User> refreshUser() async {
    // 1. Fetch remote user
    final remoteUser = await _remoteDataSource.getUser();

    // 2. Get local user (if any) to preserve fields that might be null in remote
    //    (e.g., fields captured in signup but not returned/persisted by backend yet)
    UserModel? localUser;
    final localUserStr = _storageService.getString(AppKeys.user);
    if (localUserStr != null) {
      localUser = UserModel.fromJson(jsonDecode(localUserStr));
    }

    // 3. Merge: Remote takes precedence, but if remote is null/empty and local exists, keep local.
    final mergedUser = remoteUser.copyWith(
      educationalAdministration:
          remoteUser.educationalAdministration ??
          localUser?.educationalAdministration,
      governorate: remoteUser.governorate ?? localUser?.governorate,
      name: remoteUser.name ?? localUser?.name,
      // Add other fields to merge if necessary, but these are the critical ones for reports
    );

    // 4. Save merged result
    await _storageService.setString(
      AppKeys.user,
      jsonEncode(mergedUser.toJson()),
    );
    return mergedUser.toDomain();
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
