import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../crepe/models/data_field.dart';
import '../../../crepe/models/snapshot.dart';
import '../../../crepe/models/snapshot_entity_queries.dart';
import '../view_models/video_session_view_model.dart';
import 'crepe_event_values_list.dart';

/// A near-full-height bottom sheet for creating or editing a [DataField].
///
/// Used in two modes:
///   - **Create**: triggered by tapping a red bounding box on a snapshot. The
///     [hitEntities] are queried to produce candidate graph queries; the name
///     field is auto-filled with the tapped element's text.
///   - **Edit**: opens pre-populated with an existing [initial] field. Query
///     cards are still shown so the user can change the query.
class DataFieldEditorSheet extends StatefulWidget {
  final VideoSessionViewModel session;
  final Snapshot snapshot;
  final List<Map<String, dynamic>> hitEntities;

  /// Existing field when editing; null when creating a new one.
  final DataField? initial;

  const DataFieldEditorSheet({
    super.key,
    required this.session,
    required this.snapshot,
    required this.hitEntities,
    this.initial,
  });

  /// Best-effort extraction of a human-readable label for the tapped element.
  static String? extractEntityText(List<Map<String, dynamic>> entities) {
    for (final e in entities) {
      final value = e['value'] as Map<String, dynamic>?;
      if (value == null) continue;
      final text = value['text'] as String?;
      if (text != null && text.isNotEmpty) return text;
      final desc = value['contentDescription'] as String?;
      if (desc != null && desc.isNotEmpty) return desc;
    }
    return null;
  }

  @override
  State<DataFieldEditorSheet> createState() => _DataFieldEditorSheetState();
}

class _DataFieldEditorSheetState extends State<DataFieldEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedQuery;
  List<SnapshotEntityQueries> _queryGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final autoFill = DataFieldEditorSheet.extractEntityText(widget.hitEntities);
    _nameCtrl = TextEditingController(text: initial?.name ?? autoFill ?? '');
    _descCtrl = TextEditingController();
    _selectedQuery = initial?.graphQuery;
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    final groups = await widget.session
        .getQueriesForEntities(widget.snapshot, widget.hitEntities);
    if (!mounted) return;
    setState(() {
      _queryGroups = groups;
      _loading = false;
      // Auto-select best query when creating new
      if (_selectedQuery == null && groups.isNotEmpty) {
        final first = groups.first;
        if (first.bestQueryIndex != -1 &&
            first.bestQueryIndex < first.allQueries.length) {
          _selectedQuery = first.allQueries[first.bestQueryIndex].query;
        } else if (first.allQueries.isNotEmpty) {
          _selectedQuery = first.allQueries.first.query;
        }
      }
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedQuery == null) return;
    Navigator.of(context)
        .pop(DataField(name: name, graphQuery: _selectedQuery!));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final autoFillText =
        DataFieldEditorSheet.extractEntityText(widget.hitEntities);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(Spacing.token16)),
        ),
        child: Column(
          children: [
            // Top action bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Spacing.token8, vertical: Spacing.token8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.initial == null
                          ? 'New Data Field'
                          : 'Edit Data Field',
                      style: context.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _save,
                    tooltip: 'Save Data Field',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Spacing.token16),
                children: [
                  if (autoFillText != null) ...[
                    Text(
                      'Current Data Field: "$autoFillText"',
                      style: context.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Spacing.vSpace16,
                  ],
                  Text('Enter Name of Field:', style: context.labelLarge),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Field name',
                    ),
                  ),
                  Spacing.vSpace16,
                  Text('Enter Description:', style: context.labelLarge),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _descCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Optional',
                    ),
                  ),
                  Spacing.vSpace24,
                  Text('Select Query:', style: context.labelLarge),
                  Text(
                    'Best match automatically selected.',
                    style: context.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Spacing.vSpace8,
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(Spacing.token24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_queryGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(Spacing.token16),
                      child: Text('No queries available for this element.'),
                    )
                  else
                    ..._buildQueryCards(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQueryCards() {
    final cards = <Widget>[];
    for (final group in _queryGroups) {
      for (var i = 0; i < group.allQueries.length; i++) {
        final q = group.allQueries[i];
        final isBest = i == group.bestQueryIndex;
        final isSelected = _selectedQuery == q.query;
        cards.add(_QueryCard(
          queryString: q.query,
          isBest: isBest,
          isSelected: isSelected,
          valuesChild: CrepeEventValuesList(values: q.crepeEventValues),
          onSelected: () => setState(() => _selectedQuery = q.query),
        ));
      }
    }
    return cards;
  }
}

class _QueryCard extends StatelessWidget {
  final String queryString;
  final bool isBest;
  final bool isSelected;
  final Widget valuesChild;
  final VoidCallback onSelected;

  const _QueryCard({
    required this.queryString,
    required this.isBest,
    required this.isSelected,
    required this.valuesChild,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? scheme.onSurface : Colors.transparent,
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
                        valuesChild,
                        Spacing.vSpace8,
                        Text('Query:', style: context.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          queryString,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: Spacing.token32,
                  ),
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
                    horizontal: Spacing.token8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text('BEST',
                    style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
