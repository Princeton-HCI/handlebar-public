import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../crepe/models/data_field.dart';
import '../view_models/video_session_view_model.dart';
import 'create_collector_dialog.dart';

class SnapshotFieldList extends StatelessWidget {
  final int snapshotIndex;
  final List<DataField> fields;

  const SnapshotFieldList(
      {super.key, required this.snapshotIndex, required this.fields});

  void _showCreateCollectorDialog(
      BuildContext context, VideoSessionViewModel vm, List<DataField> fields) {
    showDialog(
      context: context,
      builder: (context) => CreateCollectorDialog(
          vm: vm, snapshotIndex: snapshotIndex, fields: fields),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();

    return Container(
      padding: const EdgeInsets.all(Spacing.token16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // List of fields
          ...fields.map((f) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "• ${f.name}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Collector button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateCollectorDialog(context, vm, fields),
              icon: const Icon(Icons.add),
              label: const Text("Create Collector"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
