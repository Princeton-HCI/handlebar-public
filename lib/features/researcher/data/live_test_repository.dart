import 'dart:convert';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:logging/logging.dart';

import '../../crepe/models/collector.dart';

class LiveTestRepository {
  static final Logger _logger = Logger('LiveTestRepository');
  final CrepePlugin _plugin = CrepePlugin();

  /// Starts a live test session for the parameter collectors
  Future<void> startLiveTestSession(List<Collector> collectors) async {
    if (!await _plugin.isAccessibilityServiceEnabled()) {
      throw Exception("Accessibility Service not enabled");
    }

    try {
      final Map<String, dynamic> transformedData = {
        'Collector': <String, dynamic>{},
        'Datafield': <String, dynamic>{},
        'Data': <String, dynamic>{},
        'User': <String, dynamic>{},
      };

      for (final c in collectors) {
        final String cid = c.collectorId.toString();

        transformedData['Collector']![cid] = {
          'appName': c.appName,
          'appPackage': c.appPackage,
          'collectorId': cid,
          'membership_id': 0, // Default for testing
          'collectorStatus': 'active',
          'description': c.description,
          'collectorStartTime': 0,
          'collectorEndTime': 0,
          'deleted': false,
        };

        for (final df in c.dataFields) {
          final String dfid = df.dataFieldId.toString();
          transformedData['Datafield']![dfid] = {
            'collectorId': cid,
            'datafieldId': dfid,
            'name': df.name,
            'graphQuery': df.graphQuery,
            'demonstrated': false,
            'timeCreated': 0,
            'timelastEdited': 0,
          };
        }
      }

      final String jsonBundle = jsonEncode(transformedData);

      _logger.info('Sending ${collectors.length} collectors to Live Test Mode');
      await _plugin.startLiveTestMode(testCollectorsJson: jsonBundle);
    } catch (e, st) {
      _logger.severe('Failed to start live test session: $e', e, st);
      rethrow;
    }
  }

  /// Tells the Accessibility Service to stop testing and restore previous state
  Future<void> stopLiveTestSession() async {
    try {
      await _plugin.stopLiveTestMode();
      _logger.info('Live test session stopped successfully');
    } catch (e, st) {
      _logger.severe('Failed to stop live test session: $e', e, st);
      rethrow;
    }
  }
}
