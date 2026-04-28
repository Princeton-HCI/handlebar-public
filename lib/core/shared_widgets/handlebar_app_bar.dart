import 'package:flutter/material.dart';
import 'package:handlebar/app/design-system/breakpoints.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../app/design-system/spacing.dart';

class HandlebarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onReturn;
  final bool showBackArrow;
  final bool showMenu;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;

  const HandlebarAppBar({
    super.key,
    required this.title,
    this.onReturn,
    this.showBackArrow = true,
    this.showMenu = false,
    this.onMenuPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // THE DESKTOP GHOST MODE
    final isMobile = context.width <= Breakpoints.mobileMax;
    if (!isMobile) {
      return const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      );
    }

    // THE NORMAL MOBILE MODE
    final scheme = context.colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: scheme.surface,
      elevation: 0,

      // --- LEFT PADDING (WITH ARROW) ---
      // Flutter's default leading width is 56. We add our padding value to it
      // so the icon isn't squished when we push it inward.
      leadingWidth: showBackArrow ? 56 + Spacing.token16 : 56,
      leading: showBackArrow
          ? Padding(
              padding: const EdgeInsets.only(left: Spacing.token16),
              child: IconButton(
                onPressed: onReturn ?? () => Navigator.maybePop(context),
                icon: Icon(Icons.arrow_back, color: scheme.onSurface, size: 28),
              ),
            )
          : null,

      centerTitle: false,
      // --- LEFT PADDING (NO ARROW) ---
      // If there is no back arrow, use a larger token to pad the text.
      // If there is an arrow, keep it at 0 so it hugs the arrow closely.
      titleSpacing: showBackArrow ? 0 : Spacing.token24,
      title: Text(
        title,
        style: context.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),

      actions: [
        if (actions != null) ...actions!,

        if (showMenu)
          IconButton(
            onPressed:
                onMenuPressed ?? () => Scaffold.of(context).openEndDrawer(),
            icon: Icon(Icons.menu, color: scheme.onSurface, size: 28),
          ),

        // Pushes the actions (like the menu icon) inward from the right edge
        const SizedBox(width: Spacing.token16),
      ],

      toolbarHeight: context.scaled(Spacing.token64 - 1.5),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(color: scheme.onSurface, height: 1.5),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(Spacing.token64);
}
