import 'package:flutter_test/flutter_test.dart';
import 'package:handlebar/features/crepe/models/participant_sensor_config.dart';
import 'package:handlebar/features/crepe/models/sensor_config.dart';
import 'package:handlebar/features/crepe/utils/collector_grouping.dart';
import 'package:handlebar/features/crepe/utils/sensor_options.dart';

void main() {
  final json = <String, dynamic>{
    'sensor_id': 12,
    'type': 'location',
    'enabled': true,
    'sample_interval_seconds': 30,
    'trigger_type': 'app_foreground',
    'trigger_app_package': 'com.dd.doordash',
    'trigger_collector_id': null,
    'timeout_seconds': 1800,
  };

  group('SensorConfig.fromJson', () {
    test('parses the documented shape', () {
      final s = SensorConfig.fromJson(json);
      expect(s.sensorId, 12);
      expect(s.isLocation, isTrue);
      expect(s.enabled, isTrue);
      expect(s.sampleIntervalSeconds, 30);
      expect(s.triggerType, SensorTriggerType.appForeground);
      expect(s.triggerAppPackage, 'com.dd.doordash');
      expect(s.triggerCollectorId, isNull);
      expect(s.timeoutSeconds, 1800);
      expect(s.isDormant, isFalse);
    });

    test('null timeout means never stop', () {
      final s = SensorConfig.fromJson({...json, 'timeout_seconds': null});
      expect(s.timeoutSeconds, isNull);
    });

    test('collector_match with a null collector is dormant', () {
      final s = SensorConfig.fromJson({
        ...json,
        'trigger_type': 'collector_match',
        'trigger_app_package': null,
        'trigger_collector_id': null,
      });
      expect(s.isDormant, isTrue);
    });

    test('unknown trigger_type throws', () {
      expect(
        () => SensorConfig.fromJson({...json, 'trigger_type': 'bogus'}),
        throwsFormatException,
      );
    });
  });

  test('toPluginFormat uses wire trigger values', () {
    final m = SensorConfig.fromJson(json).toPluginFormat();
    expect(m['triggerType'], 'app_foreground');
    expect(m['sampleIntervalSeconds'], 30);
    expect(m['timeoutSeconds'], 1800);
  });

  test('ParticipantSensorConfig.fromList parses the positional tuple', () {
    final p = ParticipantSensorConfig.fromList([json, 42, 'Gig Study']);
    expect(p.sensor.sensorId, 12);
    expect(p.membershipId, 42);
    expect(p.groupName, 'Gig Study');
    expect(p.toPluginFormat()['membershipId'], 42);
  });

  test('ParticipantSensorConfig.fromList rejects short tuples', () {
    expect(() => ParticipantSensorConfig.fromList([json, 42]),
        throwsFormatException);
  });

  group('custom duration labels', () {
    test('formatDurationLong pluralises and picks the largest unit', () {
      expect(formatDurationLong(1), '1 second');
      expect(formatDurationLong(45), '45 seconds');
      expect(formatDurationLong(60), '1 minute');
      expect(formatDurationLong(120), '2 minutes');
      expect(formatDurationLong(3600), '1 hour');
      expect(formatDurationLong(5400), '90 minutes');
    });

    test('sensorIntervalLabel uses presets when they match', () {
      expect(sensorIntervalLabel(30), 'Every 30 seconds');
      expect(sensorIntervalLabel(60), 'Every minute');
      expect(sensorIntervalLabel(45), 'Every 45 seconds');
      expect(sensorIntervalLabel(120), 'Every 2 minutes');
    });

    test('sensorTimeoutLabel handles presets, custom, and never', () {
      expect(sensorTimeoutLabel(1800), 'Stop after 30 minutes');
      expect(sensorTimeoutLabel(2700), 'Stop after 45 minutes');
      expect(sensorTimeoutLabel(null), 'Never stop');
    });
  });

  group('formatDurationShort', () {
    test('picks the largest whole unit', () {
      expect(formatDurationShort(10), '10s');
      expect(formatDurationShort(90), '90s');
      expect(formatDurationShort(300), '5m');
      expect(formatDurationShort(3600), '1h');
      expect(formatDurationShort(7200), '2h');
      expect(formatDurationShort(86400), '1d');
    });
  });

  group('trigger app options', () {
    test('known gig apps are offered even with no study collectors', () {
      final opts = triggerAppOptions(const []);
      final packages = opts.map((o) => o.appPackage).toList();
      expect(packages, contains('com.doordash.driverapp'));
      expect(packages, contains('com.ubercab.driver'));
      expect(opts.length, kKnownTriggerApps.length);
    });

    test("study's own apps are appended after the known ones", () {
      final opts = triggerAppOptions([
        const CollectorAppGroup(
          appName: 'Instacart Shopper',
          appPackage: 'com.instacart.shopper',
          collectors: [],
        ),
      ]);
      expect(opts.length, kKnownTriggerApps.length + 1);
      expect(opts.last.appPackage, 'com.instacart.shopper');
      expect(opts.last.appName, 'Instacart Shopper');
    });

    test('a study app duplicating a known package does not shadow its label',
        () {
      final opts = triggerAppOptions([
        // appName is the raw package, as collectors record it today.
        const CollectorAppGroup(
          appName: 'com.ubercab.driver',
          appPackage: 'com.ubercab.driver',
          collectors: [],
        ),
      ]);
      expect(opts.length, kKnownTriggerApps.length);
      final uber =
          opts.firstWhere((o) => o.appPackage == 'com.ubercab.driver');
      expect(uber.appName, 'Uber Driver');
    });

    test('triggerAppLabel names known apps and passes through unknown ones',
        () {
      expect(triggerAppLabel('com.doordash.driverapp'),
          'DoorDash — Dasher (driver)');
      expect(triggerAppLabel('com.example.unknown'), 'com.example.unknown');
      expect(triggerAppLabel(null), 'an app');
    });
  });
}
