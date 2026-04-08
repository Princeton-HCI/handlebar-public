import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Modal dialog that prompts the researcher to name the data collector
/// they're about to create. Returns the entered name on submit, or null
/// if cancelled.
class NameCollectorDialog extends StatefulWidget {
  const NameCollectorDialog({super.key});

  @override
  State<NameCollectorDialog> createState() => _NameCollectorDialogState();
}

class _NameCollectorDialogState extends State<NameCollectorDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this Data Collector:'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.error),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(name);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
