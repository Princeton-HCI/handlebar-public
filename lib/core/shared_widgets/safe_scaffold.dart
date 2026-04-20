import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../app/design-system/spacing.dart';

class SafeScaffold extends StatelessWidget {
  final Widget child;

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer; // <--- ADDED THIS
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  final bool enableScrolling;
  final bool usePadding;

  const SafeScaffold({
    super.key,
    required this.child,
    this.scaffoldKey,
    this.appBar,
    this.drawer,
    this.endDrawer, // <--- ADDED THIS
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.enableScrolling = true,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (usePadding) {
      content = Padding(
        padding: const EdgeInsets.all(Spacing.token24),
        child: content,
      );
    }

    if (enableScrolling) {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: context.colorScheme.surfaceContainer,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}
