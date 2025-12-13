import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data != null && data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }
    }
    return error.toString();
  }
}
