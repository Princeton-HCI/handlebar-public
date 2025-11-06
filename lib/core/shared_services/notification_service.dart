import 'package:flutter/material.dart';

import '../shared_widgets/custom_toast.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  BuildContext? _context;
  OverlayEntry? _currentToast;

  void setContext(BuildContext context) {
    _context = context;
  }

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
    if (_context == null || !_context!.mounted) return;

    // Remove current toast if exists
    _currentToast?.remove();

    // Create new overlay entry
    _currentToast = OverlayEntry(
      builder: (context) => CustomToast(
        message: message,
        type: type,
        onDismiss: () {
          _currentToast?.remove();
          _currentToast = null;
        },
      ),
    );

    // Insert into overlay
    Overlay.of(_context!).insert(_currentToast!);
  }

  void dismissCurrentToast() {
    _currentToast?.remove();
    _currentToast = null;
  }
}
