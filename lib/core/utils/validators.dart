import '../constants/app_constants.dart';

/// Pure validation helpers. No Flutter dependencies – easy to unit test.
class Validators {
  Validators._();

  static String? customerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Customer name is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.customerNameMinLength) {
      return 'Customer name must be at least ${AppConstants.customerNameMinLength} characters.';
    }
    if (trimmed.length > AppConstants.customerNameMaxLength) {
      return 'Customer name must not exceed ${AppConstants.customerNameMaxLength} characters.';
    }
    return null;
  }

  static String? notes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Visit notes are required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.notesMinLength) {
      return 'Notes must be at least ${AppConstants.notesMinLength} characters.';
    }
    if (trimmed.length > AppConstants.notesMaxLength) {
      return 'Notes must not exceed ${AppConstants.notesMaxLength} characters.';
    }
    return null;
  }
}
