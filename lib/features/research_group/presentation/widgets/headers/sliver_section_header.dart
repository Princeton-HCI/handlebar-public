import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';

/// A reusable Sliver header for separating lists in a [CustomScrollView]
class SliverSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional tooltip message shown via an (i) icon next to the title
  final String? infoTooltip;

  const SliverSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.infoTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.all(Spacing.token16),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: context.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (infoTooltip != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: infoTooltip!,
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 4),
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (onAction != null && actionLabel != null)
                  HandlebarOldButton(
                    text: actionLabel!,
                    onPressed: onAction,
                    variant: ButtonVariant.primary,
                    isLoading: false,
                    minHeight: 36,
                  ),
              ],
            ),
            Divider()
          ])),
    );
  }
}
