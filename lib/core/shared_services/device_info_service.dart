import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service to manage device information
class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static final Logger _logger = Logger('DeviceInfoService');

  /// Returns the current device's timezone
  Future<String> timezone() async {
    try {
      // flutter_timezone correctly fetches the IANA string on iOS, Android, and Web
      final tz = await FlutterTimezone.getLocalTimezone();

      // Safety check: if it somehow returns an empty string, fallback to UTC
      if (tz.isEmpty) return 'UTC';

      return tz;
    } catch (_, st) {
      _logger.severe('Error getting device timezone, defaulting to UTC', st);
      return 'UTC';
    }
  }

  /// Returns the current device's locale
  String languageCode() {
    try {
      return Intl.getCurrentLocale();
    } catch (_, st) {
      _logger.severe('Error getting device language, defaulting to en_US', st);
      return 'en_US';
    }
  }

  /// Returns a string representation of the current platform information
  Future<String> platformString() async {
    try {
      // Get actual app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = "${packageInfo.version}+${packageInfo.buildNumber}";

      // 1. Guard for Web explicitly before touching dart:io
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        // Format: "AppVersion / Web: chrome, platform"
        return "$appVersion / Web: ${webInfo.browserName.name}, ${webInfo.platform}";
      }

      // 2. Safe to use Platform here because we know we aren't on Web
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return "$appVersion / ${androidInfo.manufacturer}: ${androidInfo.model}, android, ${androidInfo.version.release}";
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return "$appVersion / Apple: ${iosInfo.model}, iOS, ${iosInfo.systemVersion}";
      }

      return "$appVersion / Unknown: ${Platform.operatingSystem}";
    } catch (e, st) {
      _logger.severe("Error getting device platform: $e", st);
      // Safe fallback that avoids re-triggering the dart:io crash
      return "1.0.0+1 / Unknown OS";
    }
  }
}
