import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../crepe/utils/collection_frequency.dart';

/// Result of the [NameCollectorDialog]: the collector name plus how often it
/// should collect (in seconds; 0 = every time).
class CollectorNamingResult {
  final String name;
  final int collectionIntervalSeconds;

  const CollectorNamingResult(this.name, this.collectionIntervalSeconds);
}

/// Modal dialog that prompts the researcher to name the data collector
/// they're about to create and choose its collection frequency. Returns a
/// [CollectorNamingResult] on submit, or null if cancelled.
class NameCollectorDialog extends StatefulWidget {
  const NameCollectorDialog({super.key});

  @override
  State<NameCollectorDialog> createState() => _NameCollectorDialogState();
}

class _NameCollectorDialogState extends State<NameCollectorDialog> {
  final _ctrl = TextEditingController();
  int _intervalSeconds = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(CollectorNamingResult(name, _intervalSeconds));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this Data Collector:'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const Text('Collect this data:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _intervalSeconds,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: kCollectionFrequencyOptions
                .map((o) => DropdownMenuItem(
                      value: o.seconds,
                      child: Text(o.label),
                    ))
                .toList(),
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
        TextButton(
          onPressed: _submit,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
