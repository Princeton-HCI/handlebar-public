import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A horizontal breadcrumb showing the three collector-creation steps.
///
/// Completed steps are tappable for back-navigation. The active step is bold.
/// Future steps are visually disabled.
class CollectorStepperBreadcrumb extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  static const List<String> stepLabels = [
    'Upload Recording',
    'Select Frame',
    'Select Data Fields',
  ];

  const CollectorStepperBreadcrumb({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.token16,
        vertical: Spacing.token8,
      ),
      child: Row(
        children: [
          for (var i = 0; i < stepLabels.length; i++) ...[
            Flexible(
              child: _StepLabel(
                index: i,
                label: stepLabels[i],
                isActive: i == currentStep,
                isCompleted: i < currentStep,
                onTap: i < currentStep ? () => onStepTapped(i) : null,
              ),
            ),
            if (i < stepLabels.length - 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.token8),
                child: Icon(
                  Icons.chevron_right,
                  size: Spacing.token16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepLabel({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final Color color;
    if (isActive) {
      color = scheme.onSurface;
    } else if (isCompleted) {
      color = scheme.primary;
    } else {
      color = scheme.onSurfaceVariant.withValues(alpha: 0.5);
    }

    final text = Text(
      '${index + 1}. $label',
      style: context.bodyMedium?.copyWith(
        color: color,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        decoration: isCompleted ? TextDecoration.underline : null,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (onTap == null) return text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacing.token8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.token8, vertical: 4),
        child: text,
      ),
    );
  }
}
