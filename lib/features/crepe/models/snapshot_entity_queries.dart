/// Represents the graph queries generated for a [Snapshot]
class SnapshotEntityQueries {
  /// All generated queries
  final List<String> allQueries;

  /// Index of the best query in [allQueries], or -1 if none.
  final int bestQueryIndex;

  const SnapshotEntityQueries({
    required this.allQueries,
    required this.bestQueryIndex,
  });

  String? get bestQuery {
    if (bestQueryIndex < 0 || bestQueryIndex >= allQueries.length) {
      return null;
    }
    return allQueries[bestQueryIndex];
  }

  /// Builds [SnapshotEntityQueries] from a JSON map exported by the Crepe plugin
  factory SnapshotEntityQueries.fromJson(Map<String, dynamic> json) {
    final allQueriesList = json['allQueries'] as List<dynamic>? ?? [];

    return SnapshotEntityQueries(
      // NOTE: we're getting rid of the 'score' part of 'qs' since we
      // don't care about displaying it at this moment
      allQueries: allQueriesList
          .map((qs) => Map<String, dynamic>.from(qs)['query'] as String)
          .toList(),
      bestQueryIndex: json['bestQueryIndex'] as int? ?? -1,
    );
  }
}
