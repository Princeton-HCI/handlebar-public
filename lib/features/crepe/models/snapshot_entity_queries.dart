import 'crepe_event_values.dart';

/// Represents the graph queries generated for a [Snapshot]
class SnapshotEntityQueries {
  /// All generated queries (each elem contains 'query', 'score', and 'extractedValue')
  final List<SnapshotQuery> queries;

  /// Index of the best query in [queries], or -1 if none.
  final int bestQueryIndex;

  const SnapshotEntityQueries({
    required this.queries,
    required this.bestQueryIndex,
  });

  SnapshotQuery? get bestQuery {
    if (bestQueryIndex < 0 || bestQueryIndex >= queries.length) {
      return null;
    }
    return queries[bestQueryIndex];
  }

  /// Builds [SnapshotEntityQueries] from a JSON map exported by the Crepe plugin
  factory SnapshotEntityQueries.fromJson(Map<String, dynamic> json) {
    final queriesList = json['queries'] as List<dynamic>? ?? [];

    return SnapshotEntityQueries(
      queries: queriesList.map((qs) {
        // Coerce received maps into proper types
        final typedMap = Map<String, dynamic>.from(qs as Map);
        typedMap['crepeEventValues'] = typedMap['crepeEventValues'] != null
            ? Map<String, dynamic>.from(typedMap['crepeEventValues'] as Map)
            : <String, dynamic>{};
        ;

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
  final String description;
  final CrepeEventValues crepeEventValues;

  const SnapshotQuery(
      {required this.query,
      required this.score,
      required this.description,
      required this.crepeEventValues});

  factory SnapshotQuery.fromJson(Map<String, dynamic> json) {
    return SnapshotQuery(
        query: json['query'] as String,
        score: (json['score'] as num).toDouble(),
        description: json['description'] ?? json['query'],
        crepeEventValues: CrepeEventValues.fromJson(json['crepeEventValues']));
  }

  SnapshotQuery copyWith({
    String? query,
    double? score,
    String? description,
    CrepeEventValues? crepeEventValues,
  }) {
    return SnapshotQuery(
      query: query ?? this.query,
      score: score ?? this.score,
      description: description ?? this.description,
      crepeEventValues: crepeEventValues ?? this.crepeEventValues,
    );
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

class LlmQuerySelection {
  final Map<int, String> descriptions;
  final int bestIndex;

  const LlmQuerySelection({
    required this.descriptions,
    required this.bestIndex,
  });

  factory LlmQuerySelection.fromJson(Map<String, dynamic> json) {
    final rawDescriptions =
        Map<String, dynamic>.from(json['descriptions'] as Map? ?? const {});

    return LlmQuerySelection(
      descriptions: rawDescriptions.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? -1,
          value?.toString() ?? '',
        ),
      )..remove(-1),
      bestIndex: (json['best_index'] as num?)?.toInt() ?? -1,
    );
  }
}
