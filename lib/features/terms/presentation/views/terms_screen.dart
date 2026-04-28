import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
import '../../../../core/shared_widgets/passive_error_view.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../view_models/terms_view_model.dart';

class TermsScreen extends StatefulWidget {
  final bool isMandatory;

  const TermsScreen({super.key, required this.isMandatory});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TermsViewModel>().loadTerms();
  }

  Future<void> _handleLogout() async {
    await context.read<TermsViewModel>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TermsViewModel>();
    final theme = context.theme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        vm.isLoading,
        vm.errorMessage,
        vm.response,
        vm.isAccepting,
      ]),
      builder: (context, _) {
        // Build the raw content first
        final Widget content = _buildBody(context, theme);

        return SafeScaffold(
          usePadding: false,
          enableScrolling:
              false, // Turned off because _buildBody handles its own scrolling
          // because of the fixed footer
          appBar: HandlebarAppBar(
            title: 'Terms of Service',
            showBackArrow: false,

            // If they are trapped (mandatory), hide the menu. If not, show it
            showMenu: !widget.isMandatory,
          ),

          // If they are trapped, no drawer. If not, give them the swipe menu
          endDrawer: widget.isMandatory ? null : const HandlebarMobileDrawer(),

          child: content,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    final vm = context.read<TermsViewModel>();
    if (vm.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage.value != null && vm.termsToDisplay == null) {
      return Column(
        children: [
          Expanded(
            child: PassiveErrorView(
              message: "Could not load Handlebar's Terms and Conditions.",
              subtitle: vm.errorMessage.value,
              onRetry: () => vm.loadTerms(),
            ),
          ),
          if (widget.isMandatory)
            Padding(
              padding: const EdgeInsets.all(Spacing.token24),
              child: HandlebarButton.neutral(
                label: 'Log Out',
                expand: true,
                onPressed: _handleLogout,
              ),
            ),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.token768),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.token24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.vSpace8,
                    if (widget.isMandatory) ...[
                      Text(
                        "By using this app, you agree to Handlebar's Terms and Conditions:",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacing.vSpace24,
                    ],
                    if (vm.termsToDisplay?.title != null &&
                        vm.termsToDisplay!.title.isNotEmpty) ...[
                      Text(
                        vm.termsToDisplay!.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacing.vSpace16,
                    ],
                    Text(
                      vm.termsToDisplay?.text ?? "No terms available.",
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    Spacing.vSpace8
                  ],
                ),
              ),
            ),

            // Mandatory footer buttons
            if (widget.isMandatory)
              Container(
                padding: const EdgeInsets.all(Spacing.token24),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: const Border(
                      top: BorderSide(color: Colors.black, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    HandlebarButton.primary(
                      label: 'Accept Terms',
                      isLoading: vm.isAccepting.value,
                      onPressed: () async {
                        final success = await vm.accept();
                        if (success && context.mounted) {
                          context.go('/');
                        }
                      },
                    ),
                    Spacing.vSpace16,
                    HandlebarButton.neutral(
                      label: 'Decline & Log Out',
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
