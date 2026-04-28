import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../core/network/api_error.dart';
import '../../../core/utils/paginated_result.dart';
import '../../../core/utils/result.dart';
import '../models/crepe_event.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_store.dart';

typedef CrepeEventSendResult = Result<bool, ApiError>;
typedef CrepeEventsPageResult = Result<PaginatedResult<CrepeEvent>, ApiError>;

/// Handles [CrepeEvent] data operations
class CrepeEventRepository {
  final ApiClient _api;
  final AuthTokenStore _tokens;
  final _logger = Logger('CrepeEventRepository');

  CrepeEventRepository(this._api, this._tokens);

  static const String _base = '/api/research';

  Future<CrepeEventsPageResult> listParticipantEvents(
      {int? groupId, String? cursor, int limit = 30}) async {
    const String action = 'listParticipantEvents';

    try {
      _logger.info('Starting $action request...');
      final query = ApiClient.buildPaginationParams(cursor, limit);
      if (groupId != null) query['group_id'] = groupId.toString();

      final res = await _api.get(
        '$_base/me/crepe-events',
        queryParameters: query.isEmpty ? null : query,
      );

      return _parseListResponse(res, action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<CrepeEventsPageResult> listResearcherEventsForGroup(int groupId,
      {String? cursor, int limit = 30}) async {
    const String action = 'listResearcherEventsForGroup';
    try {
      final query = ApiClient.buildPaginationParams(cursor, limit);
      final res = await _api.get('$_base/groups/$groupId/crepe-events',
          queryParameters: query.isEmpty ? null : query);

      return _parseListResponse(res, action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<CrepeEventsPageResult> listResearcherEventsForParticipant({
    required int groupId,
    required int membershipId,
    String? cursor,
    int limit = 30,
  }) async {
    const String action = 'listResearcherEventsForParticipant';

    try {
      _logger.info('Starting $action($groupId, $membershipId) request...');

      final query = ApiClient.buildPaginationParams(cursor, limit);
      final res = await _api.get(
        '$_base/groups/$groupId/members/$membershipId/crepe-events',
        queryParameters: query.isEmpty ? null : query,
      );

      if (res.statusCode == 404) {
        final msg = 'Membership not found';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      return _parseListResponse(res, action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  CrepeEventsPageResult _parseListResponse(http.Response res, String action) {
    if (res.statusCode == 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;

      final page =
          PaginatedResult<CrepeEvent>.fromJson(map, CrepeEvent.fromJson);

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

  /// Sends a Crepe event to the backend (Participant)
  Future<CrepeEventSendResult> send(CrepeEvent event) async {
    const String action = 'send';
    try {
      _logger.info('Starting $action request...');
      // Check auth locally first since this runs in the background
      if (!_tokens.isAuthenticated) {
        return ApiClient.unauthorizedFailure(_logger, action: action);
      }

      final res = await _api.post(
        '$_base/memberships/${event.membershipId}/crepe-events',
        body: {'crepe_event': event.toJson()},
      );

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger, action: action);
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logger.info('$action  successful');
        return const Success(true);
      }

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }
}
