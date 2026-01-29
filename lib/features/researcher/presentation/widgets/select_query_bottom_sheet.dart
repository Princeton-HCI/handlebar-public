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
  final List<SnapshotQuery> allQueries;
  final int bestQueryIndex;

  const SelectQueryBottomSheet({
    super.key,
    required this.allQueries,
    required this.bestQueryIndex,
  });

  @override
  State<SelectQueryBottomSheet> createState() => _SelectQueryBottomSheetState();
}

class _SelectQueryBottomSheetState extends State<SelectQueryBottomSheet> {
  late String _selectedQueryString;

  @override
  void initState() {
    super.initState();

    // Set the default query to best query (if generated) or the first query
    SnapshotQuery defaultQuery;
    if (widget.bestQueryIndex != -1 &&
        widget.bestQueryIndex < widget.allQueries.length) {
      defaultQuery = widget.allQueries[widget.bestQueryIndex];
    } else {
      defaultQuery = widget.allQueries[0];
    }
    _selectedQueryString = defaultQuery.query;
  }

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

          // Queries
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.allQueries.length,
              itemBuilder: (context, index) {
                final SnapshotQuery q = widget.allQueries[index];
                final String queryString = q.query;
                final CrepeEventValues crepeEventValues = q.crepeEventValues;

                final isBest = (index == widget.bestQueryIndex);
                return _QueryCard(
                  crepeEventValues: crepeEventValues,
                  queryString: queryString,
                  isBest: isBest,
                  isSelected: _selectedQueryString == queryString,
                  onSelected: () {
                    setState(() {
                      _selectedQueryString = queryString;
                    });
                  },
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
    );
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
