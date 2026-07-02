/// Typed failure passed up through repositories (no raw exceptions leaking
/// into the UI layer — keeps presentation code simple and testable).
class AppFailure {
  const AppFailure(this.message, {this.statusCode, this.isNetworkError = false});

  final String message;
  final int? statusCode;
  final bool isNetworkError;

  factory AppFailure.network() => const AppFailure(
        'No internet connection. Please check your network.',
        isNetworkError: true,
      );

  factory AppFailure.unauthorized() =>
      const AppFailure('Session expired. Please log in again.', statusCode: 401);

  factory AppFailure.fromMessage(String message, {int? statusCode}) =>
      AppFailure(message, statusCode: statusCode);

  static void logError(Object error, StackTrace? stack) {
    print('========================================');
    print('🚨 DETAILED ERROR LOGGING 🚨');
    print('Time: ${DateTime.now().toIso8601String()}');
    if (error is DioException) {
      print('--- DioException ---');
      print('Request URL: ${error.requestOptions.uri}');
      print('HTTP Method: ${error.requestOptions.method}');
      print('Headers: ${error.requestOptions.headers}');
      print('Payload: ${error.requestOptions.data}');
      print('Response Status Code: ${error.response?.statusCode}');
      print('Response Body: ${error.response?.data}');
      print('DioException Message: ${error.message}');
      print('DioException Error: ${error.error}');
      print('DioException Type: ${error.type}');
      if (error.response != null) {
        print('DioException Response: ${error.response}');
      }
    } else {
      print('--- Generic Error ---');
      print('Error Class: ${error.runtimeType}');
      print('Error String: $error');
    }
    if (stack != null) {
      print('StackTrace:\n$stack');
    }
    print('========================================');
  }

  @override
  String toString() => message;
}
