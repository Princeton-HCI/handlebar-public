import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../study/data/models/research_study_member.dart';

/// Tile for displaying a [ResearchStudyMember] in the research group UI
class MemberTile extends StatelessWidget {
  final ResearchStudyMember member;
  final bool isResearcher;
  final VoidCallback onTap;
  final VoidCallback onKick;

  const MemberTile(
      {super.key,
      required this.member,
      required this.isResearcher,
      required this.onTap,
      required this.onKick});

  static const _borderWidth = 1.4;
  static const _borderRadius = 12.0;

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
    final scheme = context.colorScheme;
    final isInactive = member.unenrolledAt != null;

    final retentionLabel = _formatRetention(member.retentionPref);

    final textColor = scheme.onSurface;
    final subTextColor = scheme.onSurfaceVariant;

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: Spacing.token16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: scheme.outline, width: _borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isResearcher ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.token16, vertical: Spacing.token8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: Spacing.token32,
                height: Spacing.token32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Icon(Icons.person,
                    color: scheme.onSurface, size: Spacing.token16),
              ),

              Spacing.hSpace16,

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Membership ID (TODO: replace with first + last name eventually)
                    Row(
                      children: [
                        Text("Member #${member.membershipId}",
                            style: context.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold, color: textColor)),
                        if (isInactive) ...[
                          // Inactive status chip
                          Spacing.hSpace16,
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.token8, vertical: 2),
                            decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color:
                                        scheme.error.withValues(alpha: 0.5))),
                            child: Text("INACTIVE",
                                style: context.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onErrorContainer)),
                          )
                        ]
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Role
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(
                          member.role[0].toUpperCase() +
                              member.role.substring(1),
                          style:
                              context.bodySmall?.copyWith(color: subTextColor),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Retention
                    Row(
                      children: [
                        Icon(Icons.save_as_outlined,
                            size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(
                          "Retention: $retentionLabel",
                          style: context.bodySmall?.copyWith(
                              color: subTextColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              if (isResearcher)
                // Researcher view (3 dots)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, color: textColor),
                  itemBuilder: (context) => [
                    // View member details
                    PopupMenuItem(
                        value: 'view',
                        child: Row(children: [
                          Icon(Icons.visibility_outlined,
                              size: 20, color: scheme.onSurface),
                          Spacing.hSpace8,
                          Text("View Activity",
                              style: TextStyle(color: scheme.onSurface))
                        ])),
                    if (!isInactive)
                      // Kick member
                      PopupMenuItem(
                          value: 'kick',
                          child: Row(children: [
                            Icon(Icons.remove_circle_outline,
                                size: 20, color: scheme.error),
                            Spacing.hSpace8,
                            Text("Kick", style: TextStyle(color: scheme.error))
                          ])),
                  ],
                  onSelected: (value) {
                    if (value == 'view') onTap();
                    if (value == 'kick') onKick();
                  },
                )
              else
                // My membership (chevron)
                Icon(Icons.chevron_right, color: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
