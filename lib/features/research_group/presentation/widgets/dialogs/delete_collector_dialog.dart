import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../core/shared_services/notification_service.dart';
import '../../view_models/research_group_detail_view_model.dart';

/// DIalog for deleting a collector from a research group
class DeleteCollectorDialog extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;
  final int collectorId;

  const DeleteCollectorDialog({
    super.key,
    required this.vm,
    required this.collectorId,
  });

  @override
  State<DeleteCollectorDialog> createState() => _DeleteCollectorDialogState();
}

class _DeleteCollectorDialogState extends State<DeleteCollectorDialog> {
  bool _isLoading = false;

  Future<void> _onDelete() async {
    setState(() => _isLoading = true);

    final success = await widget.vm.deleteCollector(widget.collectorId);

    if (!mounted) return;

    if (success) {
      context.pop();
      NotificationService().showSuccess("Collector successfully deleted");
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Collector?"),
      content: const Text(
        "This action cannot be undone. ALl events tied to this collector will be lost",
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _onDelete,
          style: FilledButton.styleFrom(
            backgroundColor: context.colorScheme.error,
            foregroundColor: context.colorScheme.onError,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text("Delete"),
        )
      ],
    );
  }
}
