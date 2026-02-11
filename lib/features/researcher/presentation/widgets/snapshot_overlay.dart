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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final tapPosition = details.localPosition;

        // Find ALL boxes that contain the tap point
        final List<Map<String, dynamic>> hits = [];
        for (int i = 0; i < scaledBoxes.length; i++) {
          if (scaledBoxes[i].contains(tapPosition)) {
            hits.add(snapshot.nodeEntities[i]);
          }
        }

        // Return the list (empty or populated)
        onIntersectTap?.call(hits);
      },
      child: ClipRect(
        child: CustomPaint(
          size: containerSize,
          painter: _BoundingBoxPainter(scaledBoxes),
        ),
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final Paint _paint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;

  _BoundingBoxPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final rect in boxes) {
      canvas.drawRect(rect, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return !identical(oldDelegate.boxes, boxes);
  }
}
