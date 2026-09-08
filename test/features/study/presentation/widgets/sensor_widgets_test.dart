import 'package:flutter_test/flutter_test.dart';
import 'package:handlebar/features/crepe/models/collector.dart';
import 'package:handlebar/features/crepe/models/sensor_config.dart';
import 'package:handlebar/features/study/presentation/widgets/sensor_card.dart';
import 'package:handlebar/features/study/presentation/widgets/sensor_config_dialog.dart';

void main() {
  const base = SensorConfig(
    sensorId: 1,
    type: 'location',
    enabled: true,
    sampleIntervalSeconds: 30,
    triggerType: SensorTriggerType.appForeground,
    triggerAppPackage: 'com.dd.doordash',
    timeoutSeconds: 1800,
  );

  final collectors = [
    Collector(
      collectorId: 7,
      appName: 'DoorDash',
      appPackage: 'com.dd.doordash',
      description: 'Offer screen',
      dataFields: const [],
    ),
  ];

  group('SensorConfigDraft.diffAgainst', () {
    test('returns an empty map when nothing changed', () {
      const draft = SensorConfigDraft(
        sampleIntervalSeconds: 30,
        triggerType: SensorTriggerType.appForeground,
        triggerAppPackage: 'com.dd.doordash',
        timeoutSeconds: 1800,
      );
      expect(draft.diffAgainst(base), isEmpty);
    });

    test('sends only the interval when only it changed', () {
      const draft = SensorConfigDraft(
        sampleIntervalSeconds: 60,
        triggerType: SensorTriggerType.appForeground,
        triggerAppPackage: 'com.dd.doordash',
        timeoutSeconds: 1800,
      );
      expect(draft.diffAgainst(base), {'sample_interval_seconds': 60});
    });

    test('sends the full trigger triple when the trigger changes', () {
      const draft = SensorConfigDraft(
        sampleIntervalSeconds: 30,
        triggerType: SensorTriggerType.collectorMatch,
        triggerCollectorId: 7,
        timeoutSeconds: 1800,
      );
      expect(draft.diffAgainst(base), {
        'trigger_type': 'collector_match',
        'trigger_app_package': null,
        'trigger_collector_id': 7,
      });
    });

    test('clearing the timeout sends an explicit null', () {
      const draft = SensorConfigDraft(
        sampleIntervalSeconds: 30,
        triggerType: SensorTriggerType.appForeground,
        triggerAppPackage: 'com.dd.doordash',
        timeoutSeconds: null,
      );
      final diff = draft.diffAgainst(base);
      expect(diff.containsKey('timeout_seconds'), isTrue);
      expect(diff['timeout_seconds'], isNull);
    });
  });

  group('SensorCard.describe', () {
    test('app foreground trigger uses the friendly name for a known app', () {
      final s = base.copyWith(triggerAppPackage: 'com.doordash.driverapp');
      expect(SensorCard.describe(s, collectors),
          'While DoorDash — Dasher (driver) is open · every 30s · stops after 30m');
    });

    test('app foreground trigger falls back to the raw package', () {
      final s = base.copyWith(triggerAppPackage: 'com.example.unknown');
      expect(SensorCard.describe(s, collectors),
          'While com.example.unknown is open · every 30s · stops after 30m');
    });

    test('collector match names the collector', () {
      final s = base.copyWith(
        triggerType: SensorTriggerType.collectorMatch,
        triggerCollectorId: 7,
      );
      expect(SensorCard.describe(s, collectors),
          'When "Offer screen" matches · every 30s · stops after 30m');
    });

    test('dormant collector match is called out', () {
      const s = SensorConfig(
        sensorId: 1,
        type: 'location',
        enabled: true,
        sampleIntervalSeconds: 10,
        triggerType: SensorTriggerType.collectorMatch,
      );
      expect(s.isDormant, isTrue);
      expect(SensorCard.describe(s, collectors),
          'When a deleted collector matches · every 10s · never stops');
    });

    test('always trigger omits the timeout entirely', () {
      // Even with a stored timeout, an `always` sensor never stops — showing
      // one would be a lie about what the device does.
      final s = base.copyWith(
        triggerType: SensorTriggerType.always,
        timeoutSeconds: 3600,
      );
      expect(SensorCard.describe(s, collectors), 'Always on · every 30s');
    });
  });
}
