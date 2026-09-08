import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:crepe_plugin/crepe_plugin.dart';

import '../models/sensor_health.dart';

/// A safe wrapper around the native Crepe Android plugin.
/// Stubbed out for Web to prevent MissingPluginExceptions on the WebApp.
class CrepeService {
  final CrepePlugin _plugin = CrepePlugin();
  final _logger = Logger("CrepeService");

  Future<Map<int, Map<String, dynamic>>> generateQueriesForVideo(
    String snapshotJson,
    List<int> targetEntityIds, {
    List<String>? relationsToExclude,
  }) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] generateQueriesForVideo');
      return {};
    }
    return _plugin.generateQueriesForVideo(
      snapshotJson,
      targetEntityIds,
      relationsToExclude: relationsToExclude,
    );
  }

  Future<void> requestAccessibilityPermission() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] requestAccessibilityPermission ignored');
      return;
    }
    return _plugin.requestAccessibilityPermission();
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] isAccessibilityServiceEnabled -> false');
      return false; // Safest default for web
    }
    return _plugin.isAccessibilityServiceEnabled();
  }

  Future<void> setContinuousMonitoring(bool enabled,
      {String? collectorsJson}) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] setContinuousMonitoring($enabled) ignored');
      return;
    }
    return _plugin.setContinuousMonitoring(enabled,
        collectorsJson: collectorsJson);
  }

  Future<void> setSensorMonitoring(bool enabled, {String? sensorsJson}) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] setSensorMonitoring($enabled) ignored');
      return;
    }
    return _plugin.setSensorMonitoring(enabled, sensorsJson: sensorsJson);
  }

  Future<void> setSensorSyncConfig(String? configJson) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] setSensorSyncConfig ignored');
      return;
    }
    return _plugin.setSensorSyncConfig(configJson);
  }

  /// Device-local collection health, or null when unavailable (web, or the
  /// accessibility service has never started).
  Future<SensorHealth?> getSensorHealth() async {
    if (kIsWeb) return null;
    try {
      final json = await _plugin.getSensorHealth();
      if (json == null) return null;
      return SensorHealth.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      _logger.warning('Could not read sensor health: $e');
      return null;
    }
  }

  Future<bool> isContinuousMonitoringEnabled() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] isContinuousMonitoringEnabled -> false');
      return false;
    }
    return _plugin.isContinuousMonitoringEnabled();
  }

  /// Toggle the on-screen highlight overlay shown when a collector matches.
  /// Suppresses the visual flash only; capture is unaffected.
  Future<void> setOverlayEnabled(bool enabled) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] setOverlayEnabled($enabled) ignored');
      return;
    }
    return _plugin.setOverlayEnabled(enabled);
  }

  void setCollectorMatchesCallback(Function(Map<String, dynamic>) callback) {
    if (kIsWeb) {
      _logger.info('[WEB STUB] setCollectorMatchesCallback ignored');
      return;
    }
    _plugin.setCollectorMatchesCallback(callback);
  }

  Future<void> startRecording() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] startRecording ignored');
      return;
    }
    return _plugin.startRecording();
  }

  Future<void> stopRecording() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] stopRecording ignored');
      return;
    }
    return _plugin.stopRecording();
  }

  Future<Map<String, dynamic>> getUiSnapshot() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] getUiSnapshot -> {}');
      return {};
    }
    return _plugin.getUiSnapshot();
  }

  Future<Map<String, dynamic>> testCollectorOnSnapshot({
    required String snapshotJson,
    required String collectorJson,
  }) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] testCollectorOnSnapshot -> {}');
      return {};
    }
    return _plugin.testCollectorOnSnapshot(
      snapshotJson: snapshotJson,
      collectorJson: collectorJson,
    );
  }

  Future<void> startLiveTestMode({required String testCollectorsJson}) async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] startLiveTestMode ignored');
      return;
    }
    return _plugin.startLiveTestMode(testCollectorsJson: testCollectorsJson);
  }

  Future<void> stopLiveTestMode() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] stopLiveTestMode ignored');
      return;
    }
    return _plugin.stopLiveTestMode();
  }
}
