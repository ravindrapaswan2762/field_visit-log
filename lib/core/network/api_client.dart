import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Low-level HTTP client. Adds timeout, JSON headers, and translates
/// status codes into typed [AppException]s.
/// IMPORTANT: Never log request bodies that may contain customer data.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    try {
      final response = await _client
          .post(uri, headers: requestHeaders, body: jsonEncode(body))
          .timeout(AppConstants.httpTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on HttpException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Request timed out.');
    } on FormatException catch (e) {
      throw UnexpectedException('Invalid server response: ${e.message}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode == 200 || statusCode == 201) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    switch (statusCode) {
      case 401:
      case 403:
        throw const AuthException();
      case 422:
        final errors = body['errors'] as Map<String, dynamic>? ?? {};
        final message = body['message'] as String? ?? 'Validation failed.';
        throw ValidationServerException(message, errors: errors);
      case 429:
        final retryAfterSec = response.headers['retry-after'];
        Duration? retryAfter;
        if (retryAfterSec != null) {
          final seconds = int.tryParse(retryAfterSec);
          if (seconds != null) retryAfter = Duration(seconds: seconds);
        }
        throw RateLimitException(retryAfter: retryAfter);
      default:
        if (statusCode >= 500) {
          throw ServerException(
            body['message'] as String? ?? 'Server error.',
            statusCode: statusCode,
          );
        }
        throw ServerException(
          'Unexpected status code $statusCode.',
          statusCode: statusCode,
        );
    }
  }
}
