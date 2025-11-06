import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

/// A reusable, circular icon button with the Handlebar theme. This widget
/// can either execute an [onPressed] callback or display an informational dialog
/// with the given [dialogText].
class HandlebarIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback? onPressed;
  final String? dialogText;

  const HandlebarIconButton({
    super.key,
    required this.icon,
    required this.iconSize,
    this.onPressed,
    this.dialogText,
  });

  void _showDialog(BuildContext context, String infoText) {
    final scheme = context.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: scheme.surface,
        elevation: 8,
        title: Text('Information', style: context.titleLarge),
        content: Text(
          infoText,
          style: context.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              textStyle: context.bodyLarge!.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final backgroundColor = isDark ? scheme.surface : scheme.onSurface;
    final iconColor = isDark ? scheme.onSurface : scheme.surface;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: iconSize / 1.5),
        splashRadius: iconSize / 2,
        onPressed: dialogText != null
            ? () => _showDialog(context, dialogText!)
            : onPressed,
      ),
    );
  }
}
