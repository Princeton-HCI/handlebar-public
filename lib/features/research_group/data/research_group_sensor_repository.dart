import 'dart:convert';

import 'package:handlebar/core/network/api_executor.dart';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/result.dart';
import '../../crepe/models/participant_sensor_config.dart';
import '../../crepe/models/sensor_config.dart';

typedef ParticipantSensorsResult
    = Result<List<ParticipantSensorConfig>, ApiError>;
typedef SensorsResult = Result<List<SensorConfig>, ApiError>;
typedef SensorResult = Result<SensorConfig, ApiError>;

/// Researcher and participant access to a study's sensor configs.
/// Contract: SENSORS_API.md. Mirrors [ResearchGroupCollectorRepository].
class ResearchGroupSensorRepository with ApiExecutor {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupSensorRepository');

  static const String _base = '/api/research/groups';

  ResearchGroupSensorRepository(this._api);

  Future<SensorsResult> listGroupSensors(int groupId) async {
    final action = 'listGroupSensors($groupId)';
    return executeRequest<List<SensorConfig>>(
      action: action,
      logger: _logger,
      request: () => _api.get('$_base/$groupId/sensors'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final sensors = (map['data'] as List)
              .map((e) => SensorConfig.fromJson(e as Map<String, dynamic>))
              .toList();
          _logger.info('$action successful');
          return Success(sensors);
        }

        if (res.statusCode == 404) {
          return _notFound(action);
        }
        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  /// Enabled sensors from every study the caller actively participates in.
  Future<ParticipantSensorsResult> listParticipantSensors() async {
    const action = 'listParticipantSensors';
    return executeRequest<List<ParticipantSensorConfig>>(
      action: action,
      logger: _logger,
      request: () => _api.get('/api/research/me/sensors'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final items = (map['data'] as List).cast<List<dynamic>>();
          final sensors = items.map(ParticipantSensorConfig.fromList).toList();
          _logger.info('$action successful');
          return Success(sensors);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<SensorResult> createSensor({
    required int groupId,
    required String type,
    required int sampleIntervalSeconds,
    required SensorTriggerType triggerType,
    String? triggerAppPackage,
    int? triggerCollectorId,
    int? timeoutSeconds,
    bool enabled = true,
  }) async {
    final action = 'createSensor($groupId, $type)';
    return executeRequest<SensorConfig>(
      action: action,
      logger: _logger,
      request: () {
        final body = {
          'sensor': {
            'type': type,
            'enabled': enabled,
            'sample_interval_seconds': sampleIntervalSeconds,
            'trigger_type': triggerType.wire,
            if (triggerAppPackage != null)
              'trigger_app_package': triggerAppPackage,
            if (triggerCollectorId != null)
              'trigger_collector_id': triggerCollectorId,
            // Sent explicitly (null allowed) so "never stop" round-trips.
            'timeout_seconds': timeoutSeconds,
          }
        };
        return _api.post('$_base/$groupId/sensors', body: body);
      },
      onResponse: (res) {
        if (res.statusCode == 201) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final sensor =
              SensorConfig.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(sensor);
        }

        if (res.statusCode == 404) {
          return _notFound(action);
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

  /// Partial update: only keys present in [fields] are sent. Use
  /// `timeout_seconds: null` inside [fields] to clear the timeout.
  Future<SensorResult> updateSensor(
    int groupId,
    int sensorId,
    Map<String, dynamic> fields,
  ) async {
    final action = 'updateSensor($groupId, $sensorId)';
    return executeRequest<SensorConfig>(
      action: action,
      logger: _logger,
      request: () => _api.patch(
        '$_base/$groupId/sensors/$sensorId',
        body: {'sensor': fields},
      ),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final sensor =
              SensorConfig.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(sensor);
        }

        if (res.statusCode == 404) {
          return _notFound(action);
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

  Future<Result<bool, ApiError>> removeSensor(int groupId, int sensorId) async {
    final action = 'removeSensor($groupId, $sensorId)';
    return executeRequest<bool>(
      action: action,
      logger: _logger,
      request: () => _api.delete('$_base/$groupId/sensors/$sensorId'),
      onResponse: (res) {
        if (res.statusCode == 204) {
          _logger.info('$action successful');
          return const Success(true);
        }

        if (res.statusCode == 404) {
          return _notFound(action);
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

  Failure<T, ApiError> _notFound<T>(String action) {
    const msg = 'Sensor not found';
    _logger.warning('$action failed - $msg');
    return const Failure(ApiError(message: msg, statusCode: 404));
  }
}
