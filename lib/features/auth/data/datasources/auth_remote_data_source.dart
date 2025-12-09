import 'package:injectable/injectable.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String name, String email, String password);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // final ApiService _apiService;

  // AuthRemoteDataSourceImpl(this._apiService);

  @override
  Future<UserModel> signIn(String email, String password) async {
    // For now, since we don't have a real API, we can keep the mock logic
    // OR we can try to call the API service which will fail if the URL is invalid.
    // Let's implement the API call but keep the mock as fallback/commented out for dev.

    // return _apiService.login({'email': email, 'password': password});

    // Keeping Mock for now until real API is ready
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'test@test.com' && password == 'password') {
      return const UserModel(
        id: '1',
        email: 'test@test.com',
        name: 'Test User',
      );
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<UserModel> signUp(String name, String email, String password) async {
    // return _apiService.signUp({'name': name, 'email': email, 'password': password});

    // Keeping Mock
    await Future.delayed(const Duration(seconds: 2));
    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );
  }
}
