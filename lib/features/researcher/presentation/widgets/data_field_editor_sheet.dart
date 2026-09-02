import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../crepe/models/crepe_event_values.dart';
import '../../../crepe/models/data_field.dart';
import '../../../crepe/models/snapshot.dart';
import '../../../crepe/models/snapshot_entity_queries.dart';
import '../../../crepe/utils/query_describer.dart';
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

  /// Relation types to exclude from query generation (e.g., `['SCREEN_HAS_TEXT']`).
  final List<String>? relationsToExclude;

  /// Snapshot index in the session — stored on the field for overlay highlighting.
  final int sourceSnapshotIndex;

  const DataFieldEditorSheet({
    super.key,
    required this.session,
    required this.snapshot,
    required this.hitEntities,
    required this.sourceSnapshotIndex,
    this.initial,
    this.relationsToExclude,
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
  late final FocusNode _nameFocus;
  late final FocusNode _descFocus;
  String? _selectedQuery;
  List<SnapshotEntityQueries> _queryGroups = [];
  List<FilteredOutQuery<SnapshotQuery>> _excludedQueries = [];
  bool _loading = true;

  bool get _hasQueries =>
      _queryGroups.isNotEmpty || _excludedQueries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final autoFill = DataFieldEditorSheet.extractEntityText(widget.hitEntities);
    _nameCtrl = TextEditingController(text: initial?.name ?? autoFill ?? '');
    _descCtrl = TextEditingController();
    _nameFocus = FocusNode();
    _descFocus = FocusNode();
    _selectedQuery = initial?.graphQuery;
    _loading = false;

    if (initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocus.requestFocus();
        final text = _nameCtrl.text;
        if (text.isNotEmpty) {
          _nameCtrl.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
        }
      });
    }
  }

  void _focusDescription() {
    _descFocus.requestFocus();
  }

  Future<void> _submitDescription() async {
    FocusScope.of(context).unfocus();
    if (_descCtrl.text.trim().isEmpty) {
      NotificationService().showError(
        'Add a description so the system can generate queries',
      );
      _descFocus.requestFocus();
      return;
    }
    await _loadQueries();
  }

  Future<void> _loadQueries() async {
    final description = _descCtrl.text.trim();
    if (description.isEmpty) return;

    setState(() {
      _loading = true;
      _queryGroups = [];
      _excludedQueries = [];
      _selectedQuery = widget.initial?.graphQuery;
    });
    final groups = await widget.session.getQueriesForEntities(
      widget.snapshot,
      widget.hitEntities,
      description,
      relationsToExclude: widget.relationsToExclude,
    );
    if (!mounted) return;

    // Debug: log raw queries before filtering
    for (final group in groups) {
      debugPrint(
          '--- Raw queries from plugin (${group.queries.length} total, best=${group.bestQueryIndex}) ---');
      for (var i = 0; i < group.queries.length; i++) {
        final q = group.queries[i];
        debugPrint('  [$i] score=${q.score} query=${q.query}');
      }
    }

    final suggestedGroups = <SnapshotEntityQueries>[];
    final excluded = <FilteredOutQuery<SnapshotQuery>>[];

    for (final group in groups) {
      final partition = QueryDescriber.partitionForDisplay<SnapshotQuery>(
        queries: group.queries,
        getQuery: (q) => q.query,
        getScore: (q) => q.score,
      );

      debugPrint(
          '--- After filtering: ${partition.suggested.length} suggested, '
          '${partition.excluded.length} excluded ---');
      for (var i = 0; i < partition.suggested.length; i++) {
        final q = partition.suggested[i];
        debugPrint('  [s$i] score=${q.score} query=${q.query}');
      }
      for (var i = 0; i < partition.excluded.length; i++) {
        final e = partition.excluded[i];
        debugPrint(
            '  [x$i] ${e.reason.name} score=${e.item.score} query=${e.item.query}');
      }

      excluded.addAll(partition.excluded);
      if (partition.suggested.isNotEmpty) {
        suggestedGroups.add(SnapshotEntityQueries(
          queries: partition.suggested,
          bestQueryIndex: 0,
        ));
      }
    }

    setState(() {
      _queryGroups = suggestedGroups;
      _excludedQueries = excluded;
      _loading = false;
      // Auto-select best query when creating new
      if (_selectedQuery == null && suggestedGroups.isNotEmpty) {
        final first = suggestedGroups.first;
        if (first.bestQueryIndex != -1 &&
            first.bestQueryIndex < first.queries.length) {
          _selectedQuery = first.queries[first.bestQueryIndex].query;
        } else if (first.queries.isNotEmpty) {
          _selectedQuery = first.queries.first.query;
        }
      }
    });
  }

  CrepeEventValues? _capturedValuesForQuery(String query) {
    for (final group in _queryGroups) {
      for (final q in group.queries) {
        if (q.query == query) return q.crepeEventValues;
      }
    }
    for (final e in _excludedQueries) {
      if (e.item.query == query) return e.item.crepeEventValues;
    }
    if (widget.initial?.graphQuery == query) {
      return widget.initial?.capturedValues;
    }
    return null;
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedQuery == null) return;

    int? sourceEntityId = widget.initial?.sourceEntityId;
    if (widget.hitEntities.isNotEmpty) {
      sourceEntityId = widget.hitEntities.first['entityId'] as int?;
    }

    Navigator.of(context).pop(DataField(
      name: name,
      graphQuery: _selectedQuery!,
      dataFieldId: widget.initial?.dataFieldId,
      sourceEntityId: sourceEntityId,
      sourceSnapshotIndex:
          widget.initial?.sourceSnapshotIndex ?? widget.sourceSnapshotIndex,
      capturedValues: _capturedValuesForQuery(_selectedQuery!),
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
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
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Spacing.token16)),
        ),
        child: Column(
          children: [
            // Top action bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.token8, vertical: Spacing.token8),
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
                  Text('Field name (for you):', style: context.labelLarge),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _focusDescription(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Average wait time',
                    ),
                  ),
                  Spacing.vSpace16,
                  Text(
                    'What to capture (required, for the system):',
                    style: context.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The collector uses this description to generate graph '
                    'queries — not shown to participants.',
                    style: context.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _descCtrl,
                    focusNode: _descFocus,
                    keyboardType: TextInputType.text,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitDescription(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'e.g. "minutes shown next to the average wait label"',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loadQueries,
                      child: Text(
                        _hasQueries ? 'Regenerate queries' : 'Generate queries',
                      ),
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
                  else if (_queryGroups.isEmpty && _excludedQueries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(Spacing.token16),
                      child: Text('No queries available for this element.'),
                    )
                  else ...[
                    ..._buildQueryCards(suggested: true),
                    if (_excludedQueries.isNotEmpty) ...[
                      Spacing.vSpace24,
                      Text(
                        'Not recommended',
                        style: context.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'These queries are usually too fragile or redundant. '
                        'You can still select one if you know it fits.',
                        style: context.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Spacing.vSpace8,
                      ..._buildQueryCards(suggested: false),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQueryCards({required bool suggested}) {
    final cards = <Widget>[];
    if (suggested) {
      for (final group in _queryGroups) {
        for (var i = 0; i < group.queries.length; i++) {
          final q = group.queries[i];
          cards.add(_QueryCard(
            queryString: q.query,
            description: QueryDescriber.describe(q.query),
            isBest: i == group.bestQueryIndex,
            isSelected: _selectedQuery == q.query,
            notRecommended: false,
            valuesChild: CrepeEventValuesList(values: q.crepeEventValues),
            onSelected: () => setState(() => _selectedQuery = q.query),
          ));
        }
      }
      return cards;
    }

    for (final entry in _excludedQueries) {
      final q = entry.item;
      cards.add(_QueryCard(
        queryString: q.query,
        description: QueryDescriber.describe(q.query),
        isBest: false,
        isSelected: _selectedQuery == q.query,
        notRecommended: true,
        exclusionReason: QueryDescriber.exclusionReasonLabel(entry.reason),
        valuesChild: CrepeEventValuesList(values: q.crepeEventValues),
        onSelected: () => setState(() => _selectedQuery = q.query),
      ));
    }
    return cards;
  }
}

class _QueryCard extends StatelessWidget {
  final String queryString;
  final String description;
  final bool isBest;
  final bool isSelected;
  final bool notRecommended;
  final String? exclusionReason;
  final Widget valuesChild;
  final VoidCallback onSelected;

  const _QueryCard({
    required this.queryString,
    required this.description,
    required this.isBest,
    required this.isSelected,
    required this.notRecommended,
    this.exclusionReason,
    required this.valuesChild,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final muted = notRecommended;
    return Card(
      elevation: isSelected ? 3 : 1,
      color:
          muted ? scheme.surfaceContainerHighest.withValues(alpha: 0.35) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? scheme.onSurface
              : muted
                  ? scheme.outlineVariant
                  : Colors.transparent,
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
                        Text(
                          description,
                          style: context.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: muted ? scheme.onSurfaceVariant : null,
                          ),
                        ),
                        if (exclusionReason != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: scheme.error),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  exclusionReason!,
                                  style: context.bodySmall?.copyWith(
                                    color: scheme.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
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
