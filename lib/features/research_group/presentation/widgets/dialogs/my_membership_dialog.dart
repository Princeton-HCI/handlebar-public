import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../study/data/models/research_study_member.dart';
import '../../view_models/research_group_detail_view_model.dart';

/// Dialog for viewing the user's own membership and updating it
class MyMembershipDialog extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;
  final ResearchStudyMember member;

  const MyMembershipDialog({super.key, required this.vm, required this.member});

  @override
  State<MyMembershipDialog> createState() => _MyMembershipDialogState();
}

class _MyMembershipDialogState extends State<MyMembershipDialog> {
  late String _retentionPref;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _retentionPref = widget.member.retentionPref;
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    // Only update if changed
    if (_retentionPref != widget.member.retentionPref) {
      await widget.vm.updateMyMembership(retentionPref: _retentionPref);
    }

    if (mounted) {
      context.pop();
      NotificationService().showSuccess("Membership updated successfully");
    }
  }

  Future<void> _onLeave() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Leave Group?"),
              content: const Text(
                  "You will lose access to this group. Your data will be handled according to your retention preference."),
              actions: [
                TextButton(
                    onPressed: () => ctx.pop(false),
                    child: const Text("Cancel")),
                FilledButton(
                  onPressed: () => ctx.pop(true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Leave"),
                )
              ],
            ));

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await widget.vm.leaveGroup();

    if (mounted && success) {
      context.pop(); // Close dialog
      context.pop(); // Go back to dashboard
      NotificationService().showSuccess("Left group successfully");
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("My Membership"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Data Retention",
              style: TextStyle(fontWeight: FontWeight.bold)),

          Spacing.vSpace8,

          const Text(
            "If you leave or are kicked from this group, what should happen to the data you already contributed?",
          ),

          Spacing.vSpace16,

          // Retention radio options
          RadioGroup(
              groupValue: _retentionPref,
              onChanged: (String? val) => setState(() => _retentionPref = val!),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("Keep Collected"),
                    subtitle: const Text("Researchers keep existing data"),
                    value: "keep_collected",
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: const Text("Delete All"),
                    subtitle: const Text("Remove all my data immediately"),
                    value: "delete_all",
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ))
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // Leave group
        TextButton(
          onPressed: _isLoading ? null : _onLeave,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Leave Group"),
        ),

        // Cancel dialog
        TextButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: const Text("Cancel"),
        ),

        // Save membership changes
        ElevatedButton(
          onPressed: _isLoading ? null : _onSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Save"),
        ),
      ],
    );
  }
}
