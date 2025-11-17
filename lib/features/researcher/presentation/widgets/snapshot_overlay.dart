import 'package:flutter/material.dart';
import 'package:handlebar/features/crepe/models/snapshot.dart';

typedef SnapshotEntityTapCallback = void Function(
    int entityIndex, Map<String, dynamic> entity);

class SnapshotOverlay extends StatelessWidget {
  final Snapshot snapshot;
  final Size referenceSize;
  final Size displaySize;
  final SnapshotEntityTapCallback? onEntityTap;

  const SnapshotOverlay({
    super.key,
    required this.snapshot,
    required this.referenceSize,
    required this.displaySize,
    this.onEntityTap,
  });

  @override
  Widget build(BuildContext context) {
    final scaleX = displaySize.width / referenceSize.width * 1.67;
    final scaleY = displaySize.height / referenceSize.height * 1.67;

    // Pre-scale all boxes
    final scaledBoxes = snapshot.boundingBoxes.map((rect) {
      return Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );
    }).toList();

    return Stack(
      children: [
        // 1. Draw bounding boxes
        CustomPaint(
          painter: _BoundingBoxPainter(scaledBoxes),
          size: displaySize,
        ),

        // 2. Invisible tap targets over each box
        ...snapshot.nodeEntities.asMap().entries.map((entry) {
          final index = entry.key;
          final entity = entry.value;
          final box = scaledBoxes[index];

          return Positioned.fromRect(
            rect: box,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onEntityTap?.call(index, entity),
              child: const SizedBox.expand(), // fills the rect
            ),
          );
        }),
      ],
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
