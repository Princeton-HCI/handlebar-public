import 'dart:convert';
import 'package:handlebar/core/network/api_executor.dart';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/result.dart';
import '../../study/data/models/research_study.dart';

typedef GroupsResult = Result<List<ResearchStudy>, ApiError>;
typedef GroupResult = Result<ResearchStudy, ApiError>;
typedef BoolResult = Result<bool, ApiError>;

class ResearchGroupRepository with ApiExecutor {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupRepository');

  static const String _base = '/api/research/groups';

  ResearchGroupRepository(this._api);

  Future<GroupsResult> listUserResearchGroups() async {
    final action = 'listUserResearchGroups';
    return executeRequest<List<ResearchStudy>>(
      action: action,
      logger: _logger,
      request: () => _api.get(_base),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final items = (map['data'] as List).cast<Map<String, dynamic>>();
          final groups = items.map(ResearchStudy.fromJson).toList();
          _logger.info('$action successful');
          return Success(groups);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<GroupResult> lookupByCode(String code) async {
    final action = 'lookupByCode';
    return executeRequest<ResearchStudy>(
      action: action,
      logger: _logger,
      request: () => _api.get('$_base/lookup/$code'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final group =
              ResearchStudy.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(group);
        }

        if (res.statusCode == 404) {
          final msg = 'Group not found';
          _logger.warning('$action failed - $msg');
          return Failure(ApiError(message: msg, statusCode: 404));
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<BoolResult> joinByCode(String code) async {
    final action = 'joinByCode($code)';
    return executeRequest<bool>(
      action: action,
      logger: _logger,
      request: () => _api.post('$_base/memberships/join', body: {'code': code}),
      onResponse: (res) {
        if (res.statusCode == 201) {
          _logger.info('$action successful');
          return const Success(true);
        }

        if (res.statusCode == 404) {
          final msg = 'Group not found';
          _logger.warning('$action failed - $msg');
          return Failure(ApiError(message: msg, statusCode: 404));
        }

        if (res.statusCode == 409) {
          final msg = 'Already a member';
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

  Future<GroupResult> create(
      {required String name, required String description}) async {
    final action = 'create($name)';
    return executeRequest<ResearchStudy>(
      action: action,
      logger: _logger,
      request: () => _api.post(_base, body: {
        'research_group': {
          'name': name,
          'description': description,
        },
      }),
      onResponse: (res) {
        if (res.statusCode == 201) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final group =
              ResearchStudy.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(group);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(_logger, action: action);
        }

        return null;
      },
    );
  }

  Future<GroupResult> update(int id,
      {String? name, String? description}) async {
    final action = 'update($id)';
    return executeRequest<ResearchStudy>(
      action: action,
      logger: _logger,
      request: () {
        final attrs = <String, dynamic>{};
        if (name != null) attrs['name'] = name;
        if (description != null) attrs['description'] = description;
        return _api.patch('$_base/$id', body: {'research_group': attrs});
      },
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final group =
              ResearchStudy.fromJson(map['data'] as Map<String, dynamic>);
          _logger.info('$action successful');
          return Success(group);
        }

        if (res.statusCode == 404) {
          final msg = 'Group not found';
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

  Future<BoolResult> delete(int id) async {
    final action = 'delete($id)';
    return executeRequest<bool>(
      action: action,
      logger: _logger,
      request: () => _api.delete('$_base/$id'),
      onResponse: (res) {
        if (res.statusCode == 204) {
          _logger.info('delete successful');
          return const Success(true);
        }

        if (res.statusCode == 404) {
          final msg = 'Group not found';
          _logger.warning('$action failed - $msg');
          return Failure(ApiError(message: msg, statusCode: 404));
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
}
