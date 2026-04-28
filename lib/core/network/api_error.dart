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
