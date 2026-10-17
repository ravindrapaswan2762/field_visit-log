import 'package:flutter_test/flutter_test.dart';
import 'package:field_visit_log/sync/retry_policy.dart';
import 'package:field_visit_log/core/constants/app_constants.dart';

void main() {
  const policy = RetryPolicy();

  group('RetryPolicy.nextRetryTime', () {
    test('first retry delay is at least the initial delay', () {
      final before = DateTime.now().toUtc();
      final next = policy.nextRetryTime(0);
      final delay = next.difference(before);
      expect(
        delay.inSeconds,
        greaterThanOrEqualTo(AppConstants.initialRetryDelay.inSeconds - 1),
      );
    });

    test('second retry delay is roughly double the first', () {
      final first = policy.nextRetryTime(0);
      final second = policy.nextRetryTime(1);
      final diffSeconds = second.difference(first).inSeconds;
      // Expected: ~initialRetryDelay * 2
      expect(
        diffSeconds,
        greaterThanOrEqualTo(AppConstants.initialRetryDelay.inSeconds - 1),
      );
    });

    test('delay is capped at maxRetryDelay', () {
      final before = DateTime.now().toUtc();
      final next = policy.nextRetryTime(100); // very large attempt count
      final delay = next.difference(before);
      expect(
        delay.inSeconds,
        lessThanOrEqualTo(AppConstants.maxRetryDelay.inSeconds + 1),
      );
    });
  });

  group('RetryPolicy.isExhausted', () {
    test('returns false when under max retry count', () {
      expect(policy.isExhausted(AppConstants.maxRetryCount - 1), isFalse);
    });

    test('returns true when at max retry count', () {
      expect(policy.isExhausted(AppConstants.maxRetryCount), isTrue);
    });

    test('returns true when over max retry count', () {
      expect(policy.isExhausted(AppConstants.maxRetryCount + 5), isTrue);
    });
  });
}
