import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../app/app_locator.dart';
import '../../../core/utils/result.dart';
import '../../crepe/services/collector_service.dart';
import '../models/auth_session.dart';
import '../../../core/shared_services/device_info_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_store.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/api_executor.dart';

typedef AuthResult = Result<AuthSession, ApiError>;

class AuthRepository with ApiExecutor {
  final ApiClient _api;
  final AuthTokenStore _tokens;
  final SecureStorage _storage;
  final DeviceInfoService _device;

  final _logger = Logger("AuthRepository");

  AuthRepository(this._api, this._tokens, this._storage, this._device);

  /// Signs a user up for Handlebar and immediately logs them in
  Future<AuthResult> signup(String email, String password,
      {String? referral, required String role}) async {
    return executeRequest(
      action: 'signup',
      logger: _logger,
      request: () async => _api.post('/api/users', body: {
        "user": {
          "email": email,
          "password": password,
          "referral_code": referral,
          "role": role,
          "source": "app", // TODO: Change this based on device platform?
          "timezone_device": await _device.timezone(),
          "language_code": _device.languageCode(),
          "device_platform": await _device.platformString(),
        }
      }),
      onResponse: (res) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          _logger.info("signup successful");
          // Auto-login the newly created user
          return login(email, password);
        }

        // Return null to let the mixin handle the unhandled status code
        return null;
      },
    );
  }

  /// Logs a user in to Handlebar
  Future<AuthResult> login(String email, String password) async {
    return executeRequest(
      action: 'login',
      logger: _logger,
      request: () => _api.post('/api/sessions', body: {
        "session": {"email": email, "password": password}
      }),
      onResponse: (res) async {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final userData = map['data'] as Map<String, dynamic>?;

          if (userData != null) {
            final token = ApiClient.extractAuthToken(res);

            if (token.isNotEmpty) {
              await _tokens.saveAuthToken(token);
            }

            // Save the user's data
            await _saveUserData(userData);

            // Sync the collector state now that we know who they are!
            await getIt<CollectorService>().syncMonitoringState();

            _logger.info("login successful");
            return Success(AuthSession(token: token, userData: userData));
          }

          _logger.info("login failed - No user data found");
          return Failure(ApiError(message: "No user data found"));
        }

        if (res.statusCode == 401) {
          final msg = "User not found";
          _logger.info("login failed - $msg");
          return Failure(ApiError(message: msg, statusCode: 401));
        }

        // Return null to let the mixin handle the unhandled status code
        return null;
      },
    );
  }

  Future<void> logout() async {
    await _tokens.clearTokens();
    await getIt<CollectorService>().syncMonitoringState();
  }

  /// Saves minimal user data to secure storage
  Future<void> _saveUserData(Map<String, dynamic> user) async {
    try {
      _logger.info("Starting to save user data...");

      // 1. Let the black box handle the hard drive
      await _storage.saveUserData(
        newUserId: user['id']?.toString(),
        newFirstName: user['first_name'],
        newLastName: user['last_name'],
        newEmail: user['email'],
        newRole: user['role'],
      );

      // 2. Tell the in-memory store to update
      _tokens.setUserRole(user['role']);

      _logger.info("Save user data successful");
    } catch (e, st) {
      _logger.warning("Save user data failed: ${e.toString()}", st);
    }
  }
}
