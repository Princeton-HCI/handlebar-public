import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../models/crepe_event.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_store.dart';

typedef CrepeEventSendResult = Result<bool, ApiError>;

/// Handles [CrepeEvent] data operations
class CrepeEventRepository {
  final ApiClient _api;
  final AuthTokenStore _tokens;
  final _logger = Logger('CrepeEventRepository');

  CrepeEventRepository(this._api, this._tokens);

  Future<CrepeEventSendResult> send(CrepeEvent event) async {
    try {
      _logger.info('Starting send request...');
      if (!_tokens.isAuthenticated) {
        // Check locally first since this runs in the background
        return ApiClient.unauthorizedFailure(_logger, action: 'send');
      }

      final res = await _api.post('/api/crepe/event', body: event.toJson());

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger, action: 'send');
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logger.info('send successful');
        return const Success(true);
      }

      return ApiClient.unhandledFailure(_logger, res, action: 'send');
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: 'send');
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: 'send');
    }
  }
}
