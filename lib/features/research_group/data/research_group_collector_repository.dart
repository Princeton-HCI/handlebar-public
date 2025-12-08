import 'dart:convert';

import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../../crepe/models/collector.dart';
import '../../crepe/models/data_field.dart';
import '../../crepe/models/participant_collector.dart';

typedef ParticipantCollectorsResult
    = Result<List<ParticipantCollector>, ApiError>;
typedef CollectorsResult = Result<List<Collector>, ApiError>;
typedef CollectorResult = Result<Collector, ApiError>;
typedef BoolResult = Result<bool, ApiError>;

class ResearchGroupCollectorRepository {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupCollectorRepository');

  static const String _base = '/api/research/groups';

  ResearchGroupCollectorRepository(this._api);

  Future<CollectorsResult> listGroupCollectors(int groupId) async {
    final action = 'listGroupCollectors($groupId)';
    try {
      _logger.info("Starting $action request...");
      final res = await _api.get('$_base/$groupId/collectors');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is List) {
          final collectors = data
              .map((e) => Collector.fromJson(e as Map<String, dynamic>))
              .toList();
          _logger.info("$action successful");
          return Success(collectors);
        }

        _logger.severe('Invalid response format - data is not a list');
        return const Failure(
            ApiError(message: 'Invalid response format from server'));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: action,
        );
      }

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<ParticipantCollectorsResult> listParticipantCollectors() async {
    final action = 'listParticipantCollectors';
    try {
      _logger.info("Starting $action request...");
      final res = await _api.get('/api/research/me/collectors');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;

        final items = (map['data'] as List).cast<List<dynamic>>();

        final collectors = items.map(ParticipantCollector.fromList).toList();

        _logger.info('$action successful');
        return Success(collectors);
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: action,
        );
      }

      return ApiClient.unhandledFailure(
        _logger,
        res,
        action: action,
      );
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(
        _logger,
        e,
        action: action,
      );
    } catch (e, st) {
      return ApiClient.unexpectedFailure(
        _logger,
        e,
        st,
        action: action,
      );
    }
  }

  Future<CollectorResult> createCollectorAndAttach({
    required int groupId,
    required String appName,
    required String appPackage,
    String? description,
    required List<DataField> dataFields,
  }) async {
    final action = 'createCollectorAndAttach($groupId)';
    try {
      _logger.info("Starting $action request...");
      final dfPayload = dataFields
          .map((df) => {
                'name': df.name,
                'graph_query': df.graphQuery,
              })
          .toList();

      final body = {
        'collector': {
          'app_name': appName,
          'app_package': appPackage,
          if (description != null) 'description': description,
          'data_fields': dfPayload,
        }
      };

      final res = await _api.post('$_base/$groupId/collectors', body: body);

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

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<BoolResult> removeCollector(int groupId, int collectorId) async {
    final action = 'removeCollector($groupId, $collectorId)';
    try {
      _logger.info("Starting $action request...");
      final res = await _api.delete('$_base/$groupId/collectors/$collectorId');

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

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }
}
