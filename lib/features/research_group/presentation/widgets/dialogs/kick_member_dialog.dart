import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../core/shared_services/notification_service.dart';
import '../../view_models/research_group_detail_view_model.dart';

/// Dialog for kicking a member from a research group
class KickMemberDialog extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;
  final int membershipId;

  const KickMemberDialog({
    super.key,
    required this.vm,
    required this.membershipId,
  });

  @override
  State<KickMemberDialog> createState() => _KickMemberDialogState();
}

class _KickMemberDialogState extends State<KickMemberDialog> {
  bool _isLoading = false;

  Future<void> _onKick() async {
    setState(() => _isLoading = true);

    final success = await widget.vm.kickMember(widget.membershipId);

    if (!mounted) return;

    if (success) {
      context.pop();
      NotificationService().showSuccess("Member successfully kicked");
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AlertDialog(
      title: const Text("Kick Member?"),
      content: const Text(
        "This member will lose access to the group immediately. "
        "Any data they have already contributed will be retained or deleted according to their personal retention preference.",
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => context.pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _onKick,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Kick"),
        ),
      ],
    );
  }
}
