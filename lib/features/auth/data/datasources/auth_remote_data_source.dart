import 'package:injectable/injectable.dart';
import 'package:moalem/core/exceptions.dart';
import 'package:moalem/core/services/api_service.dart';
import 'package:moalem/features/auth/data/models/signup_request.dart';
import 'package:moalem/features/auth/data/models/token_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenModel> signIn(String email, String password);
  Future<TokenModel> signUp(SignupRequest request);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiService _apiService;

  AuthRemoteDataSourceImpl(this._apiService);

  @override
  Future<TokenModel> signIn(String email, String password) async {
    final response = await _apiService.signIn({
      'email': email,
      'password': password,
    });
    if (response.data != null) {
      return response.data!;
    }
    throw ServerException(response.message, response.status);
  }

  @override
  Future<TokenModel> signUp(SignupRequest request) async {
    final response = await _apiService.signUp(request);
    if (response.data != null) {
      return response.data!;
    }
    throw ServerException(response.message, response.status);
  }
}
