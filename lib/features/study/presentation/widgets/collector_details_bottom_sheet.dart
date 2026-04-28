import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/data_field.dart';

class CollectorDetailsBottomSheet extends StatelessWidget {
  final Collector collector;
  final bool isResearcher;

  const CollectorDetailsBottomSheet({
    super.key,
    required this.collector,
    required this.isResearcher,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.token24, Spacing.token8,
              Spacing.token24, Spacing.token16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collector.description.isNotEmpty
                    ? collector.description
                    : 'Unnamed Collector',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.token4),
              Text(
                "App Package: ${collector.appPackage}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.black),

        // Data fields list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: collector.dataFields.length,
            padding: const EdgeInsets.symmetric(vertical: Spacing.token16),
            itemBuilder: (context, index) {
              return _DataFieldCard(
                dataField: collector.dataFields[index],
                showQuery: isResearcher,
              );
            },
          ),
        ),

        // Close button
        Padding(
          padding: const EdgeInsets.all(Spacing.token24),
          child: HandlebarButton.primary(
            label: 'Close',
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _DataFieldCard extends StatelessWidget {
  final DataField dataField;
  final bool showQuery;

  const _DataFieldCard({required this.dataField, required this.showQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
          horizontal: Spacing.token24, vertical: Spacing.token8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: Colors.black, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.token16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data field name
            Row(
              children: [
                const Icon(Icons.data_object, size: 20),
                const SizedBox(width: Spacing.token8),
                Expanded(
                  child: Text(
                    dataField.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Only show graph query to researchers
            if (showQuery) ...[
              Spacing.vSpace16,
              Text(
                'Graph Query:',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.token4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.token8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black54),
                ),
                child: Text(
                  dataField.graphQuery,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
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
