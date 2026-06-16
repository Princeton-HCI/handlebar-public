import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/shared_widgets/handlebar_old_app_bar.dart';
import '../../../../core/shared_widgets/scaffolds/dynamic_responsive_scaffold.dart';
import '../view_models/collector_creation_view_model.dart';
import '../widgets/collector_stepper_breadcrumb.dart';
import 'steps/select_data_fields_step.dart';
import 'steps/select_frame_step.dart';
import 'steps/select_landmarks_step.dart';
import 'steps/upload_recording_step.dart';

/// Top-level page for the 3-step collector creation flow.
class CreateCollectorPage extends StatefulWidget {
  const CreateCollectorPage({super.key});

  @override
  State<CreateCollectorPage> createState() => _CreateCollectorPageState();
}

class _CreateCollectorPageState extends State<CreateCollectorPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectorCreationViewModel>().initialize();
    });
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved progress?'),
        content: const Text(
          'You have unsaved data fields or a loaded recording. '
          'Leaving will discard them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CollectorCreationViewModel>();

    return ValueListenableBuilder<bool>(
      valueListenable: vm.isResolvingCode,
      builder: (context, isResolving, _) {
        // 2. Show a full-screen loader while we lookup the Study Code
        if (isResolving) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 3. Handle Lookup Failure
        return ValueListenableBuilder<String?>(
          valueListenable: vm.errorMessage,
          builder: (context, error, _) {
            if (error != null) {
              return Scaffold(
                appBar: AppBar(title: const Text("Error")),
                body: Center(child: Text(error)),
              );
            }

            // 4. Resolve Success: Show the Stepper
            return _buildStepperUI(context, vm);
          },
        );
      },
    );
  }

  Widget _buildStepperUI(BuildContext context, CollectorCreationViewModel vm) {
    return PopScope(
      canPop: !vm.hasUnsavedProgress,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard(context);
        if (shouldDiscard && context.mounted) {
          context.pop();
        }
      },
      child: DynamicResponsiveScaffold(
        appBar: HandlebarOldAppBar(
          title: 'Create a Data Collector',
          onReturn: () async {
            if (vm.hasUnsavedProgress) {
              final ok = await _confirmDiscard(context);
              if (!ok) return;
            }
            if (context.mounted) context.pop();
          },
        ),
        child: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: vm.currentStep,
              builder: (context, step, _) {
                return CollectorStepperBreadcrumb(
                  currentStep: step,
                  onStepTapped: (target) async {
                    // Logic for jumping steps...
                    vm.goToStep(target);
                  },
                );
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: vm.currentStep,
                builder: (context, step, _) {
                  switch (step) {
                    case 0:
                      return const UploadRecordingStep();
                    case 1:
                      return const SelectFrameStep();
                    case 2:
                      return const SelectLandmarksStep();
                    case 3:
                      return const SelectDataFieldsStep();
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
