import 'dart:convert';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_executor.dart';
import '../../../core/utils/result.dart';
import '../models/accepted_terms.dart';
import '../models/current_terms_response.dart';

typedef CurrentTermsResult = Result<CurrentTermsResponse, ApiError>;
typedef AcceptTermsResult = Result<AcceptedTerms, ApiError>;

class TermsRepository with ApiExecutor {
  final ApiClient _api;
  final _logger = Logger('TermsRepository');

  TermsRepository(this._api);

  Future<CurrentTermsResult> checkCurrentTerms() async {
    return executeRequest<CurrentTermsResponse>(
      action: 'checkCurrentTerms',
      logger: _logger,
      request: () => _api.get('/api/terms/current'),
      onResponse: (res) {
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final response = CurrentTermsResponse.fromJson(map);

          _logger.info('checkCurrentTerms successful');
          return Success(response);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(
            _logger,
            action: 'checkCurrentTerms',
          );
        }

        return null;
      },
    );
  }

  Future<AcceptTermsResult> acceptTerms(int termsId) async {
    return executeRequest<AcceptedTerms>(
      action: 'acceptTerms',
      logger: _logger,
      request: () => _api.post(
        '/api/accepted_terms',
        body: {
          'accepted_terms': {'terms_id': termsId},
        },
      ),
      onResponse: (res) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          final data = map['data'] as Map<String, dynamic>;
          final acceptedTerms = AcceptedTerms.fromJson(data);

          _logger.info('acceptTerms successful');
          return Success(acceptedTerms);
        }

        if (ApiClient.isUnauthorized(res)) {
          return ApiClient.unauthorizedFailure(
            _logger,
            action: 'acceptTerms',
          );
        }

        return null;
      },
    );
  }
}
