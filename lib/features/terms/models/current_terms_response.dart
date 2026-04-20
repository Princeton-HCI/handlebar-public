import 'package:handlebar/features/terms/models/terms.dart';

import 'accepted_terms.dart';

/// Represents the full state of terms for the current user.
class CurrentTermsResponse {
  final Terms? currentTerms;
  final AcceptedTerms? currentAcceptedTerms;
  final Terms? futureTerms;
  final AcceptedTerms? futureAcceptedTerms;

  CurrentTermsResponse({
    required this.currentTerms,
    required this.currentAcceptedTerms,
    required this.futureTerms,
    required this.futureAcceptedTerms,
  });

  factory CurrentTermsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return CurrentTermsResponse(
      currentTerms: data['current_terms'] != null
          ? Terms.fromJson(data['current_terms'] as Map<String, dynamic>)
          : null,
      currentAcceptedTerms: data['current_accepted_terms'] != null
          ? AcceptedTerms.fromJson(
              data['current_accepted_terms'] as Map<String, dynamic>,
            )
          : null,
      futureTerms: data['future_terms'] != null
          ? Terms.fromJson(data['future_terms'] as Map<String, dynamic>)
          : null,
      futureAcceptedTerms: data['future_accepted_terms'] != null
          ? AcceptedTerms.fromJson(
              data['future_accepted_terms'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
