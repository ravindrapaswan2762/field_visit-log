/// Typed exceptions used throughout the app.
/// Use specific subtypes so callers can handle categories explicitly.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

/// A network-level error (no connection, timeout, DNS failure).
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error. Please check your connection.']);
}

/// An HTTP response with a non-2xx status code.
class ServerException extends AppException {
  const ServerException(super.message, {required this.statusCode});
  final int statusCode;
}

/// HTTP 429 – the server asked us to back off.
class RateLimitException extends AppException {
  const RateLimitException({this.retryAfter})
      : super('Too many requests. Please wait before retrying.');
  final Duration? retryAfter;
}

/// HTTP 401/403 – permanent auth failure; do not retry blindly.
class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed.']);
}

/// HTTP 422 – validation error; do not retry.
class ValidationServerException extends AppException {
  const ValidationServerException(super.message, {this.errors = const {}});
  final Map<String, dynamic> errors;
}

/// Local database error.
class AppDatabaseException extends AppException {
  const AppDatabaseException(super.message);
}

/// General unexpected error.
class UnexpectedException extends AppException {
  const UnexpectedException([super.message = 'An unexpected error occurred.']);
}
