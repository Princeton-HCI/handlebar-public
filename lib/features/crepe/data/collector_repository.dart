import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../models/active_collectors.dart';
import '../models/collector.dart';
import '../../../core/network/api_client.dart';

typedef ActiveCollectorsResult = Result<ActiveCollectors, ApiError>;

/// Handles [Collector] data operations
class CollectorRepository {
  final ApiClient _api;
  final _logger = Logger('CollectorRepository');

  CollectorRepository(this._api);

  /// Get currently active collectors
  Future<ActiveCollectorsResult> getActiveCollectors() async {
    _logger.info('Fetching active collectors...');
    try {
      final res = await _api.get('/api/crepe/collector');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final collectorData = map['data'];

        if (collectorData != null) {
          final List<Collector> collectors = switch (collectorData) {
            List list => list.map((e) => Collector.fromJson(e)).toList(),
            Map<String, dynamic> single => [Collector.fromJson(single)],
            _ => <Collector>[],
          };

          final domain = ActiveCollectors(collectors: collectors);
          _logger.info('Active collectors fetched successfully');
          return Success(domain);
        }

        _logger.severe('Invalid response format - no data field');
        return Failure(
            ApiError(message: 'Invalid response format - no data field'));
      }

      // Unhandled response
      final msg = ApiClient.errorMessage(res);
      _logger.severe('Fetch active collectors failed - $msg');
      return Failure(ApiError(message: msg, statusCode: res.statusCode));
    } on ApiException catch (e) {
      _logger.severe("Fetch active collectors failed - ${e.message}");
      return Failure(ApiError(message: e.message));
    } catch (e, st) {
      _logger.severe("Fetch active collectors failed - unexpected: $e", st);
      return const Failure(ApiError(message: "Unexpected error"));
    }
  }
}
