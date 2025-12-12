import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/api_service.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUser();
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser();
}

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiService _apiService;
  UserRemoteDataSourceImpl(this._apiService);

  @override
  Future<UserModel> getUser() async {
    return _apiService.getUser();
  }

  @override
  Future<void> deleteUser() {
    return _apiService.deleteUser();
  }

  @override
  Future<UserModel> updateUser(UserModel user) {
    return _apiService.updateUser(user);
  }
}
