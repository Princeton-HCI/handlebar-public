import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../view_models/participant_home_view_model.dart';

class JoinGroupDialog extends StatefulWidget {
  final ParticipantHomeViewModel vm;

  const JoinGroupDialog({
    super.key,
    required this.vm,
  });

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);

    // Call the ViewModel's join method
    final success = await widget.vm.joinGroup(code);

    if (!mounted) return;

    if (success) {
      // Capture the router before popping: the dialog's own context is defunct
      // afterwards, so it cannot be used to navigate.
      final router = GoRouter.of(context);
      final needsLocation = await widget.vm.needsLocationPermission();

      if (!mounted) return;
      context.pop(); // Close dialog on success

      // Prompt straight away if the study they just joined collects location.
      // Nothing else asks, so skipping this means collecting nothing.
      if (needsLocation) router.push('/location-permission');
    } else {
      // Re-enable the button if it failed (NotificationService handles the error UI)
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Study Code:'),
      content: SizedBox(
        width: 400, // Enforces the static web width we set up earlier
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HandlebarTextField(
              controller: _codeController,
              hintText: 'Code',
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
        ),
        HandlebarButton.primary(
          label: 'Join',
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
