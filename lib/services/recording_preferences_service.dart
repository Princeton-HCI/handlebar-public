import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RecordingPreferencesService {
  static const String _debugModeEnabledKey = 'ui_snapshot_debug_mode_enabled';
  static const String _captureIntervalKey = 'ui_snapshot_capture_interval';
  static const String _maxSnapshotsKey = 'ui_snapshot_max_snapshots';

  static final RecordingPreferencesService _instance =
      RecordingPreferencesService._internal();
  factory RecordingPreferencesService() => _instance;
  RecordingPreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('Recording preferences initialized');
  }

  bool get isDebugModeEnabled {
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    return _prefs!.getBool(_debugModeEnabledKey) ?? false;
  }

  Future<void> setDebugModeEnabled(bool enabled) async {
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    await _prefs!.setBool(_debugModeEnabledKey, enabled);
    debugPrint('Debug mode set to: $enabled');
  }

  int get captureIntervalSeconds {
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    return _prefs!.getInt(_captureIntervalKey) ?? 1;
  }

  Future<void> setCaptureIntervalSeconds(int seconds) async {
    if (seconds < 1 || seconds > 60) {
      debugPrint(
          'Invalid capture interval: $seconds. Must be between 1 and 60 seconds.');
      return;
    }
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    await _prefs!.setInt(_captureIntervalKey, seconds);
    debugPrint('Capture interval set to: $seconds seconds');
  }

  int get maxSnapshots {
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    return _prefs!.getInt(_maxSnapshotsKey) ?? 1200;
  }

  Future<void> setMaxSnapshots(int max) async {
    if (max < 10 || max > 1200) {
      debugPrint('Invalid max snapshots: $max. Must be between 10 and 1200.');
      return;
    }
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    await _prefs!.setInt(_maxSnapshotsKey, max);
    debugPrint('Max snapshots set to: $max');
  }

  Future<void> clearAll() async {
    if (_prefs == null) {
      throw StateError('RecordingPreferencesService not initialized');
    }
    await _prefs!.remove(_debugModeEnabledKey);
    await _prefs!.remove(_captureIntervalKey);
    await _prefs!.remove(_maxSnapshotsKey);
    debugPrint('All recording preferences cleared');
  }
}
