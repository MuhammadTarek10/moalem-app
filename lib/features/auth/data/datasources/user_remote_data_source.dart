import 'package:injectable/injectable.dart';
import 'package:moalem/core/exceptions.dart';
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
    final response = await _apiService.getUser();
    if (response.data != null) {
      return response.data!;
    }
    throw ServerException(response.message, response.status);
  }

  @override
  Future<void> deleteUser() async {
    final response = await _apiService.deleteUser();
    // Ideally check response.status == 'success' here
    if (response.status != 'success' && response.data == null) {
      // Assuming 'success' is the success string, adapt as needed
      // throw ServerException(response.message, response.status);
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final response = await _apiService.updateUser(user);
    if (response.data != null) {
      return response.data!;
    }
    throw ServerException(response.message, response.status);
  }
}
