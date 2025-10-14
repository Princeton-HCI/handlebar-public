import 'package:flutter/material.dart';
import 'package:handlebar/extensions/context_extensions.dart';

/// A reusable container that applies a soft drop shadow effect
/// on its child
class DropShadowContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double elevation;

  const DropShadowContainer(
      {super.key,
      required this.child,
      this.borderRadius = 0.0,
      this.elevation = 3.0});

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      elevation: elevation,
      shadowColor: context.colorScheme.shadow,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}
