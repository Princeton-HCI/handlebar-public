import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/home/presentation/view_models/participant_home_view_model.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../study/data/models/research_study.dart';
import '../cards/research_group_card.dart';

/// Dialog for joining a research group
class JoinGroupDialog extends StatefulWidget {
  final ParticipantHomeViewModel vm;

  const JoinGroupDialog({super.key, required this.vm});

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

// Dialog has two steps: input (lookup group) and confirm (join group)
enum _JoinStep { input, confirm }

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  _JoinStep _step = _JoinStep.input;
  bool _isLoading = false;
  ResearchStudy? _foundGroup;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onLookup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final group = await widget.vm.lookupGroup(_codeController.text.trim());

    if (group != null) {
      setState(() {
        _foundGroup = group;
        _step = _JoinStep.confirm;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onJoin() async {
    setState(() => _isLoading = true);

    final success = await widget.vm.joinGroup(_codeController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.pop();
      context.push("/group-detail", extra: _foundGroup);
      NotificationService().showSuccess("Successfully joined the group");
    }
  }

  void _onBack() {
    setState(() {
      _step = _JoinStep.input;
      _foundGroup = null;
    });
  }

  Widget _buildInputStep() {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter the unique code provided by your researcher."),
            Spacing.vSpace16,
            TextFormField(
              controller: _codeController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Group Code',
                hintText: 'e.g. ABCDE12345',
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => Validators.notEmpty(v),
            ),
          ],
        ));
  }

  List<Widget> _buildInputActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => context.pop(),
        child: const Text("Cancel"),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _onLookup,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Next"),
      ),
    ];
  }

  Widget _buildConfirmStep() {
    if (_foundGroup == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResearchGroupTile(group: _foundGroup!),
        Spacing.vSpace16,
        const Text("Is this the group you want to join?")
      ],
    );
  }

  List<Widget> _buildConfirmActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : _onBack,
        child: const Text("Back"),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _onJoin,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text("Yes, Join", style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _step == _JoinStep.input ? 'Join Research Group' : 'Confirm Group'),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            _step == _JoinStep.input ? _buildInputStep() : _buildConfirmStep(),
      ),
      actions: _step == _JoinStep.input
          ? _buildInputActions()
          : _buildConfirmActions(),
    );
  }
}
