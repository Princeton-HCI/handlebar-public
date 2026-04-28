import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../data/models/research_study_member.dart';

class MemberDetailBottomSheet extends StatelessWidget {
  final ResearchStudyMember member;

  const MemberDetailBottomSheet({
    super.key,
    required this.member,
  });

  String _formatDate(DateTime dt) => DateFormat.yMMMd().format(dt.toLocal());

  String _formatRetention(String pref) {
    return pref
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInactive = !member.isActive;

    return Column(
      mainAxisSize: MainAxisSize.min, // Hug content tightly
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.token24, Spacing.token8,
              Spacing.token24, Spacing.token16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TODO: Update to First/Last Name once supported
                        Text(
                          "Member #${member.membershipId}",
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: Spacing.token4),
                        // TODO: Update to actual email
                        Text(
                          "No email provided",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(theme, isInactive),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.black),

        // Metadata Grid Section
        Padding(
          padding: const EdgeInsets.all(Spacing.token24),
          child: Wrap(
            spacing: Spacing.token32,
            runSpacing: Spacing.token16,
            children: [
              _MemberMetadataItem(
                label: "Joined",
                value: _formatDate(member.enrolledAt),
                icon: Icons.calendar_today,
              ),
              if (isInactive && member.unenrolledAt != null)
                _MemberMetadataItem(
                  label: "Left",
                  value: _formatDate(member.unenrolledAt!),
                  icon: Icons.exit_to_app,
                  isError: true,
                ),
              if (!member.isResearcher)
                _MemberMetadataItem(
                  label: "Retention Policy",
                  value: _formatRetention(member.retentionPref),
                  icon: Icons.save_alt,
                ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.black),

        // Actions
        Padding(
          padding: const EdgeInsets.all(Spacing.token24),
          child: HandlebarButton.primary(
            label: 'Close',
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  // Stark Handlebar-style Status Badge
  Widget _buildStatusChip(ThemeData theme, bool isInactive) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.token8, vertical: Spacing.token4),
      decoration: BoxDecoration(
        color: isInactive
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surface,
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isInactive ? "INACTIVE" : "ACTIVE",
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isInactive
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSurface,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// Minimalist Metadata Item
class _MemberMetadataItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isError;

  const _MemberMetadataItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: Spacing.token4),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.token4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                isError ? theme.colorScheme.error : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
