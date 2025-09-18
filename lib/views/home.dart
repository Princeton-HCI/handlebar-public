import 'package:handlebar/network/request_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/services/ui_snapshot_recording_service.dart';
import 'package:handlebar/services/notification_service.dart';
import 'package:handlebar/widgets/home/home_action_buttons.dart';
import 'package:handlebar/widgets/home/home_header.dart';

import '../widgets/home/home_app_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final RequestHandler _requestHandler = RequestHandler();
  final UiSnapshotRecordingService _recordingService =
      UiSnapshotRecordingService();

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await _requestHandler.clearAuthToken();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    NotificationService().setContext(context);

    return Scaffold(
      appBar: HomeAppBar(
          onLogoutPressed: _handleLogout,
          onEnvChanged: () => {if (mounted) setState(() {})},
          parentContext: context,
          recordingService: _recordingService),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HomeHeader(),

              const SizedBox(height: 48),

              HomeActionButtons(homeContext: context),

              const SizedBox(height: 16),

              // Developer menu hint (only in debug mode)
              if (kDebugMode) ...[
                const Text(
                  '💡 Long press the app title to access developer settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
