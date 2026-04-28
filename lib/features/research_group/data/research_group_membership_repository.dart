import 'dart:convert';
import 'package:handlebar/core/network/api_executor.dart';
import 'package:handlebar/features/study/data/models/research_study_member.dart';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/result.dart';

typedef MemberResult = Result<ResearchStudyMember, ApiError>;
typedef MembersResult = Result<List<ResearchStudyMember>, ApiError>;
typedef BoolResult = Result<bool, ApiError>;

class ResearchGroupMembershipRepository with ApiExecutor {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupMembershipRepository');

  static const String _base = '/api/research';

  ResearchGroupMembershipRepository(this._api);

  Future<MembersResult> listResearchGroupMembers(int groupId) async {
    final action = 'listResearchGroupMembers($groupId)';
    return executeRequest<List<ResearchStudyMember>>(
      action: action,
      logger: _logger,
      request: () => _api.get('$_base/groups/$groupId/members'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final rows = (map['data'] as List).cast<Map<String, dynamic>>();
          final members = rows.map(ResearchStudyMember.fromJson).toList();
          _logger.info('$action successful');
          return Success(members);
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

  Future<MemberResult> getMyMembership(int groupId) async {
    final action = 'getMyMembership($groupId)';
    return executeRequest<ResearchStudyMember>(
      action: action,
      logger: _logger,
      request: () => _api.get('$_base/groups/$groupId/membership'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final membership =
              ResearchStudyMember.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(membership);
        }

        return null;
      },
    );
  }

  Future<MemberResult> addResearcherByEmail(int groupId, String email) async {
    final action = 'addResearcherByEmail($groupId)';
    return executeRequest<ResearchStudyMember>(
      action: action,
      logger: _logger,
      request: () =>
          _api.post('$_base/groups/$groupId/members', body: {'email': email}),
      onResponse: (res) {
        if (res.statusCode == 201) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final member = ResearchStudyMember.fromJson(map);
          _logger.info('$action successful');
          return Success(member);
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
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }
        if (ApiClient.isForbidden(res)) {
          return ApiClient.forbiddenFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<BoolResult> kick(int groupId, int membershipId) async {
    final action = 'kick($groupId, $membershipId)';
    return executeRequest<bool>(
      action: action,
      logger: _logger,
      request: () =>
          _api.delete('$_base/groups/$groupId/members/$membershipId'),
      onResponse: (res) {
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
          return Failure(ApiError(message: msg, statusCode: 409));
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

  Future<MemberResult> updateMembership({
    required int membershipId,
    required String retentionPref,
  }) async {
    final action = 'updateMembership($membershipId)';
    return executeRequest<ResearchStudyMember>(
      action: action,
      logger: _logger,
      request: () => _api.patch(
        '/api/research/memberships/$membershipId',
        body: {
          'membership': {'retention_pref_on_unenroll': retentionPref}
        },
      ),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final updatedMembership =
              ResearchStudyMember.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(updatedMembership);
        }

        if (ApiClient.isForbidden(res)) {
          return ApiClient.forbiddenFailure(_logger, action: action);
        }
        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<BoolResult> leave(int membershipId) async {
    final action = 'leave($membershipId)';
    return executeRequest<bool>(
      action: action,
      logger: _logger,
      request: () => _api.delete('$_base/memberships/$membershipId'),
      onResponse: (res) {
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
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }
}
