import 'package:dio/dio.dart';
import 'package:moalem/core/entities/failure.dart';
import 'package:moalem/core/extensions/failure_extensions.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is Failure) {
      return error.messageToDisplay;
    }
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
