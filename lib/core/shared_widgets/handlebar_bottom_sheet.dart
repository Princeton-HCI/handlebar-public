import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import '../../app/design-system/spacing.dart';

class HandlebarBottomSheet extends StatelessWidget {
  final Widget child;

  const HandlebarBottomSheet({super.key, required this.child});

  /// Helper to launch bottom sheets with consistent Handlebar styling
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: Colors.black, width: 1.5),
      ),
      builder: (ctx) => HandlebarBottomSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Standardized Drag Handle
          Center(
            child: Container(
              width: Spacing.token48,
              height: 4,
              margin: const EdgeInsets.only(
                  top: Spacing.token12, bottom: Spacing.token8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // The actual content
          Flexible(child: child),
        ],
      ),
    );
  }
}
