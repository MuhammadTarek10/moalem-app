import 'package:injectable/injectable.dart';
import 'package:moalem/features/auth/data/models/token_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenModel> signIn(String email, String password);
  Future<TokenModel> signUp(String name, String email, String password);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // final ApiService _apiService;

  // AuthRemoteDataSourceImpl(this._apiService);

  @override
  Future<TokenModel> signIn(String email, String password) async {
    // For now, since we don't have a real API, we can keep the mock logic
    // OR we can try to call the API service which will fail if the URL is invalid.
    // Let's implement the API call but keep the mock as fallback/commented out for dev.

    // return _apiService.login({'email': email, 'password': password});

    // Keeping Mock for now until real API is ready
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'test@test.com' && password == 'password') {
      return const TokenModel(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
      );
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<TokenModel> signUp(String name, String email, String password) async {
    // return _apiService.signUp({'name': name, 'email': email, 'password': password});

    // Keeping Mock
    await Future.delayed(const Duration(seconds: 2));
    return TokenModel(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
    );
  }
}
