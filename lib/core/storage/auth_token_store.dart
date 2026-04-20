import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'secure_storage.dart';

/// In-memory store for handling auth token persistence, session checks, and global
/// routing state built on top of [SecureStorage].
///
/// Extends [ChangeNotifier] so GoRouter's `refreshListenable` can instantly
/// react to changes in the user's compliance status.
class AuthTokenStore extends ChangeNotifier {
  final SecureStorage _storage;
  final _logger = Logger("AuthTokenStore");

  AuthTokenStore(this._storage);

  Future<void> init() async {
    // 1. Tell the black box to initialize itself
    await _storage.initialize();

    // 2. Read the strictly typed variables it prepared for us
    _needsTermsAcceptance = !_storage.termsAccepted;
    _userRole = _storage.role.isNotEmpty ? _storage.role : 'participant';

    _logger.info("Storage initialization successful");
  }

  // ===========================================================================
  // SESSION MANAGEMENT
  // ===========================================================================

  Future<void> saveAuthToken(String token) async {
    _logger.info("Storing the auth token...");
    // Let the wrapper handle the key names and expiration logic
    await _storage.saveAuthToken(token);
    _logger.info("Auth token storage successful");
  }

  Future<void> clearTokens() async {
    _logger.info("Clearing user session and tokens...");

    // Delete everything
    await _storage.clearStoredTokens();

    // Reset local routing flags
    _needsTermsAcceptance = false;
    _needsAccessibilityAcceptance = false;
    _userRole = 'participant';

    notifyListeners();
    _logger.info("Session wiped successfully.");
  }

  String? get token =>
      _storage.accessToken.isNotEmpty ? _storage.accessToken : null;
  bool get isExpired => _storage.isTokenExpired();
  bool get isAuthenticated => token != null && !isExpired;

  // ===========================================================================
  // ROUTING STATE FLAGS (RAM)
  // ===========================================================================

  String _userRole = 'participant';
  String get userRole => _userRole;

  void setUserRole(String role) {
    if (_userRole != role) {
      _userRole = role;
      notifyListeners();
    }
  }

  bool _needsTermsAcceptance = false;
  bool get needsTermsAcceptance => _needsTermsAcceptance;

  void setNeedsTermsAcceptance(bool value) {
    if (_needsTermsAcceptance != value) {
      _needsTermsAcceptance = value;
      notifyListeners();
    }
  }

  bool _needsAccessibilityAcceptance = false;
  bool get needsAccessibilityAcceptance => _needsAccessibilityAcceptance;

  void setNeedsAccessibilityAcceptance(bool value) {
    if (_needsAccessibilityAcceptance != value) {
      _needsAccessibilityAcceptance = value;
      notifyListeners();
    }
  }

  Future<void> markTermsAsAcceptedLocally() async {
    // Ask the wrapper to handle the disk write
    await _storage.saveTermsAccepted(true);
    setNeedsTermsAcceptance(false);
  }
}
