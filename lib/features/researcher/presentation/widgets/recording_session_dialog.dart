import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../../crepe/services/ui_snapshot_recording_service.dart';

/// Full-screen dialog to capture a screen recording + UI snapshots for collector setup.
class RecordingSessionDialog extends StatefulWidget {
  const RecordingSessionDialog({super.key});

  @override
  State<RecordingSessionDialog> createState() => _RecordingSessionDialogState();
}

class _RecordingSessionDialogState extends State<RecordingSessionDialog> {
  final _recordingService = UiSnapshotRecordingService();
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return PopScope(
      canPop: !_recordingService.isRecording && !_isBusy,
      child: Dialog.fullscreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.token24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: (_recordingService.isRecording || _isBusy)
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        'Record screen session',
                        style: context.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Spacing.vSpace16,
                Text(
                  'Open the app you want to study, then start recording. '
                  'Navigate the screens you care about, then stop when finished.',
                  style: context.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!Platform.isAndroid) ...[
                  Spacing.vSpace16,
                  Text(
                    'Recording requires Android.',
                    style: context.bodyMedium?.copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                StreamBuilder<bool>(
                  stream: _recordingService.recordingStateStream,
                  initialData: _recordingService.isRecording,
                  builder: (context, snapshot) {
                    final isRecording = snapshot.data ?? false;
                    return StreamBuilder<int>(
                      stream: _recordingService.snapshotCountStream,
                      initialData: _recordingService.snapshotCount,
                      builder: (context, countSnap) {
                        final count = countSnap.data ?? 0;
                        return Column(
                          children: [
                            if (isRecording)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: Spacing.token16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fiber_manual_record,
                                        color: scheme.error, size: 16),
                                    Spacing.hSpace8,
                                    Text(
                                      'Recording… $count snapshots',
                                      style: context.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            HandlebarOldButton(
                              text: isRecording
                                  ? 'Stop recording'
                                  : 'Start recording',
                              variant: isRecording
                                  ? ButtonVariant.destructive
                                  : ButtonVariant.primary,
                              isLoading: _isBusy,
                              prefixIcon: Icon(
                                isRecording
                                    ? Icons.stop_circle_outlined
                                    : Icons.fiber_manual_record,
                                size: Spacing.token24,
                                color: isRecording ? scheme.error : null,
                              ),
                              onPressed: (_isBusy || !Platform.isAndroid)
                                  ? null
                                  : () => isRecording
                                      ? _stopRecording(context)
                                      : _startRecording(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                Spacing.vSpace24,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() => _isBusy = true);
    final started = await _recordingService.startRecording();
    if (mounted) setState(() => _isBusy = false);
    if (!started && mounted) {
      NotificationService().showError(
        'Could not start recording. Enable the Handlebar accessibility service.',
      );
    }
  }

  Future<void> _stopRecording(BuildContext context) async {
    setState(() => _isBusy = true);
    final result = await _recordingService.stopRecording(
      persistToDownloads: true,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (result == null) return;

    if (!result.hasVideo) {
      NotificationService().showError(
        'Video was not captured. Try again or upload files manually.',
      );
      return;
    }

    Navigator.of(context).pop(result);
  }
}
