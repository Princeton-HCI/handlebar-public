import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../crepe/models/snapshot.dart';
import '../view_models/video_session_view_model.dart';

/// Horizontal scrubbable timeline strip with thumbnails and snapshot markers.
///
/// Lifted from the original ResearcherSettings view so it can be reused by
/// the new collector creation stepper. The widget is driven by an injected
/// [VideoSessionViewModel] (instead of being read from the provider tree)
/// so callers can mount it under any provider arrangement.
class VideoTimelineSlider extends StatefulWidget {
  final VideoSessionViewModel session;

  const VideoTimelineSlider({super.key, required this.session});

  @override
  State<VideoTimelineSlider> createState() => _VideoTimelineSliderState();
}

class _VideoTimelineSliderState extends State<VideoTimelineSlider>
    with SingleTickerProviderStateMixin {
  _TimelineScrollAnimator? _anim;

  static const double timelineHeight = 50.0;
  static const borderWidth = 1.6;

  VideoSessionViewModel get _vm => widget.session;

  @override
  void initState() {
    super.initState();
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
      return const SizedBox(height: timelineHeight);
    }

    final intervalSeconds = VideoSessionViewModel.intervalSeconds;
    final thumbnailWidth = VideoSessionViewModel.thumbnailWidth;
    final pixelsPerSecond = VideoSessionViewModel.pixelsPerSecond;
    final int numberOfThumbnails = (videoDurationSecs / intervalSeconds).ceil();

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
            return SizedBox(width: horizontalPadding);
          }

          final thumbIndex = index - 1;
          final bool isLast = thumbIndex == numberOfThumbnails - 1;

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
            child: _ThumbnailImage(session: _vm, time: time),
          );
        },
      );

      return ValueListenableBuilder<Duration>(
        valueListenable: _vm.playhead,
        builder: (context, playheadDuration, child) {
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

class _TimelineScrollAnimator {
  final ScrollController scrollController;

  _TimelineScrollAnimator({
    required TickerProvider vsync,
    required this.scrollController,
  }) : _animationController = AnimationController(vsync: vsync);

  final AnimationController _animationController;
  Animation<double>? _animation;

  void animateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 120),
    Curve curve = Curves.linear,
    double epsilon = 1.0,
  }) {
    if (!scrollController.hasClients) return;

    final start = scrollController.offset;
    if ((target - start).abs() < epsilon) return;

    _animationController.stop();
    _animationController.duration = duration;

    _animation = Tween<double>(begin: start, end: target)
        .animate(CurvedAnimation(parent: _animationController, curve: curve));
    _animation!.addListener(() {
      if (scrollController.hasClients) {
        scrollController.jumpTo(_animation!.value);
      }
    });

    _animationController.forward(from: 0);
  }

  void cancel() => _animationController.stop();
  void dispose() => _animationController.dispose();
}

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
      final screenX = contentPx - scrollOffset + centerX;

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

class _ThumbnailImage extends StatelessWidget {
  final VideoSessionViewModel session;
  final Duration time;

  const _ThumbnailImage({required this.session, required this.time});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: session.getThumbnailForTimestamp(time),
      builder: (context, thumbnail) {
        if (thumbnail.hasData && thumbnail.data != null) {
          return Image.memory(
            thumbnail.data!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          );
        }
        return Container(color: Colors.grey.shade800);
      },
    );
  }
}
