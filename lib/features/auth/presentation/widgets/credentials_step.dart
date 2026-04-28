import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/core/utils/validators.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../view_models/signup_viewmodel.dart';

class CredentialsStep extends StatefulWidget {
  final SignupViewModel viewModel;
  final VoidCallback onBack;
  final VoidCallback onSignupSuccess;

  const CredentialsStep({
    super.key,
    required this.viewModel,
    required this.onBack,
    required this.onSignupSuccess,
  });

  @override
  State<CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<CredentialsStep> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate the form before submitting
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await widget.viewModel.submitRegistration(email, password);

    if (success && mounted) {
      widget.onSignupSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Create your account:',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall),

          Spacing.vSpace24,

          // Inputs
          HandlebarTextField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.email(value)),

          Spacing.vSpace24,

          HandlebarTextField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => Validators.password(value)),

          Spacing.vSpace32,

          ValueListenableBuilder<bool>(
            valueListenable: widget.viewModel.isLoading,
            builder: (context, isLoading, child) {
              return HandlebarButton.primary(
                label: 'Sign Up',
                expand: true,
                isLoading: isLoading,
                onPressed: _submit,
              );
            },
          ),

          Spacing.vSpace16,

          // Align removes the width stretch from the column
          HandlebarButton.neutral(
            label: 'Go Back',
            onPressed: widget.onBack,
          ),

          Spacing.vSpace16,
        ],
      ),
    );
  }
}
