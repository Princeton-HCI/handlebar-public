import 'package:handlebar/features/terms/models/terms.dart';

/// Represents a user's acceptance of terms record
class AcceptedTerms {
  final int id;
  final DateTime? acceptedAt;
  final int? termsId;
  final Terms? terms;

  AcceptedTerms({
    required this.id,
    required this.acceptedAt,
    this.termsId,
    this.terms,
  });

  factory AcceptedTerms.fromJson(Map<String, dynamic> json) {
    return AcceptedTerms(
      id: json['id'] as int,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      termsId: json['terms_id'] as int?,
      terms: json['terms'] != null
          ? Terms.fromJson(json['terms'] as Map<String, dynamic>)
          : null,
    );
  }
}
