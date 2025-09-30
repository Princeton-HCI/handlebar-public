import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MediaStoreService {
  static final Logger _logger = Logger('MediaStoreService');
  static bool _isInitialized = false;
  static Directory? _appDocumentsDir;

  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      try {
        // Get the app's documents directory (private external storage)
        _appDocumentsDir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        _isInitialized = true;
        _logger.info('MediaStoreService initialized successfully');
        _logger.info('App documents directory: ${_appDocumentsDir?.path}');
      } catch (e) {
        _logger.severe('Failed to initialize MediaStoreService: $e');
        rethrow;
      }
    }
  }

  static Future<String?> saveFileToDownloads(
      String tempFilePath, String fileName) async {
    try {
      _logger.info('Attempting to save file: $fileName from: $tempFilePath');

      await ensureInitialized();

      // Verify temp file exists
      final tempFile = File(tempFilePath);
      if (!await tempFile.exists()) {
        _logger.warning('Temp file does not exist: $tempFilePath');
        return null;
      }

      final fileSize = await tempFile.length();
      _logger.fine('File size: $fileSize bytes');

      // Create a "Recordings" subdirectory in the app's documents directory
      final recordingsDir = Directory('${_appDocumentsDir!.path}/Recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        _logger.info('Created recordings directory: ${recordingsDir.path}');
      }

      // Copy the file to the recordings directory
      final destPath = '${recordingsDir.path}/$fileName';

      // Read bytes from temp file and write to destination
      final bytes = await tempFile.readAsBytes();
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes, flush: true);

      if (await destFile.exists()) {
        final actualSize = await destFile.length();
        _logger
            .info('File saved successfully to: $destPath ($actualSize bytes)');

        // Try to share the file (this will let user choose where to save it)
        try {
          await Share.shareXFiles([XFile(destPath)],
              text: 'Handlebar UI Snapshots Recording');
          _logger.info('File shared successfully');
        } catch (shareError) {
          _logger.warning('Share failed, but file is saved: $shareError');
        }

        return destPath;
      } else {
        _logger.severe('File was not copied successfully');
        return null;
      }
    } catch (e) {
      _logger.severe('Error in saveFileToDownloads: $e');
      return null;
    }
  }

  static Future<List<String>> getSavedRecordings() async {
    try {
      await ensureInitialized();

      final recordingsDir = Directory('${_appDocumentsDir!.path}/Recordings');
      if (!await recordingsDir.exists()) {
        return [];
      }

      final files = recordingsDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.zip'))
          .map((file) => file.path)
          .toList();

      _logger.info('Found ${files.length} saved recordings');
      return files;
    } catch (e) {
      _logger.severe('Error getting saved recordings: $e');
      return [];
    }
  }

  static Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Deleted recording: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Error deleting recording: $e');
      return false;
    }
  }

  static Future<String?> saveFileSilently(
      String tempFilePath, String fileName) async {
    try {
      _logger.info('Silently saving file: $fileName from: $tempFilePath');

      await ensureInitialized();

      // Verify temp file exists
      final tempFile = File(tempFilePath);
      if (!await tempFile.exists()) {
        _logger.warning('Temp file does not exist: $tempFilePath');
        return null;
      }

      final fileSize = await tempFile.length();
      _logger.fine('File size: $fileSize bytes');

      // Create a "Recordings" subdirectory in the app's documents directory
      final recordingsDir = Directory('${_appDocumentsDir!.path}/Recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        _logger.info('Created recordings directory: ${recordingsDir.path}');
      }

      // Copy the file to the recordings directory
      final destPath = '${recordingsDir.path}/$fileName';

      // Read bytes from temp file and write to destination
      final bytes = await tempFile.readAsBytes();
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes, flush: true);

      if (await destFile.exists()) {
        final actualSize = await destFile.length();
        _logger.info('File saved silently to: $destPath ($actualSize bytes)');

        // Clean up temp file after successful save
        try {
          await tempFile.delete();
          _logger.fine('Temp file cleaned up');
        } catch (e) {
          _logger.warning('Failed to delete temp file: $e');
        }

        return destPath;
      } else {
        _logger.severe('File was not copied successfully');
        return null;
      }
    } catch (e) {
      _logger.severe('Error in saveFileSilently: $e');
      return null;
    }
  }
}
