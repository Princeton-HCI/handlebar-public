import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';
import 'api_error.dart';

mixin ApiExecutor {
  /// Executes an API request, centralizes try/catch error handling, and standardizes logging.
  ///
  /// The [onResponse] callback should return a [Result] if it successfully handles
  /// the HTTP status code. If it returns `null`, the executor will automatically
  /// trigger `ApiClient.unhandledFailure`.
  Future<Result<T, ApiError>> executeRequest<T>({
    required String action,
    required Logger logger,
    required Future<http.Response> Function() request,
    required FutureOr<Result<T, ApiError>?> Function(http.Response res)
        onResponse,
  }) async {
    try {
      logger.info('Starting $action request...');

      final res = await request();

      // Delegate the expected status codes (200, 401, etc.) to the repository method
      final result = await onResponse(res);

      // If the repository method handled it, return that result
      if (result != null) {
        return result;
      }

      // Automatically intercept and parse 422 Validation Errors
      if (res.statusCode == 422) {
        return _handleValidationError<T>(logger, res, action);
      }

      // If onResponse returned null, it means the status code was unexpected
      return ApiClient.unhandledFailure(logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(logger, e, st, action: action);
    }
  }
}

Result<T, ApiError> _handleValidationError<T>(
  Logger logger,
  http.Response res,
  String action,
) {
  String errorMessage = "Validation failed.";

  try {
    final decoded = jsonDecode(res.body);

    // Look for the standard {"errors": {...}} structure
    if (decoded is Map<String, dynamic> && decoded.containsKey('errors')) {
      final errors = decoded['errors'] as Map<String, dynamic>;
      final List<String> formattedErrors = [];

      errors.forEach((field, messages) {
        // Capitalize the field name (e.g., "email" -> "Email")
        final cleanField = field.isNotEmpty
            ? '${field[0].toUpperCase()}${field.substring(1)}!'
            : 'Field';

        if (messages is List) {
          formattedErrors.add('$cleanField ${messages.join(' and ')}');
        } else {
          formattedErrors.add('$cleanField $messages');
        }
      });

      if (formattedErrors.isNotEmpty) {
        errorMessage = formattedErrors.join('\n');
      }
    } else if (decoded is Map<String, dynamic> &&
        decoded.containsKey('message')) {
      // Fallback for standard {"message": "..."} APIs
      errorMessage = decoded['message'];
    }
  } catch (_) {
    // If JSON parsing fails, we gracefully fall back to the generic message
    errorMessage = "Invalid data submitted!";
  }

  // Log it nicely!
  logger.warning('$action validation failed: $errorMessage');

  // Return your standard ApiError so the UI can show it in a NotificationService
  return Failure(ApiError(message: errorMessage, statusCode: 422));
}
