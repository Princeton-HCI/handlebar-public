import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../view_models/signup_viewmodel.dart';

class RoleSelectionStep extends StatelessWidget {
  final SignupViewModel viewModel;
  final Function(SignupRole) onRoleSelected;
  final VoidCallback onLoginSelected;

  const RoleSelectionStep({
    super.key,
    required this.viewModel,
    required this.onRoleSelected,
    required this.onLoginSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Are you a participant or a researcher?',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),

        Spacing.vSpace24,

        HandlebarButton.primary(
          label: 'Participant',
          expand: true,
          onPressed: () => onRoleSelected(SignupRole.participant),
        ),

        Spacing.vSpace24,

        HandlebarButton.primary(
          label: 'Researcher',
          expand: true,
          onPressed: () => onRoleSelected(SignupRole.researcher),
        ),

        Spacing.vSpace32,

        // "Returning User?" Divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.token16),
              child: Text(
                'Returning User?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        Spacing.vSpace24,

        HandlebarButton.primary(
          label: 'Login',
          expand: true,
          onPressed: onLoginSelected,
        )
      ],
    );
  }
}
