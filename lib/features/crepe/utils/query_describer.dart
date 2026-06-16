/// Why a query was moved out of the primary suggestions list.
enum QueryExclusionReason {
  screenOrLocation,
  highScore,
  fragileDynamicText,
  redundantBareSemantic,
}

/// One plugin query kept off the main list, with a reason.
class FilteredOutQuery<T> {
  final T item;
  final QueryExclusionReason reason;

  const FilteredOutQuery({required this.item, required this.reason});
}

/// Suggested queries plus those filtered out (still selectable in UI).
class QueryDisplayPartition<T> {
  final List<T> suggested;
  final List<FilteredOutQuery<T>> excluded;

  const QueryDisplayPartition({
    required this.suggested,
    required this.excluded,
  });
}

/// Produces human-readable descriptions of graph query S-expressions.
///
/// These queries look like:
/// ```
/// (conj (HAS_PACKAGE_NAME "com.app") (exists numeric_price) (RIGHT (conj (hasText "Guaranteed"))))
/// ```
///
/// The describer extracts the key predicates and produces labels like:
/// "Matches price values to the right of 'Guaranteed'"
class QueryDescriber {
  const QueryDescriber._();

  /// Returns a short, human-readable description of what [query] matches.
  static String describe(String query) {
    final parts = <String>[];

    // What type of content does it match?
    final contentType = _extractContentType(query);
    if (contentType != null) {
      parts.add('Matches $contentType');
    }

    // Spatial anchors
    final anchors = _extractSpatialAnchors(query);
    if (anchors.isNotEmpty) {
      parts.add(anchors.join(', '));
    }

    final labelAnchor = _extractStaticLabelAnchor(query);
    if (labelAnchor != null) {
      parts.add('anchored to label "$labelAnchor"');
    }

    // Exact text match
    if (contentType == null && anchors.isEmpty && labelAnchor == null) {
      final text = _extractExactText(query);
      if (text != null) {
        parts.add('Matches elements with text "$text"');
      }
    }

    if (parts.isEmpty) return 'Custom query';
    return parts.join(' ');
  }

  /// Returns true if this query should never be shown regardless of context.
  static bool isAlwaysExcluded(String query) {
    if (query.contains('SCREEN_HAS_TEXT')) return true;
    if (query.contains('HAS_SCREEN_LOCATION')) return true;
    if (query.contains('HAS_PARENT_LOCATION')) return true;
    return false;
  }

  /// Returns true if a query is an exact-text match on dynamic content
  /// (e.g., `(hasText "3.2 mi")` or `(hasText "$6.35")`).
  /// These are fragile — the text changes every time.
  static bool isExactTextOnDynamicContent(String query, double score) {
    // Score 1.5 is the plugin's marker for "text on dynamic content"
    if (score >= 1.4 && score <= 1.6) return true;
    return false;
  }

  /// Returns true if [query] contains a spatial direction predicate.
  static bool _hasSpatialAnchor(String query) {
    for (final dir in _directionLabels.keys) {
      if (query.contains("($dir ")) return true;
    }
    return false;
  }

  /// Parent/child text anchors (e.g. `HAS_CHILD_TEXT "Avg. wait"`) — not
  /// "bare" semantic; these tie the field to a stable label on screen.
  static bool _hasStaticLabelAnchor(String query) {
    return query.contains('HAS_CHILD_TEXT') || query.contains('HAS_PARENT_TEXT');
  }

  /// Short explanation shown on not-recommended query cards.
  static String exclusionReasonLabel(QueryExclusionReason reason) {
    return switch (reason) {
      QueryExclusionReason.screenOrLocation =>
        'Uses screen or parent position — breaks when layout changes',
      QueryExclusionReason.highScore =>
        'Too broad or position-dependent (high score)',
      QueryExclusionReason.fragileDynamicText =>
        'Exact text on values that change every session',
      QueryExclusionReason.redundantBareSemantic =>
        'Generic semantic-only match — prefer a more specific query above',
    };
  }

  /// Splits queries into suggested vs not-recommended, then sorts by score.
  static QueryDisplayPartition<T> partitionForDisplay<T>({
    required List<T> queries,
    required String Function(T) getQuery,
    required double Function(T) getScore,
    int maxResults = 8,
  }) {
    final suggested = <T>[];
    final excluded = <FilteredOutQuery<T>>[];

    QueryExclusionReason? exclusionReason(String query, double score) {
      if (isAlwaysExcluded(query)) {
        return QueryExclusionReason.screenOrLocation;
      }
      if (score > 3.5) return QueryExclusionReason.highScore;
      if (isExactTextOnDynamicContent(query, score)) {
        return QueryExclusionReason.fragileDynamicText;
      }
      return null;
    }

    for (final q in queries) {
      final query = getQuery(q);
      final reason = exclusionReason(query, getScore(q));
      if (reason != null) {
        excluded.add(FilteredOutQuery(item: q, reason: reason));
      } else {
        suggested.add(q);
      }
    }

    final hasSpatial =
        suggested.any((q) => _hasSpatialAnchor(getQuery(q)));

    if (hasSpatial) {
      final stillSuggested = <T>[];
      for (final q in suggested) {
        final query = getQuery(q);
        if (!_hasSpatialAnchor(query) &&
            !_hasStaticLabelAnchor(query) &&
            query.contains('exists')) {
          excluded.add(FilteredOutQuery(
            item: q,
            reason: QueryExclusionReason.redundantBareSemantic,
          ));
        } else {
          stillSuggested.add(q);
        }
      }
      suggested
        ..clear()
        ..addAll(stillSuggested);
    }

    int compareScore(T a, T b) => getScore(a).compareTo(getScore(b));
    suggested.sort(compareScore);
    excluded.sort((a, b) => compareScore(a.item, b.item));

    final cappedSuggested = suggested.length > maxResults
        ? suggested.sublist(0, maxResults)
        : suggested;

    // Queries dropped only by maxResults cap stay visible under "not recommended".
    final cappedExcluded = [
      ...excluded,
      if (suggested.length > maxResults)
        for (final q in suggested.sublist(maxResults))
          FilteredOutQuery(
            item: q,
            reason: QueryExclusionReason.redundantBareSemantic,
          ),
    ];

    return QueryDisplayPartition(
      suggested: cappedSuggested,
      excluded: cappedExcluded,
    );
  }

  /// Filters and ranks a flat list of queries for display.
  ///
  /// Prefer [partitionForDisplay] when the UI should also show filtered-out
  /// queries. See [partitionForDisplay] for ranking rules.
  static List<T> filterAndRank<T>({
    required List<T> queries,
    required String Function(T) getQuery,
    required double Function(T) getScore,
    int maxResults = 8,
  }) {
    return partitionForDisplay<T>(
      queries: queries,
      getQuery: getQuery,
      getScore: getScore,
      maxResults: maxResults,
    ).suggested;
  }

  static final _semanticTypes = <String, String>{
    'numeric_price': 'price values',
    'CONTAINS_MONEY': 'price values',
    'numeric_time': 'time values',
    'CONTAINS_TIME': 'time values',
    'numeric_date': 'date values',
    'CONTAINS_DATE': 'date values',
    'numeric_duration': 'duration values',
    'CONTAINS_DURATION': 'duration values',
    'numeric_length': 'distance values',
    'CONTAINS_LENGTH': 'distance values',
    'numeric_percentage': 'percentage values',
    'CONTAINS_PERCENTAGE': 'percentage values',
    'numeric_number': 'numeric values',
    'CONTAINS_NUMBER': 'numeric values',
    'numeric_temperature': 'temperature values',
    'CONTAINS_TEMPERATURE': 'temperature values',
    'numeric_volume': 'volume values',
    'CONTAINS_VOLUME': 'volume values',
    'CONTAINS_EMAIL_ADDRESS': 'email addresses',
    'CONTAINS_PHONE_NUMBER': 'phone numbers',
    'CONTAINS_ADDRESS': 'addresses',
  };

  static final _directionLabels = <String, String>{
    'RIGHT': 'to the right of',
    'LEFT': 'to the left of',
    'ABOVE': 'above',
    'BELOW': 'below',
    'NEAR': 'near',
    'NEXT_TO': 'next to',
  };

  /// Extracts the semantic content type from an `exists` clause.
  static String? _extractContentType(String query) {
    final existsMatch = RegExp(r'\(exists\s+(\w+)\)').firstMatch(query);
    if (existsMatch != null) {
      return _semanticTypes[existsMatch.group(1)];
    }
    return null;
  }

  /// Extracts spatial anchor descriptions like "to the right of 'Guaranteed'".
  static List<String> _extractSpatialAnchors(String query) {
    final anchors = <String>[];

    for (final entry in _directionLabels.entries) {
      // Match patterns like (RIGHT (conj (hasText "Guaranteed")))
      // or (RIGHT (hasText "Guaranteed"))
      final pattern = RegExp(
        '\\(${entry.key}\\s+\\((?:conj\\s+)?\\(hasText\\s+"([^"]+)"\\)',
      );
      for (final match in pattern.allMatches(query)) {
        final text = match.group(1);
        if (text != null) {
          anchors.add("${entry.value} '$text'");
        }
      }
    }

    return anchors;
  }

  /// Extracts exact text from a `hasText` clause (for static text queries).
  static String? _extractExactText(String query) {
    final match = RegExp(r'\(hasText\s+"([^"]+)"\)').firstMatch(query);
    return match?.group(1);
  }

  /// Extracts static label text from parent/child anchor relations.
  static String? _extractStaticLabelAnchor(String query) {
    final match = RegExp(
      r'\(HAS_(?:CHILD|PARENT)_TEXT\s+"([^"]+)"\)',
    ).firstMatch(query);
    return match?.group(1);
  }
}
