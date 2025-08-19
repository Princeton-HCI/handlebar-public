import 'package:flutter/material.dart';

Widget CrepePrimitiveUI(Map<String, dynamic> snapshot) {
  final entities = snapshot['entities'] as List<dynamic>;

  return ListView(
    children: entities.map((entity) {
      final className = entity['className'] ?? '';
      final label = entity['contentDescription'] ?? entity['text'] ?? className;

      if (className.contains('Button')) {
        return ElevatedButton(
          onPressed: entity['isClickable'] ? () {} : null,
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
