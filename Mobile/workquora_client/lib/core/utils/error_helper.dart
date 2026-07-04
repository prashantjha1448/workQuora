import 'package:dio/dio.dart';

class ErrorHelper {
  static String extractError(dynamic error) {
    if (error is DioException) {
      return error.response?.data?['message'] ?? error.message ?? 'Something went wrong';
    }
    return error.toString();
  }
}
