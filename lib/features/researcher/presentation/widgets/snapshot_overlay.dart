import 'package:flutter/material.dart';
import 'package:handlebar/features/crepe/models/snapshot.dart';

typedef SnapshotEntityTapCallback = void Function(
    List<Map<String, dynamic>> hitEntities);

/// Highlight marker for a data field defined on this snapshot.
class SelectedFieldMarker {
  /// 1-based index matching the order in [SelectedFieldsPanel].
  final int badgeNumber;

  const SelectedFieldMarker({required this.badgeNumber});
}

class _OverlayEntry {
  final int entityId;
  final Map<String, dynamic> entity;
  final Rect rect;
  final List<int>? zIndex;
  final bool isInteresting;

  const _OverlayEntry({
    required this.entityId,
    required this.entity,
    required this.rect,
    required this.zIndex,
    required this.isInteresting,
  });
}

class SnapshotOverlay extends StatelessWidget {
  final Snapshot snapshot;
  final Size videoSize;
  final Size containerSize;
  final Size originalDeviceSize;
  final SnapshotEntityTapCallback? onIntersectTap;
  final Map<String, List<int>>?
      testResults; // From testing a collector against this snapshot
  final Set<int> landmarkEntityIds;
  /// entityId → marker for data fields selected on this snapshot.
  final Map<int, SelectedFieldMarker> selectedFieldMarkers;

  const SnapshotOverlay({
    super.key,
    required this.snapshot,
    required this.videoSize,
    required this.containerSize,
    required this.originalDeviceSize,
    this.onIntersectTap,
    this.testResults,
    this.landmarkEntityIds = const {},
    this.selectedFieldMarkers = const {},
  });

  /// adding a test for whether it's something we find 'interesting'
  /// litmus test here is whether it is clickable, has text, has content description.
  /// without this, we get a lot of candidate nodes that are only containers.
  static bool _isInterestingEntity(Map<String, dynamic> entity) {
    final value = entity['value'] as Map<String, dynamic>?;
    if (value == null) return false;

    if (value['isClickable'] == true) return true;
    if (value['isEditable'] == true) return true;
    if (value['isCheckable'] == true) return true;

    final text = value['text'] as String?;
    if (text != null && text.isNotEmpty) return true;

    final desc = value['contentDescription'] as String?;
    if (desc != null && desc.isNotEmpty) return true;

    return false;
  }

  /// Compares two z-index sequences lexicographically.
  /// Returns negative if a < b, positive if a > b, zero if equal.
  /// Higher values mean drawn later (on top). Null sorts as lowest.
  static int _compareZIndex(List<int>? a, List<int>? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    final minLen = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLen; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    // If one is a prefix of the other, the longer (deeper) one is on top
    return a.length.compareTo(b.length);
  }

  /// Computes a depth rank (0 = topmost) for each box based on z-index.
  /// Returns a list parallel to the input where each value is the rank.
  static Map<int, int> _computeDepthRanks(List<_OverlayEntry> entries) {
    if (entries.isEmpty) return {};

    // Sort entity ids by z-index descending (topmost first).
    final sorted = List<_OverlayEntry>.from(entries);
    sorted.sort((a, b) => _compareZIndex(b.zIndex, a.zIndex));

    // Assign ranks and return a map keyed by entity id instead of a parallel rank list.
    final ranks = <int, int>{};
    for (int rank = 0; rank < sorted.length; rank++) {
      ranks[sorted[rank].entityId] = rank;
    }
    return ranks;
  }

  @override
  Widget build(BuildContext context) {
    // Device -> Video File Step

    // Find out how the FlutterScreenRecorder scaled the device dimensions
    final recorderFit =
        applyBoxFit(BoxFit.contain, originalDeviceSize, videoSize);
    final videoUsedSize = recorderFit.destination; // output size
    final double scale1 = videoUsedSize.width / originalDeviceSize.width;

    // Calculate recorder offsets (black bars) as the used size
    // may be less than the video size in order to maintain proper aspect ratio
    final double offsetX1 = (videoSize.width - videoUsedSize.width) / 2;
    final double offsetY1 = (videoSize.height - videoUsedSize.height) / 2;

    // Video -> This Device Screen Step

    // Find out how the video size is fit into its container on this device
    final screenFit = applyBoxFit(BoxFit.contain, videoSize, containerSize);
    final screenUsedSize = screenFit.destination;
    final double scale2 = screenUsedSize.width / videoSize.width;

    // Calculate UI offsets (black bars) as the used size
    // may be less than the container size in order to maintain proper aspect ratio
    final double offsetX2 = (containerSize.width - screenUsedSize.width) / 2;
    final double offsetY2 = (containerSize.height - screenUsedSize.height) / 2;

    final Map<int, Rect> scaledBoxesMap = {}; // entityId : Rect

    for (final entry in snapshot.boundingBoxes.entries) {
      final int entityId = entry.key;
      final Rect rect = entry.value;

      // Original device coords -> video file coords
      final videoRect = Rect.fromLTRB(
        (rect.left * scale1) + offsetX1,
        (rect.top * scale1) + offsetY1,
        (rect.right * scale1) + offsetX1,
        (rect.bottom * scale1) + offsetY1,
      );

      // Video file coords -> this device's container's coords
      scaledBoxesMap[entityId] = Rect.fromLTRB(
        (videoRect.left * scale2) + offsetX2,
        (videoRect.top * scale2) + offsetY2,
        (videoRect.right * scale2) + offsetX2,
        (videoRect.bottom * scale2) + offsetY2,
      );
    }

    // One derived UI list built from map-based snapshot data.
    final List<_OverlayEntry> overlayEntries = [];
    for (final entityId in snapshot.nodeEntities.keys) {
      final entity = snapshot.nodeEntities[entityId];
      final rect = scaledBoxesMap[entityId];

      if (entity == null || rect == null) continue;

      overlayEntries.add(
        _OverlayEntry(
          entityId: entityId,
          entity: entity,
          rect: rect,
          zIndex: snapshot.zIndexSequences[entityId],
          isInteresting: _isInterestingEntity(entity),
        ),
      );
    }

    final depthRanksByEntityId = _computeDepthRanks(overlayEntries);

    // Map the Test Mode matches to their scaled Rects for highlighting
    final Map<String, List<Rect>> highlightsToDraw = {};
    if (testResults != null) {
      for (final entry in testResults!.entries) {
        final String fieldId = entry.key;
        final List<int> matchedEntityIds = entry.value;
        final List<Rect> rectsForThisField = [];

        for (final entityId in matchedEntityIds) {
          if (scaledBoxesMap.containsKey(entityId)) {
            rectsForThisField.add(scaledBoxesMap[entityId]!);
          }
        }
        highlightsToDraw[fieldId] = rectsForThisField;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final tapPosition = details.localPosition;

        // Find ALL entries that contain the tap point
        final hits = <_OverlayEntry>[];
        for (final entry in overlayEntries) {
          if (entry.rect.contains(tapPosition)) {
            hits.add(entry);
          }
        }

        // Sort hits by z-index descending (topmost first)
        hits.sort((a, b) => _compareZIndex(b.zIndex, a.zIndex));

        // Filter to interesting entities only (skip containers).
        // Fall back to all hits if no interesting entities found.
        final interestingHits = hits.where((h) => h.isInteresting).toList();
        final result = interestingHits.isNotEmpty ? interestingHits : hits;

        onIntersectTap?.call(result.map((h) => h.entity).toList());
      },
      child: ClipRect(
        child: CustomPaint(
          size: containerSize,
          painter: _OverlayPainter(
            entries: overlayEntries,
            depthRanksByEntityId: depthRanksByEntityId,
            highlights: highlightsToDraw,
            landmarkEntityIds: landmarkEntityIds,
            selectedFieldMarkers: selectedFieldMarkers,
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<_OverlayEntry> entries;
  final Map<int, int> depthRanksByEntityId;

  // From highlight drawing
  final Map<String, List<Rect>> highlights;
  final Set<int> landmarkEntityIds;
  final Map<int, SelectedFieldMarker> selectedFieldMarkers;

  _OverlayPainter({
    required this.entries,
    required this.depthRanksByEntityId,
    required this.highlights,
    required this.landmarkEntityIds,
    required this.selectedFieldMarkers,
  });

  static const List<Color> _palette = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintInterestingBoundingBoxes(canvas);
    _paintSelectedFields(canvas);
    _paintLandmarks(canvas);
    _paintHighlights(canvas);
  }

  void _paintSelectedFields(Canvas canvas) {
    if (selectedFieldMarkers.isEmpty) return;

    final fillPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final entry in entries) {
      final marker = selectedFieldMarkers[entry.entityId];
      if (marker == null) continue;

      final rect = entry.rect;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
      _paintFieldBadge(canvas, rect, marker.badgeNumber);
    }
  }

  void _paintFieldBadge(Canvas canvas, Rect rect, int badgeNumber) {
    const badgeRadius = 12.0;
    const gapBelow = 4.0;
    final center = Offset(
      rect.center.dx,
      rect.bottom + badgeRadius + gapBelow,
    );

    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()..color = Colors.green.shade700,
    );
    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final label = '$badgeNumber';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _paintInterestingBoundingBoxes(Canvas canvas) {
    int maxRank = 0;

    // Compute max rank of interesting entries.
    for (final entry in entries) {
      if (entry.isInteresting) {
        final rank = depthRanksByEntityId[entry.entityId] ?? 0;
        if (rank > maxRank) maxRank = rank;
      }
    }

    // Only render interesting entities
    for (final entry in entries) {
      if (!entry.isInteresting) continue;

      final rank = depthRanksByEntityId[entry.entityId] ?? 0;
      final double normalizedDepth = maxRank > 0 ? rank / maxRank : 0.0;
      final double strokeAlpha = 0.80 - (normalizedDepth * 0.65);

      final strokePaint = Paint()
        ..color = Colors.red.withValues(alpha: strokeAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRect(entry.rect, strokePaint);
    }
  }

  void _paintLandmarks(Canvas canvas) {
    if (landmarkEntityIds.isEmpty) return;

    final fillPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final entry in entries) {
      if (landmarkEntityIds.contains(entry.entityId)) {
        canvas.drawRect(entry.rect, fillPaint);
        canvas.drawRect(entry.rect, strokePaint);
      }
    }
  }

  void _paintHighlights(Canvas canvas) {
    if (highlights.isEmpty) return;

    int colorIndex = 0;

    for (final entry in highlights.entries) {
      final rectsToHighlight = entry.value;
      final highlightColor = _palette[colorIndex % _palette.length];

      final fillPaint = Paint()
        ..color = highlightColor.withValues(alpha: 50 / 255)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      for (final rect in rectsToHighlight) {
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, borderPaint);
      }

      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return !identical(oldDelegate.entries, entries) ||
        !identical(oldDelegate.depthRanksByEntityId, depthRanksByEntityId) ||
        !identical(oldDelegate.highlights, highlights) ||
        !identical(oldDelegate.landmarkEntityIds, landmarkEntityIds) ||
        !identical(oldDelegate.selectedFieldMarkers, selectedFieldMarkers);
  }
}
