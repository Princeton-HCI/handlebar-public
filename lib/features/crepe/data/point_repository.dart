import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/paginated_result.dart';
import '../../../core/utils/result.dart';
import '../models/location_point.dart';

typedef LocationPointsPageResult
    = Result<PaginatedResult<LocationPoint>, ApiError>;

/// Reads study-attributed location points. Writes go through the native upload
/// path, not this repository.
class PointRepository {
  final ApiClient _api;
  final _logger = Logger('PointRepository');

  static const String _base = '/api/research';

  PointRepository(this._api);

  /// The caller's own points, optionally narrowed to one study.
  Future<LocationPointsPageResult> listParticipantPoints({
    int? groupId,
    String? cursor,
    int limit = 30,
  }) async {
    const action = 'listParticipantPoints';
    try {
      _logger.info('Starting $action request...');
      final query = ApiClient.buildPaginationParams(cursor, limit);
      if (groupId != null) query['group_id'] = groupId.toString();

      final res = await _api.get(
        '$_base/me/points',
        queryParameters: query.isEmpty ? null : query,
      );
      return _parseListResponse(res, action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  /// Every participant's points for a study. Researcher only.
  Future<LocationPointsPageResult> listResearcherPointsForGroup(
    int groupId, {
    String? cursor,
    int limit = 30,
  }) async {
    const action = 'listResearcherPointsForGroup';
    try {
      _logger.info('Starting $action request...');
      final query = ApiClient.buildPaginationParams(cursor, limit);
      final res = await _api.get(
        '$_base/groups/$groupId/points',
        queryParameters: query.isEmpty ? null : query,
      );
      return _parseListResponse(res, action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  LocationPointsPageResult _parseListResponse(
      http.Response res, String action) {
    if (res.statusCode == 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final page =
          PaginatedResult<LocationPoint>.fromJson(map, LocationPoint.fromJson);
      _logger.info('$action successful');
      return Success(page);
    }

    if (ApiClient.isForbidden(res)) {
      return ApiClient.forbiddenFailure(_logger, action: action);
    }
    if (ApiClient.isUnauthorized(res)) {
      return ApiClient.unauthorizedFailure(_logger, action: action);
    }
    return ApiClient.unhandledFailure(_logger, res, action: action);
  }
}
