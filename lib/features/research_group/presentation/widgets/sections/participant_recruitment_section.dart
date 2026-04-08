import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';

/// Displays the participant recruitment section on the study detail page.
///
/// Shows the join code with tap-to-copy, and Pause Recruitment / Edit buttons.
class ParticipantRecruitmentSection extends StatelessWidget {
  final String joinCode;
  final int participantCount;
  final VoidCallback? onEdit;

  const ParticipantRecruitmentSection({
    super.key,
    required this.joinCode,
    required this.participantCount,
    this.onEdit,
  });

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: joinCode));
    NotificationService().showSuccess('Code copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.token16,
        vertical: Spacing.token8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Participant count
          Text(
            participantCount == 0
                ? 'You currently have no participants.'
                : '$participantCount participant${participantCount == 1 ? '' : 's'} enrolled.',
            style: context.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),

          Spacing.vSpace16,

          // Add Participants card
          GestureDetector(
            onTap: () => _copyCode(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.token16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.campaign, size: 24, color: scheme.primary),
                  Spacing.hSpace16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Participants:',
                          style: context.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share this with participants to join your study! Tap to copy the code.',
                          style: context.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Spacing.vSpace8,
                        // Join code
                        Text(
                          joinCode,
                          style: context.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.copy, size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),

          Spacing.vSpace16,

          // Action buttons row
          Row(
            children: [
              if (onEdit != null)
                HandlebarButton(
                  text: 'Edit',
                  variant: ButtonVariant.primary,
                  isLoading: false,
                  minHeight: 36,
                  prefixIcon: Icon(Icons.edit_outlined,
                      size: Spacing.token16, color: scheme.onSurface),
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
