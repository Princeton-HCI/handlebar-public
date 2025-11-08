import 'dart:convert';

import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../../crepe/models/active_collectors.dart';
import '../../crepe/models/collector.dart';
import '../../crepe/models/data_field.dart';

typedef ActiveCollectorsResult = Result<ActiveCollectors, ApiError>;
typedef CollectorsResult = Result<List<Collector>, ApiError>;
typedef BoolResult = Result<bool, ApiError>;

class ResearchGroupCollectorRepository {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupCollectorRepository');

  static const String base = '/api/research/groups';

  ResearchGroupCollectorRepository(this._api);

  Future<CollectorsResult> listGroupCollectors(int groupId) async {
    try {
      _logger.info("Starting listGroupCollectors($groupId) request...");
      final res = await _api.get('$base/$groupId/collectors');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is List) {
          final collectors = data
              .map((e) => Collector.fromJson(e as Map<String, dynamic>))
              .toList();
          _logger.info("listGroupCollectors successful");
          return Success(collectors);
        }

        _logger.severe('Invalid response format - data is not a list');
        return const Failure(
            ApiError(message: 'Invalid response format from server'));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'listGroupCollectors',
        );
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'listGroupCollectors');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: 'listGroupCollectors');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'listGroupCollectors');
    }
  }

  Future<ActiveCollectorsResult> listParticipantCollectors() async {
    try {
      _logger.info("Starting listParticipantCollectors request...");
      final res = await _api.get('/api/research/me/collectors');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is List) {
          final collectors = data
              .map((e) => Collector.fromJson(e as Map<String, dynamic>))
              .toList();
          _logger.info("listParticipantCollectors successful");
          return Success(ActiveCollectors(collectors: collectors));
        }

        _logger.severe('Invalid response format - data is not a list');
        return const Failure(
            ApiError(message: 'Invalid response format from server'));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'listParticipantCollectors',
        );
      }

      return ApiClient.unhandledFailure(
        _logger,
        res,
        action: 'listParticipantCollectors',
      );
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(
        _logger,
        e,
        action: 'listParticipantCollectors',
      );
    } catch (e, st) {
      return ApiClient.unexpectedFailure(
        _logger,
        e,
        st,
        action: 'listParticipantCollectors',
      );
    }
  }

  Future<BoolResult> createCollectorAndAttach({
    required int groupId,
    required String appName,
    required String appPackage,
    String? description,
    required List<DataField> dataFields,
  }) async {
    try {
      _logger.info("Starting createCollectorAndAttach($groupId) request...");
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

      final res = await _api.post('$base/$groupId/collectors', body: body);

      if (res.statusCode == 201) {
        _logger.info("createCollectorAndAttach successful");
        return const Success(true);
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger,
            action: 'createCollectorAndAttach');
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(_logger,
            action: 'createCollectorAndAttach');
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'createCollectorAndAttach');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: 'createCollectorAndAttach');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'createCollectorAndAttach');
    }
  }

  Future<BoolResult> removeCollector(int groupId, int collectorId) async {
    try {
      _logger
          .info("Starting removeCollector($groupId, $collectorId) request...");
      final res = await _api.delete('$base/$groupId/collectors/$collectorId');

      if (res.statusCode == 204) {
        _logger.info("removeCollector successful");
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg = 'Collector not found';
        _logger.warning('removeCollector failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger,
            action: 'removeCollector');
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(_logger, action: 'removeCollector');
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'removeCollector');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: 'removeCollector');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'removeCollector');
    }
  }
}
