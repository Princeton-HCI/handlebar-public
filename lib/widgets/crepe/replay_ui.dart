import 'package:flutter/material.dart';
import 'package:handlebar/services/collector_service.dart';

class ReplayUI extends StatelessWidget {
  final Map<String, dynamic> snapshot;

  const ReplayUI({Key? key, required this.snapshot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entities = snapshot['entities'] as List<dynamic>? ?? [];

    return ListView(
      children: entities.map((entity) {
        final className = entity['className'] ?? '';
        final label = entity['contentDescription'] ?? entity['text'] ?? className;

        if (className.contains('Button')) {
          return ElevatedButton(
            onPressed: entity['isClickable']
                ? () => _showDescriptionDialog(context, entity)
                : null,
            child: Text(label.toString()),
          );
        } else if (className.contains('Switch')) {
          return SwitchListTile(
            value: entity['isChecked'] ?? false,
            onChanged: entity['isClickable'] ? (_) {} : null,
            title: Text(label.toString()),
          );
        } else {
          return ListTile(title: Text(label.toString()));
        }
      }).toList(),
    );
  }

  void _showDescriptionDialog(BuildContext context, Map<String, dynamic> entity) {
    final TextEditingController _descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Collector Description'),
          content: TextField(
            controller: _descriptionController,
            decoration: InputDecoration(hintText: 'Description'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final description = _descriptionController.text;
                if (description.isNotEmpty) {
                  final collectorService = CollectorService();
                  await collectorService.createAndSaveCollector(entity, description);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}