import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../crepe/models/crepe_event_values.dart';

/// Displays a [CrepeEventValues] model as a nicely-formatted list
class CrepeEventValuesList extends StatelessWidget {
  final CrepeEventValues values;

  const CrepeEventValuesList({super.key, required this.values});

  Widget _buildValueRow(
    BuildContext context, {
    required String label,
    required String? value,
    bool isRelation = false,
  }) {
    // If the value is null or empty, don't draw anything
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  label.toUpperCase(),
                  style: context.labelSmall?.copyWith(
                    color: Colors.grey,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Value
                Text(
                  '"$value"',
                  style: context.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(
        "No text values captured",
        style: TextStyle(color: context.colorScheme.outline),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Direct node properties
        _buildValueRow(
          context,
          label: 'Node Text:',
          value: values.nodeText,
        ),
        _buildValueRow(
          context,
          label: 'Content Description:',
          value: values.nodeContentDescription,
        ),

        // Relation properties
        _buildValueRow(
          context,
          label: 'Linked Text:',
          value: values.relationText,
          isRelation: true,
        ),
        _buildValueRow(
          context,
          label: 'Linked Description:',
          value: values.relationContentDescription,
          isRelation: true,
        ),
        _buildValueRow(
          context,
          label: 'Linked Child Texts:',
          value: values.relationChildTexts,
          isRelation: true,
        ),
      ],
    );
  }
}
