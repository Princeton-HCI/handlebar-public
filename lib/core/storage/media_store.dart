import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:logging/logging.dart';

/// Store for saving, loading, and sharing app-generated media
class MediaStore {
  static final Logger _logger = Logger('MediaStore');

  static Future<bool> saveFileToDownloads(
      String tempFilePath, String fileName) async {
    try {
      final success = await copyFileIntoDownloadFolder(
        tempFilePath,
        fileName,
      );
      return success!;
    } catch (e) {
      _logger.severe('Error saving to downloads: $e');
      return false;
    }
  }
}
