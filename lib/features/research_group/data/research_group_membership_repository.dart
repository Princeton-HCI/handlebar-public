import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../models/research_group_member.dart';

typedef MembersResult = Result<List<ResearchGroupMember>, ApiError>;
typedef BoolResult = Result<bool, ApiError>;

class ResearchGroupMembershipRepository {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupMembershipRepository');

  static const String _base = '/api/research';

  ResearchGroupMembershipRepository(this._api);

  Future<MembersResult> listResearchGroupMembers(int groupId) async {
    final action = 'listResearchGroupMembers($groupId)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.get('$_base/groups/$groupId/members');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final rows = (map['data'] as List).cast<Map<String, dynamic>>();
        final members = rows.map(ResearchGroupMember.fromJson).toList();
        _logger.info('$action successful');
        return Success(members);
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: action,
        );
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

  Future<BoolResult> addResearcherByEmail(int groupId, String email) async {
    final action = 'addResearcherByEmail($groupId)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.post(
        '$_base/groups/$groupId/members',
        body: {'email': email},
      );

      if (res.statusCode == 201) {
        _logger.info('$action successful');
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg =
            'User must create an account first before being added as a researcher';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (res.statusCode == 409) {
        final msg = 'User is already enrolled in this group';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 409));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: action,
        );
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(
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

  Future<BoolResult> kick(int groupId, int membershipId) async {
    final action = 'kick($groupId, $membershipId)';
    try {
      _logger.info('Starting $action request...');
      final res =
          await _api.delete('$_base/groups/$groupId/members/$membershipId');

      if (res.statusCode == 204) {
        _logger.info('$action successful');
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg = 'User not found';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (res.statusCode == 409) {
        final msg = 'You cannot kick yourself';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: action,
        );
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(
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

  Future<Result<int, ApiError>> lookupGroupIdByCode(String code) async {
    final action = 'lookupGroupIdByCode($code)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.get('$_base/groups/lookup/$code');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final id = (map['data'] as Map<String, dynamic>)['id'] as int;
        _logger.info('$action successful');
        return Success(id);
      }

      if (res.statusCode == 404) {
        final msg = 'Group not found';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
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

  Future<BoolResult> joinByCode(String code) async {
    final action = 'joinByCode($code)';
    try {
      _logger.info('Starting $action request...');
      final res =
          await _api.post('$_base/memberships/join', body: {'code': code});

      if (res.statusCode == 201) {
        _logger.info('$action successful');
        return const Success(true);
      }

      if (res.statusCode == 409) {
        final msg = 'Already a member';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 409));
      }

      if (res.statusCode == 404) {
        final msg = 'Group not found';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
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

  Future<BoolResult> updateMembership({
    required int membershipId,
    required String retentionPref,
  }) async {
    final action = 'updateMembership($membershipId)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.patch(
        '/api/research/memberships/$membershipId',
        body: {
          'membership': {
            'retention_pref_on_unenroll': retentionPref,
          }
        },
      );

      if (res.statusCode == 200) {
        _logger.info('$action successful');
        return const Success(true);
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(
          _logger,
          action: action,
        );
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger, action: action);
      }

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<BoolResult> leave(int membershipId) async {
    final action = 'leave($membershipId)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.delete('$_base/memberships/$membershipId');

      if (res.statusCode == 204) {
        _logger.info('$action successful');
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg = 'Membership not found';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (res.statusCode == 409) {
        final msg =
            'You are the final researcher of this group. If you intend to leave, delete the group instead.';
        _logger.warning('$action failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 409));
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
}
