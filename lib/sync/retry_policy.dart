import '../core/constants/app_constants.dart';

/// Calculates the next retry timestamp using exponential backoff.
/// The delay is bounded by [AppConstants.maxRetryDelay].
class RetryPolicy {
  const RetryPolicy();

  /// Returns the UTC timestamp at which the next retry may occur,
  /// given that [attemptCount] previous attempts have already been made.
  DateTime nextRetryTime(int attemptCount) {
    final delay = _calculateDelay(attemptCount);
    return DateTime.now().toUtc().add(delay);
  }

  /// Returns true when the visit has exhausted all retry attempts.
  bool isExhausted(int retryCount) =>
      retryCount >= AppConstants.maxRetryCount;

  /// Calculates the delay for attempt [n] (0-indexed) using backoff.
  Duration _calculateDelay(int n) {
    final seconds = AppConstants.initialRetryDelay.inSeconds *
        _pow(AppConstants.retryBackoffMultiplier, n);
    final capped = seconds.clamp(0, AppConstants.maxRetryDelay.inSeconds);
    return Duration(seconds: capped.toInt());
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
