import 'package:handlebar/network/request_handler.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/widgets/login/auth_button.dart';
import 'package:handlebar/widgets/login/email_text_field.dart';
import 'package:handlebar/widgets/login/forgot_password_link.dart';
import 'package:handlebar/widgets/login/login_error_display.dart';
import 'package:handlebar/widgets/login/login_header.dart';
import 'package:handlebar/widgets/login/password_text_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final RequestHandler requestHandler = RequestHandler();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isCreatingUser = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRequestHandler();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeRequestHandler() async {
    await requestHandler.initialize();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await requestHandler.requestSession(
        emailController.text.trim(),
        passwordController.text,
      );

      if (mounted) {
        if (result.success) {
          // Login successful, navigate to home
          context.go('/');
        } else {
          setState(() {
            _errorMessage = result.error ?? 'Login failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingUser = true;
      _errorMessage = null;
    });

    try {
      final result = await requestHandler.requestNewUser(
        emailController.text.trim(),
        passwordController.text,
        referralCode: null,
      );

      if (mounted) {
        if (result.success) {
          // User creation and login successful, navigate to home
          context.go('/');
        } else {
          setState(() {
            _errorMessage =
                result.error ?? 'Account creation failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingUser = false;
        });
      }
    }
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoginHeader(),

                  const SizedBox(height: 40),

                  if (_errorMessage != null) ...[
                    LoginErrorDisplay(
                      errorMessage: _errorMessage,
                      onDismiss: _clearError,
                    )
                  ],

                  EmailTextField(
                      emailController: emailController,
                      onChanged: (_) => _clearError()),

                  const SizedBox(height: 16),

                  PasswordTextField(
                      passwordController: passwordController,
                      onChanged: (_) => _clearError()),

                  const SizedBox(height: 24),

                  ForgotPasswordLink(),

                  const SizedBox(height: 24),

                  // Login button
                  AuthButton(
                    isLoading: _isLoading,
                    loadingText: "Logging in...",
                    onPressed:
                        (_isLoading || _isCreatingUser) ? null : _handleLogin,
                    text: "Login",
                  ),

                  const SizedBox(height: 16),

                  // Register button
                  AuthButton(
                      isLoading: _isCreatingUser,
                      loadingText: "Creating account...",
                      onPressed: (_isLoading || _isCreatingUser)
                          ? null
                          : _handleCreateUser,
                      text: "Sign Up"),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
