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

  static const String base = '/api/research';

  ResearchGroupMembershipRepository(this._api);

  Future<MembersResult> listResearchGroupMembers(int groupId) async {
    try {
      _logger.info('Starting listResearchGroupMembers($groupId) request...');
      final res = await _api.get('$base/groups/$groupId/members');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final rows = (map['data'] as List).cast<Map<String, dynamic>>();
        final members = rows.map(ResearchGroupMember.fromJson).toList();
        _logger.info('listResearchGroupMembers successful');
        return Success(members);
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'listResearchGroupMembers',
        );
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(_logger,
            action: 'listResearchGroupMembers');
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'listResearchGroupMembers');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: 'listResearchGroupMembers');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'listResearchGroupMembers');
    }
  }

  Future<BoolResult> addResearcherByEmail(int groupId, String email) async {
    try {
      _logger.info('Starting addResearcherByEmail($groupId) request...');
      final res = await _api.post(
        '$base/groups/$groupId/members',
        body: {'email': email},
      );

      if (res.statusCode == 201) {
        _logger.info('addResearcherByEmail successful');
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg =
            'User must create an account first before being added as a researcher';
        _logger.warning('addResearcherByEmail 404 - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (res.statusCode == 409) {
        final msg = 'User is already enrolled in this group';
        _logger.warning('addResearcherByEmail 409 - $msg');
        return Failure(ApiError(message: msg, statusCode: 409));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'addResearcherByEmail',
        );
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(
          _logger,
          action: 'addResearcherByEmail',
        );
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'addResearcherByEmail');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: 'addResearcherByEmail');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'addResearcherByEmail');
    }
  }

  Future<BoolResult> kick(int groupId, int membershipId) async {
    try {
      _logger.info('Starting kick($groupId, $membershipId) request...');
      final res =
          await _api.delete('$base/groups/$groupId/members/$membershipId');

      if (res.statusCode == 204) {
        _logger.info('kick successful');
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg = 'User not found';
        _logger.warning('kick 404 - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (res.statusCode == 409) {
        final msg = 'You cannot kick yourself';
        _logger.warning('kick 409 - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'kick',
        );
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(
          _logger,
          action: 'kick',
        );
      }

      return ApiClient.unhandledFailure(_logger, res, action: 'kick');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: 'kick');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: 'kick');
    }
  }

  Future<Result<int, ApiError>> lookupGroupIdByCode(String code) async {
    try {
      _logger.info('Starting lookupGroupIdByCode($code) request...');
      final res = await _api.get('$base/groups/lookup/$code');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final id = (map['data'] as Map<String, dynamic>)['id'] as int;
        _logger.info('lookupGroupIdByCode successful');
        return Success(id);
      }

      if (res.statusCode == 404) {
        final msg = 'Group not found';
        _logger.warning('lookupGroupIdByCode failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'lookupGroupIdByCode',
        );
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'lookupGroupIdByCode');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: 'lookupGroupIdByCode');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'lookupGroupIdByCode');
    }
  }

  Future<BoolResult> joinByCode(String code) async {
    try {
      _logger.info('Starting joinByCode($code) request...');
      final res =
          await _api.post('$base/memberships/join', body: {'code': code});

      if (res.statusCode == 201) {
        _logger.info('joinByCode successful');
        return const Success(true);
      }

      if (res.statusCode == 409) {
        final msg = 'Already a member';
        _logger.warning('joinByCode failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 409));
      }

      if (res.statusCode == 404) {
        final msg = 'Group not found';
        _logger.warning('joinByCode failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'joinByCode',
        );
      }

      return ApiClient.unhandledFailure(_logger, res, action: 'joinByCode');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: 'joinByCode');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: 'joinByCode');
    }
  }

  Future<BoolResult> updateMembership({
    required int membershipId,
    required String retentionPref,
  }) async {
    try {
      _logger.info('Starting updateMembership($membershipId) request...');
      final res = await _api.patch(
        '/api/research/memberships/$membershipId',
        body: {
          'membership': {
            'retention_pref_on_unenroll': retentionPref,
          }
        },
      );

      if (res.statusCode == 200) {
        _logger.info('updateMembership successful');
        return const Success(true);
      }

      if (ApiClient.isForbidden(res)) {
        return ApiClient.forbiddenFailure(
          _logger,
          action: 'updateMembership',
        );
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger,
            action: 'updateMembership');
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: 'updateMembership');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: 'updateMembership');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: 'updateMembership');
    }
  }

  Future<BoolResult> leave(int membershipId) async {
    try {
      _logger.info('Starting leave($membershipId) request...');
      final res = await _api.delete('$base/memberships/$membershipId');

      if (res.statusCode == 204) {
        _logger.info('leave successful');
        return const Success(true);
      }

      if (res.statusCode == 404) {
        final msg = 'Membership not found';
        _logger.warning('leave failed - $msg');
        return Failure(ApiError(message: msg, statusCode: 404));
      }

      if (res.statusCode == 409) {
        final msg =
            'You are the final researcher of this group. If you intend to leave, delete the group instead.';
        _logger.warning('leave 409 - $msg');
        return Failure(ApiError(message: msg, statusCode: 409));
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(
          _logger,
          action: 'leave',
        );
      }

      return ApiClient.unhandledFailure(_logger, res, action: 'leave');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: 'leave');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: 'leave');
    }
  }
}
