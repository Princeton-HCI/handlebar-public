import 'crepe_event_values.dart';

/// Represents the graph queries generated for a [Snapshot]
class SnapshotEntityQueries {
  /// All generated queries (each elem contains 'query', 'score', and 'extractedValue')
  final List<SnapshotQuery> allQueries;

  /// Index of the best query in [allQueries], or -1 if none.
  final int bestQueryIndex;

  const SnapshotEntityQueries({
    required this.allQueries,
    required this.bestQueryIndex,
  });

  SnapshotQuery? get bestQuery {
    if (bestQueryIndex < 0 || bestQueryIndex >= allQueries.length) {
      return null;
    }
    return allQueries[bestQueryIndex];
  }

  /// Builds [SnapshotEntityQueries] from a JSON map exported by the Crepe plugin
  factory SnapshotEntityQueries.fromJson(Map<String, dynamic> json) {
    final allQueriesList = json['allQueries'] as List<dynamic>? ?? [];

    return SnapshotEntityQueries(
      allQueries: allQueriesList.map((qs) {
        // Coerce received maps into proper types
        final typedMap = Map<String, dynamic>.from(qs as Map);
        typedMap['crepeEventValues'] =
            Map<String, dynamic>.from(typedMap['crepeEventValues'] as Map);

        return SnapshotQuery.fromJson(typedMap);
      }).toList(),
      bestQueryIndex: json['bestQueryIndex'] as int? ?? -1,
    );
  }
}

/// Represents a single graph query generated from a snapshot
class SnapshotQuery {
  final String query;
  final double score;
  final CrepeEventValues crepeEventValues;

  const SnapshotQuery(
      {required this.query,
      required this.score,
      required this.crepeEventValues});

  factory SnapshotQuery.fromJson(Map<String, dynamic> json) {
    return SnapshotQuery(
        query: json['query'] as String,
        score: json['score'] as double,
        crepeEventValues: CrepeEventValues.fromJson(json['crepeEventValues']));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapshotQuery &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          score == other.score;

  @override
  int get hashCode => Object.hash(query, score);
}
