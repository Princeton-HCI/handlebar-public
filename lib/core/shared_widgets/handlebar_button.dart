import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../app/design-system/spacing.dart';

enum HandlebarButtonVariant { primary, danger, neutral }

/// Helper class to group colors for the outlined variants (primary & danger).
class _HandlebarButtonColors {
  const _HandlebarButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class HandlebarButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final HandlebarButtonVariant variant;
  final bool isLoading;
  final bool expand;

  const HandlebarButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    required this.variant,
    this.isLoading = false,
    this.expand = false,
  });

  const HandlebarButton.primary({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.expand = false,
  }) : variant = HandlebarButtonVariant.primary;

  const HandlebarButton.danger({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.expand = false,
  }) : variant = HandlebarButtonVariant.danger;

  const HandlebarButton.neutral({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.expand = false,
  }) : variant = HandlebarButtonVariant.neutral;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // 1. Delegate to the correct builder based on the variant.
    final Widget button = switch (variant) {
      HandlebarButtonVariant.neutral => _buildNeutralButton(theme),
      HandlebarButtonVariant.primary ||
      HandlebarButtonVariant.danger =>
        _buildOutlinedButton(theme),
    };

    // 2. Wrap in a SizedBox if the user requested it to expand to full width
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  // The "Phantom Layout" Content Builder
  Widget _buildButtonContent() {
    // 1. Build the raw content (Icon + Text) in a Row
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          Spacing.vSpace8,
        ],
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    // 2. If NOT loading, just return the text/icon normally
    if (!isLoading) return content;

    // 3. Avoid jittering between loading and normal states
    return Stack(
      alignment: Alignment.center,
      children: [
        // This invisible layer keeps the exact width and height locked in place
        Opacity(
          opacity: 0.0,
          child: content,
        ),
        // The spinner sits perfectly centered inside that locked space
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  // Neutral Variant (Tight Text Link)
  Widget _buildNeutralButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final style = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface,
      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    ).copyWith(
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
    );

    return TextButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: _buildButtonContent(),
    );
  }

  // Primary & Danger Variants (Structured Buttons)
  Widget _buildOutlinedButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final colors = switch (variant) {
      HandlebarButtonVariant.primary => _HandlebarButtonColors(
          background: colorScheme.surface,
          foreground: colorScheme.onSurface,
          border: colorScheme.onSurface,
        ),
      HandlebarButtonVariant.danger => _HandlebarButtonColors(
          background: colorScheme.error,
          foreground: colorScheme.onError,
          border: colorScheme.onSurface,
        ),
      HandlebarButtonVariant.neutral =>
        throw StateError('Neutral is handled separately'),
    };

    final style = OutlinedButton.styleFrom(
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      elevation: effectiveOnPressed == null
          ? 0
          : 4, // Drops to 0 when loading/disabled
      shadowColor: Colors.black.withValues(alpha: 0.5),
      disabledForegroundColor: isLoading
          ? colors.foreground
          : colors.foreground.withValues(alpha: 0.38),
      side: onPressed == null
          ? BorderSide.none
          : BorderSide(color: colors.border, width: 1.5),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.token24, vertical: Spacing.token8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return const Color(0xFF2196F3).withValues(alpha: 0.10);
        }
        return null;
      }),
    );

    return OutlinedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: _buildButtonContent(),
    );
  }
}
