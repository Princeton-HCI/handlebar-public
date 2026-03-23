import 'package:flutter/material.dart';
import 'package:handlebar/features/crepe/models/snapshot.dart';

typedef SnapshotEntityTapCallback = void Function(
    List<Map<String, dynamic>> hitEntities);

class SnapshotOverlay extends StatelessWidget {
  final Snapshot snapshot;
  final Size videoSize;
  final Size containerSize;
  final Size originalDeviceSize;
  final SnapshotEntityTapCallback? onIntersectTap;

  const SnapshotOverlay({
    super.key,
    required this.snapshot,
    required this.videoSize,
    required this.containerSize,
    required this.originalDeviceSize,
    this.onIntersectTap,
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
  static List<int> _computeDepthRanks(List<List<int>?> zIndexSequences) {
    if (zIndexSequences.isEmpty) return [];

    // Create indexed list and sort by z-index descending (topmost first)
    final indexed = List.generate(zIndexSequences.length, (i) => i);
    indexed.sort((a, b) =>
        _compareZIndex(zIndexSequences[b], zIndexSequences[a]));

    // Assign ranks
    final ranks = List.filled(zIndexSequences.length, 0);
    for (int rank = 0; rank < indexed.length; rank++) {
      ranks[indexed[rank]] = rank;
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

    final scaledBoxes = snapshot.boundingBoxes.map((rect) {
      // Original device coords -> video file coords
      final videoRect = Rect.fromLTRB(
        (rect.left * scale1) + offsetX1,
        (rect.top * scale1) + offsetY1,
        (rect.right * scale1) + offsetX1,
        (rect.bottom * scale1) + offsetY1,
      );

      // Video file coords -> this device's container's coords
      return Rect.fromLTRB(
        (videoRect.left * scale2) + offsetX2,
        (videoRect.top * scale2) + offsetY2,
        (videoRect.right * scale2) + offsetX2,
        (videoRect.bottom * scale2) + offsetY2,
      );
    }).toList();

    // Mark which nodes are interesting (interactive or content-bearing)
    final isInteresting = snapshot.nodeEntities
        .map((e) => _isInterestingEntity(e))
        .toList();

    // Compute depth ranks for visual rendering
    final depthRanks = _computeDepthRanks(snapshot.zIndexSequences);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final tapPosition = details.localPosition;

        // Find ALL boxes that contain the tap point, with their indices
        final List<(int, Map<String, dynamic>)> hits = [];
        for (int i = 0; i < scaledBoxes.length; i++) {
          if (scaledBoxes[i].contains(tapPosition)) {
            hits.add((i, snapshot.nodeEntities[i]));
          }
        }

        // Sort by z-index descending (topmost first)
        hits.sort((a, b) => _compareZIndex(
            snapshot.zIndexSequences[b.$1],
            snapshot.zIndexSequences[a.$1]));

        // Filter to interesting entities only (skip containers).
        // Fall back to all hits if no interesting entities found.
        final interestingHits =
            hits.where((h) => _isInterestingEntity(h.$2)).toList();
        final result = interestingHits.isNotEmpty ? interestingHits : hits;

        onIntersectTap?.call(result.map((h) => h.$2).toList());
      },
      child: ClipRect(
        child: CustomPaint(
          size: containerSize,
          painter: _BoundingBoxPainter(scaledBoxes, depthRanks, isInteresting),
        ),
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final List<int> depthRanks;
  final List<bool> isInteresting;

  _BoundingBoxPainter(this.boxes, this.depthRanks, this.isInteresting);

  @override
  void paint(Canvas canvas, Size size) {
    // we use node 'interesting' rank to determine the opacity of the bounding box
    int maxRank = 0;
    for (int i = 0; i < boxes.length; i++) {
      if (isInteresting.isNotEmpty && isInteresting[i] && depthRanks.isNotEmpty) {
        if (depthRanks[i] > maxRank) maxRank = depthRanks[i];
      }
    }

    for (int i = 0; i < boxes.length; i++) {
      // Only render interesting (interactive/content-bearing) nodes
      if (isInteresting.isNotEmpty && !isInteresting[i]) continue;

      final rect = boxes[i];
      final rank = depthRanks.isNotEmpty ? depthRanks[i] : 0;

      // Stroke opacity: topmost ~0.80, deeper → ~0.15
      final double normalizedDepth = maxRank > 0 ? rank / maxRank : 0.0;
      final double strokeAlpha = 0.80 - (normalizedDepth * 0.65);

      final strokePaint = Paint()
        ..color = Colors.red.withValues(alpha: strokeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return !identical(oldDelegate.boxes, boxes) ||
        !identical(oldDelegate.depthRanks, depthRanks) ||
        !identical(oldDelegate.isInteresting, isInteresting);
  }
}
