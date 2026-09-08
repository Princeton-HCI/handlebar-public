import 'package:flutter/foundation.dart';

/// Which backend the app talks to.
enum ApiEnv { local, staging, production }

/// Configuration class for the API environment
class ApiEnvConfig {
  static const String _staging =
      'https://handlebar-backend-staging-427379201809.us-east1.run.app';
  static const String _prod =
      'https://handlebar-backend-staging-427379201809.us-east1.run.app';

  /// Overrides the local URL, for cases the default cannot detect.
  ///
  ///   # Physical Android device, after: adb reverse tcp:4000 tcp:4000
  ///   flutter run --dart-define=HANDLEBAR_API_URL=http://127.0.0.1:4000
  ///
  ///   # A backend on another machine
  ///   flutter run --dart-define=HANDLEBAR_API_URL=http://192.168.1.20:4000
  ///
  /// Setting it also selects [ApiEnv.local] at startup.
  static const String _localOverride =
      String.fromEnvironment('HANDLEBAR_API_URL');

  static bool get hasLocalOverride => _localOverride.isNotEmpty;

  /// Where a locally running backend lives, as seen from this platform.
  ///
  /// The Android emulator reaches the host loopback as 10.0.2.2 — `localhost`
  /// there means the emulator itself. A *physical* device can't be detected
  /// at compile time and needs `adb reverse` plus the override above.
  static String get _localDefault {
    if (_localOverride.isNotEmpty) return _localOverride;
    if (kIsWeb) return 'http://localhost:4000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:4000'
        : 'http://localhost:4000';
  }

  /// Debug builds talk to a local backend by default: it is roughly two orders
  /// of magnitude faster than a cold Cloud Run instance, and it is the only
  /// environment where unreleased endpoints exist. Switch at runtime from the
  /// developer menu if you need staging.
  static ApiEnv _env = kDebugMode ? ApiEnv.local : ApiEnv.production;

  static ApiEnv get env => _env;

  static String get baseUrl {
    switch (_env) {
      case ApiEnv.local:
        return _localDefault;
      case ApiEnv.staging:
        return _staging;
      case ApiEnv.production:
        return _prod;
    }
  }

  static String get current {
    switch (_env) {
      case ApiEnv.local:
        return 'Local';
      case ApiEnv.staging:
        return 'Staging';
      case ApiEnv.production:
        return 'Production';
    }
  }

  static void useLocal() {
    _env = ApiEnv.local;
  }

  static void useStaging() {
    _env = ApiEnv.staging;
  }

  static void useProduction() {
    _env = ApiEnv.production;
  }
}
