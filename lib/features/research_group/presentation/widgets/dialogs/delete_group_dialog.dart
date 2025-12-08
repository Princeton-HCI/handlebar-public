import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../core/shared_services/notification_service.dart';
import '../../view_models/research_group_detail_view_model.dart';

/// Dialog for deleting a research group
class DeleteGroupDialog extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;

  const DeleteGroupDialog({super.key, required this.vm});

  @override
  State<DeleteGroupDialog> createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends State<DeleteGroupDialog> {
  bool _isLoading = false;

  Future<void> _onDelete() async {
    setState(() => _isLoading = true);

    final success = await widget.vm.deleteGroup();

    if (!mounted) return;

    if (success) {
      context.pop(); // Close dialog
      context.pop(); // Go back to dashboard
      NotificationService().showSuccess("Group successfully deleted");
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Group?"),
      content: const Text(
        "This action cannot be undone. All data, including memberships and collected events, will be lost.",
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
