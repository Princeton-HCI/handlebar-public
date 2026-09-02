import '../models/collector.dart';

/// A set of collectors that all target the same app, used to render
/// collector lists grouped by application.
class CollectorAppGroup {
  final String appName;
  final String appPackage;
  final List<Collector> collectors;

  const CollectorAppGroup({
    required this.appName,
    required this.appPackage,
    required this.collectors,
  });
}

/// Groups [collectors] by their [Collector.appPackage], returning one
/// [CollectorAppGroup] per app ordered alphabetically by app name.
///
/// Creation order is preserved within each group, so collectors stay stable
/// relative to one another while being organized under their app.
List<CollectorAppGroup> groupCollectorsByApp(List<Collector> collectors) {
  final byPackage = <String, List<Collector>>{};
  final appNames = <String, String>{};

  for (final c in collectors) {
    byPackage.putIfAbsent(c.appPackage, () => []).add(c);
    // First non-empty appName wins; fall back to the package for display.
    appNames.putIfAbsent(
      c.appPackage,
      () => c.appName.isNotEmpty ? c.appName : c.appPackage,
    );
  }

  final groups = byPackage.entries
      .map((e) => CollectorAppGroup(
            appName: appNames[e.key]!,
            appPackage: e.key,
            collectors: e.value,
          ))
      .toList();

  groups.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
  return groups;
}
