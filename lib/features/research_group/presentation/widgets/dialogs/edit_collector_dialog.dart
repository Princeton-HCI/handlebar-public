import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../crepe/models/collector.dart';
import '../../../../crepe/utils/collection_frequency.dart';

/// Result of [EditCollectorDialog]: the edited name and collection frequency.
class EditCollectorResult {
  final String description;
  final int collectionIntervalSeconds;

  const EditCollectorResult(this.description, this.collectionIntervalSeconds);
}

/// Lets a researcher edit a collector's name and collection frequency.
/// Returns an [EditCollectorResult] on save, or null if cancelled.
class EditCollectorDialog extends StatefulWidget {
  final Collector collector;

  const EditCollectorDialog({super.key, required this.collector});

  @override
  State<EditCollectorDialog> createState() => _EditCollectorDialogState();
}

class _EditCollectorDialogState extends State<EditCollectorDialog> {
  late final TextEditingController _ctrl;
  late int _intervalSeconds;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.collector.description);
    _intervalSeconds = widget.collector.collectionIntervalSeconds ?? 0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(EditCollectorResult(name, _intervalSeconds));
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the current value is selectable even if it's a non-preset interval.
    final values = kCollectionFrequencyOptions.map((o) => o.seconds).toSet();
    final items = [
      ...kCollectionFrequencyOptions
          .map((o) => DropdownMenuItem(value: o.seconds, child: Text(o.label))),
      if (!values.contains(_intervalSeconds))
        DropdownMenuItem(
          value: _intervalSeconds,
          child: Text(collectionFrequencyLabel(_intervalSeconds)),
        ),
    ];

    return AlertDialog(
      title: const Text('Edit Collector'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          const Text('Collect this data:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _intervalSeconds,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: items,
            onChanged: (v) => setState(() => _intervalSeconds = v ?? 0),
          ),
        ],
      ),
      actions: [
        TextButton(
          style:
              TextButton.styleFrom(foregroundColor: context.colorScheme.error),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
