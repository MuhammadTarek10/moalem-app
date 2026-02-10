import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/core/services/license_service.dart';
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
    // Check for license validity only if the user is authenticated (token exists)

    // Read the access token from secure storage
    final token = await _secureStorageService.read(AppKeys.accessToken);

    // If token exists, add it to the request headers
    if (token != null && token.isNotEmpty) {
      // Check license validity before proceeding with authenticated requests
      // Use Service Locator directly to avoid regenerating injection code
      if (getIt.isRegistered<LicenseService>() &&
          !getIt<LicenseService>().isLicenseValid) {
        // License expired, block request
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'License expired',
          ),
        );
      }

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
