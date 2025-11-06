import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../models/terms.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_token_store.dart';

typedef TermsResult = Result<Terms, ApiError>;
typedef AcceptResult = Result<bool, ApiError>;

/// Handles study participation terms data operations
class TermsRepository {
  final ApiClient _api;
  final AuthTokenStore _tokens;

  final _logger = Logger("TermsRepository");

  TermsRepository(this._api, this._tokens);

  /// Checks if the user has accepted the most up-to-date terms of use
  Future<TermsResult> checkCurrent() async {
    _logger.info("Starting check current accepted terms request...");
    try {
      if (!_tokens.isAuthenticated) {
        _logger.info("Check current accepted terms failed - not authenticated");
        return Failure(ApiError(message: "User not authenticated"));
      }

      final res = await _api.get('/api/terms/current');

      if (ApiClient.isUnauthorized(res)) {
        _logger.info("Check current accepted terms failed - unauthorized");
        await _tokens.clearAuthToken();
        return Failure(ApiError(
          message: "Your session has expired. Please log in again.",
          statusCode: 401,
        ));
      }

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final termsData = map['data'] as Map<String, dynamic>?;

        final currTerms = termsData?['current_terms'] as Map<String, dynamic>?;
        final currAcceptedTerms =
            termsData?['current_accepted_terms'] as Map<String, dynamic>?;

        final info = Terms(
          hasAcceptedCurrentTerms: currAcceptedTerms != null,
          currentTermsId: currTerms?['id'] as int?,
        );

        _logger.info("Check current accepted terms successful");
        return Success(info);
      }

      final errorMsg = ApiClient.errorMessage(res);
      _logger.severe("Check current accepted terms failed - $errorMsg");
      return Failure(ApiError(
        message: errorMsg,
        statusCode: res.statusCode,
      ));
    } on ApiException catch (e) {
      _logger.severe("Check current accepted terms failed - ${e.message}");
      return Failure(ApiError(message: e.message));
    } catch (e, st) {
      _logger.severe(
          "Check current accepted terms failed - unexpected: $e", st);
      return const Failure(ApiError(message: "Unexpected error"));
    }
  }

  /// Accept the current terms of use
  Future<AcceptResult> accept(int termsId) async {
    try {
      _logger.info("Starting accept terms request...");
      if (!_tokens.isAuthenticated) {
        _logger.info("Accept terms failed - not authenticated");
        return Failure(ApiError(message: "User not authenticated"));
      }

      final res = await _api.post(
        '/api/accepted_terms',
        body: {
          'accepted_terms': {'terms_id': termsId}
        },
      );

      if (ApiClient.isUnauthorized(res)) {
        _logger.info("Accept terms failed - unauthorized");
        await _tokens.clearAuthToken();
        return Failure(ApiError(
          message: "Your session has expired. Please log in again.",
          statusCode: 401,
        ));
      }

      if (res.statusCode == 200 ||
          res.statusCode == 201 ||
          res.statusCode == 422) {
        // 200/201 = accepted now, 422 = already accepted
        _logger.info("Accept terms successful");
        return const Success(true);
      }

      final errorMsg = ApiClient.errorMessage(res);
      _logger.severe("Accept terms failed - $errorMsg");
      return Failure(ApiError(
        message: errorMsg,
        statusCode: res.statusCode,
      ));
    } on ApiException catch (e) {
      _logger.severe("Accept terms failed - ${e.message}");
      return Failure(ApiError(message: e.message));
    } catch (e, st) {
      _logger.severe("Accept terms failed - unexpected: $e", st);
      return const Failure(ApiError(message: "Unexpected error"));
    }
  }
}
