import 'collector.dart';

/// Response model for API calls that fetch collector configurations,
/// containing a list of collectors and providing transformation utilities.
class CollectorResponse {
  final List<Collector> collectors;
  final DateTime fetchedAt;

  CollectorResponse({
    required this.collectors,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory CollectorResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<Collector> collectors = [];

    if (data is List) {
      collectors = data.map((item) => Collector.fromJson(item)).toList();
    } else if (data is Map<String, dynamic>) {
      collectors = [Collector.fromJson(data)];
    }

    return CollectorResponse(
      collectors: collectors,
    );
  }

  Map<String, dynamic> toPluginFormat() {
    final Map<String, dynamic> transformedData = {
      'Collector': <String, dynamic>{},
      'Datafield': <String, dynamic>{},
      'Data': <String, dynamic>{},
      'User': <String, dynamic>{},
    };

    for (final collector in collectors) {
      final collectorIdStr = collector.collectorId.toString();

      transformedData['Collector'][collectorIdStr] = {
        'appName': collector.appName,
        'appPackage': collector.appPackage,
        'collectorId': collectorIdStr,
        'collectorStatus': 'active',
        'description': collector.description ?? '',
        'collectorStartTime': 0,
        'collectorEndTime': 0,
        'collectorStartTimeString': '',
        'collectorEndTimeString': '',
        'creatorUserId': '',
        'deleted': false,
      };

      for (final dataField in collector.dataFields) {
        final dataFieldIdStr = dataField.dataFieldId.toString();

        transformedData['Datafield'][dataFieldIdStr] = {
          'collectorId': collectorIdStr,
          'datafieldId': dataFieldIdStr,
          'name': dataField.name,
          'graphQuery': dataField.graphQuery,
          'demonstrated': false,
          'timeCreated': 0,
          'timelastEdited': 0,
        };
      }
    }

    return transformedData;
  }
}
