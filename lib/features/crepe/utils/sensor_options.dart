import 'collection_frequency.dart';
import 'collector_grouping.dart';

// NOTE: The add/edit sensor dialog currently offers only the presets below.
// The backend accepts any positive integer for both the sample interval and
// the timeout, and the label helpers at the bottom of this file already
// render arbitrary values, so a "Custom..." entry (number + unit) can be
// added to the dialog later without touching the model or repository.

/// Presets for how often a location sensor records a fix while active.
/// GPS needs finer options than [kCollectionFrequencyOptions]
const List<CollectionFrequencyOption> kLocationSampleIntervalOptions = [
  CollectionFrequencyOption('Every 10 seconds', 10),
  CollectionFrequencyOption('Every 30 seconds', 30),
  CollectionFrequencyOption('Every minute', 60),
  CollectionFrequencyOption('Every 5 minutes', 300),
];

/// A preset for how long a sensor keeps sampling after its trigger was last
/// satisfied. `null` seconds = never stop once started.
class SensorTimeoutOption {
  final String label;
  final int? seconds;
  const SensorTimeoutOption(this.label, this.seconds);
}

const List<SensorTimeoutOption> kLocationTimeoutOptions = [
  SensorTimeoutOption('Stop after 15 minutes', 900),
  SensorTimeoutOption('Stop after 30 minutes', 1800),
  SensorTimeoutOption('Stop after 1 hour', 3600),
  SensorTimeoutOption('Stop after 2 hours', 7200),
  SensorTimeoutOption('Never stop', null),
];

/// Compact duration for card subtitles: 10 -> "10s", 300 -> "5m", 7200 -> "2h".
String formatDurationShort(int seconds) {
  if (seconds % 86400 == 0 && seconds >= 86400) return '${seconds ~/ 86400}d';
  if (seconds % 3600 == 0 && seconds >= 3600) return '${seconds ~/ 3600}h';
  if (seconds % 60 == 0 && seconds >= 60) return '${seconds ~/ 60}m';
  return '${seconds}s';
}

/// Long-form duration for labels: 45 -> "45 seconds", 120 -> "2 minutes",
/// 3600 -> "1 hour". Falls back to seconds for values that are not a whole
/// number of the larger unit.
String formatDurationLong(int seconds) {
  String plural(int n, String unit) => n == 1 ? '1 $unit' : '$n ${unit}s';
  if (seconds % 86400 == 0 && seconds >= 86400) {
    return plural(seconds ~/ 86400, 'day');
  }
  if (seconds % 3600 == 0 && seconds >= 3600) {
    return plural(seconds ~/ 3600, 'hour');
  }
  if (seconds % 60 == 0 && seconds >= 60) {
    return plural(seconds ~/ 60, 'minute');
  }
  return plural(seconds, 'second');
}

/// Label for a sample interval, preset or custom: "Every 30 seconds".
String sensorIntervalLabel(int seconds) {
  for (final opt in kLocationSampleIntervalOptions) {
    if (opt.seconds == seconds) return opt.label;
  }
  return 'Every ${formatDurationLong(seconds)}';
}

/// Label for a timeout, preset or custom: "Stop after 45 minutes",
/// or "Never stop" for `null`.
String sensorTimeoutLabel(int? seconds) {
  for (final opt in kLocationTimeoutOptions) {
    if (opt.seconds == seconds) return opt.label;
  }
  return 'Stop after ${formatDurationLong(seconds!)}';
}


/// An app a researcher can pick as an `app_foreground` trigger target.
class TriggerAppOption {
  /// Human-readable name shown in the dropdown.
  final String appName;

  /// Android package name sent to the backend as `trigger_app_package`.
  final String appPackage;

  const TriggerAppOption(this.appName, this.appPackage);
}

/// Gig apps offered by default, so a researcher can target an app before the
/// study has any collectors for it.
///
/// Both the worker-facing and consumer-facing packages are listed because they
/// are genuinely different apps: a study of delivery work wants the Dasher /
/// Uber Driver package, and picking the wrong one silently never fires the
/// trigger. Add entries here as studies need them.
const List<TriggerAppOption> kKnownTriggerApps = [
  TriggerAppOption('DoorDash — Dasher (driver)', 'com.doordash.driverapp'),
  TriggerAppOption('Uber Driver', 'com.ubercab.driver'),
];

/// The app choices offered in the sensor dialog: the known gig apps above,
/// followed by any other app this study already collects from.
///
/// Deduplicated by package, with [kKnownTriggerApps] winning so a study
/// collector whose `appName` is just the raw package string doesn't shadow a
/// friendly label.
List<TriggerAppOption> triggerAppOptions(List<CollectorAppGroup> studyApps) {
  final seen = kKnownTriggerApps.map((a) => a.appPackage).toSet();
  return [
    ...kKnownTriggerApps,
    for (final a in studyApps)
      if (seen.add(a.appPackage))
        TriggerAppOption(
          a.appName.isNotEmpty ? a.appName : a.appPackage,
          a.appPackage,
        ),
  ];
}

/// Friendly label for a trigger package, e.g. "DoorDash — Dasher (driver)".
/// Falls back to the raw package for apps we don't have a name for.
String triggerAppLabel(String? appPackage) {
  if (appPackage == null || appPackage.isEmpty) return 'an app';
  for (final a in kKnownTriggerApps) {
    if (a.appPackage == appPackage) return a.appName;
  }
  return appPackage;
}
