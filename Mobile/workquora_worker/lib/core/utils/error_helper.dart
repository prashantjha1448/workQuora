import 'package:dio/dio.dart';

// Shared error-message extractor for the providers/screens added in this
// batch. auth_provider.dart already has its own private _parseError — left
// untouched; this is a separate utility for everything new.
class ErrorHelper {
  static String extract(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Something went wrong';
    }
    return error.toString();
  }
}
