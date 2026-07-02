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

  @override
  String toString() => message;
}
