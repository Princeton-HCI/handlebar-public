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

  Future<void> initialize() async {
    email = await storage.read(key: "handlebar_email") ?? "";
    accessCode = await storage.read(key: "handlebar_access_code") ?? "";
    refreshToken = await storage.read(key: "handlebar_refresh_token") ?? "";
    accessToken = await storage.read(key: "handlebar_auth_token") ?? "";
    userId = await storage.read(key: "handlebar_user_id") ?? "";
    firstName = await storage.read(key: "handlebar_first_name") ?? "";
    lastName = await storage.read(key: "handlebar_last_name") ?? "";
    String tokenExpiresDate =
        await storage.read(key: "handlebar_token_expires") ?? "";
    if (tokenExpiresDate.isEmpty) {
      // Set token expiration to 90 days from now
      dateTokenExpires = DateTime.now().add(const Duration(days: 90));
      await storage.write(
          key: "handlebar_token_expires", value: dateTokenExpires.toString());
    } else {
      dateTokenExpires = DateTime.parse(tokenExpiresDate);
    }
    dataPrivacyCheck = bool.parse(
        await storage.read(key: "handlebar_privacy_consent") ?? "false",
        caseSensitive: false);
  }

  // Check if the current token is expired
  bool isTokenExpired() {
    return DateTime.now().isAfter(dateTokenExpires);
  }

  // Update token expiration when saving a new token
  Future<void> updateTokenExpiration() async {
    dateTokenExpires = DateTime.now().add(const Duration(days: 90));
    await storage.write(
        key: "handlebar_token_expires", value: dateTokenExpires.toString());
  }

  // Clear authentication tokens and user data
  Future<void> clearStoredTokens() async {
    await storage.write(key: 'handlebar_auth_token', value: '');
    await storage.write(key: 'handlebar_refresh_token', value: '');
    await storage.write(key: 'handlebar_email', value: '');
    await storage.write(key: 'handlebar_user_id', value: '');
    await storage.write(key: 'handlebar_first_name', value: '');
    await storage.write(key: 'handlebar_last_name', value: '');
    await storage.write(key: 'handlebar_token_expires', value: '');

    accessToken = '';
    refreshToken = '';
    email = '';
    userId = '';
    firstName = '';
    lastName = '';
    dateTokenExpires = DateTime.now();
  }
}
