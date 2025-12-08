import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../crepe/models/crepe_event.dart';

/// Tile for displaying a [CrepeEvent] in a research group UI
class CrepeEventTile extends StatelessWidget {
  final CrepeEvent event;
  final bool fromDashboard;

  const CrepeEventTile(
      {super.key, required this.event, required this.fromDashboard});

  static const _borderWidth = 1.4;
  static const _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dateGroupStr =
        "Collected on ${DateFormat.yMMMd().add_jm().format(event.collectedAt.toLocal())}";

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: Spacing.token16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: scheme.outline, width: _borderWidth),
      ),
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: const Icon(Icons.data_array,
                  color: Colors.blue, size: Spacing.token16),
            ),
            Spacing.hSpace16,

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Datafield name
                  Text("Datafield: ${event.dataFieldName}",
                      style: context.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),

                  // Crepe event captured value
                  Text(
                    "Captured Value: ${event.capturedValue}",
                    style: context.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (fromDashboard) ...[
                    // If displaying from dashboard display which research group
                    // the event belongs to
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group,
                            size: Spacing.token16, color: scheme.onSurface),
                        Spacing.hSpace8,
                        Text(
                          "Associated with ${event.groupName}",
                          style: context.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Collection date
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        dateGroupStr,
                        style: context.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
