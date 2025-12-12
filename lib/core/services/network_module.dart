import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/api_service.dart';
import 'package:moalem/core/services/auth_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(AuthInterceptor authInterceptor) {
    final dio = Dio();
    dio.options.headers['Content-Type'] = 'application/json';

    // Add auth interceptor first to attach tokens to requests
    dio.interceptors.add(authInterceptor);

    // Add pretty logger for better debugging
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    return dio;
  }

  @lazySingleton
  ApiService apiService(Dio dio) => ApiService(dio);
}
