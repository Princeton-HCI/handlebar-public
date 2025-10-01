import 'package:flutter/material.dart';

class PlaybackControls extends StatefulWidget {
  final int currentIndex;
  final int totalSnapshots;
  final bool isPlaying;
  final Function(int) onSeek;
  final VoidCallback onPlayPause;
  final Function(bool) onToggleView;
  final bool showVideoToggle;
  final int? startTimestamp;
  final int? endTimestamp;
  final int? currentTimestamp;

  const PlaybackControls({
    Key? key,
    required this.currentIndex,
    required this.totalSnapshots,
    required this.isPlaying,
    required this.onSeek,
    required this.onPlayPause,
    required this.onToggleView,
    this.showVideoToggle = false,
    this.startTimestamp,
    this.endTimestamp,
    this.currentTimestamp,
  }) : super(key: key);

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  bool _isSnapshotView = true;

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '00:00';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTime(int? start, int? current) {
    if (start == null || current == null) return '00:00';
    final elapsed = current - start;
    return _formatDuration(elapsed);
  }

  String _getTotalDuration() {
    if (widget.startTimestamp == null || widget.endTimestamp == null) {
      return _formatDuration(widget.totalSnapshots * 1000);
    }
    return _formatDuration(widget.endTimestamp! - widget.startTimestamp!);
  }

  double _getSliderValue() {
    if (widget.totalSnapshots == 0) return 0.0;
    return widget.currentIndex /
        (widget.totalSnapshots - 1).clamp(1, widget.totalSnapshots);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar and time
              Row(
                children: [
                  Text(
                    _formatTime(widget.startTimestamp, widget.currentTimestamp),
                    style: theme.textTheme.bodySmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: _getSliderValue(),
                      onChanged: (value) {
                        if (widget.totalSnapshots > 0) {
                          final newIndex =
                              (value * (widget.totalSnapshots - 1)).round();
                          widget.onSeek(newIndex);
                        }
                      },
                      activeColor: colorScheme.primary,
                      inactiveColor:
                          colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  Text(
                    _getTotalDuration(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous snapshot
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: widget.currentIndex > 0
                        ? () => widget.onSeek(widget.currentIndex - 1)
                        : null,
                    iconSize: 32,
                  ),
                  // Play/Pause button
                  IconButton(
                    icon: Icon(
                      widget.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: widget.onPlayPause,
                    iconSize: 48,
                    color: colorScheme.primary,
                  ),
                  // Next snapshot
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: widget.currentIndex < widget.totalSnapshots - 1
                        ? () => widget.onSeek(widget.currentIndex + 1)
                        : null,
                    iconSize: 32,
                  ),
                ],
              ),
              // View toggle (prepared for future video integration)
              if (widget.showVideoToggle)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('UI Snapshot'),
                        icon: Icon(Icons.phone_android),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Screen Video'),
                        icon: Icon(Icons.videocam),
                        enabled: false, // Disabled for now
                      ),
                    ],
                    selected: {_isSnapshotView},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _isSnapshotView = selection.first;
                      });
                      widget.onToggleView(_isSnapshotView);
                    },
                  ),
                ),
              // Snapshot indicator
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Snapshot ${widget.currentIndex + 1} of ${widget.totalSnapshots}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
