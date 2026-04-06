import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/shared_services/notification_service.dart';

/// A widget that displays action buttons in the home screen
class HomeActionButtons extends StatelessWidget {
  final BuildContext homeContext;

  const HomeActionButtons({super.key, required this.homeContext});

  Future<void> _enableAccessibilityService() async {
    try {
      final crepePlugin = CrepePlugin();
      final isEnabled = await crepePlugin.isAccessibilityServiceEnabled();

      if (isEnabled) {
        // Service is already enabled
        NotificationService()
            .showSuccess('✅ Accessibility service is already enabled');
      } else {
        // Open accessibility settings
        await crepePlugin.requestAccessibilityPermission();
      }
    } catch (e) {
      NotificationService()
          .showError('❌ Error checking accessibility service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlatformElevatedButton(
          onPressed: () {
            context.go('/study-consent');
          },
          child: const Text('Research Study Participation'),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          onPressed: () {
            context.push('/dashboard');
          },
          child: const Text('Research Group Dashboard'),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          onPressed: _enableAccessibilityService,
          child: const Text('Enable Accessibility Service'),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          onPressed: () => {},
          child: const Text('Enable Monitoring'),
        ),
      ],
    );
  }
}
