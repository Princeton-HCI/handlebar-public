import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:url_launcher/link.dart';

import '../../../../app/app_locator.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/network/api_client.dart';
import '../../models/auth_session.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../../../core/shared_widgets/buttons/handlebar_segment_group.dart';
import '../../../../core/shared_widgets/inputs/handlebar_text_field.dart';
import '../../../../core/shared_widgets/inputs/interaction_blocker.dart';
import '../../../../core/shared_widgets/scaffolds/static_responsive_scaffold.dart';

enum _AuthMode { login, signup }

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Result<AuthSession, ApiError> r = await authRepo.login(
        _emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    r.fold(onSuccess: (auth) {
      context.go('/');
    }, onFailure: (err) {
      setState(() {
        _errorMessage = err.message.isNotEmpty
            ? err.message
            : 'Login failed. Please try again.';
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Result<AuthSession, ApiError> r = await authRepo.signup(
        _emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    r.fold(
      onSuccess: (_) => context.go('/'),
      onFailure: (err) {
        setState(() {
          _errorMessage = err.message.isNotEmpty
              ? err.message
              : 'Account creation failed. Please try again.';
        });
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaticResponsiveScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacing.vSpace48,
          _LoginHeader(),
          Spacing.vSpace32,
          InteractionBlocker(
              isBlocked: _isLoading,
              child: Column(children: [
                SizedBox(
                    width: context.scaled(Spacing.token288),
                    child: HandlebarSegmentGroup(
                      index: _mode == _AuthMode.login ? 0 : 1,
                      tabs: const ["Login", "Sign Up"],
                      minHeight: Spacing.token56,
                      onPressed: (index) => setState(() {
                        _mode = index == 0 ? _AuthMode.login : _AuthMode.signup;
                        _formKey.currentState?.reset();
                        _emailController.clear();
                        _passwordController.clear();
                        _showPassword = false;
                        _clearError();
                      }),
                    )),
                Spacing.vSpace24,
                if (_errorMessage != null) ...[
                  _LoginErrorDisplay(
                    errorMessage: _errorMessage,
                    onDismiss: _clearError,
                  )
                ],
                _LoginForm(
                  formKey: _formKey,
                  mode: _mode,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  showPassword: _showPassword,
                  onTogglePassword: () =>
                      setState(() => _showPassword = !_showPassword),
                  clearError: _clearError,
                ),
                if (_mode == _AuthMode.login) ...[
                  Spacing.vSpace24,
                  _ForgotPasswordLink(),
                ]
              ])),
          Spacing.vSpace24,
          SizedBox(
            width: context.scaled(Spacing.token256),
            child: HandlebarButton(
                text: _mode == _AuthMode.login ? "Login" : "Sign Up",
                variant: ButtonVariant.primary,
                isLoading: _isLoading,
                minHeight: Spacing.token40,
                loadingText: _mode == _AuthMode.login
                    ? "Logging in..."
                    : "Creating account...",
                onPressed: _isLoading
                    ? null
                    : (_mode == _AuthMode.login)
                        ? _handleLogin
                        : _handleCreateUser),
          )
        ],
      ),
    );
  }
}

/// A Widget for displaying the login logo and welcome text
class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Image.asset(
        'assets/logo-small.png',
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.directions_car,
            size: 120,
            color: Colors.blue,
          );
        },
      ),
      Spacing.vSpace40,
      Text("Welcome to Handlebar!", style: context.headlineLarge),
      Spacing.vSpace8,
      Text("Login or Sign Up Below", style: context.headlineSmall),
    ]);
  }
}

/// A Widget for displaying the login form fields
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _AuthMode mode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback clearError;

  const _LoginForm({
    required this.formKey,
    required this.mode,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
    required this.clearError,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HandlebarTextField(
            controller: emailController,
            hint: "Enter your email",
            inputType: TextInputType.emailAddress,
            isObscured: false,
            prefix: const Icon(Icons.email),
            onChanged: (_) => clearError(),
            validator: Validators.email,
          ),
          Spacing.vSpace24,
          HandlebarTextField(
            controller: passwordController,
            hint: "Enter your password",
            isObscured: !showPassword,
            prefix: const Icon(Icons.lock),
            suffix: IconButton(
              onPressed: onTogglePassword,
              icon:
                  Icon(showPassword ? Icons.visibility_off : Icons.visibility),
            ),
            onChanged: (_) => clearError(),
            validator: Validators.password,
          ),
          if (mode == _AuthMode.signup) ...[
            Spacing.vSpace24,
            HandlebarTextField(
              controller: passwordController,
              hint: "Enter your researcher ID (optional)",
              isEnabled: false,
              isObscured: true,
              prefix: const Icon(Icons.perm_identity),
            ),
          ]
        ],
      ),
    );
  }
}

/// A text link Widget for navigating to the forgot password page from the login screen
class _ForgotPasswordLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse('https://www.driversseat.co/contact'),
      builder: (BuildContext context, FollowLink? followLink) => TextButton(
        onPressed: followLink,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Forgot Password?',
            style: TextStyle(fontStyle: FontStyle.italic)),
      ),
    );
  }
}

/// A banner Widget for displaying login/registration errors
class _LoginErrorDisplay extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onDismiss;

  const _LoginErrorDisplay({this.errorMessage, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.token16, vertical: Spacing.token8),
      margin: const EdgeInsets.only(bottom: Spacing.token24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        border: Border.all(color: scheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          Spacing.hSpace16,
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
            color: scheme.onErrorContainer,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
