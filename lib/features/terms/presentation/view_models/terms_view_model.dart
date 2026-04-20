import 'package:flutter/foundation.dart';
import 'package:handlebar/features/auth/data/auth_repository.dart';

import '../../data/terms_repository.dart';
import '../../models/accepted_terms.dart';
import '../../models/current_terms_response.dart';
import '../../models/terms.dart';

class TermsViewModel {
  final AuthRepository _authRepo;
  final TermsRepository _termsRepo;

  TermsViewModel(this._authRepo, this._termsRepo);

  // --- STATE ---
  final ValueNotifier<CurrentTermsResponse?> response = ValueNotifier(null);
  final ValueNotifier<bool> isLoading =
      ValueNotifier(true); // Start loading immediately
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<bool> isAccepting = ValueNotifier(false);

  // --- DERIVED PROPERTIES ---
  // These just read from the current value of the response notifier
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
      onFailure: (error) {
        errorMessage.value = error.message;
      },
    );

    isLoading.value = false;
  }

  Future<bool> accept() async {
    final termsId = termsToDisplay?.id;
    if (termsId == null) return false;

    isAccepting.value = true;
    errorMessage.value = null;

    final result = await _termsRepo.acceptTerms(termsId);

    result.fold(
      onSuccess: (_) {
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
      },
      onFailure: (error) {
        errorMessage.value = error.message;
      },
    );

    isAccepting.value = false;

    return result.isSuccess;
  }

  Future<void> logout() async {
    await _authRepo.logout();
  }

  // Always clean up your notifiers!
  void dispose() {
    response.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    isAccepting.dispose();
  }
}
