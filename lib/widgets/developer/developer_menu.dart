import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:flutter/material.dart';

import '../../network/request_handler.dart';
import '../../services/collector_service.dart';
import '../../services/notification_service.dart';
import '../../services/ui_snapshot_recording_service.dart';

/// Service class responsible for showing the developer settings
class DeveloperMenu {
  static Future<T?> show<T>({
    required BuildContext parentContext,
    required VoidCallback onEnvChangeInParent,
    required UiSnapshotRecordingService recordingService,
  }) {
    return showModalBottomSheet<T>(
      context: parentContext,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _DeveloperMenuContent(
          bottomSheetContext: context,
          onEnvChangeInParent: onEnvChangeInParent,
          parentContext: parentContext,
          recordingService: recordingService,
        );
      },
    );
  }
}

/// A widget that builds the UI content for the developer menu bottom sheet
class _DeveloperMenuContent extends StatelessWidget {
  final BuildContext bottomSheetContext;
  final VoidCallback onEnvChangeInParent;
  final BuildContext parentContext;
  final UiSnapshotRecordingService recordingService;

  const _DeveloperMenuContent(
      {required this.bottomSheetContext,
      required this.onEnvChangeInParent,
      required this.parentContext,
      required this.recordingService});

  void _showCollectorStatus(
      BuildContext bottomSheetContext, BuildContext parentContext) async {
    Navigator.pop(bottomSheetContext);

    final collectorService = CollectorService();

    // Check if continuous monitoring is enabled
    bool isCrepeEnabled = false;
    try {
      final crepePlugin = CrepePlugin();
      isCrepeEnabled = await crepePlugin.isContinuousMonitoringEnabled();
    } catch (e) {
      // Handle error silently
    }

    // Check if home screen is in the widget tree
    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
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
                  'Continuous Monitoring: ${isCrepeEnabled ? "🔄 ACTIVE" : "⏸️ INACTIVE"}'),
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

  void _switchAPIEnvironment(String env) async {
    onEnvChangeInParent();
    Navigator.pop(bottomSheetContext);
    if (env == 'Production') {
      RequestHandler.useProduction();
      NotificationService().showSuccess('✅ Switched to Production');
    } else if (env == 'Staging') {
      RequestHandler.useStaging();
      NotificationService().showSuccess('✅ Switched to Staging');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _ApiEnvironmentPanel(onSwitchTo: _switchAPIEnvironment,),
            const Divider(height: 30),
            _SnapshotRecordingPanel(
                parentContext: parentContext,
                recordingService: recordingService,
                closeDeveloperMenu: () {
                  Navigator.pop(bottomSheetContext);
                }),
            const Divider(height: 30),
            _SystemStatusContainer(onShowCollectorStatus: () {
              _showCollectorStatus(bottomSheetContext, parentContext);
            })
          ],
        ),
      ),
    );
  }
}

/// A widget that displays the current API environment (e.g. staging, production)
/// and buttons to switch between them
class _ApiEnvironmentPanel extends StatelessWidget {
  final void Function(String) onSwitchTo;

  const _ApiEnvironmentPanel({
    required this.onSwitchTo,
  });

  @override
  Widget build(BuildContext context) {
    final currentEnv = RequestHandler.currentEnvironment;
    final apiUrl = RequestHandler.apiBaseUrl;

    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environment: $currentEnv',
              style: TextStyle(
                fontSize: 16,
                color:
                    currentEnv == 'Production' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'API URL: $apiUrl',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Environment-switching buttons
            Row(children: [
              // Switch to prod button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onSwitchTo('Production'),
                  icon: const Icon(Icons.cloud),
                  label: const Text('Production'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        currentEnv == 'Production' ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Switch to staging button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:  () => onSwitchTo('Staging'),
                  icon: const Icon(Icons.build),
                  label: const Text('Staging'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        currentEnv == 'Staging' ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
            ])
          ],
        ));
  }
}

/// A widget that displays controls for UI snapshot recording
class _SnapshotRecordingPanel extends StatelessWidget {
  final VoidCallback closeDeveloperMenu;
  final BuildContext parentContext;
  final UiSnapshotRecordingService recordingService;

  const _SnapshotRecordingPanel({
    required this.closeDeveloperMenu,
    required this.parentContext,
    required this.recordingService,
  });

  Future<void> _handleClearSnapshotsPressed(BuildContext dialogContext) async {
    if (!parentContext.mounted) return;

    final shouldClear = await showDialog<bool>(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Snapshots'),
          content: Text(
              'Are you sure you want to clear ${recordingService.snapshotCount} snapshots?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (parentContext.mounted && shouldClear == true) {
      recordingService.clearSnapshots();
      closeDeveloperMenu();
      NotificationService().showSuccess('✅ Snapshots cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          '📹 UI Snapshot Recording',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<bool>(
          stream: recordingService.recordingStateStream,
          initialData: recordingService.isRecording,
          builder: (context, snapshot) {
            final isRecording = snapshot.data ?? false;
            return Column(
              children: [
                // Recording mode display and button
                SwitchListTile(
                  title: const Text('Recording Mode'),
                  subtitle: Text(isRecording
                      ? 'Recording in progress...'
                      : 'Start recording UI snapshots'),
                  value: isRecording,
                  onChanged: (value) async {
                    if (value) {
                      await recordingService.startRecording();
                    } else {
                      await recordingService.stopRecording();
                    }
                  },
                ),
                // Captured snapshots counter
                StreamBuilder<int>(
                  stream: recordingService.snapshotCountStream,
                  initialData: recordingService.snapshotCount,
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
                        icon: const Icon(Icons.download),
                        label: const Text('Saved to Downloads'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: recordingService.snapshotCount > 0
                            ? () async {
                                closeDeveloperMenu();
                                NotificationService().showSuccess(
                                    '✅ Snapshots already saved to Downloads');
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear'),
                        onPressed: recordingService.snapshotCount > 0
                            ? () => _handleClearSnapshotsPressed(context)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A widget that displays system status information
class _SystemStatusContainer extends StatelessWidget {
  final VoidCallback onShowCollectorStatus;

  const _SystemStatusContainer({required this.onShowCollectorStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            onPressed: onShowCollectorStatus,
            icon: const Icon(Icons.info_outline),
            label: const Text('Collector Status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }
}
