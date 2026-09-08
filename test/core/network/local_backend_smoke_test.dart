@Timeout(Duration(seconds: 20))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:handlebar/core/network/api_env_config.dart';
import 'package:http/http.dart' as http;

/// Verifies the client can actually reach a locally running backend.
///
/// Skipped unless you opt in, so it never breaks CI or a normal `flutter test`:
///
///   cd ../handlebar-backend && mix phx.server
///   flutter test --dart-define=HANDLEBAR_API_URL=http://localhost:4000
void main() {
  // Debug builds already default to the local environment, but a plain
  // `flutter test` must not require a running server — so these stay gated on
  // the explicit override.
  final skip = ApiEnvConfig.hasLocalOverride
      ? null
      : 'Requires a local backend and '
          '--dart-define=HANDLEBAR_API_URL=http://localhost:4000';

  group('local backend', () {
    test('ApiEnvConfig honours the dart-define override', () {
      expect(ApiEnvConfig.current, 'Local');
      expect(ApiEnvConfig.baseUrl, startsWith('http'));
    }, skip: skip);

    test('public terms endpoint is reachable', () async {
      final res =
          await http.get(Uri.parse('${ApiEnvConfig.baseUrl}/api/terms/public'));
      expect(res.statusCode, 200, reason: 'is `mix phx.server` running?');
      expect(res.body, contains('"data"'));
    }, skip: skip);

    test('sensors endpoint exists and is authenticated', () async {
      final res = await http
          .get(Uri.parse('${ApiEnvConfig.baseUrl}/api/research/me/sensors'));
      // 401 (not 404) proves the route is mounted and auth-gated.
      expect(res.statusCode, 401);
    }, skip: skip);

    test('points endpoint exists and is authenticated', () async {
      final res = await http.post(
        Uri.parse('${ApiEnvConfig.baseUrl}/api/research/points'),
        headers: {'Content-Type': 'application/json'},
        body: '{"location":[]}',
      );
      expect(res.statusCode, 401);
    }, skip: skip);
  });
}
