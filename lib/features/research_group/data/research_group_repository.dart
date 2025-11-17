import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';
import '../models/research_group.dart';

typedef GroupsResult = Result<List<ResearchGroup>, ApiError>;
typedef GroupResult = Result<ResearchGroup, ApiError>;
typedef GroupDeleteResult = Result<bool, ApiError>;

class ResearchGroupRepository {
  final ApiClient _api;
  final _logger = Logger('ResearchGroupRepository');

  static const String _base = '/api/research/groups';

  ResearchGroupRepository(this._api);

  Future<GroupsResult> listUserResearchGroups() async {
    final action = 'listUserResearchGroups';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.get(_base);

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (map['data'] as List).cast<Map<String, dynamic>>();
        final groups = items.map(ResearchGroup.fromJson).toList();
        _logger.info('$action successful');
        return Success(groups);
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

  Future<GroupResult> getById(int id) async {
    final action = 'getById($id)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.get('$_base/$id');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final group =
            ResearchGroup.fromJson(map['data'] as Map<String, dynamic>);
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

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<GroupResult> create(
      {required String name, required String description}) async {
    final action = 'create($name)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.post(_base, body: {
        'research_group': {
          'name': name,
          'description': description,
        },
      });

      if (res.statusCode == 201) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final group =
            ResearchGroup.fromJson(map['data'] as Map<String, dynamic>);
        _logger.info('$action successful');
        return Success(group);
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

  Future<GroupResult> update(int id,
      {String? name, String? description}) async {
    final action = 'update($id)';
    try {
      _logger.info('Starting $action request');
      final attrs = <String, dynamic>{};
      if (name != null) attrs['name'] = name;
      if (description != null) attrs['description'] = description;

      final res =
          await _api.patch('$_base/$id', body: {'research_group': attrs});

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final group =
            ResearchGroup.fromJson(map['data'] as Map<String, dynamic>);
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

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }

  Future<GroupDeleteResult> delete(int id) async {
    final action = 'delete($id)';
    try {
      _logger.info('Starting $action request...');
      final res = await _api.delete('$_base/$id');

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

      return ApiClient.unhandledFailure(_logger, res, action: action);
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: action);
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: action);
    }
  }
}
