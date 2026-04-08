import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../crepe/models/data_field.dart';

/// Persistent panel listing the [DataField]s the user has accumulated for
/// the collector under construction. Each row has a three-dot menu with
/// Edit / Delete actions.
class SelectedFieldsPanel extends StatelessWidget {
  final List<DataField> fields;
  final int currentSnapshot;
  final int totalSnapshots;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;

  const SelectedFieldsPanel({
    super.key,
    required this.fields,
    required this.currentSnapshot,
    required this.totalSnapshots,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.token16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected Data Fields:',
                  style: context.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (totalSnapshots > 0)
                Text(
                  'Snapshot ${currentSnapshot + 1} of $totalSnapshots',
                  style: context.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          Spacing.vSpace8,
          if (fields.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.token16),
              child: Center(
                child: Text(
                  'No data fields are selected. Tap on a red box to add a '
                  'field to this collector.',
                  textAlign: TextAlign.center,
                  style: context.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...fields.asMap().entries.map((e) {
              final i = e.key;
              final f = e.value;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(f.name),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'edit') onEdit(i);
                      if (v == 'delete') onDelete(i);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
