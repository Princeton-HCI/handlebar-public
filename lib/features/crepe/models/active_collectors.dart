import 'collector.dart';

/// Represents the currently active collectors running in the background
class ActiveCollectors {
  final List<Collector> collectors;
  final DateTime fetchedAt;

  ActiveCollectors({required this.collectors, DateTime? fetchedAt})
      : fetchedAt = fetchedAt ?? DateTime.now();

  Map<String, dynamic> toPluginFormat() {
    final transformedData = {
      'Collector': <String, dynamic>{},
      'Datafield': <String, dynamic>{},
      'Data': <String, dynamic>{},
      'User': <String, dynamic>{},
    };

    for (final c in collectors) {
      final cid = c.collectorId.toString();
      transformedData['Collector']?[cid] = {
        'appName': c.appName,
        'appPackage': c.appPackage,
        'collectorId': cid,
        'collectorStatus': 'active',
        'description': c.description ?? '',
        'collectorStartTime': 0,
        'collectorEndTime': 0,
        'collectorStartTimeString': '',
        'collectorEndTimeString': '',
        'creatorUserId': '',
        'deleted': false,
      };

      for (final df in c.dataFields) {
        final dfid = df.dataFieldId.toString();
        transformedData['Datafield']?[dfid] = {
          'collectorId': cid,
          'datafieldId': dfid,
          'name': df.name,
          'graphQuery': df.graphQuery,
          'demonstrated': false,
          'timeCreated': 0,
          'timelastEdited': 0,
        };
      }
    }
    return transformedData;
  }
}
