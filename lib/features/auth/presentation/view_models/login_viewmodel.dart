import 'package:flutter/foundation.dart';
import 'package:handlebar/features/crepe/services/crepe_service.dart';

import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../terms/data/terms_repository.dart';
import '../../data/auth_repository.dart';

class LoginViewModel {
  final AuthRepository _authRepo;
  final TermsRepository _termsRepo;
  final AuthTokenStore _authStore;
  final CrepeService _crepeService;

  LoginViewModel({
    required AuthRepository authRepo,
    required AuthTokenStore authStore,
    required TermsRepository termsRepo,
    required CrepeService crepeService,
  })  : _authRepo = authRepo,
        _authStore = authStore,
        _termsRepo = termsRepo,
        _crepeService = crepeService;

  // State Notifiers
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<bool> login(String email, String password) async {
    isLoading.value = true;

    try {
      final loginResult = await _authRepo.login(email, password);

      final loginSuccess = loginResult.fold(onSuccess: (_) {
        NotificationService().showSuccess("Successfully logged in!");
        return true;
      }, onFailure: (error) {
        NotificationService().showError(error.message);
        return false;
      });

      if (!loginSuccess) return false;

      final termsResult = await _termsRepo.checkCurrentTerms();
      termsResult.fold(
        onSuccess: (response) {
          final needsToAccept = response.currentTerms != null &&
              response.currentAcceptedTerms == null;
          _authStore.setNeedsTermsAcceptance(needsToAccept);
        },
        onFailure: (error) {
          NotificationService().showError(error.message);
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
      NotificationService().showError("An unexpected error occurred");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
  }
}
