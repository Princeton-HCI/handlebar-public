import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

/// A layout wrapper that applies responsive width constraints, text scaling,
/// and SafeArea
class DynamicResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final double? maxContentWidth;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;

  const DynamicResponsiveScaffold({
    super.key,
    this.appBar,
    this.maxContentWidth,
    this.padding,
    this.floatingActionButton,
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
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth ??
                      context.layout.maxContentWidth ??
                      double.infinity,
                ),
                child: child),
          ),
        ),
      ),
    );
  }
}
