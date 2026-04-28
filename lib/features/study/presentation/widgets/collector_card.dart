import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import '../../../../../app/design-system/spacing.dart';
import '../../../crepe/models/collector.dart';

class CollectorCard extends StatelessWidget {
  final Collector collector;
  final bool isResearcher;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const CollectorCard({
    super.key,
    required this.collector,
    required this.isResearcher,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final fieldNamesString = collector.dataFields.map((f) => f.name).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.token8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(Spacing.token8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.token16,
          vertical: Spacing.token16,
        ),

        // Layers icon
        leading: Icon(
          Icons.layers,
          size: 28,
          color: theme.colorScheme.onSurfaceVariant,
        ),

        // Title
        title: Text(
          collector.description.isNotEmpty
              ? collector.description
              : 'Unnamed Collector',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),

        // Subtitle (Data fields, max 1 line, italic)
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Data Collectors: $fieldNamesString",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Three-dot menu
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'details') onViewDetails();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 20, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('View Details'),
                  ],
                ),
              ),
            ];

            // Only add delete option if they are a researcher
            if (isResearcher) {
              items.add(
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Collector',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              );
            }
            return items;
          },
        ),
      ),
    );
  }
}
