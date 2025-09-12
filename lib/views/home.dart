import 'package:handlebar/network/request_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/services/collector_service.dart';
import 'package:handlebar/services/ui_snapshot_recording_service.dart';
import 'package:handlebar/services/notification_service.dart';
import 'package:crepe_plugin/crepe_plugin.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final RequestHandler _requestHandler = RequestHandler();
  final UiSnapshotRecordingService _recordingService =
      UiSnapshotRecordingService();

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

  void _showDeveloperMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛠️ Developer Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Environment Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Environment: ${RequestHandler.currentEnvironment}',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              RequestHandler.currentEnvironment == 'Production'
                                  ? Colors.green
                                  : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'API URL: ${RequestHandler.apiBaseUrl}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          RequestHandler.useProduction();
                          setState(() {});
                          Navigator.pop(context);
                          NotificationService()
                              .showSuccess('✅ Switched to Production');
                        },
                        icon: const Icon(Icons.cloud),
                        label: const Text('Production'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              RequestHandler.currentEnvironment == 'Production'
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          RequestHandler.useStaging();
                          setState(() {});
                          Navigator.pop(context);
                          NotificationService()
                              .showWarning('🔧 Switched to Staging');
                        },
                        icon: const Icon(Icons.build),
                        label: const Text('Staging'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              RequestHandler.currentEnvironment == 'Staging'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      RequestHandler.toggleEnvironment();
                      setState(() {});
                      Navigator.pop(context);
                      NotificationService().showInfo(
                          '🔄 Toggled to ${RequestHandler.currentEnvironment}');
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Toggle Environment'),
                  ),
                ),
                const Divider(height: 30),
                const Text(
                  '📹 UI Snapshot Recording',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<bool>(
                  stream: _recordingService.recordingStateStream,
                  initialData: _recordingService.isRecording,
                  builder: (context, snapshot) {
                    final isRecording = snapshot.data ?? false;
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Recording Mode'),
                          subtitle: Text(isRecording
                              ? 'Recording in progress...'
                              : 'Start recording UI snapshots'),
                          value: isRecording,
                          onChanged: (value) async {
                            if (value) {
                              await _recordingService.startRecording();
                            } else {
                              await _recordingService.stopRecording();
                              if (mounted &&
                                  _recordingService.snapshotCount > 0) {
                                // Note: This notification is now handled by the recording service itself
                              }
                            }
                          },
                        ),
                        StreamBuilder<int>(
                          stream: _recordingService.snapshotCountStream,
                          initialData: _recordingService.snapshotCount,
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Captured Snapshots'),
                              trailing: Text(
                                count.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _recordingService.snapshotCount > 0
                                    ? () async {
                                        Navigator.pop(
                                            context); // Close developer menu first

                                        // Snapshots are already auto-saved to Downloads
                                        // Just show confirmation
                                        NotificationService().showSuccess(
                                            '✅ Snapshots already saved to Downloads');
                                      }
                                    : null,
                                icon: const Icon(Icons.download),
                                label: const Text('Saved to Downloads'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _recordingService.snapshotCount > 0
                                    ? () async {
                                        if (!mounted) return;
                                        final navigator = Navigator.of(context);
                                        final shouldClear =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Clear Snapshots'),
                                              content: Text(
                                                  'Are you sure you want to clear ${_recordingService.snapshotCount} snapshots?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text('Clear'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (mounted && shouldClear == true) {
                                          _recordingService.clearSnapshots();
                                          navigator.pop();
                                          NotificationService().showSuccess(
                                              '✅ Snapshots cleared');
                                        }
                                      }
                                    : null,
                                icon: const Icon(Icons.delete),
                                label: const Text('Clear'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 30),
                const Text(
                  '📊 System Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close developer menu
                      _showCollectorStatus();
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Collector Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _testCollectors() async {
    final collectorService = CollectorService();

    // Show loading dialog
    showDialog(
      context: context,
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
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result.success) {
      NotificationService()
          .showSuccess('✅ Successfully tested collectors: ${result.message}');
    } else {
      NotificationService()
          .showError('❌ Failed to test collectors: ${result.message}');
    }
  }

  void _showCollectorStatus() async {
    final collectorService = CollectorService();

    // Check if continuous monitoring is enabled
    bool isEnabled = false;
    try {
      final crepePlugin = CrepePlugin();
      isEnabled = await crepePlugin.isContinuousMonitoringEnabled();
    } catch (e) {
      // Handle error silently
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('🎯 Collector Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Service Initialized: ${collectorService.isInitialized ? "✅" : "❌"}'),
                const SizedBox(height: 8),
                Text(
                    'Continuous Monitoring: ${isEnabled ? "🔄 ACTIVE" : "⏸️ INACTIVE"}'),
                const SizedBox(height: 8),
                Text(
                    'Active Collectors: ${collectorService.activeCollectorResponse != null ? "📊 LOADED (${collectorService.activeCollectorResponse!.collectors.length})" : "❌ NONE"}'),
                const SizedBox(height: 16),
                const Text(
                  'When continuous monitoring is active, the app will automatically detect when you navigate to collector target screens (like Maps) and send events to the backend.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set context for notification service
    NotificationService().setContext(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _showDeveloperMenu,
          child: const Text('Handlebar'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Recording indicator
          StreamBuilder<bool>(
            stream: _recordingService.recordingStateStream,
            initialData: _recordingService.isRecording,
            builder: (context, snapshot) {
              final isRecording = snapshot.data ?? false;
              if (!isRecording) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Environment indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: RequestHandler.currentEnvironment == 'Production'
                  ? Colors.green
                  : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              RequestHandler.currentEnvironment == 'Production'
                  ? 'PROD'
                  : 'STAGE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_car,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Handlebar!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your driver dashboard for tracking and insights.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Main action buttons
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
                onPressed: () {
                  context.go('/replay-snapshot');
                },
                child: const Text('Replay Snapshot'),
              ),
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
