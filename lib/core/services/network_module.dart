import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/api_service.dart';

@module
abstract class NetworkModule {
  @singleton
  Dio get dio {
    final dio = Dio();
    dio.options.headers['Content-Type'] = 'application/json';
    // Add interceptors here if needed (e.g., for auth tokens)
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return dio;
  }

  @singleton
  ApiService getApiService(Dio dio) => ApiService(dio);
}
