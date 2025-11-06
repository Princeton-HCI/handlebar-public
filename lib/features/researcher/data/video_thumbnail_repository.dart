import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Handles the creation and storage for video timeline thumbnails
class VideoThumbnailRepository {
  static final _logger = Logger('VideoThumbnailRepository');

  final File videoFile;
  final Map<Duration, Uint8List> _cache = {};
  static const int _maxCacheSize = 200;
  final Map<Duration, Future<Uint8List?>> _pendingJobs = {};

  final Pool _pool = Pool(4);

  VideoThumbnailRepository(this.videoFile);

  /// Returns true if the cache already contains a thumbnail for [time]
  bool hasThumbnail(Duration time) => _cache.containsKey(time);

  /// Returns a cached thumbnail if available, otherwise generates it sequentially
  Future<Uint8List?> getThumbnailForTimestamp(Duration time) async {
    if (_cache.containsKey(time)) {
      // Return the already-generated thumbnail to not repeat work
      return _cache[time];
    }

    if (_pendingJobs.containsKey(time)) {
      // Return the pending future to not repeat work between UI's FutureBuilder
      // and viewmodel's prefetch methods
      return _pendingJobs[time];
    }

    _logger.info('Generating thumbnail for $time');

    final job = _generateThumbnail(time);
    _pendingJobs[time] = job;
    job.whenComplete(() {
      _pendingJobs.remove(time);
    });

    return job;
  }

  Future<Uint8List?> _generateThumbnail(Duration time) async {
    // Allow at most 4 thumbnails to be generated at once using the resource pool
    return _pool.withResource<Uint8List?>(() async {
      try {
        final imageBytes = await VideoThumbnail.thumbnailData(
          video: videoFile.path,
          timeMs: time.inMilliseconds,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 250,
          quality: 95,
        );

        if (imageBytes != null) {
          if (_cache.length >= _maxCacheSize) {
            _cache.remove(_cache.keys.first);
          }

          _cache[time] = imageBytes;
          _logger.info('Successfully generated thumbnail for $time');
        } else {
          _logger.warning('Failed to generate thumbnail for $time');
        }

        return imageBytes;
      } catch (e, st) {
        _logger.severe('Thumbnail generation failed for $time: $e', e, st);
        return null;
      }
    });
  }

  void dispose() {
    _cache.clear();
    _pool.close();
    _logger.info('VideoThumbnailRepository disposed');
  }
}
