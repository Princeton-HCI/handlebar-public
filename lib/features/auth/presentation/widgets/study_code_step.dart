import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../view_models/signup_viewmodel.dart';

class StudyCodeStep extends StatelessWidget {
  final SignupViewModel viewModel;
  final VoidCallback onBack;
  final VoidCallback onValidCodeProvided;

  final TextEditingController _codeController = TextEditingController();

  StudyCodeStep({
    super.key,
    required this.viewModel,
    required this.onBack,
    required this.onValidCodeProvided,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enter the research study code:',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),

        Spacing.vSpace24,

        HandlebarTextField(
          controller: _codeController,
          hintText: 'Ex: DCACH4TAUQ',
          textInputAction: TextInputAction.done,
          // Automatically trigger submit on keyboard enter
          onFieldSubmitted: (_) async {
            final isValid = await viewModel.setStudyCode(_codeController.text);
            if (isValid) onValidCodeProvided();
          },
        ),

        Spacing.vSpace32,

        // Submit Button tied to loading state
        ValueListenableBuilder<bool>(
          valueListenable: viewModel.isLoading,
          builder: (context, isLoading, child) {
            return HandlebarButton.primary(
              label: 'Continue',
              expand: true,
              isLoading: isLoading,
              onPressed: () async {
                final isValid =
                    await viewModel.setStudyCode(_codeController.text);
                if (isValid) {
                  onValidCodeProvided();
                }
              },
            );
          },
        ),

        Spacing.vSpace16,

        HandlebarButton.neutral(label: 'Go Back', onPressed: onBack),

        Spacing.vSpace16,

        // Error Message Display
        ValueListenableBuilder<String?>(
          valueListenable: viewModel.errorMessage,
          builder: (context, error, child) {
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: Spacing.token16),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
