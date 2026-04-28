import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/utils/validators.dart';
import '../../view_models/research_group_dashboard_view_model.dart';

/// Dialog for creating a research group
class CreateGroupDialog extends StatefulWidget {
  final OldResearchGroupDashboardViewModel vm;

  const CreateGroupDialog({super.key, required this.vm});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.vm.createGroup(
      _nameController.text.trim(),
      _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
      NotificationService().showSuccess("Group successfully created");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Research Group'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Uber Fares Study',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.notEmpty(v),
            ),
            Spacing.vSpace16,
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Short description of the study...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => Validators.notEmpty(v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _onSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
