import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../models/auth_session.dart';
import '../../../core/shared_services/device_info_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_store.dart';
import '../../../core/storage/secure_storage.dart';

typedef AuthResult = Result<AuthSession, ApiError>;

/// Handles user authentication data operations
class AuthRepository {
  final ApiClient _api;
  final AuthTokenStore _tokens;
  final SecureStorage _storage;
  final DeviceInfoService _device;

  final _logger = Logger("AuthRepository");

  AuthRepository(this._api, this._tokens, this._storage, this._device);

  /// Signs a user up for Handlebar and immediately logs them in
  Future<AuthResult> signup(String email, String password,
      {String? referral}) async {
    try {
      _logger.info("Starting signup request...");
      final body = {
        "user": {
          "email": email,
          "password": password,
          "referral_code": referral,
          "source": "app",
          "timezone_device": await _device.timezone(),
          "language_code": _device.languageCode(),
          "device_platform": await _device.platformString(),
        }
      };

      final res = await _api.post('/api/users', body: body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logger.info("Registration successful");
        // Auto-login the newly created user
        return login(email, password);
      }

      // Unhandled result
      final errorMsg = ApiClient.errorMessage(res);
      _logger.severe("Registration failed - $errorMsg");
      return Failure(ApiError(
        message: errorMsg,
        statusCode: res.statusCode,
      ));
    } on ApiException catch (e) {
      _logger.severe("Registration failed - ${e.message}");
      return Failure(ApiError(message: e.message));
    } catch (e, st) {
      _logger.severe("Registration failed - unexpected: $e", st);
      return const Failure(ApiError(message: "Unexpected error"));
    }
  }

  /// Logs a user in to Handlebar
  Future<AuthResult> login(String email, String password) async {
    try {
      _logger.info("Starting login request...");
      final res = await _api.post('/api/sessions', body: {
        "session": {"email": email, "password": password}
      });

      if (res.statusCode == 401) {
        _logger.info("Login failed - 401 User not found");
        return Failure(ApiError(message: "User not found", statusCode: 401));
      }

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final userData = map['data'] as Map<String, dynamic>?;

        if (userData != null) {
          final token = ApiClient.extractAuthToken(res);

          if (token.isNotEmpty) {
            // Persist the auth token
            await _tokens.saveAuthToken(token);
          }
          await _saveUserData(userData);

          _logger.info("Login successful");
          return Success(AuthSession(token: token, userData: userData));
        }

        _logger.info("Login failed - No user data found");
        return Failure(ApiError(message: "No user data found"));
      }

      // Unhandled result
      final errorMsg = ApiClient.errorMessage(res);
      _logger.severe("Login failed - $errorMsg");
      return Failure(ApiError(
        message: errorMsg,
        statusCode: res.statusCode,
      ));
    } on ApiException catch (e) {
      _logger.severe("Login failed - ${e.message}");
      return Failure(ApiError(message: e.message));
    } catch (e, st) {
      _logger.severe("Login failed - unexpected: $e", st);
      return const Failure(ApiError(message: "Unexpected error"));
    }
  }

  /// Logs a user out of Handlebar
  Future<void> logout() async => _tokens.clearAuthToken();

  /// Saves minimal user data to secure storage
  Future<void> _saveUserData(Map<String, dynamic> user) async {
    try {
      _logger.info("Starting to save user data...");
      final toSave = {
        'handlebar_user_id': user['id']?.toString(),
        'handlebar_first_name': user['first_name'],
        'handlebar_last_name': user['last_name'],
        'handlebar_email': user['email'],
      };
      for (final entry in toSave.entries) {
        if (entry.value != null) {
          await _storage.storage.write(key: entry.key, value: entry.value!);
        }
      }
      if (user['email'] != null) _storage.email = user['email'];
      _logger.info("Save user data successful");
    } catch (e, st) {
      _logger.warning("Save user data failed: ${e.toString()}", st);
    }
  }
}
