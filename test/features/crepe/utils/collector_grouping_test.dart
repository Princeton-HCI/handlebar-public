import 'package:flutter_test/flutter_test.dart';
import 'package:handlebar/features/crepe/models/collector.dart';
import 'package:handlebar/features/crepe/utils/collection_frequency.dart';
import 'package:handlebar/features/crepe/utils/collector_grouping.dart';

Collector _collector(int id, String appName, String appPackage,
    {int? intervalSeconds}) {
  return Collector(
    collectorId: id,
    appName: appName,
    appPackage: appPackage,
    description: 'collector $id',
    dataFields: const [],
    collectionIntervalSeconds: intervalSeconds,
  );
}

void main() {
  group('groupCollectorsByApp', () {
    test('groups by package and sorts groups alphabetically by app name', () {
      final collectors = [
        _collector(1, 'Uber', 'com.ubercab'),
        _collector(2, 'DoorDash', 'com.dd.doordash'),
        _collector(3, 'Uber', 'com.ubercab'),
      ];

      final groups = groupCollectorsByApp(collectors);

      expect(groups.map((g) => g.appName), ['DoorDash', 'Uber']);
      expect(groups[0].collectors.length, 1);
      expect(groups[1].collectors.length, 2);
    });

    test('preserves creation order within a group', () {
      final groups = groupCollectorsByApp([
        _collector(1, 'Uber', 'com.ubercab'),
        _collector(2, 'Uber', 'com.ubercab'),
      ]);

      expect(groups.single.collectors.map((c) => c.collectorId), [1, 2]);
    });

    test('falls back to package when app name is empty', () {
      final groups = groupCollectorsByApp([_collector(1, '', 'com.ubercab')]);
      expect(groups.single.appName, 'com.ubercab');
    });
  });

  group('Collector serialization', () {
    test('round-trips collection_interval_seconds via fromJson', () {
      final json = {
        'collector_id': 5,
        'app_name': 'Uber',
        'app_package': 'com.ubercab',
        'description': 'ratings',
        'collection_interval_seconds': 3600,
        'datafields': <dynamic>[],
      };

      final c = Collector.fromJson(json);
      expect(c.collectionIntervalSeconds, 3600);
      expect(c.toPluginFormat()['collectionIntervalSeconds'], 3600);
    });

    test('defaults plugin interval to 0 when unset', () {
      final c = _collector(1, 'Uber', 'com.ubercab');
      expect(c.collectionIntervalSeconds, isNull);
      expect(c.toPluginFormat()['collectionIntervalSeconds'], 0);
    });
  });

  group('collectionFrequencyLabel', () {
    test('maps known presets', () {
      expect(collectionFrequencyLabel(0), 'Every time');
      expect(collectionFrequencyLabel(null), 'Every time');
      expect(collectionFrequencyLabel(3600), 'Once per hour');
    });

    test('derives a label for non-preset intervals', () {
      expect(collectionFrequencyLabel(7200), 'Once per 2 hours');
    });
  });
}
