import 'package:flutter/material.dart';
import 'package:handlebar/extensions/context_extensions.dart';
import 'package:handlebar/widgets/common/effects/drop_shadow_container.dart';
import '../../design-system/spacing.dart';

/// A reusable, optionally selectable segmented box Widget with the Handlebar theme
class HandlebarSegmentGroup extends StatelessWidget {
  final int index;
  final void Function(int)? onPressed;
  final double minHeight;
  final List<String> tabs;

  const HandlebarSegmentGroup({
    super.key,
    required this.index,
    this.onPressed,
    this.minHeight = Spacing.token48,
    required this.tabs,
  });

  static const _borderRadius = 8.0;
  static const _borderWidth = 1.4;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final segmentBox = SegmentedButton<int>(
        showSelectedIcon: false,
        segments: List.generate(
          tabs.length,
          (i) => ButtonSegment<int>(
            value: i,
            label: Text(tabs[i], style: context.labelLarge),
          ),
        ),
        selected: {index},
        onSelectionChanged: onPressed != null
            ? (newSelection) => onPressed!(newSelection.first)
            : null,
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          selectedBackgroundColor: Colors.blue[200],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
              side: BorderSide(color: scheme.outline, width: _borderWidth)),
          padding: EdgeInsets.symmetric(
            vertical: (minHeight - 24).clamp(0, double.infinity) / 2,
          ),
        ));

    return DropShadowContainer(borderRadius: _borderRadius, child: segmentBox);
  }
}
