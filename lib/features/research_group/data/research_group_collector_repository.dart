import 'dart:convert';

import 'package:handlebar/core/network/api_executor.dart';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/result.dart';
import '../../crepe/models/collector.dart';
import '../../crepe/models/data_field.dart';
import '../../crepe/models/participant_collector.dart';

typedef ParticipantCollectorsResult
    = Result<List<ParticipantCollector>, ApiError>;
typedef CollectorsResult = Result<List<Collector>, ApiError>;
typedef CollectorResult = Result<Collector, ApiError>;
typedef BoolResult = Result<bool, ApiError>;

class ResearchGroupCollectorRepository with ApiExecutor {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupCollectorRepository');

  static const String _base = '/api/research/groups';

  ResearchGroupCollectorRepository(this._api);

  Future<CollectorsResult> listGroupCollectors(int groupId) async {
    final action = 'listGroupCollectors($groupId)';
    return executeRequest<List<Collector>>(
      action: action,
      logger: _logger,
      request: () => _api.get('$_base/$groupId/collectors'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final collectors = (map['data'] as List)
              .map((e) => Collector.fromJson(e as Map<String, dynamic>))
              .toList();
          _logger.info("$action successful");
          return Success(collectors);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<ParticipantCollectorsResult> listParticipantCollectors() async {
    final action = 'listParticipantCollectors';
    return executeRequest<List<ParticipantCollector>>(
      action: action,
      logger: _logger,
      request: () => _api.get('/api/research/me/collectors'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final items = (map['data'] as List).cast<List<dynamic>>();
          final collectors = items.map(ParticipantCollector.fromList).toList();

          _logger.info('$action successful');
          return Success(collectors);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<CollectorResult> createCollectorAndAttach({
    required int groupId,
    required String appName,
    required String appPackage,
    required String description,
    required List<DataField> dataFields,
    List<String>? screenLandmarks,
    String? screenName,
  }) async {
    final action = 'createCollectorAndAttach($groupId)';
    return executeRequest<Collector>(
      action: action,
      logger: _logger,
      request: () {
        final dfPayload = dataFields
            .map((df) => {'name': df.name, 'graph_query': df.graphQuery})
            .toList();
        final body = {
          'collector': {
            'app_name': appName,
            'app_package': appPackage,
            'description': description,
            if (screenName != null) 'screen_name': screenName,
            if (screenLandmarks != null && screenLandmarks.isNotEmpty)
              'screen_landmarks': screenLandmarks,
            'data_fields': dfPayload,
          }
        };
        return _api.post('$_base/$groupId/collectors', body: body);
      },
      onResponse: (res) {
        if (res.statusCode == 201) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final collector =
              Collector.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info("$action successful");
          return Success(collector);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }
        if (ApiClient.isForbidden(res)) {
          return ApiClient.forbiddenFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<BoolResult> removeCollector(int groupId, int collectorId) async {
    final action = 'removeCollector($groupId, $collectorId)';
    return executeRequest<bool>(
      action: action,
      logger: _logger,
      request: () => _api.delete('$_base/$groupId/collectors/$collectorId'),
      onResponse: (res) {
        if (res.statusCode == 204) {
          _logger.info("$action successful");
          return const Success(true);
        }

        if (res.statusCode == 404) {
          final msg = 'Collector not found';
          _logger.warning('$action failed - $msg');
          return Failure(ApiError(message: msg, statusCode: 404));
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }
        if (ApiClient.isForbidden(res)) {
          return ApiClient.forbiddenFailure(_logger, action: action);
        }

        return null;
      },
    );
  }
}
