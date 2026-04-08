import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/scaffolds/dynamic_responsive_scaffold.dart';
import '../view_models/collector_creation_view_model.dart';
import '../widgets/collector_stepper_breadcrumb.dart';
import 'steps/select_data_fields_step.dart';
import 'steps/select_frame_step.dart';
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
    NotificationService().setContext(context);
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
    final vm = context.watch<CollectorCreationViewModel>();

    final errorListener = ValueListenableBuilder<String?>(
      valueListenable: vm.session.errorMessage,
      builder: (_, msg, __) {
        if (msg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().showError(msg);
          });
        }
        return const SizedBox.shrink();
      },
    );

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
        appBar: HandlebarAppBar(
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
                    if (target < step && vm.hasUnsavedProgress) {
                      final ok = await _confirmDiscard(context);
                      if (!ok) return;
                    }
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
                      return const SelectDataFieldsStep();
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            errorListener,
          ],
        ),
      ),
    );
  }
}
