import 'package:flutter/foundation.dart';
import 'package:handlebar/services/notification_service.dart';

enum RecordingErrorType {
  accessibilityServiceDisabled,
  pluginNotInitialized,
  snapshotCaptureFailed,
  exportFailed,
  memoryLimit,
  fileSystemError,
  unknown
}

class RecordingError {
  final RecordingErrorType type;
  final String message;
  final String? details;
  final DateTime timestamp;

  RecordingError({
    required this.type,
    required this.message,
    this.details,
  }) : timestamp = DateTime.now();

  String get userFriendlyMessage {
    switch (type) {
      case RecordingErrorType.accessibilityServiceDisabled:
        return 'Accessibility service is not enabled. Please enable it in Settings to use recording.';
      case RecordingErrorType.pluginNotInitialized:
        return 'Recording system is not initialized. Please restart the app.';
      case RecordingErrorType.snapshotCaptureFailed:
        return 'Failed to capture UI snapshot. Make sure the app has proper permissions.';
      case RecordingErrorType.exportFailed:
        return 'Failed to export snapshots. Please check storage permissions.';
      case RecordingErrorType.memoryLimit:
        return 'Memory limit reached. Please export or clear existing snapshots.';
      case RecordingErrorType.fileSystemError:
        return 'File system error occurred. Please check available storage space.';
      case RecordingErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  String get actionableGuidance {
    switch (type) {
      case RecordingErrorType.accessibilityServiceDisabled:
        return 'Go to Settings > Accessibility and enable the app\'s accessibility service.';
      case RecordingErrorType.pluginNotInitialized:
        return 'Force close and restart the app to reinitialize the recording system.';
      case RecordingErrorType.snapshotCaptureFailed:
        return 'Check that the accessibility service is running and try again.';
      case RecordingErrorType.exportFailed:
        return 'Make sure the app has storage permissions and sufficient space available.';
      case RecordingErrorType.memoryLimit:
        return 'Export your current snapshots to free up memory, or clear them if not needed.';
      case RecordingErrorType.fileSystemError:
        return 'Free up storage space on your device and try again.';
      case RecordingErrorType.unknown:
        return 'If the problem persists, please restart the app.';
    }
  }
}

class RecordingErrorHandler {
  static final RecordingErrorHandler _instance =
      RecordingErrorHandler._internal();
  factory RecordingErrorHandler() => _instance;
  RecordingErrorHandler._internal();

  final List<RecordingError> _errorHistory = [];
  final NotificationService _notificationService = NotificationService();
  static const int _maxErrorHistory = 50;

  List<RecordingError> get errorHistory => List.unmodifiable(_errorHistory);

  RecordingError handleError(dynamic error, {RecordingErrorType? type}) {
    RecordingErrorType errorType = type ?? _classifyError(error);
    String message = _extractMessage(error);
    String? details = error is Exception ? error.toString() : null;

    final recordingError = RecordingError(
      type: errorType,
      message: message,
      details: details,
    );

    _addToHistory(recordingError);
    _logError(recordingError);
    _showErrorToUser(recordingError);

    return recordingError;
  }

  RecordingErrorType _classifyError(dynamic error) {
    if (error == null) return RecordingErrorType.unknown;

    String errorString = error.toString().toLowerCase();

    if (errorString.contains('accessibility')) {
      return RecordingErrorType.accessibilityServiceDisabled;
    } else if (errorString.contains('not initialized') ||
        errorString.contains('null')) {
      return RecordingErrorType.pluginNotInitialized;
    } else if (errorString.contains('snapshot')) {
      return RecordingErrorType.snapshotCaptureFailed;
    } else if (errorString.contains('export') ||
        errorString.contains('share')) {
      return RecordingErrorType.exportFailed;
    } else if (errorString.contains('memory')) {
      return RecordingErrorType.memoryLimit;
    } else if (errorString.contains('file') ||
        errorString.contains('storage')) {
      return RecordingErrorType.fileSystemError;
    }

    return RecordingErrorType.unknown;
  }

  String _extractMessage(dynamic error) {
    if (error == null) return 'Unknown error occurred';

    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return error.toString();
  }

  void _addToHistory(RecordingError error) {
    _errorHistory.add(error);

    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }

  void _logError(RecordingError error) {
    debugPrint('Recording Error [${error.type}]: ${error.message}');
    if (error.details != null) {
      debugPrint('Details: ${error.details}');
    }
  }

  void _showErrorToUser(RecordingError error) {
    // Show user-friendly error message with actionable guidance
    final message =
        '${error.userFriendlyMessage}\n\n${error.actionableGuidance}';
    _notificationService.showError(message);
  }

  void clearErrorHistory() {
    _errorHistory.clear();
    debugPrint('Error history cleared');
  }

  bool hasRecentError(RecordingErrorType type,
      {Duration within = const Duration(minutes: 5)}) {
    final cutoff = DateTime.now().subtract(within);
    return _errorHistory
        .any((error) => error.type == type && error.timestamp.isAfter(cutoff));
  }
}
