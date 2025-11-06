import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../crepe/services/collector_service.dart';
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

  Future<void> _testCollectors() async {
    final collectorService = CollectorService();

    // Show loading dialog
    showDialog(
      context: homeContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Testing collectors...'),
            ],
          ),
        );
      },
    );

    final result = await collectorService.testActiveCollectors();

    // Hide loading dialog
    if (homeContext.mounted) Navigator.of(homeContext).pop();

    if (result.success) {
      NotificationService()
          .showSuccess('✅ Successfully tested collectors: ${result.message}');
    } else {
      NotificationService()
          .showError('❌ Failed to test collectors: ${result.message}');
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
          onPressed: _enableAccessibilityService,
          child: const Text('Enable Accessibility Service'),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          onPressed: _testCollectors,
          child: const Text('Enable Monitoring'),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          onPressed: () async {
            await _testCollectors();
            if (context.mounted) {
              context.go('/replay-snapshot');
            }
          },
          child: const Text('Replay Snapshot'),
        ),
      ],
    );
  }
}
