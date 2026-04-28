import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/features/study/data/models/research_study.dart';

import '../../../../../app/design-system/spacing.dart';

/// Tile for displaying a [ResearchStudy] in the research group UI
class ResearchGroupTile extends StatelessWidget {
  final ResearchStudy group;
  final VoidCallback? onTap;

  const ResearchGroupTile({super.key, required this.group, this.onTap});

  static const _borderWidth = 1.4;
  static const _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Card(
        margin: const EdgeInsets.symmetric(
            horizontal: Spacing.token16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.outline, width: _borderWidth),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.token16, vertical: Spacing.token8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: Spacing.token32,
                  height: Spacing.token32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  child: Icon(Icons.group,
                      color: scheme.onSurface, size: Spacing.token16),
                ),

                Spacing.hSpace16,

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group name
                      Text(group.name,
                          style: context.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),

                      const SizedBox(height: 4),

                      // Group description
                      Text(
                        group.description,
                        style: context.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (group.isResearcher) ...[
                        // Group code if researcher
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.key,
                                size: Spacing.token16, color: scheme.onSurface),
                            const SizedBox(width: 4),
                            Text("Code: ${group.code}",
                                style: context.labelMedium
                                    ?.copyWith(fontFamily: 'monospace')),
                          ],
                        )
                      ]
                    ],
                  ),
                ),

                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ]
              ],
            ),
          ),
        ));
  }
}
