import 'package:flutter/foundation.dart';
import '../../../auth/data/auth_repository.dart';
import '../../services/crepe_service.dart';

class AccessibilityViewModel {
  final AuthRepository _authRepo;
  final CrepeService _crepeService;

  AccessibilityViewModel(this._authRepo, this._crepeService);

  // UI State
  final ValueNotifier<bool> isEnabled = ValueNotifier(false);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Checks the current status of the accessibility service
  Future<void> checkStatus() async {
    isLoading.value = true;
    final status = await _crepeService.isAccessibilityServiceEnabled();
    isEnabled.value = status;
    isLoading.value = false;
  }

  /// Opens the Android Accessibility Settings page
  Future<void> openSettings() async {
    await _crepeService.requestAccessibilityPermission();
  }

  Future<void> logout() async {
    await _authRepo.logout();
  }

  void dispose() {
    isEnabled.dispose();
    isLoading.dispose();
  }
}
