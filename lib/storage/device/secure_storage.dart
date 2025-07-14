import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  String email = "";
  String accessCode = "";
  String refreshToken = "";
  String accessToken = "";
  String userId = "";
  String firstName = "";
  String lastName = "";
  DateTime dateTokenExpires = DateTime.now();
  bool dataPrivacyCheck = false;

  // Singleton instance
  static final SecureStorage _secureStorage = SecureStorage._internal();
  final storage = const FlutterSecureStorage();

  // Public factory constructor for accessing the singleton instance
  factory SecureStorage() {
    return _secureStorage;
  }

  // Private named constructor
  SecureStorage._internal();

  //class constructor
  Future<void> initialize() async {
    email = await storage.read(key: "dsc_email") ?? "";
    accessCode = await storage.read(key: "dsc_access_code") ?? "";
    refreshToken = await storage.read(key: "dsc_refresh_token") ?? "";
    accessToken = await storage.read(key: "dsc_auth_token") ?? "";
    userId = await storage.read(key: "dsc_user_id") ?? "";
    firstName = await storage.read(key: "dsc_first_name") ?? "";
    lastName = await storage.read(key: "dsc_last_name") ?? "";
    String tokenExpiresDate = await storage.read(key: "dsc_token_expires") ?? "";
    if (tokenExpiresDate.isEmpty) {
      // Set token expiration to 90 days from now
      dateTokenExpires = DateTime.now().add(const Duration(days: 90));
      await storage.write(key: "dsc_token_expires", value: dateTokenExpires.toString());
    }
    else {
      dateTokenExpires = DateTime.parse(tokenExpiresDate);
    }
    dataPrivacyCheck = bool.parse(await storage.read(key: "dsc_privacy_consent") ?? "false", caseSensitive: false);
  }

  // Check if the current token is expired
  bool isTokenExpired() {
    return DateTime.now().isAfter(dateTokenExpires);
  }

  // Update token expiration when saving a new token
  Future<void> updateTokenExpiration() async {
    dateTokenExpires = DateTime.now().add(const Duration(days: 90));
    await storage.write(key: "dsc_token_expires", value: dateTokenExpires.toString());
  }

  // Clear authentication tokens and user data
  Future<void> clearAuthTokens() async {
    await storage.write(key: 'dsc_auth_token', value: '');
    await storage.write(key: 'dsc_refresh_token', value: '');
    await storage.write(key: 'dsc_email', value: '');
    await storage.write(key: 'dsc_user_id', value: '');
    await storage.write(key: 'dsc_first_name', value: '');
    await storage.write(key: 'dsc_last_name', value: '');
    await storage.write(key: 'dsc_token_expires', value: '');
    
    accessToken = '';
    refreshToken = '';
    email = '';
    userId = '';
    firstName = '';
    lastName = '';
    dateTokenExpires = DateTime.now();
  }
}