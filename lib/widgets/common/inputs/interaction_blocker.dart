import 'package:flutter/material.dart';

/// A Widget that wraps a child with an opacity fade and disables interaction
/// when [isBlocked] is true
class InteractionBlocker extends StatelessWidget {
  final bool isBlocked;
  final Widget child;
  final Duration duration;
  final double disabledOpacity;

  const InteractionBlocker({
    super.key,
    required this.isBlocked,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
    this.disabledOpacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isBlocked ? disabledOpacity : 1.0,
      duration: duration,
      child: AbsorbPointer(
        absorbing: isBlocked,
        child: child,
      ),
    );
  }
}
