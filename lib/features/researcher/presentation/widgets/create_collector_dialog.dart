import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../crepe/models/data_field.dart';
import '../view_models/video_session_view_model.dart';

/// Dialog for creating collectors for a research group
class CreateCollectorDialog extends StatefulWidget {
  final VideoSessionViewModel vm;
  final int snapshotIndex;
  final List<DataField> fields;

  const CreateCollectorDialog(
      {super.key,
      required this.vm,
      required this.snapshotIndex,
      required this.fields});

  @override
  State<CreateCollectorDialog> createState() => _CreateCollectorDialogState();
}

class _CreateCollectorDialogState extends State<CreateCollectorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.vm.createCollectorFromSnapshot(
      snapshotIndex: widget.snapshotIndex,
      description: _descCtrl.text.trim(),
      fields: widget.fields,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
      NotificationService().showSuccess("Collector successfully created");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Save Collector"),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: "Description",
                ),
                validator: (v) => Validators.notEmpty(v),
              ),
            ],
          )),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _onSubmit(),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Create"),
        ),
      ],
    );
  }
}
