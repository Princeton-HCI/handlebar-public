import 'package:flutter/foundation.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import 'package:handlebar/features/research_group/data/research_group_repository.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../crepe/services/crepe_service.dart';
import '../../data/auth_repository.dart';

enum SignupRole { participant, researcher, none }

class SignupViewModel {
  final AuthRepository _authRepo;
  final ResearchGroupRepository _groupRepo;
  final AuthTokenStore _authStore;
  final CrepeService _crepeService;

  SignupViewModel({
    required AuthRepository authRepo,
    required ResearchGroupRepository groupRepo,
    required AuthTokenStore authStore,
    required CrepeService crepeService,
  })  : _authRepo = authRepo,
        _groupRepo = groupRepo,
        _authStore = authStore,
        _crepeService = crepeService;

  // --- UI State Notifiers ---
  final ValueNotifier<SignupRole> selectedRole = ValueNotifier(SignupRole.none);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // --- Cache state ---
  String? _studyCode;
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
      NotificationService().showError("Please enter a valid study code.");
      return false;
    }

    // ONLY skip if the code hasn't changed AND we already succeeded.
    // If the last result was 'false', we want to try the API call again
    if (cleanCode == _lastCheckedCode && _lastCheckResult == true) {
      return true;
    }

    _lastCheckedCode = cleanCode;
    isLoading.value = true;

    try {
      final result = await _groupRepo.lookupByCode(cleanCode);

      return result.fold(
        onSuccess: (group) {
          _lastCheckResult = true;
          _studyCode = cleanCode;
          return true;
        },
        onFailure: (ApiError error) {
          _lastCheckResult = false;
          NotificationService().showError(error.message);
          return false;
        },
      );
    } catch (e) {
      NotificationService().showError("An unexpected error occurred.");
      return false;
    } finally {
      isLoading.value = false;
      _lastCheckResult = false;
    }
  }

  // Called from the Final Screen (Email/Password entry)
  Future<bool> submitRegistration(String email, String password) async {
    if (selectedRole.value == SignupRole.participant &&
        (_studyCode == null || _studyCode!.isEmpty)) {
      NotificationService().showError("Missing study code for participant.");
      return false;
    }

    isLoading.value = true;

    try {
      // 1. Execute the signup
      final signupResult = await _authRepo.signup(email, password,
          referral: _studyCode, role: selectedRole.value.name);

      // 2. If signup fails, handle error and stop
      if (!signupResult.isSuccess) {
        signupResult.fold(
            onSuccess: (_) {},
            onFailure: (e) {
              NotificationService().showError(e.message);
            });
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

      return signupResult.fold(onSuccess: (_) {
        NotificationService().showSuccess("Account successfully created!");
        return true;
      }, onFailure: (e) {
        NotificationService().showError(e.message);
        return false;
      });
    } catch (e) {
      NotificationService().showError("An unexpected error occurred.");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
  }
}
