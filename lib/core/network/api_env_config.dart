import 'package:flutter/foundation.dart';

/// Configuration class for the API environment
class ApiEnvConfig {
  static const String _staging =
      'https://handlebar-backend-23350212163.us-east1.run.app';
  static const String _prod =
      'https://handlebar-backend-23350212163.us-east1.run.app';

  // For testing the local backend:
  // static const String _staging = 'http://10.0.2.2:4000';
  // static const String _prod = 'http://10.0.2.2:4000';

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
