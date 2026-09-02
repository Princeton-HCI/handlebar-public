import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  String email = "";
  String accessCode = "";
  String refreshToken = "";
  String accessToken = "";
  String userId = "";
  String firstName = "";
  String lastName = "";
  String role = "participant";
  DateTime dateTokenExpires = DateTime.now();
  bool dataPrivacyCheck = false;

  // NEW: RAM cache for terms
  bool termsAccepted = false;

  // Participant preference: show on-screen highlight cards during collection.
  // Defaults to true (overlays shown) when unset.
  bool showCollectorOverlays = true;

  // Singleton instance
  static final SecureStorage _secureStorage = SecureStorage._internal();
  final storage = const FlutterSecureStorage();

  factory SecureStorage() {
    return _secureStorage;
  }

  SecureStorage._internal();

  Future<void> initialize() async {
    email = await storage.read(key: "handlebar_email") ?? "";
    accessCode = await storage.read(key: "handlebar_access_code") ?? "";
    refreshToken = await storage.read(key: "handlebar_refresh_token") ?? "";
    accessToken = await storage.read(key: "handlebar_auth_token") ?? "";
    userId = await storage.read(key: "handlebar_user_id") ?? "";
    firstName = await storage.read(key: "handlebar_first_name") ?? "";
    lastName = await storage.read(key: "handlebar_last_name") ?? "";
    role = await storage.read(key: "handlebar_role") ?? "participant";

    // READ TERMS ON BOOT
    final termsStr = await storage.read(key: "handlebar_terms_accepted");
    termsAccepted = (termsStr == 'true');

    // Overlay preference defaults to ON unless explicitly disabled.
    final overlayStr = await storage.read(key: "handlebar_show_overlays");
    showCollectorOverlays = (overlayStr != 'false');

    String tokenExpiresDate =
        await storage.read(key: "handlebar_token_expires") ?? "";
    if (tokenExpiresDate.isEmpty) {
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

  bool isTokenExpired() {
    return DateTime.now().isAfter(dateTokenExpires);
  }

  /// Saves the auth token and updates expiration
  Future<void> saveAuthToken(String token) async {
    accessToken = token;
    await storage.write(key: 'handlebar_auth_token', value: token);
    await _updateTokenExpiration();
  }

  Future<void> saveUserData({
    required String? newUserId,
    required String? newFirstName,
    required String? newLastName,
    required String? newEmail,
    required String newRole,
  }) async {
    // 1. Update RAM
    userId = newUserId ?? '';
    firstName = newFirstName ?? '';
    lastName = newLastName ?? '';
    email = newEmail ?? '';
    role = newRole;

    // 2. Write to disk securely
    if (newUserId != null) {
      await storage.write(key: 'handlebar_user_id', value: newUserId);
    }
    if (newFirstName != null) {
      await storage.write(key: 'handlebar_first_name', value: newFirstName);
    }
    if (newLastName != null) {
      await storage.write(key: 'handlebar_last_name', value: newLastName);
    }
    if (newEmail != null) {
      await storage.write(key: 'handlebar_email', value: newEmail);
    }
    await storage.write(key: 'handlebar_role', value: newRole);
  }

  /// Persists the participant's overlay-visibility preference.
  Future<void> saveShowCollectorOverlays(bool show) async {
    showCollectorOverlays = show;
    await storage.write(
        key: 'handlebar_show_overlays', value: show ? 'true' : 'false');
  }

  /// Caches the terms acceptance
  Future<void> saveTermsAccepted(bool accepted) async {
    termsAccepted = accepted;
    if (accepted) {
      await storage.write(key: 'handlebar_terms_accepted', value: 'true');
    } else {
      await storage.delete(key: 'handlebar_terms_accepted');
    }
  }

  Future<void> _updateTokenExpiration() async {
    dateTokenExpires = DateTime.now().add(const Duration(days: 90));
    await storage.write(
        key: "handlebar_token_expires", value: dateTokenExpires.toString());
  }

  // Clear authentication tokens and user data
  Future<void> clearStoredTokens() async {
    // It's safer to delete keys than leave empty strings floating around!
    await storage.delete(key: 'handlebar_auth_token');
    await storage.delete(key: 'handlebar_refresh_token');
    await storage.delete(key: 'handlebar_email');
    await storage.delete(key: 'handlebar_user_id');
    await storage.delete(key: 'handlebar_first_name');
    await storage.delete(key: 'handlebar_last_name');
    await storage.delete(key: 'handlebar_token_expires');
    await storage.delete(key: 'handlebar_role');
    await storage.delete(key: 'handlebar_terms_accepted');
    await storage.delete(key: 'handlebar_privacy_consent');

    accessToken = '';
    refreshToken = '';
    email = '';
    userId = '';
    firstName = '';
    lastName = '';
    role = 'participant';
    termsAccepted = false;
    dataPrivacyCheck = false;
    dateTokenExpires = DateTime.now();
  }
}
