import 'package:flutter/foundation.dart';

import '../../services/location_permission_service.dart';

class LocationPermissionViewModel {
  final LocationPermissionService _service;

  LocationPermissionViewModel({required LocationPermissionService service})
      : _service = service;

  final ValueNotifier<LocationPermissionStatus> status =
      ValueNotifier(LocationPermissionStatus.denied);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> hasNotifications = ValueNotifier(true);

  /// True once location collection can actually run in the background, which
  /// is the only state that matters — foreground-only is indistinguishable
  /// from denied in practice, because the participant is in another app
  /// whenever a sensor is triggered.
  bool get isComplete => status.value == LocationPermissionStatus.always;

  Future<void> refresh() async {
    isLoading.value = true;
    status.value = await _service.check();
    hasNotifications.value = await _service.hasNotificationPermission();
    isLoading.value = false;
  }

  /// Advances one step. Android will not grant background access in the same
  /// breath as foreground, so this deliberately does one thing per press and
  /// lets the participant see the result before continuing.
  Future<void> requestNext() async {
    isLoading.value = true;
    try {
      switch (status.value) {
        case LocationPermissionStatus.denied:
          status.value = await _service.requestForeground();
          break;
        case LocationPermissionStatus.foregroundOnly:
          status.value = await _service.requestBackground();
          break;
        case LocationPermissionStatus.permanentlyDenied:
          await _service.openSettings();
          break;
        case LocationPermissionStatus.always:
        case LocationPermissionStatus.unsupported:
          break;
      }

      // Ask for notifications once location is usable, so the participant can
      // see when collection is happening. Non-blocking: collection works
      // without it, they just lose the transparency signal.
      if (status.value == LocationPermissionStatus.always &&
          !hasNotifications.value) {
        hasNotifications.value = await _service.requestNotifications();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openSettings() => _service.openSettings();

  void dispose() {
    status.dispose();
    isLoading.dispose();
    hasNotifications.dispose();
  }
}
