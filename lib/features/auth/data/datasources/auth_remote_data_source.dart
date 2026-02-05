import 'package:dio/dio.dart';
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
    try {
      final response = await _apiService.signIn({
        'email': email,
        'password': password,
      });
      if (response.data != null) {
        return response.data!;
      }
      throw ServerException(response.message, response.status);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TokenModel> signUp(SignupRequest request) async {
    try {
      final response = await _apiService.signUp(request);
      if (response.data != null) {
        return response.data!;
      }
      throw ServerException(response.message, response.status);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ServerException _handleDioError(DioException error) {
    if (error.response?.data != null && error.response!.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;

      // Check for nested data.message
      if (data.containsKey('data') && data['data'] is Map) {
        final innerData = data['data'] as Map<String, dynamic>;
        if (innerData.containsKey('message')) {
          final message = innerData['message'];
          if (message is List) {
            return ServerException(message.join('\n'));
          } else if (message is String) {
            return ServerException(message);
          }
        }
      }

      // Check for top-level message
      if (data.containsKey('message')) {
        return ServerException(data['message'].toString());
      }
    }

    // Fallback to default error message
    return ServerException(
      error.message ?? 'Something went wrong, please try again later',
    );
  }
}
