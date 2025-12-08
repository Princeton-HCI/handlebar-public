import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/utils/validators.dart';
import '../../view_models/research_group_detail_view_model.dart';

/// Dialog for editing a research group's information
class EditGroupDialog extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;

  const EditGroupDialog({super.key, required this.vm});

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _nameCtrl = TextEditingController(text: widget.vm.group.value.name);
    _descCtrl = TextEditingController(text: widget.vm.group.value.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await widget.vm.updateGroup(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      context.pop();
      NotificationService().showSuccess("Group successfully updated");
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Group"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Group Name"),
              validator: (v) => Validators.notEmpty(v),
            ),
            Spacing.vSpace16,
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _isLoading ? null : () => context.pop(),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _onSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Save"),
        )
      ],
    );
  }
}
