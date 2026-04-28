import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/features/crepe/models/snapshot.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/shared_services/notification_service.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/data_field.dart';
import '../../../crepe/models/snapshot_entity_queries.dart';
import '../view_models/video_session_view_model.dart';
import '../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../../../core/shared_widgets/buttons/handlebar_icon_button.dart';
import '../../../../core/shared_widgets/handlebar_old_app_bar.dart';
import '../../../../core/shared_widgets/buttons/handlebar_segment_group.dart';
import '../../../../core/shared_widgets/scaffolds/static_responsive_scaffold.dart';
import '../widgets/select_query_bottom_sheet.dart';
import '../widgets/snapshot_field_list.dart';
import '../widgets/snapshot_overlay.dart';

/// Top-level widget for the Researcher Settings screen

/// Main stateful widget for the Researcher Settings screen that builds the UI
class ResearcherSettings extends StatefulWidget {
  const ResearcherSettings({super.key});

  @override
  State<ResearcherSettings> createState() => _ResearcherSettingsState();
}

class _ResearcherSettingsState extends State<ResearcherSettings> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
  }

  static final _videoPlayerWidth = Spacing.token288;
  static final _exitIconWidth = Spacing.token32;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();

    // Listen for any errors encountered in the viewmodel
    final errorListener = ValueListenableBuilder<String?>(
        valueListenable: vm.errorMessage,
        builder: (_, msg, __) {
          if (msg != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService().showError(msg);
            });
          }
          return const SizedBox.shrink();
        });

    final placeholderChild = SizedBox(
      width: Spacing.token288,
      child: _UploadPlaceholder(
          onScreenRecordingUpload: () => vm.loadFilesAndInitializeSession()),
    );

    final loadingChild = SizedBox(
      width: _videoPlayerWidth,
      child: const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    // The video player, exit button, and playback controls
    final videoChild = ValueListenableBuilder<bool>(
      valueListenable: vm.isInitialized,
      builder: (context, isInitialized, _) {
        if (!isInitialized) return placeholderChild;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _videoPlayerWidth,
              child: Stack(
                children: [
                  // Video player
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _videoPlayerWidth,
                      child: const _VideoPlayerContainer(),
                    ),
                  ),
                  // Exit button
                  Align(
                      alignment: Alignment.topRight,
                      child: Transform.translate(
                        offset: Offset(_exitIconWidth / 2, -_exitIconWidth / 2),
                        child: HandlebarIconButton(
                            icon: Icons.close_rounded,
                            iconSize: _exitIconWidth,
                            onPressed: vm.unloadVideoSession),
                      ))
                ],
              ),
            ),
            // Playback controls
            Spacing.vSpace16,
            SizedBox(
              width: context.scaled(Spacing.token352),
              child: _VideoPlaybackControls(),
            ),

            Spacing.vSpace16,
            const Divider(),
            Spacing.vSpace16,

            // Session collectors
            SizedBox(
              width: context.scaled(Spacing.token352),
              child: const _CreatedCollectorsList(),
            ),

            Spacing.vSpace16,

            SizedBox(
              width: context.scaled(Spacing.token352),
              child: const _LiveTestSessionControl(),
            ),
          ],
        );
      },
    );

    // Main body for the container
    final body = ValueListenableBuilder<bool>(
        valueListenable: vm.isLoading,
        builder: (context, isLoading, _) {
          return Column(
            children: [
              SizedBox(
                  width: context.scaled(Spacing.token352),
                  child: HandlebarSegmentGroup(
                    index: _selectedTab,
                    tabs: const ["View Recording", "Set Up Collectors"],
                    onPressed: (i) => setState(() {
                      _selectedTab = i;
                    }),
                    minHeight: Spacing.token56,
                  )),
              Spacing.vSpace24,
              if (_selectedTab == 0)
                if (isLoading) loadingChild else videoChild
              else
                const Text("Collector setup coming soon..."),
            ],
          );
        });
    return Stack(
      children: [
        StaticResponsiveScaffold(
          appBar: HandlebarOldAppBar(
            title: "Researcher Settings",
            onReturn: () => context.pop(),
          ),
          child: Column(
            children: [body, errorListener],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: vm.isCrepeQueryLoading,
          builder: (context, isCrepeQueryLoading, _) {
            if (!isCrepeQueryLoading) return const SizedBox.shrink();

            return Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withAlpha(125),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A placeholder widget shown when no video has loaded yet
class _UploadPlaceholder extends StatelessWidget {
  final VoidCallback onScreenRecordingUpload;

  const _UploadPlaceholder({required this.onScreenRecordingUpload});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HandlebarOldButton(
              text: "Upload Screen Recording",
              variant: ButtonVariant.primary,
              isLoading: false,
              onPressed: onScreenRecordingUpload,
              prefixIcon: const Icon(Icons.drive_folder_upload_outlined,
                  size: Spacing.token32),
            ),
            Spacing.hSpace16,
            HandlebarIconButton(
              icon: Icons.info_outline_rounded,
              iconSize: Spacing.token32,
              dialogText:
                  "Upload an MP4 file generated by Handlebar’s built-in recorder. The recording will be analyzed to identify "
                  "UI elements for data collection.",
            ),
          ],
        ),
      ],
    );
  }
}

/// A simple container widget that groups the video player and collector overlay
class _VideoPlayerContainer extends StatelessWidget {
  const _VideoPlayerContainer();

  double determinePortraitAspectRatio(double originalAspectRatio) {
    return originalAspectRatio > 1.0
        ? 1 / originalAspectRatio
        : originalAspectRatio;
  }

  Future<void> _handleEntityTap(BuildContext context,
      List<Map<String, dynamic>> hitEntities, Snapshot snapshot) async {
    final vm = context.read<VideoSessionViewModel>();

    // Ask WHAT to capture (semantic intent)
    final datafieldDescription = await _showDescriptionDialog(context);
    if (datafieldDescription == null ||
        datafieldDescription.isEmpty ||
        !context.mounted) {
      return;
    }

    final List<SnapshotEntityQueries> queryGroups = await vm
        .getQueriesForEntities(snapshot, hitEntities, datafieldDescription);

    if (queryGroups.isEmpty || !context.mounted) return;

    // User selects query
    final String? selectedQuery = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SelectQueryBottomSheet(queryGroups: queryGroups));

    if (selectedQuery == null || !context.mounted) return;

    // Ask for field name (NEW)
    final fieldName = await _showFieldNameDialog(context);
    if (fieldName == null || fieldName.isEmpty || !context.mounted) return;

    // Save
    vm.addDataField(snapshot, selectedQuery, fieldName);

    /// Maybe here we take them to the setup collectors page?
    NotificationService().showSuccess(
        "Data field stored for snapshot [CURR_SNAPSHOT_INDEX]. Use it to create a collector!");
  }

  Future<String?> _showDescriptionDialog(BuildContext context) {
    final TextEditingController descCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Describe what you are trying to capture'),
        content: TextField(
          controller: descCtrl,
          decoration: const InputDecoration(labelText: 'Description...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(descCtrl.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showFieldNameDialog(BuildContext context) {
    final TextEditingController descCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this Datafield'),
        content: TextField(
          controller: descCtrl,
          decoration: const InputDecoration(labelText: 'Short name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(descCtrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();
    final controller = vm.videoController!;

    final displayAspectRatio =
        determinePortraitAspectRatio(controller.value.aspectRatio);

    return AspectRatio(
        aspectRatio: displayAspectRatio,
        child: Container(
            color: Colors.black,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final videoSize = controller.value.size;
                final containerSize =
                    Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(alignment: Alignment.center, children: [
                  // Video player
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: videoSize.width,
                      height: videoSize.height,
                      child: VideoPlayer(controller),
                    ),
                  ),

                  // Overlay
                  SizedBox(
                    width: containerSize.width,
                    height: containerSize.height,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        vm.currSnapshotIndex,
                        vm.testResults,
                        vm.activeTestCollector,
                      ]),
                      builder: (context, _) {
                        // Extract the current values directly from the view model
                        final index = vm.currSnapshotIndex.value;
                        final snapshot = vm.snapshots[index];

                        final testResults = vm.testResults.value;
                        // We are testing if we have an active test collector
                        final isTesting = vm.activeTestCollector.value != null;

                        return SnapshotOverlay(
                          snapshot: snapshot,
                          videoSize: videoSize,
                          containerSize: containerSize,
                          originalDeviceSize: vm.deviceSize,
                          testResults: testResults,

                          // Disable tapping if we are testing!
                          onIntersectTap: isTesting
                              ? null
                              : (hitEntities) => _handleEntityTap(
                                  context, hitEntities, snapshot),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ValueListenableBuilder<int>(
                      valueListenable: vm.currSnapshotIndex,
                      builder: (context, index, _) {
                        return ValueListenableBuilder<
                            Map<int, List<DataField>>>(
                          valueListenable: vm.dataFields,
                          builder: (context, allFieldsMap, _) {
                            final fields = allFieldsMap[index] ?? [];

                            // TODO: confirm if we need this first check
                            if (index >= vm.snapshots.length) {
                              return const SizedBox.shrink();
                            }
                            if (fields.isEmpty) return const SizedBox.shrink();

                            return SnapshotFieldList(
                                snapshotIndex: index, fields: fields);
                          },
                        );
                      },
                    ),
                  ),
                ]);
              },
            )));
  }
}

/// A widget that groups all video control UI elements together, including
/// the timeline, time/snapshot info, and playback buttons
class _VideoPlaybackControls extends StatelessWidget {
  const _VideoPlaybackControls();

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();
    final controller = vm.videoController!;
    const double controlRowHeight = Spacing.token56;

    // Toggle between snapshot and smooth mode
    final modeToggleButton = ValueListenableBuilder<bool>(
      valueListenable: vm.isSnapshotMode,
      builder: (context, isSnapshotMode, _) {
        return InkWell(
          onTap: vm.toggleMode,
          borderRadius: BorderRadius.circular(Spacing.token8),
          child: Padding(
              padding: EdgeInsetsGeometry.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSnapshotMode
                        ? Icons.videocam_outlined
                        : Icons.phone_android_outlined,
                    size: Spacing.token24,
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        // Invisible text so both modes have same center
                        opacity: 0.0,
                        child: Text('Snapshot', style: context.bodySmall),
                      ),
                      Text(
                        isSnapshotMode ? 'Video' : 'Snapshot',
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                ],
              )),
        );
      },
    );

    // Snapshot counter and video progress timer
    final infoColumn = AnimatedBuilder(
        animation: Listenable.merge([vm.currSnapshotIndex, vm.playhead]),
        builder: (context, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.snapshots.isNotEmpty)
                  Text(
                    'Snapshot ${vm.currSnapshotIndex.value + 1} of ${vm.snapshots.length}',
                    style: context.bodySmall,
                  ),
                Text(
                  '${_formatDuration(vm.playhead.value)} / ${_formatDuration(controller.value.duration)}',
                  style: context.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.token16),
          child: SizedBox(
            height: controlRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text info
                Expanded(
                  child: infoColumn,
                ),

                // Toggle button
                Transform.translate(
                  offset: const Offset(0, -3),
                  child: modeToggleButton,
                ),
              ],
            ),
          ),
        ),
        Spacing.vSpace8,
        const _VideoTimelineSlider(),
        Spacing.vSpace8,
        const _PlaybackButtons(),
      ],
    );
  }
}

/// The interactive timeline widget with thumbnails responsible for
/// displaying playback progress and handling user scrubbing gestures
class _VideoTimelineSlider extends StatefulWidget {
  const _VideoTimelineSlider();
  @override
  State<_VideoTimelineSlider> createState() => _VideoTimelineSliderState();
}

class _VideoTimelineSliderState extends State<_VideoTimelineSlider>
    with SingleTickerProviderStateMixin {
  late final VideoSessionViewModel _vm;
  _TimelineScrollAnimator? _anim;

  static const double timelineHeight = 50.0;
  static const borderWidth = 1.6;

  @override
  void initState() {
    super.initState();
    _vm = context.read<VideoSessionViewModel>();
    _anim = _TimelineScrollAnimator(
      vsync: this,
      scrollController: _vm.timelineScrollController,
    );
  }

  @override
  void dispose() {
    _anim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _vm.videoController!;

    final videoDurationSecs = controller.value.duration.inMilliseconds / 1000.0;
    if (videoDurationSecs <= 0) {
      // No timeline for zero-second duration video
      return const SizedBox(height: timelineHeight);
    }

    // Store constants for timeline from the viewmodel
    final intervalSeconds = VideoSessionViewModel.intervalSeconds;
    final thumbnailWidth = VideoSessionViewModel.thumbnailWidth;
    final pixelsPerSecond = VideoSessionViewModel.pixelsPerSecond;
    final int numberOfThumbnails = (videoDurationSecs / intervalSeconds).ceil();

    // Handle edge case where last thumbnail must be cut off due to shorter video length
    double lastThumbnailDurationSecs = videoDurationSecs % intervalSeconds;
    if (lastThumbnailDurationSecs == 0.0) {
      lastThumbnailDurationSecs = intervalSeconds.toDouble();
    }
    final double lastThumbnailWidth =
        lastThumbnailDurationSecs * pixelsPerSecond;
    final double totalContentWidth =
        (numberOfThumbnails - 1) * thumbnailWidth + lastThumbnailWidth;

    return LayoutBuilder(builder: (context, constraints) {
      final double viewportWidth = constraints.maxWidth;
      final double horizontalPadding = viewportWidth / 2;
      final borderSide =
          BorderSide(color: context.colorScheme.onSurface, width: borderWidth);

      final timeline = ListView.builder(
        controller: _vm.timelineScrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: numberOfThumbnails + 2,
        itemBuilder: (context, index) {
          if (index == 0 || index == numberOfThumbnails + 1) {
            // Render padding at the start and end of the list
            return SizedBox(width: horizontalPadding);
          }

          final thumbIndex = index - 1;
          final bool isLast = thumbIndex == numberOfThumbnails - 1;

          // Last thumbnail needs dynamic width for it to not be longer than video
          final double currentWidth =
              isLast ? lastThumbnailWidth : thumbnailWidth;
          final time =
              Duration(seconds: (thumbIndex * intervalSeconds).round());

          return Container(
            width: currentWidth,
            height: timelineHeight,
            decoration: BoxDecoration(
              border: Border(
                top: borderSide,
                bottom: borderSide,
                left: thumbIndex == 0 ? borderSide : BorderSide.none,
                right: isLast ? borderSide : BorderSide.none,
              ),
            ),
            child: _ThumbnailImage(time: time),
          );
        },
      );

      return ValueListenableBuilder<Duration>(
        valueListenable: _vm.playhead,
        builder: (context, playheadDuration, child) {
          // Canonical playhead dictates how to move the slider
          final isScrubbing = _vm.isUserScrubbing.value;

          if (isScrubbing) {
            _anim!.cancel();
            return child!;
          }

          final targetContentPx =
              (playheadDuration.inMilliseconds / 1000.0) * pixelsPerSecond;
          final targetScrollPx = targetContentPx.clamp(0.0, totalContentWidth);

          _anim!.animateTo(
            targetScrollPx,
            duration: const Duration(milliseconds: 200),
            curve: _vm.isSnapshotMode.value ? Curves.easeOut : Curves.linear,
          );

          return child!;
        },
        child: SizedBox(
          height: timelineHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              // User dictates how to move the slider, playhead updates
              // itself during scroll
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _anim!.cancel();
                _vm.onTimelineScrollStart();
              } else if (n is ScrollEndNotification) {
                _vm.onTimelineScrollEnd(n.metrics.pixels);
              }
              return false;
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                timeline,
                // Snapshot position markers
                if (_vm.snapshots.isNotEmpty)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _vm.timelineScrollController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(viewportWidth, timelineHeight),
                          painter: _SnapshotMarkerPainter(
                            snapshots: _vm.snapshots,
                            scrollOffset:
                                _vm.timelineScrollController.hasClients
                                    ? _vm.timelineScrollController.offset
                                    : 0.0,
                            viewportWidth: viewportWidth,
                            pixelsPerSecond: pixelsPerSecond,
                            timelineHeight: timelineHeight,
                          ),
                        );
                      },
                    ),
                  ),
                // Playhead vertical line
                Container(
                    width: 3, height: timelineHeight, color: Colors.redAccent),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Animator for a [ScrollController] to provide finer control over jump animations
class _TimelineScrollAnimator {
  final ScrollController scrollController;

  _TimelineScrollAnimator({
    required TickerProvider vsync,
    required this.scrollController,
  }) : _animationController = AnimationController(vsync: vsync);

  final AnimationController _animationController;
  Animation<double>? _animation;

  // Smoothly scroll to the target time, cancelling any in-flight animations
  void animateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 120),
    Curve curve = Curves.linear,
    double epsilon = 1.0,
  }) {
    if (!scrollController.hasClients) return;

    final start = scrollController.offset;
    if ((target - start).abs() < epsilon) return;

    // Restart the animation with new parameters
    _animationController.stop();
    _animationController.duration = duration;

    _animation = Tween<double>(begin: start, end: target)
        .animate(CurvedAnimation(parent: _animationController, curve: curve));
    _animation!.addListener(() {
      if (scrollController.hasClients) {
        scrollController.jumpTo(_animation!.value);
      }
    });

    // Start animation
    _animationController.forward(from: 0);
  }

  void cancel() => _animationController.stop();

  void dispose() => _animationController.dispose();
}

/// Paints thin vertical lines on the timeline at each snapshot's position
class _SnapshotMarkerPainter extends CustomPainter {
  final List<Snapshot> snapshots;
  final double scrollOffset;
  final double viewportWidth;
  final double pixelsPerSecond;
  final double timelineHeight;

  _SnapshotMarkerPainter({
    required this.snapshots,
    required this.scrollOffset,
    required this.viewportWidth,
    required this.pixelsPerSecond,
    required this.timelineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 1.5;

    final centerX = viewportWidth / 2;

    for (final snapshot in snapshots) {
      final snapshotTimeSecs = snapshot.videoTimestamp.inMilliseconds / 1000.0;
      final contentPx = snapshotTimeSecs * pixelsPerSecond;
      // Position relative to viewport: content position minus scroll offset,
      // shifted so that scroll offset 0 aligns with the center (the playhead)
      final screenX = contentPx - scrollOffset + centerX;

      // Only paint if visible
      if (screenX >= 0 && screenX <= viewportWidth) {
        canvas.drawLine(
          Offset(screenX, 0),
          Offset(screenX, timelineHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnapshotMarkerPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.snapshots != snapshots;
  }
}

/// The widget for displaying a single thumbnail image in the timeline
class _ThumbnailImage extends StatelessWidget {
  final Duration time;
  const _ThumbnailImage({required this.time});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();

    return FutureBuilder<Uint8List?>(
      future: vm.getThumbnailForTimestamp(time),
      builder: (context, thumbnail) {
        if (thumbnail.hasData && thumbnail.data != null) {
          // Our specific thumbnail exists, display it
          return Image.memory(
            thumbnail.data!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          );
        }
        // Thumbnail does not yet exist, show a placeholder
        return Container(color: Colors.grey.shade800);
      },
    );
  }
}

/// Renders the main playback buttons (play/pause, seek) and
/// dynamically switches between controls for snapshot and smooth mode
class _PlaybackButtons extends StatelessWidget {
  const _PlaybackButtons();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();
    final colorScheme = context.colorScheme;

    Widget createIconButton(Icon icon, VoidCallback? onPressed,
        {double iconSize = Spacing.token40}) {
      return IconButton(
        icon: icon,
        onPressed: onPressed,
        color: colorScheme.onSurface,
        iconSize: iconSize,
      );
    }

    final playPauseButton = ValueListenableBuilder<bool>(
      valueListenable: vm.isPlaying,
      builder: (context, isPlaying, _) {
        return createIconButton(
          Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
          vm.togglePlayPause,
        );
      },
    );

    return ValueListenableBuilder<bool>(
      valueListenable: vm.isSnapshotMode,
      builder: (context, isSnapshotMode, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: vm.isSnapshotMode.value
                  ? [
                      // Snapshot mode buttons
                      createIconButton(
                        const Icon(Icons.fast_rewind),
                        () => vm.seekBySnapshots(-5),
                      ),
                      createIconButton(
                        const Icon(Icons.skip_previous),
                        () => vm.seekBySnapshots(-1),
                      ),
                      playPauseButton,
                      createIconButton(
                        const Icon(Icons.skip_next),
                        () => vm.seekBySnapshots(1),
                      ),
                      createIconButton(
                        const Icon(Icons.fast_forward),
                        () => vm.seekBySnapshots(5),
                      ),
                    ]
                  : [
                      // Smooth mode buttons
                      createIconButton(
                        const Icon(Icons.replay_30),
                        () => vm.seekBySmooth(const Duration(seconds: -30)),
                      ),
                      createIconButton(
                        const Icon(Icons.replay_5),
                        () => vm.seekBySmooth(const Duration(seconds: -5)),
                      ),
                      playPauseButton,
                      createIconButton(
                        const Icon(Icons.forward_5),
                        () => vm.seekBySmooth(const Duration(seconds: 5)),
                      ),
                      createIconButton(
                        const Icon(Icons.forward_30),
                        () => vm.seekBySmooth(const Duration(seconds: 30)),
                      ),
                    ],
            ),
          ],
        );
      },
    );
  }
}

class _CreatedCollectorsList extends StatelessWidget {
  const _CreatedCollectorsList();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();

    return ValueListenableBuilder<List<Collector>>(
      valueListenable: vm.sessionCollectors,
      builder: (context, collectors, _) {
        if (collectors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(Spacing.token16),
            child: Text("No collectors created yet. Tap the UI to create one."),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.token16),
              child: Text("Created Collectors",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Spacing.vSpace8,
            // List out the collectors
            ...collectors.map((collector) {
              return ValueListenableBuilder<Collector?>(
                valueListenable: vm.activeTestCollector,
                builder: (context, activeCollector, _) {
                  // Check if this specific row is the one currently being tested
                  final isTestingThis =
                      activeCollector?.collectorId == collector.collectorId;

                  return ListTile(
                    title: Text(collector.appName),
                    subtitle: Text(
                        "${collector.dataFields.length} Data Fields • ${collector.description}"),
                    trailing: HandlebarOldButton(
                      text: isTestingThis ? "Stop Testing" : "Test",
                      variant: isTestingThis
                          ? ButtonVariant.destructive
                          : ButtonVariant.primary,
                      onPressed: () => vm.toggleRecordingTestMode(collector),
                      isLoading: false,
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class _LiveTestSessionControl extends StatelessWidget {
  const _LiveTestSessionControl();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<VideoSessionViewModel>();

    return ValueListenableBuilder<bool>(
      valueListenable: vm.isLiveTesting,
      builder: (context, isLiveTesting, _) {
        return Container(
          margin: const EdgeInsets.all(Spacing.token16),
          padding: const EdgeInsets.all(Spacing.token16),
          decoration: BoxDecoration(
            color: isLiveTesting
                ? context.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : context.theme.cardColor,
            borderRadius: BorderRadius.circular(Spacing.token16),
            border: Border.all(
              color: isLiveTesting
                  ? context.theme.colorScheme.primary
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isLiveTesting
                        ? Icons.sensors_rounded
                        : Icons.sensors_off_rounded,
                    color: isLiveTesting
                        ? context.colorScheme.primary
                        : Colors.grey,
                  ),
                  Spacing.hSpace8,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Live System Test",
                          style: context.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isLiveTesting
                              ? "Testing all session collectors live on device..."
                              : "Test all session collectors against live apps.",
                          style: context.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacing.vSpace16,
              HandlebarOldButton(
                text: isLiveTesting
                    ? "Stop Live Session"
                    : "Start Live Session Test",
                variant: isLiveTesting
                    ? ButtonVariant.destructive
                    : ButtonVariant.primary,
                onPressed: vm.toggleLiveTest,
                isLoading: false,
              ),
            ],
          ),
        );
      },
    );
  }
}
