import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MediaStoreService {
  static bool _isInitialized = false;
  static Directory? _appDocumentsDir;

  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      try {
        // Get the app's documents directory (private external storage)
        _appDocumentsDir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        _isInitialized = true;
        debugPrint('✅ MediaStoreService initialized successfully');
        debugPrint('📁 App documents directory: ${_appDocumentsDir?.path}');
      } catch (e) {
        debugPrint('❌ Failed to initialize MediaStoreService: $e');
        rethrow;
      }
    }
  }

  static Future<String?> saveFileToDownloads(
      String tempFilePath, String fileName) async {
    try {
      debugPrint('📁 Attempting to save file: $fileName from: $tempFilePath');

      await ensureInitialized();

      // Verify temp file exists
      final tempFile = File(tempFilePath);
      if (!await tempFile.exists()) {
        debugPrint('❌ Temp file does not exist: $tempFilePath');
        return null;
      }

      final fileSize = await tempFile.length();
      debugPrint('📊 File size: $fileSize bytes');

      // Create a "Recordings" subdirectory in the app's documents directory
      final recordingsDir = Directory('${_appDocumentsDir!.path}/Recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        debugPrint('📁 Created recordings directory: ${recordingsDir.path}');
      }

      // Copy the file to the recordings directory
      final destPath = '${recordingsDir.path}/$fileName';
      final destFile = await tempFile.copy(destPath);

      if (await destFile.exists()) {
        final actualSize = await destFile.length();
        debugPrint(
            '✅ File saved successfully to: $destPath ($actualSize bytes)');

        // Try to share the file (this will let user choose where to save it)
        try {
          await Share.shareXFiles([XFile(destPath)],
              text: 'Handlebar UI Snapshots Recording');
          debugPrint('📤 File shared successfully');
        } catch (shareError) {
          debugPrint('⚠️ Share failed, but file is saved: $shareError');
        }

        return destPath;
      } else {
        debugPrint('❌ File was not copied successfully');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in saveFileToDownloads: $e');
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

      debugPrint('📁 Found ${files.length} saved recordings');
      return files;
    } catch (e) {
      debugPrint('❌ Error getting saved recordings: $e');
      return [];
    }
  }

  static Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted recording: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting recording: $e');
      return false;
    }
  }
}
