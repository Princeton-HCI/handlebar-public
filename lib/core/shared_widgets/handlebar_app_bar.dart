import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../app/design-system/spacing.dart';

/// A reusable app bar with the Handlebar theme
class HandlebarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onReturn;

  const HandlebarAppBar({super.key, required this.title, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AppBar(
      leading: IconButton(
          onPressed: onReturn ?? () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: scheme.onSurface,
          )),
      title: Text(
        title,
        style: context.titleLarge!.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      toolbarHeight: context.scaled(Spacing.token64 - 1),
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: scheme.onSurface, height: 1)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(Spacing.token64);
}
