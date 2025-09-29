import 'package:flutter/material.dart';
import 'package:handlebar/models/collector.dart';

class AvailableCollectors extends StatelessWidget {
  final List<Collector> collectors;
  final void Function(Collector collector, bool toggleValue) onToggle;
  final bool debugToggleValue;

  const AvailableCollectors({
    super.key,
    required this.collectors,
    required this.onToggle,
    required this.debugToggleValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.blueGrey.shade100,
          child: const Text(
            "Available Collectors",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: collectors.length,
            itemBuilder: (BuildContext context, int index) {
              final collector = collectors[index];

              return ListTile(
                title: Text(collector.description ?? "No Description"),
                trailing: Switch(
                  value: debugToggleValue,
                  onChanged: (val) => onToggle(collector, val),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
