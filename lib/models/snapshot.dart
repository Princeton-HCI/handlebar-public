import 'dart:ui';

/// Represents a single Crepe snapshot captured from a video.
class Snapshot {
  /// Original capture timestamp (in epoch time ms)
  final int originalTimestamp;

  /// Timestamp relative to the start of the video
  final Duration videoTimestamp;

  /// Entity data describing UI elements in the snapshot
  final List<Map<String, dynamic>> entities;

  /// Rectangular screen regions corresponding to detected entities
  final List<Rect> boundingBoxes;

  Snapshot(
      {required this.originalTimestamp,
      required this.videoTimestamp,
      required this.entities,
      required this.boundingBoxes});

  /// Builds a [Snapshot] from a JSON map exported by Crepe
  factory Snapshot.fromJson(
      {required Map<String, dynamic> json, required int startTimestamp}) {
    final int originalTimestamp = json['captureTimestamp'] as int;
    final List<Map<String, dynamic>> entities =
        List<Map<String, dynamic>>.from(json['entities'] ?? []);

    // Extract bounding boxes from the entities
    final List<Rect> boundingBoxes = [];
    for (final entity in entities) {
      final boundsString = entity['boundsInScreen'] as String?;
      if (boundsString != null) {
        final corners =
            boundsString.split(' ').map((c) => double.parse(c)).toList();
        boundingBoxes
            .add(Rect.fromLTRB(corners[0], corners[1], corners[2], corners[3]));
      }
    }

    return Snapshot(
        originalTimestamp: originalTimestamp,
        videoTimestamp:
            Duration(milliseconds: originalTimestamp - startTimestamp),
        entities: entities,
        boundingBoxes: boundingBoxes);
  }
}
