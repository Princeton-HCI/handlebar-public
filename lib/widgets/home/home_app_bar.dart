import 'package:flutter/material.dart';
import 'package:handlebar/services/ui_snapshot_recording_service.dart';
import 'package:handlebar/widgets/developer/developer_menu.dart';

import '../../network/request_handler.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onEnvChanged;
  final VoidCallback onLogoutPressed;
  final BuildContext parentContext;
  final UiSnapshotRecordingService recordingService;

  const HomeAppBar(
      {super.key,
      required this.onLogoutPressed,
      required this.onEnvChanged,
      required this.parentContext,
      required this.recordingService});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onLongPress: () => DeveloperMenu.show(
            parentContext: parentContext,
            onEnvChangeInParent: onEnvChanged,
            recordingService: recordingService),
        child: const Text('Handlebar'),
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        // API environment indicator
        _StatusIndicator(
            type: RequestHandler.currentEnvironment == 'Production'
                ? _IndicatorType.production
                : _IndicatorType.staging),

        // Recording indicator
        _StatusIndicator(
            type: _IndicatorType.recording, recordingService: recordingService),

        IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogoutPressed,
            tooltip: 'Logout')
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

enum _IndicatorType { production, staging, recording }

class _StatusIndicator extends StatelessWidget {
  final _IndicatorType type;
  final UiSnapshotRecordingService? recordingService;

  const _StatusIndicator({required this.type, this.recordingService})
      : assert(type != _IndicatorType.recording || recordingService != null,
            "recordingService must be provided when indicator type is 'recording'");

  Widget _buildEnvironmentIndicator(BuildContext context) {
    String text;
    Color backgroundColor;

    switch (type) {
      case _IndicatorType.production:
        text = 'PROD';
        backgroundColor = Colors.green;
        break;
      case _IndicatorType.staging:
        text = 'STAGE';
        backgroundColor = Colors.orange;
        break;
      default:
        throw ArgumentError('Unhandled indicator type: $type');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(BuildContext context) {
    return StreamBuilder(
        stream: recordingService!.recordingStateStream,
        initialData: recordingService!.isRecording,
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
        });
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _IndicatorType.production:
      case _IndicatorType.staging:
        return _buildEnvironmentIndicator(context);
      case _IndicatorType.recording:
        return _buildRecordingIndicator(context);
    }
  }
}
