import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:handlebar/features/crepe/models/snapshot_entity_queries.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';

import '../../../crepe/data/snapshot_repository.dart';
import '../../../crepe/models/data_field.dart';
import '../../data/video_thumbnail_repository.dart';
import '../../../crepe/models/snapshot.dart';

enum Owner { video, timer, idle, user }

class VideoSessionViewModel extends ChangeNotifier {
  static final _logger = Logger('VideoSessionViewModel');

  // ================
  // State variables
  // ================

  // ---- Public UI flags ----
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isUserScrubbing = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // ---- Public playback state ----
  final ValueNotifier<Duration> playhead = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> isSnapshotMode = ValueNotifier(false);
  final ValueNotifier<int> currSnapshotIndex = ValueNotifier(0);

  // ---- Public getters ----
  VideoPlayerController? get videoController => _videoController;
  ScrollController get timelineScrollController => _timelineScrollController;

  // ---- Public collector state ----
  final ValueNotifier<bool> isCrepeQueryLoading = ValueNotifier(false);

  // ---- Public constants ----
  static const double intervalSeconds = 2;
  static const double thumbnailWidth = 80.0;
  static const int windowSize = 30;
  static double get pixelsPerSecond => thumbnailWidth / intervalSeconds;

  // ---- Private controllers ----
  final ScrollController _timelineScrollController = ScrollController();
  VideoPlayerController? _videoController;

  // ---- Private playback state  ----
  Owner _owner = Owner.idle; // Who has permission to control the playhead
  int _epoch = 0; // Version # to prevent old async tasks from running

  Timer? _snapshotPlaybackTimer;

  bool _wasPlayingBeforeScrub = false;
  int? _scrubEpoch;
  Timer? _scrubDebounce;

  // ---- Private collector state ----
  List<Snapshot> snapshots = []; // List of all loaded video snapshots
  final Map<int, List<DataField>> _dataFieldsForSnapshot = {};

  // ---- Private repositories ----
  final SnapshotRepository _snapshotRepo = SnapshotRepository();
  VideoThumbnailRepository? _thumbnailRepo;

  // ---- Private thumbnail pre-fetching state  ----
  Timer? _prefetchThrottle;
  bool _isPrefetchRunning = false;
  int? _prefetchStart;
  int? _prefetchEnd;

  // ================
  // Lifecycle methods
  // ================

  @override
  void dispose() {
    unloadVideoSession();
    super.dispose();
  }

  // ================
  // Session methods
  // ================

  /// Initializes a session by loading snapshots from a ZIP and the associated video.
  Future<void> loadFilesAndInitializeSession() async {
    isLoading.value = true;
    isInitialized.value = false;
    errorMessage.value = null;

    try {
      _logger.info('Starting a new video session load');

      // Prompt for the snapshots ZIP file
      final zipResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['zip']);
      if (zipResult == null || zipResult.files.single.path == null) {
        _logger.warning('User did not submit a ZIP file');
        isLoading.value = false;
        return;
      }

      final zipFile = File(zipResult.files.single.path!);
      snapshots = await _snapshotRepo.loadSnapshotsFromZip(zipFile);

      // Prompt for the accompanying video file
      final videoResult =
          await FilePicker.platform.pickFiles(type: FileType.video);
      if (videoResult == null || videoResult.files.single.path == null) {
        _logger.warning('User did not submit a video file');
        isLoading.value = false;
        return;
      }

      final videoFile = File(videoResult.files.single.path!);
      await _initialize(videoFile);
    } on SnapshotLoadException catch (e, st) {
      _logger.severe('Failed to load snapshots: ${e.message}', e, st);
      errorMessage.value = e.message;
    } catch (e, st) {
      _logger.severe('Unexpected error while loading session $st', e, st);
      errorMessage.value = 'Something went wrong while loading the video.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Initializes a session by loading a video and creating placeholder snapshots
  Future<void> loadVideoAndInitializeSession() async {
    isLoading.value = true;
    isInitialized.value = false;
    errorMessage.value = null;

    try {
      final videoResult =
          await FilePicker.platform.pickFiles(type: FileType.video);
      if (videoResult == null || videoResult.files.single.path == null) {
        _logger.warning('User did not submit a video file');
        isLoading.value = false;
        return;
      }

      final videoFile = File(videoResult.files.single.path!);
      await _initialize(videoFile);

      final totalSeconds = _videoController!.value.duration.inSeconds;
      snapshots = List.generate(totalSeconds, (i) {
        return Snapshot(
          originalTimestamp: i * 1000,
          videoTimestamp: Duration(seconds: i),
          metadata: {},
          allEntities: [],
          nodeEntities: [],
          triples: [],
          boundingBoxes: [],
        );
      });
    } catch (e, st) {
      _logger.severe('Unexpected error while loading session', e, st);
      errorMessage.value = 'Something went wrong while loading the video.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper to set up all controllers and default states for a new video
  Future<void> _initialize(File videoFile) async {
    await _videoController?.dispose();
    _thumbnailRepo?.dispose();
    _setOwner(Owner.idle);

    // Initialize video controller
    _logger.info('Initializing video controller from file: ${videoFile.path}');
    final vc = VideoPlayerController.file(videoFile);
    await vc.initialize();
    _videoController = vc;
    _videoController!.addListener(_onVideoUpdate);
    _logger.info('Video controller initialization successful');

    // Initialize thumbnail repository
    _logger
        .info('Initializing thumbnail repository from file: ${videoFile.path}');
    _thumbnailRepo = VideoThumbnailRepository(videoFile);
    _logger.info('Thumbnail repository initialization successful');

    await _prefetchInitialThumbnails();

    _timelineScrollController.addListener(_onScrollUpdate);

    // Set defaults
    currSnapshotIndex.value = 0;
    isPlaying.value = false;
    isSnapshotMode.value = true;
    playhead.value = Duration.zero;

    isInitialized.value = true;
    _logger.info('Session initialization successful');
  }

  /// Cleans up all video-related resources and resets the view model to its initial state
  Future<void> unloadVideoSession() async {
    // Stop all timers
    _stopSnapshotTimer();
    _scrubDebounce?.cancel();
    _prefetchThrottle?.cancel();

    // Reset repos and controllers
    _thumbnailRepo?.dispose();
    _thumbnailRepo = null;
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoUpdate);
      await _videoController!.dispose();
      _videoController = null;
    }

    _timelineScrollController.removeListener(_onScrollUpdate);
    if (_timelineScrollController.hasClients) {
      _timelineScrollController.jumpTo(0);
    }

    // Clear all data collections
    snapshots = [];

    // Reset all public UI state
    isInitialized.value = false;
    isPlaying.value = false;
    isSnapshotMode.value = true;
    isUserScrubbing.value = false;
    currSnapshotIndex.value = 0;
    playhead.value = Duration.zero;
    errorMessage.value = null;
    isLoading.value = false;

    // Reset all private internal state
    _owner = Owner.idle;
    _epoch = 0;
    _wasPlayingBeforeScrub = false;
    _scrubEpoch = null;
    _isPrefetchRunning = false;
    _prefetchStart = null;
    _prefetchEnd = null;
  }

  // ================
  // Playback methods
  // ================

  /// Toggles the player between smooth playback and discrete snapshot mode
  Future<void> toggleMode() async {
    final wasPlaying = isPlaying.value;
    final nextIsSnapshot = !isSnapshotMode.value;

    // Always pause the current transport before making changes
    if (isSnapshotMode.value) {
      _stopSnapshotTimer();
    } else {
      await _pauseSmooth();
    }
    _setOwner(Owner.idle);

    Duration target = playhead.value;
    if (nextIsSnapshot && snapshots.isNotEmpty) {
      // When entering snapshot mode, snap to latest snapshot
      final idx = _findSnapshotIndexForPosition(playhead.value);
      currSnapshotIndex.value = idx;
      target = snapshots[idx].videoTimestamp;
      _writePlayhead(target, Owner.idle);
    }

    // Invalidate old async work from previous mode if necessary
    final e = _bumpEpoch();
    isSnapshotMode.value = nextIsSnapshot;
    await _seekRendererTo(target, e);

    if (nextIsSnapshot) {
      // Snapshot mode always begins in a paused state
      isPlaying.value = false;
      _setOwner(Owner.idle);
    } else {
      // Smooth mode restores the previous playing state
      isPlaying.value = wasPlaying;
      if (wasPlaying) {
        _setOwner(Owner.video);
        await _playSmooth();
      } else {
        _setOwner(Owner.idle);
      }
    }
  }

  /// Listener for [videoController] that fires continuously while the video is playing
  void _onVideoUpdate() {
    if (!isSnapshotMode.value &&
        _canWrite(Owner.video) &&
        !isUserScrubbing.value &&
        isInitialized.value &&
        _videoReady) {
      final vc = _videoController!.value;
      _writePlayhead(vc.position, Owner.video);

      // Handle video reaching its end naturally
      final dur = vc.duration;
      if (dur > Duration.zero && vc.position >= dur) {
        if (isPlaying.value) {
          isPlaying.value = false;
          _setOwner(Owner.idle);
        }
      }
    }

    if (isInitialized.value &&
        !isSnapshotMode.value &&
        !isUserScrubbing.value) {
      // Prefetch on any video update in smooth mode, even when paused
      _updateThumbnailCacheWindow();
    }
  }

  /// Toggles the play/pause state based on the current mode
  Future<void> togglePlayPause() async {
    if (isSnapshotMode.value) {
      // In snapshot mode the timer controls playback
      if (isPlaying.value) {
        // From playing to paused
        _stopSnapshotTimer();
        _setOwner(Owner.idle);
        isPlaying.value = false;
        _bumpEpoch();
      } else {
        // From paused to playing
        _setOwner(Owner.timer);
        _startSnapshotTimer(_epoch);
        isPlaying.value = true;
      }
    } else {
      // In smooth mode the video controller listener controls playback
      if (isPlaying.value) {
        // From playing to paused
        await _pauseSmooth();
        _setOwner(Owner.idle);
        isPlaying.value = false;
        _bumpEpoch();
      } else {
        // From paused to playing
        _setOwner(Owner.video);
        await _playSmooth();
        isPlaying.value = true;
      }
    }
  }

  /// Helper to start smooth video playback via the controller
  Future<void> _playSmooth() async {
    if (_videoReady) await _videoController!.play();
  }

  /// Helper to pause smooth video playback via the controller
  Future<void> _pauseSmooth() async {
    if (_videoReady) await _videoController!.pause();
  }

  /// Starts the snapshot playback timer that drives video playback in snapshot mode
  void _startSnapshotTimer(int epoch) {
    _stopSnapshotTimer();
    _snapshotPlaybackTimer =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      // Check epoch and ownership to prevent stale updates
      if (epoch != _epoch || !_canWrite(Owner.timer) || snapshots.isEmpty) {
        return;
      }

      // Advance to the next snapshot
      final nextSnapshot =
          (currSnapshotIndex.value + 1).clamp(0, snapshots.length - 1);
      final nextSnapshotPosition = snapshots[nextSnapshot].videoTimestamp;
      _writePlayhead(nextSnapshotPosition, Owner.timer);
      await _seekRendererTo(nextSnapshotPosition, epoch);

      _updateThumbnailCacheWindow();

      if (nextSnapshot == snapshots.length - 1) {
        // Stop playback when we reach the final snapshot
        _stopSnapshotTimer();
        _setOwner(Owner.idle);
        isPlaying.value = false;
      }
    });
  }

  /// Cancels the snapshot playback timer
  void _stopSnapshotTimer() {
    _snapshotPlaybackTimer?.cancel();
    _snapshotPlaybackTimer = null;
  }

  // ================
  // Seek methods
  // ================

  /// Seeks forward or backward by a given [offset] in smooth mode
  Future<void> seekBySmooth(Duration offset) async {
    if (!_videoReady || isSnapshotMode.value) return;

    final target = playhead.value + offset;
    // Owner performing seeking depends on if the video was already playing
    final by = isPlaying.value ? Owner.video : Owner.idle;
    await _seekTo(target, by);
  }

  /// Seeks forward or backward by a given snapshot [count] in snapshot mode
  Future<void> seekBySnapshots(int count) async {
    if (!_videoReady || snapshots.isEmpty || !isSnapshotMode.value) return;

    final nextSnapshot =
        (currSnapshotIndex.value + count).clamp(0, snapshots.length - 1);
    final target = snapshots[nextSnapshot].videoTimestamp;
    // Owner performing seeking depends on if the video was already playing
    final by = isPlaying.value ? Owner.timer : Owner.idle;

    await _seekTo(target, by);
  }

  /// Helper that executes a seek to a specific time
  Future<void> _seekTo(Duration target, Owner by) async {
    final clampedTarget = _clampToDuration(target);

    // Update playhead immediately and render new video frame
    _writePlayhead(clampedTarget, by);
    await _seekRendererTo(clampedTarget, _epoch);

    if (!isUserScrubbing.value) _updateThumbnailCacheWindow();
  }

  // ==============
  // Timeline methods
  // ==============

  /// Callback method for when the user start dragging the timeline
  void onTimelineScrollStart() {
    _scrubDebounce?.cancel();
    _wasPlayingBeforeScrub = isPlaying.value;
    isUserScrubbing.value = true;

    // User owns the playhead during drag
    _setOwner(Owner.user);
    _scrubEpoch = _bumpEpoch();

    // Always pause the current transport
    if (isSnapshotMode.value) {
      _stopSnapshotTimer();
    } else {
      _pauseSmooth();
    }
  }

  /// Listener for [timelineScrollController] that fires continuously while the
  /// user's finger is dragging across the timeline
  void _onScrollUpdate() {
    if (!isUserScrubbing.value || !_videoReady) return;

    final epoch = _scrubEpoch!;
    _scrubDebounce?.cancel();

    final offset = _timelineScrollController.offset;
    var target = _pxToDuration(offset);

    // Sync playhead and prefetch as we scroll
    _writePlayhead(target, Owner.user);
    _updateThumbnailCacheWindow();

    // Render the frame we scrubbed to on the timeline with a 90ms debounce
    _scrubDebounce = Timer(const Duration(milliseconds: 90), () async {
      if (epoch != _epoch) return;

      await _seekRendererTo(target, epoch);
    });
  }

  /// Callback method for when the user stops dragging the timeline
  void onTimelineScrollEnd(double scrollOffset) async {
    if (!isUserScrubbing.value) return;
    _scrubDebounce?.cancel();

    // Calculate the final target time
    var target = _pxToDuration(scrollOffset);
    if (isSnapshotMode.value && snapshots.isNotEmpty) {
      // In snapshot mode always snap to latest snapshot on release
      final idx = _findSnapshotIndexForPosition(target);
      target = snapshots[idx].videoTimestamp;
    }

    // Clean up scrubbing-related state
    isUserScrubbing.value = false;
    _scrubEpoch = null;

    // Sync playhead and video to where user finished scrolling to
    final epoch = _scrubEpoch ?? _bumpEpoch();
    _writePlayhead(target, Owner.user);
    await _seekRendererTo(target, epoch);

    final v = _videoController!.value;
    final dur = v.duration;
    final beforeEnd =
        dur > Duration.zero && v.position < (dur - Duration(milliseconds: 120));

    // Hand control back, preserving logical playback state
    if (_wasPlayingBeforeScrub) {
      if (isSnapshotMode.value) {
        _setOwner(Owner.timer);
        _startSnapshotTimer(_bumpEpoch());
        isPlaying.value = true;
      } else if (beforeEnd) {
        // Only resume if we haven't scrubbed to the end of the video
        _setOwner(Owner.video);
        await _playSmooth();
        isPlaying.value = true;
      } else {
        // If at end of video, remain paused
        _setOwner(Owner.idle);
        isPlaying.value = false;
      }
    } else {
      _setOwner(Owner.idle);
    }
  }

  /// Returns the thumbnail notifier for a given [time]
  Future<Uint8List?> getThumbnailForTimestamp(Duration time) {
    return _thumbnailRepo!.getThumbnailForTimestamp(time);
  }

  /// Fetches the initial window of thumbnails needed for the timeline to appear populated
  Future<void> _prefetchInitialThumbnails() async {
    if (_thumbnailRepo == null || !_videoReady) return;

    final totalDur = _videoController!.value.duration;
    final totalThumbs = (totalDur.inSeconds / intervalSeconds).ceil() + 1;

    const start = 0;
    final end = windowSize.clamp(0, totalThumbs);

    await _warmThumbnailCacheRange(start, end, totalDur);

    // Set the prefetch window state
    _prefetchStart = start;
    _prefetchEnd = end;
  }

  /// Calculates the window of thumbnails to loads based on current state
  /// and triggers the pre-fetch
  void _updateThumbnailCacheWindow() {
    if (_thumbnailRepo == null || !isInitialized.value || !_videoReady) return;

    if (_prefetchThrottle != null && _prefetchThrottle!.isActive) {
      return;
    }

    // No timer is active, schedule a new one
    _prefetchThrottle = Timer(const Duration(milliseconds: 120), () async {
      if (_isPrefetchRunning) {
        // Previous fetch still running, cancel this one
        return;
      }

      _isPrefetchRunning = true;

      try {
        final totalDur = _videoController!.value.duration;
        final totalThumbs = (totalDur.inSeconds / intervalSeconds).ceil() + 1;

        int centerIndex;
        if (isUserScrubbing.value) {
          // While dragging prefetch is viewport-driven
          final offsetPx = _timelineScrollController.offset;
          centerIndex = (offsetPx / thumbnailWidth).floor();
        } else {
          // During normal playback / seeks, prefetch is play-head driven
          final double seconds = playhead.value.inMilliseconds / 1000.0;
          centerIndex = (seconds / intervalSeconds).floor();
        }

        // Compute new window (inclusive-exclusive)
        final start = (centerIndex - windowSize).clamp(0, totalThumbs);
        final end = (centerIndex + windowSize).clamp(0, totalThumbs);

        if (_prefetchStart == null ||
            start >= (_prefetchEnd ?? -1) ||
            end <= (_prefetchStart ?? -1)) {
          // First run or non-overlapping jump, prefetch entire window
          await _warmThumbnailCacheRange(start, end, totalDur);
        } else {
          // Run overlapping ranges in parallel
          final List<Future> jobs = [];
          if (end > _prefetchEnd!) {
            // Slide to the right
            jobs.add(_warmThumbnailCacheRange(_prefetchEnd!, end, totalDur));
          }
          if (start < _prefetchStart!) {
            // Slide to the left
            jobs.add(
                _warmThumbnailCacheRange(start, _prefetchStart!, totalDur));
          }
          if (jobs.isNotEmpty) {
            await Future.wait(jobs);
          }
        }

        _prefetchStart = start;
        _prefetchEnd = end;
      } finally {
        _isPrefetchRunning = false;
      }
    });
  }

  /// Helper to load a specific range of thumbnails into the repository's cache
  Future<void> _warmThumbnailCacheRange(
      int start, int end, Duration totalDuration) async {
    final List<Future> fetchJobs = [];

    for (int i = start; i < end; i++) {
      final time = Duration(seconds: i * intervalSeconds.floor());
      if (time > totalDuration) break;

      if (_thumbnailRepo!.hasThumbnail(time)) {
        // Thumbnail already exists, skip
        continue;
      }

      final job = _thumbnailRepo!.getThumbnailForTimestamp(time);
      fetchJobs.add(job);
    }

    // Wait for all the thumbnail generation jobs in this range to finish
    if (fetchJobs.isNotEmpty) {
      await Future.wait(fetchJobs);
    }
  }

  // ==============
  // Collector methods
  // ==============

  /// Returns the graph queries for the [entity] in the context of the [snapshot]
  Future<SnapshotEntityQueries?> getQueriesForEntity(
      Snapshot snapshot, Map<String, dynamic> entity) async {
    isCrepeQueryLoading.value = true;
    try {
      if (isPlaying.value) {
        // Pause the video if it's playing (ideally we'll remove this check
        // once we force users only being able to click on an entity iff
        // the player is in snapshot mode with the video paused)
        // but maybe this is a good guard regardless
        togglePlayPause();
      }

      final queries = await _snapshotRepo.getQueriesForEntity(snapshot, entity);

      if (queries.allQueries.isEmpty) {
        errorMessage.value = 'No queries were generated.';
        return null;
      }

      return queries;
    } catch (e) {
      errorMessage.value = 'Failed to generate queries.';
      return null;
    } finally {
      isCrepeQueryLoading.value = false;
    }
  }

  /// Creates a [DataField] for the given [snapshot] that can later become
  /// part of a [Collector]
  void addDataField(
      Snapshot snapshot, String selectedQuery, String description) {
    final newDataField = DataField(
      dataFieldId: DateTime.now().millisecondsSinceEpoch,
      graphQuery: selectedQuery,
      name: description,
    );

    _dataFieldsForSnapshot.putIfAbsent(currSnapshotIndex.value, () => []);
    _dataFieldsForSnapshot[currSnapshotIndex.value]!.add(newDataField);
  }

  // ==============
  // General helper methods
  // ==============

  /// True if the [videoController] is initialized and ready
  bool get _videoReady =>
      _videoController != null && _videoController!.value.isInitialized;

  /// Sets the owner of the [playhead]
  void _setOwner(Owner o) => _owner = o;

  /// Checks if [who] has permissions to write to the [playhead]
  bool _canWrite(Owner who) => _owner == who;

  /// Increments the epoch version to invalidate stale async tasks
  int _bumpEpoch() => ++_epoch;

  /// Single, guarded method to update the [playhead] and its followers
  void _writePlayhead(Duration position, Owner by) {
    if (!_canWrite(by)) return;
    if (position == playhead.value) return;
    playhead.value = position;

    // Keep index in sync always
    if (snapshots.isNotEmpty) {
      final idx = _findSnapshotIndexForPosition(position);
      if (idx != currSnapshotIndex.value) {
        currSnapshotIndex.value = idx;
      }
    }
  }

  /// Tells the [videoController] to seek to a specific time
  Future<void> _seekRendererTo(Duration t, int epoch) async {
    if (!_videoReady) return;
    if (epoch != _epoch) return;
    await _videoController!.seekTo(t);
  }

  /// Finds the latest snapshot whose timestamp is <= [position]
  int _findSnapshotIndexForPosition(Duration position) {
    if (snapshots.isEmpty) return 0;

    int lo = 0;
    int hi = snapshots.length - 1;
    int result = 0;

    // Find latest index with binary search
    while (lo <= hi) {
      int mid = lo + ((hi - lo) >> 1);
      if (snapshots[mid].videoTimestamp <= position) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    return result;
  }

  /// Ensures a [Duration] is not negative or past the end of the video
  Duration _clampToDuration(Duration position) {
    final dur = _videoController?.value.duration ?? Duration.zero;
    if (position < Duration.zero) return Duration.zero;
    if (position > dur) return dur;
    return position;
  }

  /// Converts a pixel offset on the timeline to its corresponding [Duration]
  Duration _pxToDuration(double px) =>
      Duration(milliseconds: ((px / pixelsPerSecond) * 1000).round());
}
