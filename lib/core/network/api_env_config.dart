import 'package:flutter/foundation.dart';

/// Configuration class for the API environment
class ApiEnvConfig {
  static const String _staging =
      'https://dsc-api-staging-23350212163.us-central1.run.app';
  static const String _prod =
      'https://dsc-api-service-23350212163.us-central1.run.app';

  static bool _useProd = kDebugMode ? false : true;

  static String get baseUrl => _useProd ? _prod : _staging;
  static String get current => _useProd ? 'Production' : 'Staging';

  static void useProduction() {
    _useProd = true;
  }

  static void useStaging() {
    _useProd = false;
  }
}
