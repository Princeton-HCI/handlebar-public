import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:handlebar/core/utils/result.dart';
import 'package:http/http.dart' as http;

import '../storage/auth_token_store.dart';
import 'api_env_config.dart';

/// Thin HTTP client for interacting with the backend server that centralizes
/// the creation of headers, request timeouts,
class ApiClient {
  final AuthTokenStore _tokens;

  ApiClient(this._tokens);

  // Timeout for all HTTP calls
  static final Duration timeout = const Duration(seconds: 15);

  Future<http.Response> get(String path, {Map<String, String>? headers}) =>
      _wrap(http.get(_uri(path), headers: _headers(headers)));

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

  /// Extracts the authentication token from a server response if it exists
  static String extractAuthToken(http.Response res) {
    final authHeader = res.headers['authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      // Remove "Bearer" prefix
      return authHeader.substring(7);
    }

    return '';
  }

  /// Formats an HTTP error response
  static String errorMessage(http.Response res) =>
      'HTTP ${res.statusCode}: ${res.body}';

  static bool isUnauthorized(http.Response res) => res.statusCode == 401;
}

/// Exception for client-side API failures from no HTTP response
class ApiException implements Exception {
  final String message;
  const ApiException._(this.message);
  const ApiException.timeout() : this._("Server timeout");
  const ApiException.network() : this._("Network unreachable");
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
