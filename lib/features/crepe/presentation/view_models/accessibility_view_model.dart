import 'package:flutter/foundation.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../services/crepe_service.dart';

class AccessibilityViewModel {
  final AuthRepository _authRepo;
  final CrepeService _crepeService;

  AccessibilityViewModel({
    required AuthRepository authRepo,
    required CrepeService crepeService,
  })  : _authRepo = authRepo,
        _crepeService = crepeService;

  // UI State
  final ValueNotifier<bool> isEnabled = ValueNotifier(false);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  bool? _wasEnabled;

  /// Checks the current status of the accessibility service
  Future<void> checkStatus() async {
    isLoading.value = true;
    final status = await _crepeService.isAccessibilityServiceEnabled();

    // Transition Logic (Only fire if we have a previous state to compare to)
    if (_wasEnabled != null) {
      if (status && !_wasEnabled!) {
        // Disabled -> Enabled
        NotificationService().showSuccess(
            "✅ Accessibility Service Enabled!\nWelcome to Handlebar");
      } else if (!status && _wasEnabled!) {
        // Enabled -> Disabled
        NotificationService().showError(
            "Accessibility Service Disabled! Enable it to access Handlebar!");
      }
    }
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
