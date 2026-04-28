import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../app/app_locator.dart';
import '../../features/crepe/services/crepe_service.dart';
import '../../features/terms/data/terms_repository.dart';
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

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    await _storage.initialize();

    // Read raw storage
    _needsTermsAcceptance = !_storage.termsAccepted;
    _userRole = _storage.role.isNotEmpty ? _storage.role : 'participant';

    if (isAuthenticated) {
      // 1. Check Terms
      final termsRepo = getIt<TermsRepository>();
      final result = await termsRepo.checkCurrentTerms();
      result.fold(
        onSuccess: (response) {
          final needsToAccept = response.currentTerms != null &&
              response.currentAcceptedTerms == null;
          if (!needsToAccept) {
            markTermsAsAcceptedLocally();
          } else {
            _needsTermsAcceptance = true;
          }
        },
        onFailure: (error) =>
            debugPrint("Terms check failed, relying on cache"),
      );

      // 2. Check Accessibility (If Mobile)
      if (!kIsWeb) {
        final isAccEnabled =
            await getIt<CrepeService>().isAccessibilityServiceEnabled();
        _needsAccessibilityAcceptance = !isAccEnabled;
      }
    }

    // Tell GoRouter we are done booting
    _isInitialized = true;
    notifyListeners();
  }

  // ===========================================================================
  // SESSION MANAGEMENT
  // ===========================================================================

  Future<void> saveAuthToken({
    required String token,
    required bool hasAcceptedTerms,
    required String role,
  }) async {
    _logger.info("Storing the auth token and user state...");

    // Save to disk
    await _storage.saveAuthToken(token);
    await _storage.saveTermsAccepted(hasAcceptedTerms);

    // Update RAM
    _needsTermsAcceptance = !hasAcceptedTerms;
    _userRole = role;

    _logger.info("Auth token and state storage successful");
    notifyListeners();
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
