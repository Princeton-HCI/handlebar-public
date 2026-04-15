import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:handlebar/features/crepe/models/snapshot_entity_queries.dart';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../models/collector.dart';
import '../models/snapshot.dart';

typedef LlmQuerySelectionResult = Result<Map<int, LlmQuerySelection>, ApiError>;

/// Handles UI snapshot data operations
class SnapshotRepository {
  final ApiClient _api;
  static final Logger _logger = Logger('SnapshotRepository');

  SnapshotRepository(this._api);

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
      String datafieldDescription,
      int groupId) async {
    final String snapshotJson = jsonEncode(snapshot.toPluginFormat());

    // Extract just the IDs to send to the plugin
    final List<int> entityIds =
        entities.map((e) => e['entityId'] as int).toList();

    if (entityIds.isEmpty) return {};

    try {
      // Call plugin
      final rawResults =
          await _plugin.generateQueriesForVideo(snapshotJson, entityIds);

      // Convert raw strings to domain object
      final Map<int, SnapshotEntityQueries> baseResults = {};
      for (final entry in rawResults.entries) {
        final int entityId = int.parse(entry.key.toString());
        final dynamic queryJson = entry.value;

        if (queryJson is Map) {
          // For every entity, we map it to their queries
          baseResults[entityId] = SnapshotEntityQueries.fromJson(
            Map<String, dynamic>.from(queryJson),
          );
        }
      }

      return await _tryEnrichBatchWithLlm(
          baseResults: baseResults,
          datafieldDescription: datafieldDescription,
          groupId: groupId);
    } catch (e) {
      _logger.severe('Failed to get queries from plugin: $e');
      rethrow;
    }
  }

  Future<Map<int, SnapshotEntityQueries>> _tryEnrichBatchWithLlm({
    required Map<int, SnapshotEntityQueries> baseResults,
    required String datafieldDescription,
    required int groupId,
  }) async {
    if (baseResults.isEmpty) {
      return {};
    }

    // Skip entities with no query at all
    final entitiesToEnrich = <int, SnapshotEntityQueries>{
      for (final entry in baseResults.entries)
        if (entry.value.queries.isNotEmpty) entry.key: entry.value,
    };

    if (entitiesToEnrich.isEmpty) {
      return baseResults;
    }

    final res = await _selectAndDescribeQueriesBatchWithLlm(
      userDescription: datafieldDescription,
      entities: entitiesToEnrich,
      groupId: groupId,
    );

    return res.fold(
      onSuccess: (llmResults) => _mergeBatchWithLlmResults(
        baseResults: baseResults,
        llmResults: llmResults,
      ),
      onFailure: (e) {
        _logger.warning(
          'Batched LLM enrichment failed, using plugin results as fallback: ${e}',
        );
        return baseResults;
      },
    );
  }

  Future<LlmQuerySelectionResult> _selectAndDescribeQueriesBatchWithLlm(
      {required String userDescription,
      required Map<int, SnapshotEntityQueries> entities,
      required int groupId}) async {
    try {
      final payload = {
        'user_description': userDescription,
        'entities': [
          for (final entry in entities.entries)
            {
              'entity_id': entry.key,
              'queries': [
                for (final queryEntry in entry.value.queries.asMap().entries)
                  {
                    'index': queryEntry.key,
                    'query': queryEntry.value.query,
                  },
              ],
            },
        ],
      };

      final response = await _api.post(
        '/api/research/groups/$groupId/llm/query-selection',
        body: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseMap = jsonDecode(response.body) as Map<String, dynamic>;

        final rawResults = Map<String, dynamic>.from(
            responseMap['results'] as Map? ?? const {});

        final parsed = <int, LlmQuerySelection>{};

        for (final entry in rawResults.entries) {
          final entityId = int.tryParse(entry.key);
          if (entityId == null) continue;

          final value = entry.value;
          if (value is Map) {
            parsed[entityId] = LlmQuerySelection.fromJson(
              Map<String, dynamic>.from(value),
            );
          }
        }

        return Success(parsed);
      }

      if (ApiClient.isUnauthorized(response)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'selectAndDescribeQueriesBatchWithLlm',
        );
      }

      return ApiClient.unhandledFailure(
        _logger,
        response,
        action: 'selectAndDescribeQueriesBatchWithLlm',
      );
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(
        _logger,
        e,
        action: 'selectAndDescribeQueriesBatchWithLlm',
      );
    } catch (e, st) {
      return ApiClient.unexpectedFailure(
        _logger,
        e,
        st,
        action: 'selectAndDescribeQueriesBatchWithLlm',
      );
    }
  }

  // Merge backend descriptions + backend best index into plugin result
  // for ALL entities' queries
  Map<int, SnapshotEntityQueries> _mergeBatchWithLlmResults({
    required Map<int, SnapshotEntityQueries> baseResults,
    required Map<int, LlmQuerySelection> llmResults,
  }) {
    final merged = <int, SnapshotEntityQueries>{};

    for (final entry in baseResults.entries) {
      final entityId = entry.key;
      final base = entry.value;
      final llm = llmResults[entityId];

      if (llm == null) {
        merged[entityId] = base;
        continue;
      }

      merged[entityId] = _mergeWithLlmResult(base, llm);
    }

    return merged;
  }

  // Merge backend descriptions + backend best index into plugin result for a
  // SINGLE entity's queries
  SnapshotEntityQueries _mergeWithLlmResult(
    SnapshotEntityQueries base,
    LlmQuerySelection llm,
  ) {
    final updatedQueries = base.queries.asMap().entries.map((entry) {
      final index = entry.key;
      final query = entry.value;

      final llmDescription = llm.descriptions[index];

      return query.copyWith(
        // Replace description only if backend gave us one.
        description:
            (llmDescription != null && llmDescription.trim().isNotEmpty)
                ? llmDescription
                : query.description,
      );
    }).toList();

    // Use backend best index only if valid, otherwise keep plugin heuristic
    final safeBestIndex =
        (llm.bestIndex >= 0 && llm.bestIndex < updatedQueries.length)
            ? llm.bestIndex
            : _safeBestIndex(base.bestQueryIndex, updatedQueries.length);

    return SnapshotEntityQueries(
      queries: updatedQueries,
      bestQueryIndex: safeBestIndex,
    );
  }

  int _safeBestIndex(int index, int queryCount) {
    if (queryCount == 0) return -1;
    if (index < 0 || index >= queryCount) return 0;
    return index;
  }

  /// Tests a specific [Collector] against a single [Snapshot]
  /// Returns a map of DataField IDs to a list of matched SugiliteEntity IDs.
  Future<Map<String, List<int>>> testCollector(
    Snapshot snapshot,
    Collector collector,
  ) async {
    try {
      // Serialize the snapshot
      final String snapshotJson = jsonEncode(snapshot.toPluginFormat());

      // Serialize the collector
      final String collectorJson = jsonEncode(collector.toPluginFormat());

      // Call the plugin
      _logger.info(
          'Testing collector ${collector.description} against snapshot...');
      final Map<String, dynamic> rawMatches =
          await _plugin.testCollectorOnSnapshot(
        snapshotJson: snapshotJson,
        collectorJson: collectorJson,
      );

      // Safely cast to strong Dart types
      final Map<String, List<int>> typedMatches = rawMatches.map((key, value) {
        final List<int> entityIds = List<int>.from(value as List<dynamic>);
        return MapEntry(key, entityIds);
      });

      _logger.info(
          'Test complete. Found matches for ${typedMatches.length} data fields.');
      return typedMatches;
    } catch (e, st) {
      _logger.severe('Failed to test collector on snapshot: $e', e, st);
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
