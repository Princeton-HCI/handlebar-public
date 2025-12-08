import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:handlebar/core/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../storage/auth_token_store.dart';
import 'api_env_config.dart';

/// Thin HTTP client for interacting with the backend server that centralizes
/// the creation of headers, request timeouts,
class ApiClient {
  final AuthTokenStore _tokens;

  ApiClient(this._tokens);

  // ==== HTTP FUNCTIONALITY ====

  static final Duration timeout = const Duration(seconds: 15);

  Future<http.Response> get(String path,
      {Map<String, String>? headers, Map<String, String>? queryParameters}) {
    final baseUri = _uri(path);
    final finalUri = baseUri.replace(queryParameters: queryParameters);
    return _wrap(http.get(finalUri, headers: _headers(headers)));
  }

  Future<http.Response> post(String path,
          {Object? body, Map<String, String>? headers}) =>
      _wrap(http.post(_uri(path),
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body)));

  Future<http.Response> patch(String path,
          {Object? body, Map<String, String>? headers}) =>
      _wrap(http.patch(_uri(path),
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body)));

  Future<http.Response> delete(String path,
          {Object? body, Map<String, String>? headers}) =>
      _wrap(http.delete(_uri(path),
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body)));

  Uri _uri(String path) => Uri.parse('${ApiEnvConfig.baseUrl}$path');

  /// Builds JSON headers
  Map<String, String> _headers([Map<String, String>? extra]) {
    final header = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (_tokens.token != null) 'authorization': 'Bearer ${_tokens.token}',
    };
    if (extra != null) header.addAll(extra);
    return header;
  }

  /// Applies a global timeout and converts socket/timeout errors to ApiException
  Future<http.Response> _wrap(call) async {
    try {
      return await call.timeout(timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    }
  }

  // ==== API HELPERS ====

  /// Extracts the authentication token from a server response if it exists
  static String extractAuthToken(http.Response res) {
    final authHeader = res.headers['authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      // Remove "Bearer" prefix
      return authHeader.substring(7);
    }

    return '';
  }

  static Map<String, String> buildPaginationParams(String? cursor, int? limit) {
    final params = <String, String>{};
    if (cursor != null) params['after'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    return params;
  }

  /// 401 = not authenticated / token missing/bad
  static bool isUnauthorized(http.Response res) => res.statusCode == 401;

  /// 403 = authenticated but not allowed (role / group)
  static bool isForbidden(http.Response res) => res.statusCode == 403;

  static Failure<T, ApiError> unauthorizedFailure<T>(
    Logger logger, {
    required String action,
  }) {
    logger.info('$action failed - unauthorized (401)');
    return const Failure(ApiError(
      message: 'You are not authenticated. Please sign up or log in.',
      statusCode: 401,
    ));
  }

  static Failure<T, ApiError> forbiddenFailure<T>(
    Logger logger, {
    required String action,
  }) {
    logger.info('$action failed - forbidden (403)');
    return const Failure(
      ApiError(
        message: 'You do not have permission to perform this action.',
        statusCode: 403,
      ),
    );
  }

  static Failure<T, ApiError> unhandledFailure<T>(
    Logger logger,
    http.Response res, {
    required String action,
  }) {
    final msg = errorMessage(res);
    logger.severe('$action failed - unhandled $msg');
    return Failure(ApiError(
        message: "An unexpected error occurred", statusCode: res.statusCode));
  }

  static Failure<T, ApiError> connectionFailure<T>(
    Logger logger,
    ApiException e, {
    required String action,
  }) {
    logger.severe('$action failed - ${e.message}');
    return Failure(ApiError(message: e.message));
  }

  static Failure<T, ApiError> unexpectedFailure<T>(
    Logger logger,
    Object e,
    StackTrace st, {
    required String action,
  }) {
    logger.severe('$action failed - unexpected: $e', e, st);
    return const Failure(ApiError(message: 'Unexpected error'));
  }

  /// Formats an HTTP error response
  static String errorMessage(http.Response res) =>
      'HTTP ${res.statusCode}: ${res.body}';
}

/// Exception for client-side API failures from no HTTP response
class ApiException implements Exception {
  final String message;
  const ApiException._(this.message);
  const ApiException.timeout() : this._("The connection has timed out");
  const ApiException.network() : this._("The network is unreachable");
  @override
  String toString() => message;
}

/// Error value returned in [Failure] for server-side or translated errors
class ApiError {
  final String message;
  final int? statusCode; // null for client-side (no HTTP response)
  const ApiError({required this.message, this.statusCode});
  @override
  String toString() => 'ApiError($message, status: $statusCode)';
}
