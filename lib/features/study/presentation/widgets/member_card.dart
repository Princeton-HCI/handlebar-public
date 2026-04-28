import 'package:flutter/material.dart';
import '../../../../../app/design-system/spacing.dart';
import '../../data/models/research_study_member.dart';

class MemberCard extends StatelessWidget {
  final ResearchStudyMember member;
  final bool isUs;
  final bool isCurrentUserResearcher;
  final VoidCallback onKick;
  final VoidCallback onLeave;
  final VoidCallback onEditDataGov;
  final VoidCallback onViewDetails;

  const MemberCard({
    super.key,
    required this.member,
    required this.isUs,
    required this.isCurrentUserResearcher,
    required this.onKick,
    required this.onLeave,
    required this.onEditDataGov,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Use member.firstName and member.lastName once stored in backend
    final displayName = "Member ${member.userId}";
    final isInactive = !member.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.token8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isInactive
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(Spacing.token8),
      ),
      color: isInactive
          ? theme.colorScheme.surface.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.token16,
          vertical: Spacing.token16,
        ),
        onTap: (!isUs && !member.isResearcher) ? onViewDetails : null,
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Spacing.token8,
          children: [
            Text(
              isUs ? "Me ($displayName)" : displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isInactive
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                    : null,
              ),
            ),
            if (isInactive) _buildInactiveBadge(theme),
          ],
        ),
        subtitle: Text(
          "No email provided", // TODO: Need to send email from backend
          style: TextStyle(
            color: isInactive
                ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                : null,
          ),
        ),
        trailing: isInactive ? null : _buildTrailingMenu(context),
      ),
    );
  }

  Widget _buildInactiveBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'INACTIVE',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTrailingMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'details':
            onViewDetails();
            break;
          case 'leave':
            onLeave();
            break;
          case 'edit_gov':
            onEditDataGov();
            break;
          case 'kick':
            onKick();
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 20, color: Colors.black87),
                SizedBox(width: 12),
                Text('View Details'),
              ],
            ),
          ),
        ];

        if (isUs && member.isResearcher) {
          items.add(
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Leave Study', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        } else if (isUs && !member.isResearcher) {
          items.add(
            const PopupMenuItem(
              value: 'edit_gov',
              child: Row(
                children: [
                  Icon(Icons.policy_outlined, size: 20, color: Colors.black87),
                  SizedBox(width: 12),
                  Text('Edit Data Governance'),
                ],
              ),
            ),
          );
          items.add(
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Leave Study', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        } else if (!isUs && isCurrentUserResearcher) {
          items.add(
            const PopupMenuItem(
              value: 'kick',
              child: Row(
                children: [
                  Icon(Icons.person_remove_outlined,
                      size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Kick from Study', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
