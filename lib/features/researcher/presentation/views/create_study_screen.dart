import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/breakpoints.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/view_models/create_study_view_model.dart'; // Added import

class CreateStudyScreen extends StatefulWidget {
  const CreateStudyScreen({super.key});

  @override
  State<CreateStudyScreen> createState() => _CreateStudyScreenState();
}

class _CreateStudyScreenState extends State<CreateStudyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<CreateStudyViewModel>();

    final study = await vm.createStudy(
      _nameController.text.trim(),
      _descController.text.trim(),
    );

    if (!mounted) return;

    if (study != null) {
      NotificationService().showSuccess("Study successfully created");
      // Hand the study back so the home screen can open its detail page,
      // where collectors and sensors are configured.
      context.pop(study);
    } else if (vm.errorMessage.value != null) {
      NotificationService().showError(vm.errorMessage.value!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final vm = context.read<CreateStudyViewModel>();

    final isDesktop = context.width > Breakpoints.mobileMax;

    return SafeScaffold(
      usePadding: true,
      enableScrolling: true,
      appBar: HandlebarAppBar(
        title: 'Create a Study',
        showBackArrow: true,
        onReturn: () => context.pop(),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.token768),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Spacing.vSpace8,
                  Text(
                    'Create a Study',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Spacing.vSpace16,
                  const Divider(),
                  Spacing.vSpace24,
                ],
                if (!isDesktop) Spacing.vSpace24,
                Text(
                  'Enter a name and description\nfor your study:',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                Spacing.vSpace32,
                HandlebarTextField(
                  controller: _nameController,
                  hintText: 'Name',
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.notEmpty(v),
                ),
                Spacing.vSpace24,
                HandlebarTextField(
                  controller: _descController,
                  hintText: 'Description',
                  maxLines: 4, // Utilizing our new property!
                  isRequired: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.notEmpty(v),
                ),
                Spacing.vSpace32,
                Align(
                  alignment: Alignment.centerRight,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: vm.isSubmitting,
                    builder: (context, isSubmitting, _) {
                      return HandlebarButton.primary(
                        label: 'Create',
                        isLoading: isSubmitting,
                        onPressed: _onSubmit,
                      );
                    },
                  ),
                ),
                Spacing.vSpace32,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
