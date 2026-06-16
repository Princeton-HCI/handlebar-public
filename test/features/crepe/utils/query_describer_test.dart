import 'package:flutter_test/flutter_test.dart';
import 'package:handlebar/features/crepe/utils/query_describer.dart';

/// Realistic query strings modeled after actual plugin output from
/// OntologyQueryUtils.generateQueriesForSnapshot().
///
/// Score reference:
///   0.10 — static text match
///   0.15 — dual-anchor spatial + semantic
///   0.30 — single-anchor spatial + semantic
///   0.50 — bare semantic existence
///   1.00 — parent text / view ID (editable)
///   1.50 — exact text on dynamic content
///   3.20 — view ID (non-editable)
///  100.0 — screen location
///  101.0 — parent location

// -- Realistic query strings --------------------------------------------------

const _dualAnchorSpatial =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(exists numeric_price) '
    '(RIGHT (conj (hasText "Guaranteed incl. tips") (HAS_PACKAGE_NAME "com.doordash.driverapp") ) ) '
    '(BELOW (conj (hasText "3.2 mi") (HAS_PACKAGE_NAME "com.doordash.driverapp") ) ) )';

const _singleAnchorSpatial =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(exists numeric_price) '
    '(RIGHT (conj (hasText "Guaranteed incl. tips") (HAS_PACKAGE_NAME "com.doordash.driverapp") ) ) )';

const _bareSemantic =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(exists numeric_price) )';

const _bareSemanticDistance =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(exists numeric_length) )';

const _exactTextDynamic =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(hasText "\$6.35") )';

const _exactTextDynamicDistance =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(hasText "3.2 mi") )';

const _staticText =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(hasText "Guaranteed incl. tips") )';

const _screenHasText =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(SCREEN_HAS_TEXT "Guaranteed incl. tips") '
    '(exists numeric_price) )';

const _screenLocation =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_SCREEN_LOCATION "[100,200][300,400]") )';

const _parentLocation =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PARENT_LOCATION "[100,200][300,400]") )';

const _spatialAbove =
    '(conj (HAS_CLASS_NAME "android.widget.TextView") '
    '(HAS_PACKAGE_NAME "com.doordash.driverapp") '
    '(exists numeric_length) '
    '(ABOVE (conj (hasText "Deliver by") (HAS_PACKAGE_NAME "com.doordash.driverapp") ) ) )';

const _ancestorChildTextAnchor =
    '(conj (exists numeric_duration) '
    '(HAS_PARENT (conj (HAS_CHILD_TEXT "Avg. wait")) ) '
    '(HAS_PACKAGE_NAME com.doordash.driverapp) '
    '(HAS_CLASS_NAME android.widget.TextView))';

const _viewId =
    '(conj (HAS_CLASS_NAME "android.widget.EditText") '
    '(HAS_VIEW_ID "com.app:id/email_input") )';

void main() {
  group('QueryDescriber.describe', () {
    test('dual-anchor spatial + semantic', () {
      final desc = QueryDescriber.describe(_dualAnchorSpatial);
      expect(desc, contains('price values'));
      expect(desc, contains("to the right of 'Guaranteed incl. tips'"));
    });

    test('single-anchor spatial + semantic', () {
      final desc = QueryDescriber.describe(_singleAnchorSpatial);
      expect(desc, contains('price values'));
      expect(desc, contains("to the right of 'Guaranteed incl. tips'"));
    });

    test('spatial above with distance', () {
      final desc = QueryDescriber.describe(_spatialAbove);
      expect(desc, contains('distance values'));
      expect(desc, contains("above 'Deliver by'"));
    });

    test('bare semantic shows content type', () {
      final desc = QueryDescriber.describe(_bareSemantic);
      expect(desc, contains('price values'));
    });

    test('bare semantic distance', () {
      final desc = QueryDescriber.describe(_bareSemanticDistance);
      expect(desc, contains('distance values'));
    });

    test('static text match', () {
      final desc = QueryDescriber.describe(_staticText);
      expect(desc, contains('Guaranteed incl. tips'));
    });

    test('query with no recognizable pattern', () {
      final desc = QueryDescriber.describe('(conj (HAS_CLASS_NAME "foo"))');
      expect(desc, equals('Custom query'));
    });
  });

  group('QueryDescriber.isAlwaysExcluded', () {
    test('excludes SCREEN_HAS_TEXT', () {
      expect(QueryDescriber.isAlwaysExcluded(_screenHasText), isTrue);
    });

    test('excludes HAS_SCREEN_LOCATION', () {
      expect(QueryDescriber.isAlwaysExcluded(_screenLocation), isTrue);
    });

    test('excludes HAS_PARENT_LOCATION', () {
      expect(QueryDescriber.isAlwaysExcluded(_parentLocation), isTrue);
    });

    test('does not exclude spatial queries', () {
      expect(QueryDescriber.isAlwaysExcluded(_singleAnchorSpatial), isFalse);
    });

    test('does not exclude bare semantic', () {
      expect(QueryDescriber.isAlwaysExcluded(_bareSemantic), isFalse);
    });
  });

  group('QueryDescriber.isExactTextOnDynamicContent', () {
    test('score 1.5 is dynamic text', () {
      expect(
        QueryDescriber.isExactTextOnDynamicContent(_exactTextDynamic, 1.5),
        isTrue,
      );
    });

    test('score 0.1 is not dynamic text', () {
      expect(
        QueryDescriber.isExactTextOnDynamicContent(_staticText, 0.1),
        isFalse,
      );
    });

    test('score 0.3 is not dynamic text', () {
      expect(
        QueryDescriber.isExactTextOnDynamicContent(
            _singleAnchorSpatial, 0.3),
        isFalse,
      );
    });
  });

  group('QueryDescriber.filterAndRank', () {
    // Helper to create a (query, score) pair
    (String, double) q(String query, double score) => (query, score);

    List<(String, double)> filter(List<(String, double)> queries) {
      return QueryDescriber.filterAndRank<(String, double)>(
        queries: queries,
        getQuery: (q) => q.$1,
        getScore: (q) => q.$2,
      );
    }

    test('excludes SCREEN_HAS_TEXT queries', () {
      final result = filter([
        q(_screenHasText, 0.45),
        q(_bareSemantic, 0.5),
      ]);
      expect(result.length, 1);
      expect(result.first.$1, _bareSemantic);
    });

    test('excludes location-based queries', () {
      final result = filter([
        q(_screenLocation, 100.0),
        q(_parentLocation, 101.0),
        q(_bareSemantic, 0.5),
      ]);
      expect(result.length, 1);
      expect(result.first.$1, _bareSemantic);
    });

    test('excludes exact text on dynamic content (score ~1.5)', () {
      final result = filter([
        q(_exactTextDynamic, 1.5),
        q(_exactTextDynamicDistance, 1.5),
        q(_bareSemantic, 0.5),
      ]);
      expect(result.length, 1);
      expect(result.first.$1, _bareSemantic);
    });

    test('excludes queries with score > 3.5', () {
      final result = filter([
        q(_viewId, 3.6),
        q(_bareSemantic, 0.5),
      ]);
      expect(result.length, 1);
      expect(result.first.$1, _bareSemantic);
    });

    test('when spatial queries exist, drops bare semantic queries', () {
      final result = filter([
        q(_dualAnchorSpatial, 0.15),
        q(_singleAnchorSpatial, 0.3),
        q(_bareSemantic, 0.5),
        q(_bareSemanticDistance, 0.5),
      ]);
      // Bare semantics should be dropped because spatial alternatives exist
      expect(result.any((r) => r.$1 == _bareSemantic), isFalse);
      expect(result.any((r) => r.$1 == _bareSemanticDistance), isFalse);
      // Spatial queries remain
      expect(result.any((r) => r.$1 == _dualAnchorSpatial), isTrue);
      expect(result.any((r) => r.$1 == _singleAnchorSpatial), isTrue);
    });

    test('when no spatial queries exist, keeps bare semantic queries', () {
      final result = filter([
        q(_bareSemantic, 0.5),
        q(_staticText, 0.1),
      ]);
      expect(result.any((r) => r.$1 == _bareSemantic), isTrue);
      expect(result.any((r) => r.$1 == _staticText), isTrue);
    });

    test('sorts by score ascending (best first)', () {
      final result = filter([
        q(_bareSemantic, 0.5),
        q(_singleAnchorSpatial, 0.3),
        q(_dualAnchorSpatial, 0.15),
      ]);
      expect(result[0].$2, 0.15);
      expect(result[1].$2, 0.3);
      // bare semantic dropped because spatial exist
    });

    test('caps results at maxResults', () {
      final manyQueries = List.generate(
        20,
        (i) => q(_staticText, 0.1 + i * 0.01),
      );
      final result = QueryDescriber.filterAndRank<(String, double)>(
        queries: manyQueries,
        getQuery: (q) => q.$1,
        getScore: (q) => q.$2,
        maxResults: 5,
      );
      expect(result.length, 5);
    });

    test('empty input returns empty output', () {
      final result = filter([]);
      expect(result, isEmpty);
    });

    test('all queries excluded returns empty', () {
      final result = filter([
        q(_screenHasText, 0.45),
        q(_exactTextDynamic, 1.5),
        q(_screenLocation, 100.0),
      ]);
      expect(result, isEmpty);
    });

    test('keeps static text queries alongside spatial', () {
      final result = filter([
        q(_singleAnchorSpatial, 0.3),
        q(_staticText, 0.1),
      ]);
      // Static text is not bare semantic, so it should be kept
      expect(result.any((r) => r.$1 == _staticText), isTrue);
      expect(result.any((r) => r.$1 == _singleAnchorSpatial), isTrue);
    });

    test('realistic DoorDash offer screen scenario', () {
      // Simulates the full set of queries generated for "$6.35" on the offer screen
      final result = filter([
        q(_dualAnchorSpatial, 0.15),
        q(_singleAnchorSpatial, 0.3),
        q(_spatialAbove, 0.3),
        q(_bareSemantic, 0.5),
        q(_exactTextDynamic, 1.5),
        q(_screenHasText, 0.45),
        q(_screenLocation, 100.0),
      ]);

      // Should keep: dual-anchor, single-anchor, spatial-above
      // Should drop: bare semantic (spatial exists), exact dynamic, SCREEN_HAS_TEXT, location
      expect(result.length, 3);
      expect(result[0].$1, _dualAnchorSpatial); // score 0.15
      expect(result[1].$2, 0.3); // one of the single-anchor spatials
      expect(result[2].$2, 0.3);

      // None of the bad ones
      expect(result.any((r) => r.$1 == _bareSemantic), isFalse);
      expect(result.any((r) => r.$1 == _exactTextDynamic), isFalse);
      expect(result.any((r) => r.$1 == _screenHasText), isFalse);
    });

    test('keeps HAS_CHILD_TEXT anchor when spatial alternatives exist', () {
      final result = filter([
        q(_ancestorChildTextAnchor, 0.35),
        q(_spatialAbove, 0.45),
        q(_bareSemantic, 0.5),
      ]);
      expect(result.any((r) => r.$1 == _ancestorChildTextAnchor), isTrue);
      expect(result.first.$1, _ancestorChildTextAnchor);
      expect(result.any((r) => r.$1 == _bareSemantic), isFalse);
    });

    test('partitionForDisplay lists excluded queries with reasons', () {
      final partition = QueryDescriber.partitionForDisplay<(String, double)>(
        queries: [
          q(_ancestorChildTextAnchor, 0.35),
          q(_spatialAbove, 0.45),
          q(_bareSemantic, 0.5),
          q(_exactTextDynamic, 1.5),
          q(_screenLocation, 100.0),
        ],
        getQuery: (e) => e.$1,
        getScore: (e) => e.$2,
      );
      expect(partition.suggested.length, 2);
      expect(
        partition.excluded.any(
          (e) =>
              e.reason == QueryExclusionReason.redundantBareSemantic &&
              e.item.$1 == _bareSemantic,
        ),
        isTrue,
      );
      expect(
        partition.excluded.any(
          (e) =>
              e.reason == QueryExclusionReason.fragileDynamicText,
        ),
        isTrue,
      );
    });
  });

  test('describe includes static label anchor', () {
    expect(
      QueryDescriber.describe(_ancestorChildTextAnchor),
      contains('Avg. wait'),
    );
  });
}
