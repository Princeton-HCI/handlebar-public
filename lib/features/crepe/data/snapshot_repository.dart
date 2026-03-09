import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:handlebar/features/crepe/models/snapshot_entity_queries.dart';
import 'package:logging/logging.dart';

import '../models/snapshot.dart';

/// Handles UI snapshot data operations
class SnapshotRepository {
  static final Logger _logger = Logger('SnapshotRepository');

  final CrepePlugin _plugin = CrepePlugin();

  /// Loads raw snapshot JSONs from a ZIP file into a list of [Snapshot] objects
  Future<RecordingData> loadSnapshotsFromZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    List<Map<String, dynamic>> rawSnapshots = [];
    Size deviceSize = Size(0, 0);
    int? recordingStartTimestamp;

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.name.contains('metadata')) {
          // Extract the recording's metadata (device screen width + height)
          try {
            final content = utf8.decode(file.content as List<int>);
            final json = jsonDecode(content);
            deviceSize = Size(
              (json['screenWidth'] as num).toDouble(),
              (json['screenHeight'] as num).toDouble(),
            );
            recordingStartTimestamp = json['startTimestamp'] as int?;
          } catch (e) {
            _logger.warning('Failed to parse metadata file', e);
          }
          continue;
        }

        if (file.isFile && file.name.endsWith('.json')) {
          // Extract snapshot JSON
          try {
            final content = utf8.decode(file.content as List<int>);
            final decoded = jsonDecode(content);

            // Keep only files that contain UI entities
            if (decoded is Map &&
                decoded.containsKey('entities') &&
                decoded['captureTimestamp'] is int) {
              rawSnapshots.add(Map<String, dynamic>.from(decoded));
            }
          } catch (e, st) {
            _logger.warning('Skipping invalid JSON in ${file.name}: $e', e, st);
          }
        }
      }
    } catch (e, st) {
      _logger.severe('Error reading ZIP archive: $e', st);
      throw SnapshotLoadException('The selected ZIP file could not be read.');
    }

    if (rawSnapshots.isEmpty) {
      throw SnapshotLoadException(
        'The selected ZIP does not contain valid snapshot JSON files.',
      );
    }

    // Sort and convert to Snapshot models
    rawSnapshots.sort((a, b) =>
        (a['captureTimestamp'] as int).compareTo(b['captureTimestamp'] as int));
    // Use video start timestamp if available so snapshot videoTimestamps
    // align with actual video positions. Fall back to first snapshot time
    // for recordings that don't have this metadata.
    final int startTime = recordingStartTimestamp ??
        rawSnapshots.first['captureTimestamp'] as int;
    final List<Snapshot> snapshots = rawSnapshots
        .map((json) => Snapshot.fromJson(json: json, startTimestamp: startTime))
        .toList();

    _logger.info(
        'Loaded ${snapshots.length} snapshots from $zipFile successfully');

    return RecordingData(snapshots, deviceSize);
  }

  /// Returns graph queries for a snapshot [entity] in the context of the given
  /// [snapshot]
  Future<Map<int, SnapshotEntityQueries>> getQueriesForEntities(
    Snapshot snapshot,
    List<Map<String, dynamic>> entities,
  ) async {
    final String snapshotJson = jsonEncode(snapshot.toPluginJson());

    // Extract just the IDs to send to the plugin
    final List<int> entityIds =
        entities.map((e) => e['entityId'] as int).toList();

    if (entityIds.isEmpty) return {};

    try {
      // Call plugin
      final rawResults =
          await _plugin.generateQueriesForVideo(snapshotJson, entityIds);

      // Convert raw strings to domain object
      final Map<int, SnapshotEntityQueries> domainResults = {};
      for (var entry in rawResults.entries) {
        final int entityId = int.parse(entry.key.toString());
        final dynamic queryJson = entry.value;

        if (queryJson is Map) {
          domainResults[entityId] = SnapshotEntityQueries.fromJson(
              Map<String, dynamic>.from(queryJson));
        }
      }

      return domainResults;
    } catch (e) {
      _logger.severe('Failed to get queries from plugin: $e');
      rethrow;
    }
  }
}

/// Exception thrown when encountering an issue from loading snapshots
class SnapshotLoadException implements Exception {
  final String message;
  SnapshotLoadException(this.message);

  @override
  String toString() => 'SnapshotLoadException: $message';
}

/// Class to hold snapshots and the recording device size
class RecordingData {
  final List<Snapshot> snapshots;
  final Size recordingDeviceSize;

  RecordingData(this.snapshots, this.recordingDeviceSize);
}
