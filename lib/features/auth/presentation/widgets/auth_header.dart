import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/design-system/spacing.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Image.asset(
        'assets/logo-small.png',
        height: 140,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.directions_car,
            size: 120,
            color: Colors.blue,
          );
        },
      ),
      Spacing.vSpace40,
      Text(
        "Welcome to Handlebar!",
        textAlign: TextAlign.center,
        style: context.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      Spacing.vSpace8,
    ]);
  }
}
