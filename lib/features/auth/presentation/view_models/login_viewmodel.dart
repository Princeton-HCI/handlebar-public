import 'package:flutter/foundation.dart';
import 'package:handlebar/features/crepe/services/crepe_service.dart';

import '../../../../core/storage/auth_token_store.dart';
import '../../../terms/data/terms_repository.dart';
import '../../data/auth_repository.dart';

class LoginViewModel {
  final AuthRepository _authRepo;
  final TermsRepository _termsRepo;
  final AuthTokenStore _authStore;
  final CrepeService _crepeService;

  // State Notifiers
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  LoginViewModel(
      this._authRepo, this._termsRepo, this._authStore, this._crepeService);

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 1. Perform the login
      final loginResult = await _authRepo.login(email, password);

      final loginSuccess = loginResult.fold(
          onSuccess: (_) => true, // Proceed to next steps
          onFailure: (e) {
            errorMessage.value = e.message;
            return false; // Tell the function to stop
          });

      // If the fold returned false (failure), escape the function early
      if (!loginSuccess) return false;

      // 3. If we made it here, login succeeded! Check terms compliance.
      final termsResult = await _termsRepo.checkCurrentTerms();

      termsResult.fold(
        onSuccess: (response) {
          final needsToAccept = response.currentTerms != null &&
              response.currentAcceptedTerms == null;
          _authStore.setNeedsTermsAcceptance(needsToAccept);
        },
        onFailure: (error) {
          // Default to true on network error to protect the trap door
          _authStore.setNeedsTermsAcceptance(true);
        },
      );

      if (!kIsWeb) {
        final isAccEnabled =
            await _crepeService.isAccessibilityServiceEnabled();
        _authStore.setNeedsAccessibilityAcceptance(!isAccEnabled);
      } else {
        _authStore.setNeedsAccessibilityAcceptance(false);
      }

      return true;
    } catch (e) {
      // Safety net for unexpected crashes
      errorMessage.value = "An unexpected error occurred.";
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}
