import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:crepe_plugin/crepe_plugin.dart';

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

  Future<bool> isContinuousMonitoringEnabled() async {
    if (kIsWeb) {
      _logger.info('[WEB STUB] isContinuousMonitoringEnabled -> false');
      return false;
    }
    return _plugin.isContinuousMonitoringEnabled();
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
