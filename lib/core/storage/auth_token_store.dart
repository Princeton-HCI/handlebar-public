import 'package:logging/logging.dart';

import 'secure_storage.dart';

/// Store for handling auth token persistence and session checks built on top of
/// [SecureStorage]
class AuthTokenStore {
  final SecureStorage _storage;
  final _logger = Logger("AuthTokenStore");

  AuthTokenStore(this._storage);

  Future<void> init() async {
    _storage.initialize();
    _logger.info("Storage initialization successful");
  }

  /// Save the auth token and set/refresh its expiration window
  Future<void> saveAuthToken(String token) async {
    _logger.info("Storing the auth token...");
    await _storage.storage.write(key: 'handlebar_auth_token', value: token);
    _storage.accessToken = token;
    await _storage.updateTokenExpiration();
    _logger.info("Auth token storage successful");
  }

  /// Clear the auth token and stored user data
  Future<void> clearAuthToken() async => _storage.clearStoredTokens();

  /// Get the current auth token's value
  String? get token =>
      _storage.accessToken.isNotEmpty ? _storage.accessToken : null;

  bool get isExpired => _storage.isTokenExpired();

  bool get isAuthenticated => token != null && !isExpired;
}
