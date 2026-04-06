import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:handlebar/core/storage/media_store.dart';
import 'package:logging/logging.dart';
import 'package:handlebar/features/crepe/services/recording_preferences_service.dart';
import 'package:handlebar/features/crepe/services/recording_error_handler.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UiSnapshotRecordingService {
  static final UiSnapshotRecordingService _instance =
      UiSnapshotRecordingService._internal();
  factory UiSnapshotRecordingService() => _instance;
  UiSnapshotRecordingService._internal() {
    _initializePreferences();
  }

  static final Logger _logger = Logger('UiSnapshotRecordingService');
  final CrepePlugin _crepePlugin = CrepePlugin();
  final RecordingPreferencesService _preferencesService =
      RecordingPreferencesService();
  final RecordingErrorHandler _errorHandler = RecordingErrorHandler();
  final NotificationService _notificationService = NotificationService();

  bool _isRecording = false;
  bool _isVideoRecording = false;
  bool _isCapturing = false;
  Timer? _snapshotRecordingTimer;
  final List<Map<String, dynamic>> _snapshots = [];
  int? _recordingStartTime;
  int? _recordingEndTime;

  int get _captureIntervalMilliseconds =>
      _preferencesService.captureIntervalMilliseconds;
  int get _maxSnapshots => _preferencesService.maxSnapshots;

  final _recordingStateController = StreamController<bool>.broadcast();
  final _snapshotCountController = StreamController<int>.broadcast();

  bool get isRecording => _isRecording;
  int get snapshotCount => _snapshots.length;
  List<Map<String, dynamic>> get snapshots => List.unmodifiable(_snapshots);
  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  Stream<int> get snapshotCountStream => _snapshotCountController.stream;

  Future<bool> startRecording() async {
    if (_isRecording) {
      _logger.warning('Recording already in progress');
      return false;
    }

    try {
      if (!await _crepePlugin.isAccessibilityServiceEnabled()) {
        _errorHandler.handleError(
          'Accessibility service is not enabled',
          type: RecordingErrorType.accessibilityServiceDisabled,
        );
        return false;
      }

      // Start video recording (foreground)
      try {
        final started =
            await FlutterScreenRecording.startRecordScreen("handlebar_session");
        if (started) {
          _isVideoRecording = true;
          // Capture timestamp AFTER startRecordScreen returns, since the
          // video is now actively recording. This aligns snapshot timestamps
          // with actual video positions.
          final now = DateTime.now().millisecondsSinceEpoch;
          _recordingStartTime = now;
          _logger.info("Screen recording started at $_recordingStartTime");
        } else {
          _logger.warning("Screen recording failed to start");
          _recordingStartTime = null;
        }
      } catch (videoError) {
        _logger.severe("Error starting screen recording: $videoError");
        _recordingStartTime = null;
        // We continue anyway, as snapshots might still be useful for debugging
      }

      // Start snapshot collection (background)
      _isRecording = true;

      _snapshots.clear();

      _recordingStateController.add(_isRecording);
      _snapshotCountController.add(_snapshots.length);

      await _crepePlugin.startRecording();

      // Capture first snapshot immediately and then on interval
      _runSnapshotLoop();

      _notificationService.showSuccess('🔴 Recording started');
      return true;
    } catch (e) {
      // Let error handler classify the error automatically
      _errorHandler.handleError(e);
      _isRecording = false;
      _recordingStateController.add(_isRecording);
      return false;
    }
  }

  void _runSnapshotLoop() {
    _captureSnapshot();

    _snapshotRecordingTimer = Timer.periodic(
      Duration(milliseconds: _captureIntervalMilliseconds),
      (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        _captureSnapshot();
      },
    );
  }

  Future<void> stopRecording() async {
    _isRecording = false;

    await _crepePlugin.stopRecording();

    // Stop all snapshot collection immediately
    _snapshotRecordingTimer?.cancel();
    _snapshotRecordingTimer = null;

    _isCapturing = false;
    _recordingEndTime = DateTime.now().millisecondsSinceEpoch;

    // Stop video recording and get path
    String? rawVideoPath;
    if (_isVideoRecording) {
      try {
        rawVideoPath = await FlutterScreenRecording.stopRecordScreen;
        _isVideoRecording = false;
        _logger.info("Video finalized at: $rawVideoPath");
      } catch (e) {
        _logger.severe("Error stopping video: $e");
      }
    }

    _recordingStateController.add(false);

    _logger.info('Recording stopped. Captured ${_snapshots.length} snapshots');

    // Save everything if we have snapshots
    if (_snapshots.isNotEmpty) {
      await _saveSessionToDownloads(rawVideoPath);
    } else {
      _logger.warning("No snapshots captured, skipping save.");
    }
  }

  Future<void> _captureSnapshot() async {
    if (!_isRecording) return;

    // Prevent overlapping captures. Without this,
    // we get stacked snapshots, this helps ensure they are evenly spaced
    if (_isCapturing) {
      _logger.fine(
          'Skipping snapshot capture — previous capture still in progress');
      return;
    }
    _isCapturing = true;

    try {
      final snapshotData = await _crepePlugin.getUiSnapshot();

      if (snapshotData.containsKey('error')) {
        _errorHandler.handleError(
          snapshotData['error'],
          type: RecordingErrorType.snapshotCaptureFailed,
        );
        return;
      }

      final snapshotRaw = snapshotData['snapshot'];
      if (snapshotRaw == null) {
        _logger.warning('Snapshot data is null');
        return;
      }

      // Convert from Map<Object?, Object?> to Map<String, dynamic>
      final snapshot = Map<String, dynamic>.from(snapshotRaw as Map);
      final metadata = snapshotRaw['metadata'];

      // Use the time Java finished building it, NOT the time Dart received it
      final int captureTimestamp =
          metadata['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
      snapshot['captureTimestamp'] = captureTimestamp;

      _snapshots.add(snapshot);

      if (_snapshots.length > _maxSnapshots) {
        _snapshots.removeAt(0);
      }

      _snapshotCountController.add(_snapshots.length);

      _logger.fine('Captured snapshot ${_snapshots.length}');
    } catch (e) {
      _errorHandler.handleError(e,
          type: RecordingErrorType.snapshotCaptureFailed);
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _saveSessionToDownloads(String? rawVideoPath) async {
    _logger.info("Saving session...");

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    bool videoSaved = false;
    bool dataSaved = false;

    // Save video
    if (rawVideoPath != null) {
      final videoFile = File(rawVideoPath);
      if (await videoFile.exists()) {
        final videoName = 'handlebar_video_$timestamp.mp4';
        videoSaved =
            await MediaStore.saveFileToDownloads(rawVideoPath, videoName);
        // Clean up the temp video
        try {
          await videoFile.delete();
        } catch (_) {}
      }
    }

    // Save snapshots
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/handlebar_data_$timestamp.zip';

    if (await _createSnapshotZip(zipPath)) {
      final zipName = 'handlebar_data_$timestamp.zip';
      dataSaved = await MediaStore.saveFileToDownloads(zipPath, zipName);
      // Clean up the temp zip
      try {
        await File(zipPath).delete();
      } catch (_) {}
    }

    // Notify the user
    if (videoSaved && dataSaved) {
      _notificationService.showSuccess('Recording session saved');
    } else if (dataSaved) {
      _notificationService.showWarning('Data saved, but Video failed');
    } else {
      _notificationService.showError('Failed to save recording session');
    }
  }

  Future<bool> _createSnapshotZip(String destPath) async {
    try {
      final archive = Archive();

      // Add metadata
      final metadata = await getSessionMetadata();
      final metaBytes = utf8.encode(jsonEncode(metadata));
      archive
          .addFile(ArchiveFile('metadata.json', metaBytes.length, metaBytes));
      _logger.info('Added metadata file to archive');

      // Add snapshots
      for (int i = 0; i < _snapshots.length; i++) {
        final s = _snapshots[i];
        final bytes = utf8.encode(jsonEncode(s));
        // Use capture timestamp in filename
        final ts =
            s['captureTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        archive.addFile(ArchiveFile('snapshot_$ts.json', bytes.length, bytes));
      }
      _logger.info('Added ${_snapshots.length} snapshot files to archive');

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes == null) return false;

      final file = File(destPath);
      await file.writeAsBytes(zipBytes);
      _logger.info('ZIP file created successfully (${zipBytes.length} bytes)');
      return true;
    } catch (e) {
      _logger.severe("Error creating ZIP: $e");
      return false;
    }
  }

  void clearSnapshots() {
    _snapshots.clear();
    _recordingStartTime = null;
    _recordingEndTime = null;
    _isCapturing = false;
    _snapshotCountController.add(_snapshots.length);
    _logger.info('Snapshots cleared');
  }

  Future<Map<String, dynamic>> getSessionMetadata() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();

    String deviceModel = 'Unknown';
    String androidVersion = 'Unknown';
    String manufacturer = 'Unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceModel = androidInfo.model;
        androidVersion = androidInfo.version.release;
        manufacturer = androidInfo.manufacturer;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceModel = iosInfo.model;
        androidVersion = iosInfo.systemVersion;
        manufacturer = 'Apple';
      }
    } catch (e) {
      _logger.warning('Failed to get device info: $e');
    }

    // Get screen dimensions
    int screenHeight;
    int screenWidth;
    try {
      final display = WidgetsBinding.instance.platformDispatcher.displays.first;
      screenHeight = display.size.height.toInt();
      screenWidth = display.size.width.toInt();
    } catch (e) {
      _logger.severe('Failed to get screen dimensions: $e');
      throw Exception('Failed to get screen dimensions: $e');
    }

    return {
      'startTimestamp': _recordingStartTime,
      'endTimestamp': _recordingEndTime,
      'snapshotCount': _snapshots.length,
      'captureIntervalMilliseconds': _captureIntervalMilliseconds,
      'maxSnapshots': _maxSnapshots,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'deviceModel': deviceModel,
      'androidVersion': androidVersion,
      'manufacturer': manufacturer,
      'screenHeight': screenHeight,
      'screenWidth': screenWidth,
    };
  }

  Future<void> _initializePreferences() async {
    await _preferencesService.initialize();
  }

  void dispose() {
    _snapshotRecordingTimer?.cancel();
    _recordingStateController.close();
    _snapshotCountController.close();
  }
}
