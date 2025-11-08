import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../models/terms.dart';
import '../../../core/network/api_client.dart';

typedef TermsResult = Result<Terms, ApiError>;
typedef AcceptResult = Result<bool, ApiError>;

/// Handles study participation terms data operations
class TermsRepository {
  final ApiClient _api;

  final _logger = Logger("TermsRepository");

  TermsRepository(this._api);

  /// Checks if the user has accepted the most up-to-date terms of use
  Future<TermsResult> checkCurrentTerms() async {
    _logger.info("Starting checkCurrentTerms request...");
    try {
      final res = await _api.get('/api/terms/current');

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

        _logger.info("checkCurrentTerms successful");
        return Success(info);
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger,
            action: 'checkCurrentTerms');
      }

      return ApiClient.unhandledFailure(_logger, res,
          action: "checkCurrentTerms");
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e,
          action: "checkCurrentTerms");
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st,
          action: "checkCurrentTerms");
    }
  }

  /// Accept the current terms of use
  Future<AcceptResult> acceptTerms(int termsId) async {
    try {
      _logger.info("Starting acceptTerms request...");

      final res = await _api.post(
        '/api/accepted_terms',
        body: {
          'accepted_terms': {'terms_id': termsId}
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logger.info("acceptTerms successful");
        return const Success(true);
      }

      if (ApiClient.isUnauthorized(res)) {
        return ApiClient.unauthorizedFailure(_logger,
            action: 'checkCurrentTerms');
      }

      return ApiClient.unhandledFailure(_logger, res, action: "acceptTerms");
    } on ApiException catch (e) {
      return ApiClient.connectionFailure(_logger, e, action: "acceptTerms");
    } catch (e, st) {
      return ApiClient.unexpectedFailure(_logger, e, st, action: "acceptTerms");
    }
  }
}
