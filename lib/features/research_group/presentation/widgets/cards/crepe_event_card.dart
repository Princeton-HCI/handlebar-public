import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../crepe/models/crepe_event.dart';
import '../../../../researcher/presentation/widgets/crepe_event_values_list.dart';

/// Tile for displaying a [CrepeEvent] in a research group UI
class CrepeEventTile extends StatelessWidget {
  final CrepeEvent event;
  final bool fromDashboard;
  /// When true, shows a one-line preview of captured text under the field name.
  final bool showCapturedPreview;
  /// Outer card margin; defaults to horizontal inset for list screens.
  final EdgeInsetsGeometry? margin;

  const CrepeEventTile({
    super.key,
    required this.event,
    required this.fromDashboard,
    this.showCapturedPreview = false,
    this.margin,
  });

  static const _borderWidth = 1.4;
  static const _borderRadius = 12.0;

  void _showDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.token24, vertical: Spacing.token8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: Spacing.token96,
                      height: 4,
                      margin:
                          const EdgeInsets.symmetric(vertical: Spacing.token8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text("Captured Details",
                      style: context.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),

                  Spacing.vSpace8,

                  const Divider(height: 1),

                  Spacing.vSpace8,

                  CrepeEventValuesList(values: event.capturedValues),

                  Spacing.vSpace32
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dateGroupStr =
        "Collected on ${DateFormat.yMMMd().add_jm().format(event.collectedAt.toLocal())}";

    return Card(
        margin: margin ??
            const EdgeInsets.symmetric(
                horizontal: Spacing.token16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: BorderSide(color: scheme.outline, width: _borderWidth),
        ),
        child: InkWell(
          onTap: () => _showDetailsModal(context),
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
                      Text("${event.dataFieldName}",
                          style: context.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),

                      if (showCapturedPreview) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.capturedValues.displaySummary,
                          style: context.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

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
                            Flexible(
                              child: Text(
                                "Associated with ${event.groupName}",
                                style: context.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                          Expanded(
                            child: Text(
                              dateGroupStr,
                              style: context.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                Spacing.hSpace8,
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ));
  }
}
