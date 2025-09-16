import 'package:flutter/material.dart';

/// A widget for displaying the logo and welcome text for the login screen
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 60),
      Image.asset(
        'assets/logo-small.png',
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.directions_car,
            size: 120,
            color: Colors.blue,
          );
        },
      ),
      const SizedBox(height: 40),
      const Text(
        "Log in to Handlebar",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        "Welcome back!",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    ]);
  }
}
