import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:logging/logging.dart';
import 'package:handlebar/services/media_store_service.dart';
import 'package:handlebar/services/recording_preferences_service.dart';
import 'package:handlebar/services/recording_error_handler.dart';
import 'package:handlebar/services/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UiSnapshotRecordingService {
  static final UiSnapshotRecordingService _instance = UiSnapshotRecordingService._internal();
  factory UiSnapshotRecordingService() => _instance;
  UiSnapshotRecordingService._internal() {
    _initializePreferences();
  }

  static final Logger _logger = Logger('UiSnapshotRecordingService');
  final CrepePlugin _crepePlugin = CrepePlugin();
  final RecordingPreferencesService _preferencesService = RecordingPreferencesService();
  final RecordingErrorHandler _errorHandler = RecordingErrorHandler();
  final NotificationService _notificationService = NotificationService();
  
  bool _isRecording = false;
  Timer? _recordingTimer;
  final List<Map<String, dynamic>> _snapshots = [];
  DateTime? _recordingStartTime;
  DateTime? _recordingEndTime;
  
  int get _captureIntervalSeconds => _preferencesService.captureIntervalSeconds;
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
      final isAccessibilityEnabled = await _crepePlugin.isAccessibilityServiceEnabled();
      if (!isAccessibilityEnabled) {
        _errorHandler.handleError(
          'Accessibility service is not enabled',
          type: RecordingErrorType.accessibilityServiceDisabled,
        );
        return false;
      }
      
      await _crepePlugin.initializeGraphQuery();
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingEndTime = null;
      _snapshots.clear();
      
      _recordingStateController.add(_isRecording);
      _snapshotCountController.add(_snapshots.length);
      
      await _captureSnapshot();
      
      _recordingTimer = Timer.periodic(
        Duration(seconds: _captureIntervalSeconds),
        (_) => _captureSnapshot(),
      );
      
      _logger.info('Recording started successfully');
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
  
  Future<void> stopRecording() async {
    if (!_isRecording) {
      _logger.warning('No recording in progress');
      return;
    }
    
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;
    _recordingEndTime = DateTime.now();
    
    _recordingStateController.add(_isRecording);
    
    _logger.info('Recording stopped. Captured ${_snapshots.length} snapshots');
    
    // Automatically save recordings if we have snapshots
    if (_snapshots.isNotEmpty) {
      try {
        _logger.info('💾 Attempting to save ${_snapshots.length} snapshots...');
        final savedPath = await _saveToDownloads();
        if (savedPath != null) {
          _logger.info('✅ Recording saved successfully: $savedPath');
          _notificationService.showSuccess('✅ Saved ${_snapshots.length} snapshots! File will be shared.');
        } else {
          _logger.warning('❌ Failed to save recording');
          _notificationService.showError('❌ Failed to save recording. Check storage permissions.');
        }
      } catch (e) {
        _logger.severe('❌ Error saving recording: $e');
        _notificationService.showError('❌ Error saving recording: ${e.toString()}');
      }
    }
  }
  
  Future<void> _captureSnapshot() async {
    if (!_isRecording) return;
    
    try {
      await _crepePlugin.updateSnapshot();
      
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
      
      // Add capture timestamp
      snapshot['captureTimestamp'] = DateTime.now().millisecondsSinceEpoch;
      
      _snapshots.add(snapshot);
      
      if (_snapshots.length > _maxSnapshots) {
        _snapshots.removeAt(0);
      }
      
      _snapshotCountController.add(_snapshots.length);
      
      _logger.fine('Captured snapshot ${_snapshots.length}');
    } catch (e) {
      _errorHandler.handleError(e, type: RecordingErrorType.snapshotCaptureFailed);
    }
  }
  
  void clearSnapshots() {
    _snapshots.clear();
    _recordingStartTime = null;
    _recordingEndTime = null;
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
    
    return {
      'startTime': _recordingStartTime?.toIso8601String(),
      'endTime': _recordingEndTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'snapshotCount': _snapshots.length,
      'captureIntervalSeconds': _captureIntervalSeconds,
      'maxSnapshots': _maxSnapshots,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'deviceModel': deviceModel,
      'androidVersion': androidVersion,
      'manufacturer': manufacturer,
    };
  }

  Future<String?> _saveToDownloads() async {
    _logger.info('💾 Starting save process...');
    try {
      if (_snapshots.isEmpty) {
        _logger.warning('⚠️ No snapshots to save');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'handlebar_ui_snapshots_$timestamp.zip';
      _logger.info('📁 Creating ZIP file: $fileName');
      
      // Create temp file first
      final tempDir = Directory.systemTemp;
      final tempFilePath = '${tempDir.path}/$fileName';
      _logger.info('📂 Temp file path: $tempFilePath');
      
      final archive = Archive();
      
      // Add metadata file
      final metadata = await getSessionMetadata();
      final metadataJson = const JsonEncoder.withIndent('  ').convert(metadata);
      final metadataBytes = utf8.encode(metadataJson);
      archive.addFile(ArchiveFile('metadata.json', metadataBytes.length, metadataBytes));
      _logger.info('📋 Added metadata.json (${metadataBytes.length} bytes)');
      
      // Add snapshot files
      for (int i = 0; i < _snapshots.length; i++) {
        final snapshot = _snapshots[i];
        final snapshotJson = const JsonEncoder.withIndent('  ').convert(snapshot);
        final snapshotBytes = utf8.encode(snapshotJson);
        
        // Use timestamp in filename for easy sync with screen recordings
        final timestamp = snapshot['captureTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        final snapshotFileName = 'snapshot_${timestamp}.json';
        archive.addFile(ArchiveFile(snapshotFileName, snapshotBytes.length, snapshotBytes));
      }
      _logger.info('📸 Added ${_snapshots.length} snapshot files to archive');
      
      // Create ZIP file
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      
      if (zipBytes == null) {
        _logger.severe('❌ Failed to encode zip file');
        return null;
      }
      
      _logger.info('📦 ZIP file created successfully (${zipBytes.length} bytes)');
      
      // Save to temp file first
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(zipBytes);
      
      // Verify temp file was created
      if (await tempFile.exists()) {
        final actualSize = await tempFile.length();
        _logger.info('✅ Temp file created: $tempFilePath (${actualSize} bytes)');
      } else {
        _logger.severe('❌ Temp file was not created');
        return null;
      }
      
      // Save to app's recordings directory
      _logger.info('🚀 Attempting to save to app recordings directory...');
      final result = await MediaStoreService.saveFileToDownloads(tempFilePath, fileName);
      if (result != null) {
        _logger.info('✅ ZIP file saved successfully: $result');
        // Clean up temp file after successful save
        try {
          await tempFile.delete();
          _logger.info('🗑️ Temp file cleaned up');
        } catch (e) {
          _logger.warning('⚠️ Failed to delete temp file: $e');
        }
        return result;
      } else {
        _logger.warning('⚠️ Failed to save recording, keeping temp file: $tempFilePath');
        return tempFilePath;
      }
      
    } catch (e) {
      _logger.severe('❌ Error in _saveToDownloads: $e');
      _errorHandler.handleError(e, type: RecordingErrorType.fileSystemError);
      return null;
    }
  }
  
  Future<void> _initializePreferences() async {
    await _preferencesService.initialize();
  }
  
  void dispose() {
    _recordingTimer?.cancel();
    _recordingStateController.close();
    _snapshotCountController.close();
  }
}