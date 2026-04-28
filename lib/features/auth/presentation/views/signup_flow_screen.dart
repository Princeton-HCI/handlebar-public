import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../view_models/signup_viewmodel.dart';
import '../widgets/auth_header.dart';
import '../widgets/credentials_step.dart';
import '../widgets/role_selection_step.dart';
import '../widgets/study_code_step.dart';

class SignupFlowScreen extends StatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    // PageController lets us slide between screens without changing the URL
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- NAVIGATION HELPERS ---

  void _goToLogin() {
    context.go('/login');
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SignupViewModel>();

    return SafeScaffold(
        enableScrolling: true,
        usePadding: false,
        child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Spacing.token512),
              child: Column(children: [
                Spacing.vSpace24,
                const Padding(
                  padding: EdgeInsets.all(Spacing.token24),
                  child: AuthHeader(),
                ),
                ValueListenableBuilder<SignupRole>(
                  valueListenable: vm.selectedRole,
                  builder: (context, role, child) {
                    final pages = [
                      _AuthStepWrapper(
                        child: RoleSelectionStep(
                          viewModel: vm,
                          onLoginSelected: _goToLogin,
                          onRoleSelected: (selectedRole) {
                            vm.setRole(selectedRole);
                            _nextPage();
                          },
                        ),
                      ),
                      if (role == SignupRole.participant)
                        _AuthStepWrapper(
                          child: StudyCodeStep(
                            viewModel: vm,
                            onBack: _previousPage,
                            onValidCodeProvided: _nextPage,
                          ),
                        ),
                      _AuthStepWrapper(
                        child: CredentialsStep(
                          viewModel: vm,
                          onBack: _previousPage,
                          onSignupSuccess: () => context.go('/accept-terms'),
                        ),
                      ),
                    ];

                    return ExpandablePageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: pages,
                    );
                  },
                )
              ])),
        ));
  }
}

class _AuthStepWrapper extends StatelessWidget {
  final Widget child;

  const _AuthStepWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.token24,
          vertical: 0,
        ),
        child: child,
      ),
    );
  }
}
