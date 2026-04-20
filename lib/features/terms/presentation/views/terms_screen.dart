import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/app_locator.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
import '../../../../core/shared_widgets/passive_error_view.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/terms_repository.dart';
import '../view_models/terms_view_model.dart';

class TermsScreen extends StatefulWidget {
  final bool isMandatory;

  const TermsScreen({super.key, required this.isMandatory});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final TermsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        TermsViewModel(getIt<AuthRepository>(), getIt<TermsRepository>());
    _viewModel.loadTerms();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await _viewModel.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _viewModel.isLoading,
        _viewModel.errorMessage,
        _viewModel.response,
        _viewModel.isAccepting,
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

  // This just returns the Column, no Scaffold involved!
  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (_viewModel.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage.value != null &&
        _viewModel.termsToDisplay == null) {
      return Column(
        children: [
          Expanded(
            child: PassiveErrorView(
              message: "Could not load Handlebar's Terms and Conditions.",
              subtitle: _viewModel.errorMessage.value,
              onRetry: () => _viewModel.loadTerms(),
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
                    if (_viewModel.termsToDisplay?.title != null &&
                        _viewModel.termsToDisplay!.title.isNotEmpty) ...[
                      Text(
                        _viewModel.termsToDisplay!.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacing.vSpace16,
                    ],
                    Text(
                      _viewModel.termsToDisplay?.text ?? "No terms available.",
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
                      isLoading: _viewModel.isAccepting.value,
                      onPressed: () async {
                        final success = await _viewModel.accept();
                        if (success && context.mounted) {
                          // TODO: have the viewmodel interact with AuthTokenSTore, not the UI
                          await getIt<AuthTokenStore>()
                              .markTermsAsAcceptedLocally();

                          if (context.mounted) context.go('/');
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
