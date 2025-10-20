import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:logging/logging.dart';

import '../models/snapshot.dart';

/// Repository responsible for loading and decoding UI snapshot data
/// from a ZIP archive selected by the user
class SnapshotRepository {
  static final Logger _logger = Logger('SnapshotRepository');

  Future<List<Snapshot>> loadSnapshotsFromZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    List<Map<String, dynamic>> rawSnapshots = [];

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract valid JSON snapshots
      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.json')) {
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
    final int startTime = rawSnapshots.first['captureTimestamp'];
    final List<Snapshot> snapshots = rawSnapshots
        .map((json) => Snapshot.fromJson(json: json, startTimestamp: startTime))
        .toList();

    _logger.info(
        'Loaded ${snapshots.length} snapshots from $zipFile successfully');

    return snapshots;
  }
}

/// Exception thrown when encountering an issue from loading snapshots
class SnapshotLoadException implements Exception {
  final String message;
  SnapshotLoadException(this.message);

  @override
  String toString() => 'SnapshotLoadException: $message';
}
