import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/utils/validators.dart';
import '../../view_models/research_group_detail_view_model.dart';

/// Dialog for adding a researcher to a research group
class AddResearcherDialog extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;

  const AddResearcherDialog({super.key, required this.vm});

  @override
  State<AddResearcherDialog> createState() => _AddResearcherDialogState();
}

class _AddResearcherDialogState extends State<AddResearcherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.vm.addResearcher(_emailController.text.trim());

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
      NotificationService().showSuccess("Researcher added successfully");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Researcher"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the email of the user you want to add as a researcher. They must already have an account.",
            ),
            Spacing.vSpace16,
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                hintText: "researcher@example.com",
                border: const OutlineInputBorder(),
              ),
              validator: (v) => Validators.email(v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _onSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Add"),
        )
      ],
    );
  }
}
