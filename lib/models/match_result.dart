import 'collector_match.dart';

/// Contains the results of matching data against collectors, including
/// matched items, processing timestamp, and any errors that occurred.
class MatchResult {
  final List<CollectorMatch> matches;
  final DateTime processedAt;
  final String? error;

  MatchResult({
    required this.matches,
    DateTime? processedAt,
    this.error,
  }) : processedAt = processedAt ?? DateTime.now();

  bool get hasMatches => matches.isNotEmpty;
  bool get hasError => error != null;

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    List<CollectorMatch> matches = [];

    if (json['matches'] is List) {
      matches = (json['matches'] as List)
          .map((item) =>
              CollectorMatch.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return MatchResult(
      matches: matches,
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matches': matches.map((m) => m.toJson()).toList(),
      'processedAt': processedAt.toIso8601String(),
      if (error != null) 'error': error,
    };
  }
}
