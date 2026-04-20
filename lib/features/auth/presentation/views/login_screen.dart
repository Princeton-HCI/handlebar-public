import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/core/utils/validators.dart';
import 'package:handlebar/features/auth/presentation/widgets/auth_header.dart';
import 'package:handlebar/features/crepe/services/crepe_service.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../terms/data/terms_repository.dart';
import '../../data/auth_repository.dart';
import '../view_models/login_viewmodel.dart';
import '../../../../app/app_locator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;

  // 1. Create a GlobalKey for the Form
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(
        getIt<AuthRepository>(),
        getIt<TermsRepository>(),
        getIt<AuthTokenStore>(),
        getIt<CrepeService>());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate the form before attempting login
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _viewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return SafeScaffold(
      enableScrolling: true,
      usePadding: true,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Spacing.token512),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacing.vSpace24,

                const AuthHeader(),

                Spacing.vSpace24,

                // Header
                Text('Login to your account:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall),

                Spacing.vSpace24,

                HandlebarTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    // Email Validator
                    validator: (value) => Validators.email(value)),

                Spacing.vSpace24,

                HandlebarTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    // Password Validator
                    validator: (value) => Validators.password(value)),

                Spacing.vSpace32,

                ValueListenableBuilder<bool>(
                  valueListenable: _viewModel.isLoading,
                  builder: (context, isLoading, child) {
                    return HandlebarButton.primary(
                      label: 'Login',
                      expand: true,
                      isLoading: isLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),

                Spacing.vSpace32,

                // "Returning User?" Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.token16),
                      child: Text(
                        "New User?",
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
                  label: 'Register',
                  expand: true,
                  onPressed: () => context.go('/register'),
                ),

                Spacing.vSpace24,

                ValueListenableBuilder<String?>(
                  valueListenable: _viewModel.errorMessage,
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
            ),
          ),
        ),
      ),
    );
  }
}
