import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/core/shared_widgets/buttons/handlebar_button.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../crepe/models/collector.dart';
import '../../../../crepe/models/data_field.dart';

/// Bottom sheet for displaying a collector's details (description, app package,
/// data fields)
class OldCollectorDetailsBottomSheet extends StatelessWidget {
  final Collector collector;
  final bool isResearcher;

  const OldCollectorDetailsBottomSheet({
    super.key,
    required this.collector,
    required this.isResearcher,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: Spacing.token96,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: Spacing.token8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(Spacing.token16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collector.description,
                  style:
                      context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "App Package: ${collector.appPackage}",
                  style: context.bodyMedium
                      ?.copyWith(fontFamily: 'monospace', color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Data fields list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: collector.dataFields.length,
              padding: const EdgeInsets.symmetric(vertical: Spacing.token8),
              itemBuilder: (context, index) {
                final field = collector.dataFields[index];
                return _DataFieldCard(
                  dataField: field,
                  showQuery: isResearcher,
                );
              },
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(Spacing.token16),
            child: SizedBox(
              width: double.infinity,
              child: HandlebarOldButton(
                text: 'Close',
                variant: ButtonVariant.primary,
                isLoading: false,
                minHeight: Spacing.token40,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataFieldCard extends StatelessWidget {
  final DataField dataField;
  final bool showQuery;

  const _DataFieldCard({required this.dataField, required this.showQuery});

  static final _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: Spacing.token16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.token16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data field name
            Row(
              children: [
                Icon(Icons.data_object, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Datafield: ${dataField.name}",
                    style: context.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Only show graph query to researchers
            if (showQuery) ...[
              Spacing.vSpace8,

              // Query label
              Text(
                'Graph Query:',
                style: context.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),

              // Graph query code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  dataField.graphQuery,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
