import 'package:flutter/foundation.dart';
import 'package:handlebar/core/network/api_error.dart';
import 'package:handlebar/features/auth/data/auth_repository.dart';

import '../../../../app/app_locator.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../data/terms_repository.dart';
import '../../models/accepted_terms.dart';
import '../../models/current_terms_response.dart';
import '../../models/terms.dart';

class TermsViewModel {
  final AuthRepository _authRepo;
  final TermsRepository _termsRepo;

  TermsViewModel({
    required AuthRepository authRepo,
    required TermsRepository termsRepo,
  })  : _authRepo = authRepo,
        _termsRepo = termsRepo;

  // --- STATE ---
  final ValueNotifier<CurrentTermsResponse?> response = ValueNotifier(null);
  final ValueNotifier<bool> isLoading =
      ValueNotifier(true); // Start loading immediately
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<bool> isAccepting = ValueNotifier(false);

  // --- DERIVED PROPERTIES ---
  Terms? get termsToDisplay => response.value?.currentTerms;

  bool get needsToAccept =>
      response.value?.currentTerms != null &&
      response.value?.currentAcceptedTerms == null;

  // --- ACTIONS ---
  Future<void> loadTerms() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _termsRepo.checkCurrentTerms();

    result.fold(
      onSuccess: (data) {
        response.value = data;
      },
      onFailure: (ApiError error) {
        errorMessage.value = error.message;
      },
    );

    isLoading.value = false;
  }

  Future<bool> accept() async {
    final termsId = termsToDisplay?.id;
    if (termsId == null) {
      // TODO: THIS MUST BE FALSE. SWITCH WHEN TERMS ADDED TO DB
      await getIt<AuthTokenStore>().markTermsAsAcceptedLocally();
      return true;
    }

    isAccepting.value = true;
    errorMessage.value = null;

    final result = await _termsRepo.acceptTerms(termsId);

    result.fold(
      onSuccess: (_) async {
        // Optimistically update local state so the UI reflects acceptance
        response.value = CurrentTermsResponse(
          currentTerms: response.value!.currentTerms,
          currentAcceptedTerms: AcceptedTerms(
            id: 0, // Mock ID for local state
            acceptedAt: DateTime.now(),
            termsId: termsId,
          ),
          futureTerms: response.value!.futureTerms,
          futureAcceptedTerms: response.value!.futureAcceptedTerms,
        );

        await getIt<AuthTokenStore>().markTermsAsAcceptedLocally();
      },
      onFailure: (ApiError e) async {
        NotificationService().showError(e.message);
      },
    );

    isAccepting.value = false;

    return result.isSuccess;
  }

  Future<void> logout() async {
    await _authRepo.logout();
  }

  void dispose() {
    response.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    isAccepting.dispose();
  }
}
