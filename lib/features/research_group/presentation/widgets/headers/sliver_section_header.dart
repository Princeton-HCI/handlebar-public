import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';

/// A reusable Sliver header for separating lists in a [CustomScrollView]
class SliverSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SliverSectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.all(Spacing.token16),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: context.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (onAction != null && actionLabel != null)
                  HandlebarButton(
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
