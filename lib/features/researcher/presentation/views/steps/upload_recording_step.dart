import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../view_models/collector_creation_view_model.dart';

/// Step 1 of the collector creation flow: choose how to provide a recording.
class UploadRecordingStep extends StatelessWidget {
  const UploadRecordingStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CollectorCreationViewModel>();
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(Spacing.token24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.token352),
          child: ValueListenableBuilder<bool>(
            valueListenable: vm.session.isLoading,
            builder: (context, isLoading, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create a new recording or upload an existing screen '
                    'recording and JSON file.',
                    style: context.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  Spacing.vSpace24,
                  HandlebarOldButton(
                    text: 'Create a new recording',
                    variant: ButtonVariant.primary,
                    isLoading: false,
                    prefixIcon: const Icon(Icons.fiber_manual_record,
                        size: Spacing.token24),
                    onPressed: isLoading
                        ? null
                        : () => vm.startNewRecording(context),
                  ),
                  Spacing.vSpace16,
                  HandlebarOldButton(
                    text: 'Upload existing recording',
                    variant: ButtonVariant.primary,
                    isLoading: isLoading,
                    prefixIcon: const Icon(Icons.drive_folder_upload_outlined,
                        size: Spacing.token24),
                    onPressed: isLoading ? null : vm.uploadRecording,
                  ),
                  Spacing.vSpace32,
                  Container(
                    padding: const EdgeInsets.all(Spacing.token16),
                    decoration: BoxDecoration(
                      color:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: Spacing.token24, color: scheme.primary),
                        Spacing.hSpace16,
                        Expanded(
                          child: Text(
                            'Data Collectors are tools used in your study to '
                            'collect screen content from a specific app. '
                            'Start by recording a short screen capture of '
                            'the app you want to collect data from.',
                            style: context.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
