import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailRepository {
  static final _logger = Logger('VideoThumbnailRepository');

  final File videoFile;
  final Map<Duration, Uint8List> _cache = {};
  static const int _maxCacheSize = 50;

  VideoThumbnailRepository(this.videoFile);

  /// Returns true if the cache already contains a thumbnail for [time].
  bool hasThumbnail(Duration time) => _cache.containsKey(time);

  /// Returns a cached thumbnail if available, otherwise generates it sequentially.
  Future<Uint8List?> getThumbnailForTimestamp(Duration time) async {
    if (_cache.containsKey(time)) {
      return _cache[time];
    }

    _logger.info('Generating thumbnail for $time');

    try {
      final imageBytes = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        timeMs: time.inMilliseconds,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 160,
        quality: 80,
      );

      if (imageBytes != null) {
        if (_cache.length >= _maxCacheSize) {
          _cache.remove(_cache.keys.first);
        }

        _cache[time] = imageBytes;
        _logger.info('Successfully generated thumbnail for $time.');
      } else {
        _logger.warning('Failed to generate thumbnail for $time.');
      }

      return imageBytes;
    } catch (e, st) {
      _logger.severe('Thumbnail generation failed for $time: $e', e, st);
      return null;
    }
  }

  void dispose() {
    _cache.clear();
    _logger.info('VideoThumbnailRepository disposed.');
  }
}
