import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../view_models/collector_creation_view_model.dart';
import '../../widgets/snapshot_overlay.dart';
import '../../widgets/video_timeline_slider.dart';

/// Step 2 of the collector creation flow: pick a snapshot to define data
/// fields against. Stripped-down compared to the legacy researcher settings
/// view: no mode toggle, no timeline strip, no scrubbing — just sequential
/// snapshot navigation with prev/play/next buttons.
class SelectFrameStep extends StatelessWidget {
  const SelectFrameStep({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double _portraitAspectRatio(double original) {
    return original > 1.0 ? 1 / original : original;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CollectorCreationViewModel>();
    final session = vm.session;

    return ValueListenableBuilder<bool>(
      valueListenable: session.isInitialized,
      builder: (context, isInit, _) {
        if (!isInit || session.videoController == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final controller = session.videoController!;
        final aspectRatio = _portraitAspectRatio(controller.value.aspectRatio);

        return Padding(
          padding: const EdgeInsets.all(Spacing.token16),
          child: Column(
            children: [
              // Snapshot viewer (video frame + bounding boxes)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      color: Colors.black,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final videoSize = controller.value.size;
                          final containerSize = Size(
                              constraints.maxWidth, constraints.maxHeight);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: videoSize.width,
                                  height: videoSize.height,
                                  child: VideoPlayer(controller),
                                ),
                              ),
                              SizedBox(
                                width: containerSize.width,
                                height: containerSize.height,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: session.currSnapshotIndex,
                                  builder: (context, index, _) {
                                    if (index >= session.snapshots.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final snapshot = session.snapshots[index];
                                    return SnapshotOverlay(
                                      snapshot: snapshot,
                                      videoSize: videoSize,
                                      containerSize: containerSize,
                                      originalDeviceSize: session.deviceSize,
                                      // Non-interactive in this step.
                                      onIntersectTap: null,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Spacing.vSpace16,

              // Counter + timestamp
              AnimatedBuilder(
                animation: Listenable.merge(
                    [session.currSnapshotIndex, session.playhead]),
                builder: (context, _) {
                  final total = session.snapshots.length;
                  final idx = session.currSnapshotIndex.value;
                  return Column(
                    children: [
                      Text(
                        total == 0
                            ? 'No snapshots'
                            : 'Snapshot ${idx + 1} of $total',
                        style: context.bodyMedium,
                      ),
                      Text(
                        '${_formatDuration(session.playhead.value)} / '
                        '${_formatDuration(controller.value.duration)}',
                        style: context.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
              Spacing.vSpace8,

              // Scrubbable thumbnail timeline
              VideoTimelineSlider(session: session),
              Spacing.vSpace8,

              // Prev / play-pause / next
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: Spacing.token40,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => session.seekBySnapshots(-1),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: session.isPlaying,
                    builder: (context, isPlaying, _) => IconButton(
                      iconSize: Spacing.token48,
                      icon: Icon(isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled),
                      onPressed: session.togglePlayPause,
                    ),
                  ),
                  IconButton(
                    iconSize: Spacing.token40,
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => session.seekBySnapshots(1),
                  ),
                ],
              ),
              Spacing.vSpace16,

              // Select this frame
              SizedBox(
                width: double.infinity,
                child: HandlebarButton(
                  text: 'Select This Frame',
                  variant: ButtonVariant.primary,
                  isLoading: false,
                  prefixIcon: const Icon(Icons.check, size: Spacing.token24),
                  onPressed: () {
                    // currSnapshotIndex is already pointing at the chosen
                    // frame; advancing the stepper is enough.
                    vm.next();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
