import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../crepe/models/collector.dart';
import '../../../../crepe/models/participant_collector.dart';
import '../../../../crepe/utils/collection_frequency.dart';
import '../bottom-sheets/collector_details_bottom_sheet.dart';

/// Tile for displaying a [Collector] in the research group UI
class CollectorTile extends StatelessWidget {
  final Collector collector;
  final String? groupName;

  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const CollectorTile({
    super.key,
    required this.collector,
    this.groupName,
    this.onDelete,
    this.onEdit,
  });

  factory CollectorTile.participant(ParticipantCollector item,
      {VoidCallback? onTap}) {
    return CollectorTile(
      collector: item.collector,
      groupName: item.groupName,
    );
  }

  void _showCollectorDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => OldCollectorDetailsBottomSheet(
          collector: collector, isResearcher: onDelete != null),
    );
  }

  static const _borderWidth = 1.4;
  static const _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: Spacing.token16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outline, width: _borderWidth),
        borderRadius: BorderRadius.circular(_borderRadius),
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
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: const Icon(Icons.android,
                  color: Colors.teal, size: Spacing.token16),
            ),
            Spacing.hSpace16,

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Researcher-defined description of collector
                  Text(collector.description,
                      style: context.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 4),

                  // Data field names summary
                  if (collector.dataFields.isNotEmpty)
                    Text(
                      'Data Fields: ${collector.dataFields.map((f) => f.name).join(', ')}',
                      style: context.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      collector.appPackage,
                      style: context.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Collection-frequency chip (only when not "every time")
                  if ((collector.collectionIntervalSeconds ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule,
                            size: Spacing.token16, color: scheme.onSurface),
                        Spacing.hSpace8,
                        Flexible(
                          child: Text(
                            collectionFrequencyLabel(
                                collector.collectionIntervalSeconds),
                            style: context.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Conditional group name chip
                  if (groupName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group,
                            size: Spacing.token16, color: scheme.onSurface),
                        Spacing.hSpace8,
                        Flexible(
                          child: Text(
                            "Associated with $groupName",
                            style: context.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Trailing action - 3 dots
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: scheme.onSurface),
              itemBuilder: (context) => [
                // View collector details
                PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: scheme.onSurface),
                      Spacing.hSpace8,
                      Text("Details",
                          style: TextStyle(color: scheme.onSurface)),
                    ],
                  ),
                ),
                if (onEdit != null)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 20, color: scheme.onSurface),
                        Spacing.hSpace8,
                        Text("Edit Collector",
                            style: TextStyle(color: scheme.onSurface)),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: scheme.error),
                        Spacing.hSpace8,
                        Text("Delete Collector",
                            style: TextStyle(color: scheme.error)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'details') _showCollectorDetails(context);
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
            )
          ],
        ),
      ),
    );
  }
}
