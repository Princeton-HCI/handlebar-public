import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/features/auth/data/auth_repository.dart';

import '../../../../app/app_locator.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart'; // Added for HandlebarMobileDrawer
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../services/crepe_service.dart';
import '../view_models/accessibility_view_model.dart';

class AccessibilityScreen extends StatefulWidget {
  final bool isMandatory;

  const AccessibilityScreen({super.key, required this.isMandatory});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen>
    with WidgetsBindingObserver {
  late final AccessibilityViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel =
        AccessibilityViewModel(getIt<AuthRepository>(), getIt<CrepeService>());

    // No need to check native status if we're on the web
    if (!kIsWeb) {
      _viewModel.checkStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      _viewModel.checkStatus().then((_) {
        // If they were trapped and finally enabled it, release them!
        if (widget.isMandatory && _viewModel.isEnabled.value && mounted) {
          getIt<AuthTokenStore>().setNeedsAccessibilityAcceptance(false);
          context.go('/');
        }
      });
    }
  }

  // Escape hatch for trapped users
  Future<void> _handleLogout() async {
    await _viewModel.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _viewModel.isEnabled,
        _viewModel.isLoading,
      ]),
      builder: (context, _) {
        final Widget content = _buildBody(context, theme);

        return SafeScaffold(
          usePadding: false,
          enableScrolling: false,
          appBar: HandlebarAppBar(
            title: 'Accessibility Service',
            showBackArrow: false,
            showMenu: !widget.isMandatory, // Hide menu if trapped
          ),
          endDrawer: widget.isMandatory ? null : const HandlebarMobileDrawer(),
          child: content,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    final isEnabled = _viewModel.isEnabled.value;

    return Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.token768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize:
                MainAxisSize.min, // Keep column height tight to its children
            children: [
// --- SCROLLABLE CONTENT AREA ---
              // This takes up all available space and scrolls if the screen is too small
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.token24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Spacing.token16),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: theme.colorScheme.onSurface),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kIsWeb
                              ? "For Handlebar's data collection to work properly, it relies on the Handlebar Accessibility Service to read the device's screen.\n\n"
                                  "As such, you will not be able to access Handlebar's core functions until it is enabled.\n\n"
                                  "This feature is only available on the mobile application."
                              : "For Handlebar's data collection to work properly, it relies on the Handlebar Accessibility Service to read the device's screen.\n\n"
                                  "As such, you will not be able to access Handlebar's core functions until it is enabled.\n\n"
                                  "To enable/disable the Accessibility Service:\n"
                                  "1. Click 'Go to Accessibility Settings' below\n"
                                  "2. Click on 'Installed apps'\n"
                                  "3. Click on 'Handlebar Accessibility Service'\n"
                                  "4. Turn it on/off",
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Spacing.vSpace24,
                      if (!kIsWeb) ...[
                        Center(
                          child: HandlebarButton.primary(
                            label: 'Go to Accessibility Settings',
                            isLoading: _viewModel.isLoading.value,
                            onPressed: () => _viewModel.openSettings(),
                          ),
                        ),
                        Spacing.vSpace16,
                        SizedBox(
                          height: Spacing.token48,
                          child: Center(
                            child: Text(
                              isEnabled
                                  ? 'Accessibility Service is currently ENABLED'
                                  : 'Accessibility Service is currently DISABLED',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // --- PINNED FOOTER AREA ---
              if (widget.isMandatory) ...[
                Container(
                  padding: const EdgeInsets.all(Spacing.token24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: const Border(
                        top: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: HandlebarButton.neutral(
                    label: 'Decline & Log Out',
                    onPressed: _handleLogout,
                  ),
                )
              ]
            ],
          )),
    );
  }
}
