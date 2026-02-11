import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/core/shared_widgets/buttons/handlebar_button.dart';
import 'package:handlebar/features/crepe/models/snapshot_entity_queries.dart';
import 'package:handlebar/features/researcher/presentation/widgets/crepe_event_values_list.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../crepe/models/crepe_event_values.dart';

/// Bottom sheet that displays all graph queries for a [Snapshot] entity
/// and allows the user to select one of them
class SelectQueryBottomSheet extends StatefulWidget {
  final List<SnapshotEntityQueries> queryGroups;

  const SelectQueryBottomSheet({super.key, required this.queryGroups});

  @override
  State<SelectQueryBottomSheet> createState() => _SelectQueryBottomSheetState();
}

class _SelectQueryBottomSheetState extends State<SelectQueryBottomSheet> {
  late String _selectedQueryString;

  @override
  void initState() {
    super.initState();

    // Set the default query to best query (if generated) or the first query
    if (widget.queryGroups.isNotEmpty) {
      final firstGroup = widget.queryGroups.first;
      if (firstGroup.bestQueryIndex != -1 &&
          firstGroup.bestQueryIndex < firstGroup.allQueries.length) {
        _selectedQueryString =
            firstGroup.allQueries[firstGroup.bestQueryIndex].query;
      } else if (firstGroup.allQueries.isNotEmpty) {
        _selectedQueryString = firstGroup.allQueries.first.query;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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

          // Title and subtitle
          Padding(
            padding: const EdgeInsets.all(Spacing.token16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Graph Queries', style: context.titleLarge),
                const SizedBox(height: 4),
                Text(
                    'Please choose the query that best captures the target entity.',
                    style: context.bodyMedium),
              ],
            ),
          ),

          const Divider(height: 1),

          // Queries, grouped by entity
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.queryGroups.length,
              itemBuilder: (context, groupIndex) {
                final group = widget.queryGroups[groupIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Visual separator between entities
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (groupIndex > 0) const Divider(thickness: 2),
                              Container(
                                color: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Entity $groupIndex',
                                  style: context.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Query cards for this entity
                    ...group.allQueries.asMap().entries.map((entry) {
                      final queryIndex = entry.key;
                      final q = entry.value;

                      // Check: Is this the best query?
                      final isBestForThisGroup =
                          (queryIndex == group.bestQueryIndex);

                      // Check: Is this the currently selected query?
                      final isSelected = (_selectedQueryString == q.query);

                      return _QueryCard(
                        crepeEventValues: q.crepeEventValues,
                        queryString: q.query,
                        isBest: isBestForThisGroup,
                        isSelected: isSelected,
                        onSelected: () {
                          setState(() {
                            _selectedQueryString = q.query;
                          });
                        },
                      );
                    })
                  ],
                );
              },
            ),
          ),

          // Select button
          Padding(
            padding: const EdgeInsets.all(Spacing.token16),
            child: SizedBox(
              width: double.infinity,
              child: HandlebarButton(
                text: 'Select',
                variant: ButtonVariant.primary,
                isLoading: false,
                minHeight: Spacing.token40,
                onPressed: () =>
                    Navigator.of(context).pop(_selectedQueryString),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _QueryCard extends StatelessWidget {
  final CrepeEventValues crepeEventValues;
  final String queryString;
  final bool isBest;
  final bool isSelected;
  final VoidCallback onSelected;

  const _QueryCard({
    required this.crepeEventValues,
    required this.queryString,
    required this.isBest,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Card(
      elevation: isSelected ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.onSurface : Colors.transparent,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onSelected,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.token16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrepeEventValuesList(values: crepeEventValues),
                        Spacing.vSpace8,
                        Text(
                          'Query:',
                          style: context.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(
                              left: Spacing.token8, right: Spacing.token32),
                          child: Text(
                            queryString,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Checkbox Icon
                  Padding(
                    padding: EdgeInsets.only(right: Spacing.token32),
                    child: Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                      size: Spacing.token32,
                    ),
                  )
                ],
              ),
            ),
          ),
          if (isBest)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 4, horizontal: Spacing.token16),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'BEST',
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
