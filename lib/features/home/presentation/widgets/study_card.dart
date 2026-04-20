import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../research_group/models/research_group.dart';

class StudyCard extends StatelessWidget {
  final ResearchGroup group;
  final VoidCallback? onTap;

  const StudyCard({
    super.key,
    required this.group,
    this.onTap,
  });

  static const _borderWidth = 1.4;
  static const _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final theme = context.theme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.token16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outline, width: _borderWidth),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.token16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Group Name
              Text(
                group.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              Spacing.vSpace4,

              // 2. Group Description
              Text(
                group.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              Spacing.vSpace4,

              // 3. Active Components
              Text(
                'Active Components: ${group.activeComponentCount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurface,
                ),
              ),

              Spacing.vSpace12,

              // 5. Action Footer (View Details + Circle Icon)
              if (onTap != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface,
                      ),
                    ),

                    Spacing.hSpace16,

                    // The dark circle with the white chevron inside
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.surface, // Inverted color for the icon
                        size: 24,
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
