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
      _logger.info('Sending CrepeEvent...');
      if (!_tokens.isAuthenticated) {
        _logger.info('CrepeEvent send blocked - not authenticated');
        return Failure(ApiError(message: 'User not authenticated'));
      }

      final res = await _api.post('/api/crepe/event', body: event.toJson());

      if (ApiClient.isUnauthorized(res)) {
        _logger.info('CrepeEvent send failed - unauthorized (401)');
        await _tokens.clearAuthToken();
        return Failure(ApiError(
          message: 'Your session has expired. Please log in again.',
          statusCode: 401,
        ));
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logger.info('CrepeEvent sent successfully');
        return const Success(true);
      }

      // Unhandled response
      final msg = ApiClient.errorMessage(res);
      _logger.severe('CrepeEvent send failed - $msg');
      return Failure(ApiError(message: msg, statusCode: res.statusCode));
    } on ApiException catch (e) {
      _logger.severe("CrepeEvent send failed - ${e.message}");
      return Failure(ApiError(message: e.message));
    } catch (e, st) {
      _logger.severe("CrepeEvent send failed - unexpected: $e", st);
      return const Failure(ApiError(message: "Unexpected error"));
    }
  }
}
