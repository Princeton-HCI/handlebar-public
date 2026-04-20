import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';

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

      // If onResponse returned null, it means the status code was unexpected
      return ApiClient.unhandledFailure(logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(logger, e, st, action: action);
    }
  }
}
