import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/services/secure_storage_service.dart';

@singleton
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorageService;

  AuthInterceptor(this._secureStorageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Read the access token from secure storage
    final token = await _secureStorageService.read(AppKeys.accessToken);

    // If token exists, add it to the request headers
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // You can add token refresh logic here if needed
    // For example, if you get a 401, refresh the token and retry
    super.onError(err, handler);
  }
}
