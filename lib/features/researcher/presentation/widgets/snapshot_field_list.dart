import 'package:flutter/material.dart';
import 'package:handlebar/features/crepe/services/collector_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../crepe/models/data_field.dart';
import '../view_models/video_session_view_model.dart';

class SnapshotFieldList extends StatelessWidget {
  final List<DataField> fields;
  final Map<String, dynamic> snapshot;

  const SnapshotFieldList({super.key, required this.fields, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // list of fields
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

          //collector button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateCollectorDialog(context, snapshot, fields),
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

  void _showCreateCollectorDialog(
      BuildContext context, Map<String, dynamic> snapshot, List<DataField> fields) async {
    final TextEditingController nameCtrl = TextEditingController();
    final vm = Provider.of<VideoSessionViewModel>(context, listen: false);
    final collectorService = CollectorService();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Name Collector"),
        content: TextField(
          controller: nameCtrl,
          decoration:
          const InputDecoration(hintText: "Collector name (e.g., Login Flow)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, nameCtrl.text.trim()),
            child: const Text("Create"),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    collectorService.createAndSaveCollector(snapshot, fields, nameCtrl.text);
    vm.clearDataFields();

    NotificationService().showSuccess("Collector '$name' created!");
  }
}
