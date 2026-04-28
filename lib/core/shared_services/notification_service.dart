import 'package:flutter/material.dart';

import '../shared_widgets/custom_toast.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  OverlayEntry? _currentToast;

  void showSuccess(String message) {
    _showToast(message, ToastType.success);
  }

  void showError(String message) {
    _showToast(message, ToastType.error);
  }

  void showInfo(String message) {
    _showToast(message, ToastType.info);
  }

  void showWarning(String message) {
    _showToast(message, ToastType.warning);
  }

  void _showToast(String message, ToastType type) {
    // Grab the overlay directly from the GlobalKey
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentToast?.remove();

    _currentToast = OverlayEntry(
      builder: (context) => CustomToast(
        message: message,
        type: type,
        onDismiss: dismissCurrentToast,
      ),
    );

    overlayState.insert(_currentToast!);
  }

  void dismissCurrentToast() {
    _currentToast?.remove();
    _currentToast = null;
  }
}
