import 'package:flutter/material.dart';
import '../../../../app/design-system/spacing.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap it in a basic MaterialApp so it has access to Directionality and Theme
    // before the main app boots.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo-small.png',
                height: 140,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.directions_car,
                    size: 120,
                    color: Colors.black,
                  );
                },
              ),
              Spacing.vSpace32,
              // Subtle loading indicator
              const CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
