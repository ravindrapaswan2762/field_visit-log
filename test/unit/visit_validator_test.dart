import 'package:flutter_test/flutter_test.dart';
import 'package:field_visit_log/core/utils/validators.dart';

void main() {
  group('Validators.customerName', () {
    test('returns error when null', () {
      expect(Validators.customerName(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.customerName(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(Validators.customerName('A'), isNotNull);
    });

    test('accepts minimum valid length', () {
      expect(Validators.customerName('Jo'), isNull);
    });

    test('accepts a normal name', () {
      expect(Validators.customerName('Jane Doe'), isNull);
    });

    test('returns error when too long', () {
      expect(Validators.customerName('A' * 81), isNotNull);
    });

    test('accepts exactly 80 characters', () {
      expect(Validators.customerName('A' * 80), isNull);
    });

    test('trims whitespace before validating length', () {
      // "  A  " is only 1 real char — should fail min length.
      expect(Validators.customerName('  A  '), isNotNull);
    });
  });

  group('Validators.notes', () {
    test('returns error when null', () {
      expect(Validators.notes(null), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.notes(''), isNotNull);
    });

    test('returns error when too short', () {
      expect(Validators.notes('Hi'), isNotNull);
    });

    test('accepts minimum valid length', () {
      expect(Validators.notes('Hello'), isNull);
    });

    test('accepts normal notes', () {
      expect(Validators.notes('Customer requested a callback next week.'), isNull);
    });

    test('returns error when notes exceed 500 characters', () {
      expect(Validators.notes('A' * 501), isNotNull);
    });

    test('accepts exactly 500 characters', () {
      expect(Validators.notes('A' * 500), isNull);
    });
  });
}
