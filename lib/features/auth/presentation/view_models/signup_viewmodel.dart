import 'package:flutter/foundation.dart';
import 'package:handlebar/features/research_group/data/research_group_repository.dart';

import '../../../../core/storage/auth_token_store.dart';
import '../../../crepe/services/crepe_service.dart';
import '../../data/auth_repository.dart';

enum SignupRole { participant, researcher, none }

class SignupViewModel {
  final AuthRepository _authRepo;
  final ResearchGroupRepository _groupRepo;
  final AuthTokenStore _authStore;
  final CrepeService _crepeService;

  // --- UI State Notifiers ---
  final ValueNotifier<SignupRole> selectedRole = ValueNotifier(SignupRole.none);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // Constructor Injection
  SignupViewModel(
      this._authRepo, this._groupRepo, this._authStore, this._crepeService);
  String? studyCode;

  // --- Cache state ---
  String? _lastCheckedCode;
  bool _lastCheckResult = false;

  // Called from "Select Role" screen
  void setRole(SignupRole role) {
    selectedRole.value = role;
  }

  // Called from "Input Research Study Code" screen
  Future<bool> setStudyCode(String code) async {
    final cleanCode = code.trim();

    if (cleanCode.isEmpty) {
      errorMessage.value = "Please enter a valid study code.";
      return false;
    }

    // ONLY skip if the code hasn't changed AND we already succeeded.
    // If the last result was 'false', we want to try the API call again
    if (cleanCode == _lastCheckedCode && _lastCheckResult == true) {
      return true;
    }

    _lastCheckedCode = cleanCode;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _groupRepo.lookupByCode(cleanCode);

      // Always stop loading regardless of result
      isLoading.value = false;

      return result.fold(
        onSuccess: (group) {
          _lastCheckResult = true;
          studyCode = cleanCode;
          return true;
        },
        onFailure: (error) {
          _lastCheckResult = false;
          errorMessage.value = error.message;
          return false;
        },
      );
    } catch (e) {
      errorMessage.value = "An unexpected error occurred.";
      return false;
    } finally {
      isLoading.value = false;
      _lastCheckResult = false;
    }
  }

  // Called from the Final Screen (Email/Password entry)
  Future<bool> submitRegistration(String email, String password) async {
    if (selectedRole.value == SignupRole.participant &&
        (studyCode == null || studyCode!.isEmpty)) {
      errorMessage.value = "Missing study code for participant.";
      return false;
    }

    // Start loading
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 1. Execute the signup
      final signupResult = await _authRepo.signup(email, password,
          referral: studyCode, role: selectedRole.value.name);

      // 2. If signup fails, handle error and stop
      if (!signupResult.isSuccess) {
        signupResult.fold(
          onSuccess: (_) {},
          onFailure: (e) => errorMessage.value = e.message,
        );
        return false; // Escapes the function early
      }

      // 3. New signups always have to accept Handlebar's terms
      _authStore.setNeedsTermsAcceptance(true);

      // 4. Check Accessibility Status only for mobile
      if (!kIsWeb) {
        final isAccEnabled =
            await _crepeService.isAccessibilityServiceEnabled();
        // If it is NOT enabled, they need to accept it!
        _authStore.setNeedsAccessibilityAcceptance(!isAccEnabled);
      } else {
        // Web users never need accessibility
        _authStore.setNeedsAccessibilityAcceptance(false);
      }

      return signupResult.fold(
          onSuccess: (_) => true,
          onFailure: (e) {
            errorMessage.value = e.message;
            return false;
          });
    } catch (e) {
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
