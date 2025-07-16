import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:handlebar/storage/device/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class RequestHandler {
  final secureStorage = SecureStorage();
  final requestHeaders = <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // API Environment Configuration
  static const String _stagingUrl = 'https://dsc-api-staging-23350212163.us-central1.run.app';
  static const String _productionUrl = 'https://dsc-api-service-23350212163.us-central1.run.app';
  
  static bool _useProduction = kDebugMode ? false : true;
  static String get apiBaseUrl => _useProduction ? _productionUrl : _stagingUrl;
  static String get currentEnvironment => _useProduction ? 'Production' : 'Staging';
  
  static void useProduction() {
    _useProduction = true;
    log('✅ Switched to Production: $_productionUrl', name: 'RequestHandler');
  }
  
  static void useStaging() {
    _useProduction = false;
    log('🔧 Switched to Staging: $_stagingUrl', name: 'RequestHandler');
  }
  
  static void toggleEnvironment() {
    _useProduction = !_useProduction;
    log('🔄 Toggled to ${currentEnvironment}: ${apiBaseUrl}', name: 'RequestHandler');
  }

  // Set up singleton instance of RequestHandler
  static final RequestHandler _requestHandler = RequestHandler._internal();

  factory RequestHandler() {
    return _requestHandler;
  }

  RequestHandler._internal();

  // Initialize the request handler by loading stored auth token
  Future<void> initialize() async {
    await secureStorage.initialize();
    await _updateAuthorizationHeader();
    
    log('🌐 API Environment: ${currentEnvironment} (${apiBaseUrl})', name: 'RequestHandler');
  }

  // Update the authorization header with the stored access token
  Future<void> _updateAuthorizationHeader() async {
    if (secureStorage.accessToken.isNotEmpty) {
      requestHeaders['authorization'] = 'Bearer ${secureStorage.accessToken}';
    } else {
      // Remove authorization header when no token is available
      requestHeaders.remove('authorization');
    }
  }

  // Save auth token securely and update headers
  Future<void> _saveAuthToken(String token) async {
    await secureStorage.storage.write(key: 'dsc_auth_token', value: token);
    secureStorage.accessToken = token;
    // Update token expiration to 90 days from now
    await secureStorage.updateTokenExpiration();
    await _updateAuthorizationHeader();
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    await secureStorage.clearAuthTokens();
    await _updateAuthorizationHeader();
  }

  // Device info
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Get device timezone - using flutter_timezone for reliable IANA identifiers
  Future<String> _getDeviceTimezone() async {
    try {
      final String timezone = await FlutterTimezone.getLocalTimezone();
      log("Device timezone: $timezone", name: 'RequestHandler.DeviceInfo');
      return timezone;
    } catch (e) {
      log("Error getting timezone", error: e, name: 'RequestHandler.DeviceInfo');
      return 'UTC'; // Safe fallback
    }
  }

  // Get device language code
  String _getLanguageCode() {
    try {
      return Intl.getCurrentLocale();
    } catch (e) {
      return 'en_US'; // fallback
    }
  }

  // Get detailed device platform information
  Future<String> _getDevicePlatform() async {
    try {
      // Get actual app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
      
      String deviceInfo = "";

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        
        // Format: "AppVersion / Manufacturer: Model, OS, Version"
        deviceInfo = "$appVersion / ${androidInfo.manufacturer}: ${androidInfo.model}, android, ${androidInfo.version.release}";
        
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        
        // Format: "AppVersion / Apple: Model, iOS, Version"
        deviceInfo = "$appVersion / Apple: ${iosInfo.model}, iOS, ${iosInfo.systemVersion}";
        
      } else {
        deviceInfo = "$appVersion / Unknown: ${Platform.operatingSystem}";
      }

      return deviceInfo;
    } catch (e) {
      log("Error getting device platform info", error: e, name: 'RequestHandler.DeviceInfo');
      return "1.0.0+1 / Unknown: ${Platform.operatingSystem}";
    }
  }

  Future<AuthResult> requestNewUser(String newEmail, String newPassword, {String? referralCode}) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBaseUrl}/api/users'),
        headers: requestHeaders,
        body: jsonEncode({
          "user": {
            "email": newEmail,
            "password": newPassword,
            "referral_code": referralCode,
            "source": "app",
            "timezone_device": await _getDeviceTimezone(),
            "language_code": _getLanguageCode(),
            "device_platform": await _getDevicePlatform(),
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = responseData['data'] as Map<String, dynamic>?;
        
        if (userData != null) {
          // Auto-login the newly created user
          final loginResult = await requestSession(newEmail, newPassword);
          
          if (loginResult.success) {
            log("User creation and login successful", name: 'RequestHandler.Auth');
            return AuthResult(success: true, token: loginResult.token, userData: userData);
          } else {
            return loginResult;
          }
        } else {
          return AuthResult(success: false, error: "Invalid response format - no user data");
        }
      } else {
        final error = _extractErrorMessage(response);
        return AuthResult(success: false, error: error);
      }
    } catch (e) {
      return AuthResult(success: false, error: "Network error: ${e.toString()}");
    }
  }

  // Save user data to secure storage - simplified version
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final dataMap = {
        'dsc_user_id': userData['id']?.toString(),
        'dsc_first_name': userData['first_name'],
        'dsc_last_name': userData['last_name'],
        'dsc_email': userData['email'],
      };
      
      for (final entry in dataMap.entries) {
        if (entry.value != null) {
          await secureStorage.storage.write(key: entry.key, value: entry.value!);
        }
      }
      
      if (userData['email'] != null) {
        secureStorage.email = userData['email'];
      }
      
      log("User data saved successfully", name: 'RequestHandler.Storage');
    } catch (e) {
      log("Error saving user data", error: e, name: 'RequestHandler.Storage');
    }
  }

  Future<AuthResult> requestSession(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBaseUrl}/api/sessions'),
        headers: requestHeaders,
        body: jsonEncode({"session": {"email": email, "password": password}}),
      );

      if (response.statusCode == 401) {
        return AuthResult(success: false, error: "User not found");
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = responseData['data'] as Map<String, dynamic>?;
        
        if (userData != null) {
          // Extract and save auth token
          final authToken = _extractAuthToken(response);
          
          if (authToken != null && authToken.isNotEmpty) {
            await _saveAuthToken(authToken);
          } else {
            log("Warning: No authentication token found", name: 'RequestHandler.Auth');
          }
          
          await _saveUserData(userData);
          log("Login successful", name: 'RequestHandler.Auth');
          
          return AuthResult(success: true, token: authToken, userData: userData);
        } else {
          return AuthResult(success: false, error: "Invalid response format - no user data found");
        }
      } else {
        final error = _extractErrorMessage(response);
        return AuthResult(success: false, error: error);
      }
    } catch (e) {
      return AuthResult(success: false, error: "Network error: ${e.toString()}");
    }
  }

  // Extract auth token from response - simplified version
  String? _extractAuthToken(http.Response response) {
    final authHeader = response.headers['authorization'];
    
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7); // Remove "Bearer " prefix
    }
    
    return null;
  }

  // Check for 401 unauthorized and handle token clearing
  Future<AuthResult?> _checkUnauthorized(http.Response response) async {
    if (response.statusCode == 401) {
      log("401 Unauthorized - clearing auth", name: 'RequestHandler.Auth');
      await clearAuthToken();
      return AuthResult(success: false, error: "Your session has expired. Please log in again.");
    }
    return null; // Continue processing
  }

  // Extract error message from response - simplified version
  String _extractErrorMessage(http.Response response) {
    return 'HTTP ${response.statusCode}: ${response.body}';
  }

  // Check if user is currently authenticated
  bool isAuthenticated() {
    if (secureStorage.accessToken.isEmpty || secureStorage.isTokenExpired()) {
      if (secureStorage.accessToken.isNotEmpty) {
        log("Token expired, clearing authentication", name: 'RequestHandler.Auth');
        _clearExpiredTokenAsync();
      }
      return false;
    }
    return true;
  }

  // Helper method to clear expired tokens asynchronously
  Future<void> _clearExpiredTokenAsync() async {
    await clearAuthToken();
  }

  // Accept terms for research study
  Future<AuthResult> acceptTerms(int termsId) async {
    try {
      if (!isAuthenticated()) {
        return AuthResult(success: false, error: "User not authenticated");
      }

      final response = await http.post(
        Uri.parse('${apiBaseUrl}/api/accepted_terms'),
        headers: requestHeaders,
        body: jsonEncode({'accepted_terms': {'terms_id': termsId}}),
      );

      // Check for 401 unauthorized
      final unauthorizedResult = await _checkUnauthorized(response);
      if (unauthorizedResult != null) return unauthorizedResult;

      // 422 might mean terms already accepted
      if (response.statusCode == 422) {
        return AuthResult(success: true);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Terms accepted successfully", name: 'RequestHandler.Terms');
        return AuthResult(success: true);
      }

      final error = _extractErrorMessage(response);
      return AuthResult(success: false, error: error);
    } catch (e) {
      return AuthResult(success: false, error: "Network error: ${e.toString()}");
    }
  }

  // Check current terms status
  Future<TermsResult> checkCurrentTerms() async {
    try {
      if (!isAuthenticated()) {
        return TermsResult(success: false, error: "User not authenticated");
      }

      final response = await http.get(
        Uri.parse('${apiBaseUrl}/api/terms/current'),
        headers: requestHeaders,
      );

      // Check for 401 unauthorized
      final unauthorizedResult = await _checkUnauthorized(response);
      if (unauthorizedResult != null) {
        return TermsResult(success: false, error: unauthorizedResult.error);
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          final currentTerms = data['current_terms'] as Map<String, dynamic>?;
          final currentAcceptedTerms = data['current_accepted_terms'] as Map<String, dynamic>?;
          
          final currentTermsId = currentTerms?['id'] as int?;
          final hasAcceptedCurrentTerms = currentAcceptedTerms != null;
          
          log("Current terms status checked: accepted=$hasAcceptedCurrentTerms, termsId=$currentTermsId", name: 'RequestHandler.Terms');
          return TermsResult(
            success: true, 
            hasAcceptedCurrentTerms: hasAcceptedCurrentTerms,
            currentTermsId: currentTermsId
          );
        } else {
          return TermsResult(success: false, error: "Invalid response format");
        }
      }

      final error = _extractErrorMessage(response);
      return TermsResult(success: false, error: error);
    } catch (e) {
      return TermsResult(success: false, error: "Network error: ${e.toString()}");
    }
  }

  // Send CrepeEvent to backend
  Future<AuthResult> sendCrepeEvent(Map<String, dynamic> crepeEvent, {int dataFieldId = 3}) async {
    try {
      if (!isAuthenticated()) {
        return AuthResult(success: false, error: "User not authenticated");
      }

      final response = await http.post(
        Uri.parse('${apiBaseUrl}/api/crepe/event'),
        headers: requestHeaders,
        body: jsonEncode({
          'data_field_id': dataFieldId,
          'collected_at': DateTime.now().toIso8601String(),
          'content': jsonEncode(crepeEvent)
        }),
      );

      // Check for 401 unauthorized
      final unauthorizedResult = await _checkUnauthorized(response);
      if (unauthorizedResult != null) return unauthorizedResult;

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("CrepeEvent sent successfully", name: 'RequestHandler.Crepe');
        return AuthResult(success: true);
      }

      final error = _extractErrorMessage(response);
      return AuthResult(success: false, error: error);
    } catch (e) {
      return AuthResult(success: false, error: "Network error: ${e.toString()}");
    }
  }
}

// Result class for authentication operations
class AuthResult {
  final bool success;
  final String? error;
  final String? token;
  final Map<String, dynamic>? userData;

  AuthResult({required this.success, this.error, this.token, this.userData});
}

// Result class for terms operations
class TermsResult {
  final bool success;
  final String? error;
  final bool hasAcceptedCurrentTerms;
  final int? currentTermsId;

  TermsResult({
    required this.success,
    this.error,
    this.hasAcceptedCurrentTerms = false,
    this.currentTermsId,
  });
}