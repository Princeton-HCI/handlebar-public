import 'package:flutter/material.dart';
import 'package:handlebar/extensions/context_extensions.dart';

/// A layout wrapper Widget that centers its child within a finite scrollable,
/// SafeArea, Scaffold container and applies responsive width constraints and
/// text scaling
class StaticResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final double? maxContentWidth;
  final EdgeInsetsGeometry? padding;

  const StaticResponsiveScaffold({
    super.key,
    this.appBar,
    this.maxContentWidth,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(context.scaler),
        ),
        child: Scaffold(
            appBar: appBar,
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: padding ?? context.layout.topLevelScreenPadding,
                    child: Center(
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: maxContentWidth ??
                                    context.layout.maxContentWidth ??
                                    double.infinity),
                            child: child))))));
  }
}
