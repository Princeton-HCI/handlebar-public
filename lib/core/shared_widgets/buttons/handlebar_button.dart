import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../app/design-system/spacing.dart';
import '../effects/drop_shadow_container.dart';

enum ButtonVariant { primary, destructive }

/// A reusable button Widget with the Handlebar theme
class HandlebarButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final double minHeight;
  final String? loadingText;
  final Widget? prefixIcon;

  const HandlebarButton(
      {super.key,
      required this.text,
      this.onPressed,
      required this.variant,
      required this.isLoading,
      this.minHeight = Spacing.token48,
      this.loadingText,
      this.prefixIcon});

  static const _borderRadius = 8.0;
  static const _borderWidth = 1.2;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final disabled = isLoading || onPressed == null;
    final textStyle = switch (variant) {
      ButtonVariant.primary => context.labelLarge,
      ButtonVariant.destructive =>
        context.labelLarge?.copyWith(color: scheme.onError),
    };

    final Widget child;
    if (isLoading) {
      child = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(
            width: Spacing.token16,
            height: Spacing.token16,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black))),
        Spacing.hSpace16,
        Text(loadingText ?? 'Please wait...', style: textStyle)
      ]);
    } else {
      final List<Widget> rowChildren = [];
      if (prefixIcon != null) {
        rowChildren.add(prefixIcon!);
        rowChildren.add(Spacing.hSpace8);
      }
      rowChildren.add(Text(text, style: textStyle));

      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: rowChildren,
      );
    }

    final commonPadding = EdgeInsets.symmetric(
      vertical: (minHeight - 32).clamp(0, double.infinity) / 2,
      horizontal: Spacing.token16,
    );

    final Widget button = switch (variant) {
      ButtonVariant.primary => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: scheme.outline, width: _borderWidth),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius)),
            padding: commonPadding,
            minimumSize: Size(0, minHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),
      ButtonVariant.destructive => FilledButton(
          onPressed: disabled ? null : onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: scheme.onError,
            backgroundColor: scheme.error,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius)),
            padding: commonPadding,
            minimumSize: Size(0, minHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        )
    };

    return DropShadowContainer(borderRadius: _borderRadius, child: button);
  }
}
