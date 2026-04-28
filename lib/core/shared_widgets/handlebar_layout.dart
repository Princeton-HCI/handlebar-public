import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/app/design-system/breakpoints.dart';
import 'package:handlebar/app/design-system/spacing.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/core/shared_widgets/handlebar_button.dart';
import 'package:handlebar/features/auth/data/auth_repository.dart';

import '../../app/app_locator.dart';

/// The master shell for the app.
/// On Mobile: It gets completely out of the way.
/// On Desktop: It provides the permanent top bar and left sidebar.
class HandlebarLayout extends StatelessWidget {
  final Widget child;

  const HandlebarLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= Breakpoints.mobileMax;

        // --- MOBILE ---
        // The Shell does nothing. The individual screen's Scaffold takes over
        if (isMobile) {
          return child;
        }

        // --- DESKTOP ---
        return Scaffold(
          body: Column(
            children: [
              // 1. Persistent Top Navigation Bar
              Container(
                height: Spacing.token64,
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.token24),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border:
                      Border(bottom: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Handlebar',
                      style: context.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                    const Spacer(),
                    // User profile icon could go here
                  ],
                ),
              ),

              // 2. Main Area (Sidebar + Content)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Persistent Sidebar
                    Container(
                      width: Spacing.token256,
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: scheme.outlineVariant)),
                      ),
                      child: const _Sidebar(),
                    ),

                    // Main Content (The screen passing its own Scaffold/AppBar)
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A reusable drawer that holds the exact same sidebar for mobile users.
/// Drop this into the `endDrawer` of any mobile screen that needs a hamburger menu.
class HandlebarMobileDrawer extends StatelessWidget {
  const HandlebarMobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: SafeArea(
        child: _Sidebar(),
      ),
    );
  }
}

// === INTERNAL SIDEBAR LOGIC ===

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    // Dynamically grab the current path from GoRouter! No need to pass it down.
    final currentPath = GoRouterState.of(context).uri.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Navigation Links
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.token16,
              vertical: Spacing.token24,
            ),
            children: [
              _SidebarItem(
                label: 'Studies',
                route: '/',
                currentPath: currentPath,
              ),
              Spacing.vSpace8,
              _SidebarItem(
                label: 'Accessibility Service',
                route: '/accessibility',
                currentPath: currentPath,
              ),
              Spacing.vSpace8,
              _SidebarItem(
                label: 'Terms and Conditions',
                route: '/terms',
                currentPath: currentPath,
              ),
              Spacing.vSpace8,
            ],
          ),
        ),

        // 2. Pinned Footer (Log Out)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.token24),
            child: Align(
              alignment: Alignment.center,
              child: HandlebarButton.danger(
                label: 'Log Out',
                onPressed: () async {
                  // Close the mobile drawer gracefully before logging out
                  if (Scaffold.of(context).hasDrawer &&
                      Scaffold.of(context).isDrawerOpen) {
                    Navigator.pop(context);
                  }

                  await getIt<AuthRepository>().logout();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final String route;
  final String currentPath;

  const _SidebarItem({
    required this.label,
    required this.route,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    if (route == '/') {
      isActive = currentPath == '/' || currentPath.startsWith('/studies');
    } else {
      isActive = currentPath.startsWith(route);
    }

    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Spacing.token8),
        border: Border.all(
          color: isActive ? scheme.primary : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: ListTile(
        hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        visualDensity: VisualDensity.compact,
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                color: scheme.onSurface,
              ),
        ),
        onTap: () {
          if (isActive && currentPath == route) return;

          if (Scaffold.of(context).hasDrawer &&
              Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }

          context.go(route);
        },
      ),
    );
  }
}
