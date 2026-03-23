import 'dart:ui';

/// Represents a single Crepe snapshot captured from a video.
class Snapshot {
  /// Original capture timestamp (in epoch time ms)
  final int originalTimestamp;

  /// Timestamp relative to the start of the video
  final Duration videoTimestamp;

  /// Full metadata map (packageName, activityName)
  final Map<String, dynamic> metadata;

  /// The original, complete list of ALL entities
  final List<Map<String, dynamic>> allEntities;

  /// A filtered list containing ONLY the entities that are NODEs
  final List<Map<String, dynamic>> nodeEntities;

  /// Triple data describing relationships between entities
  final List<Map<String, dynamic>> triples;

  /// Rectangular screen regions corresponding to NODE-type entities
  final List<Rect> boundingBoxes;

  /// Z-index sequences for each node entity (parallel to [nodeEntities]).
  /// Each sequence is a list of drawing-order values from root to leaf.
  /// Null for entities from older recordings without z-index data.
  final List<List<int>?> zIndexSequences;

  Snapshot({
    required this.originalTimestamp,
    required this.videoTimestamp,
    required this.metadata,
    required this.allEntities,
    required this.nodeEntities,
    required this.triples,
    required this.boundingBoxes,
    required this.zIndexSequences,
  });

  /// Builds a [Snapshot] from a JSON map exported by the Crepe plugin
  factory Snapshot.fromJson(
      {required Map<String, dynamic> json, required int startTimestamp}) {
    // Get all the raw data from the JSON
    final int originalTimestamp = json['captureTimestamp'] as int;
    final Map<String, dynamic> metadata =
        Map<String, dynamic>.from(json['metadata'] ?? {});
    final List<Map<String, dynamic>> allEntities =
        List<Map<String, dynamic>>.from(json['entities'] ?? []);
    final List<Map<String, dynamic>> triples =
        List<Map<String, dynamic>>.from(json['triples'] ?? []);

    final List<Map<String, dynamic>> nodeEntitiesList = [];
    final List<Rect> boundingBoxesList = [];
    final List<List<int>?> zIndexSequencesList = [];
    for (final entityMap in allEntities) {
      if (entityMap['type'] == 'NODE') {
        // Process bounding boxes only for NODE entities
        final nodeValue = entityMap['value'] as Map<String, dynamic>?;
        final boundsString = nodeValue?['boundsInScreen'] as String?;

        // Skip nodes that are not visible to the user (e.g. off-screen
        // navigation drawer items). Default to true for older recordings
        // that don't have this field.
        final bool isVisible =
            nodeValue?['isVisibleToUser'] as bool? ?? true;

        if (boundsString != null && isVisible) {
          nodeEntitiesList.add(entityMap);
          final corners =
              boundsString.split(' ').map((c) => double.parse(c)).toList();
          boundingBoxesList.add(
              Rect.fromLTRB(corners[0], corners[1], corners[2], corners[3]));

          // Parse z-index sequence (null for older recordings)
          final rawZSeq = nodeValue?['nodeZIndexSequence'] as List<dynamic>?;
          zIndexSequencesList.add(
            rawZSeq?.map((e) => (e as num).toInt()).toList(),
          );
        }
      }
    }

    return Snapshot(
        originalTimestamp: originalTimestamp,
        videoTimestamp:
            Duration(milliseconds: originalTimestamp - startTimestamp),
        metadata: metadata,
        allEntities: allEntities,
        nodeEntities: nodeEntitiesList,
        triples: triples,
        boundingBoxes: boundingBoxesList,
        zIndexSequences: zIndexSequencesList);
  }

  /// Converts the Snapshot back into a JSON-compatible map for the Crepe plugin
  Map<String, dynamic> toPluginJson() {
    return {
      'metadata': metadata,
      'entities': allEntities,
      'triples': triples,
    };
  }
}
