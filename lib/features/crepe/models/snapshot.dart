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

  Snapshot({
    required this.originalTimestamp,
    required this.videoTimestamp,
    required this.metadata,
    required this.allEntities,
    required this.nodeEntities,
    required this.triples,
    required this.boundingBoxes,
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
    for (final entityMap in allEntities) {
      if (entityMap['type'] == 'NODE') {
        // Process bounding boxes only for NODE entities
        final nodeValue = entityMap['value'] as Map<String, dynamic>?;
        final boundsString = nodeValue?['boundsInScreen'] as String?;

        if (boundsString != null) {
          nodeEntitiesList.add(entityMap);
          final corners =
              boundsString.split(' ').map((c) => double.parse(c)).toList();
          boundingBoxesList.add(
              Rect.fromLTRB(corners[0], corners[1], corners[2], corners[3]));
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
        boundingBoxes: boundingBoxesList);
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
