import 'package:handlebar/features/crepe/models/participant_collector.dart';

/// Represents all the collectors running in the background
/// from all research groups where the user is a participant
class ActiveCollectors {
  final List<ParticipantCollector> collectors;
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

    for (final pc in collectors) {
      final c = pc.collector;
      final membershipId = pc.membershipId;

      final cid = c.collectorId.toString();
      transformedData['Collector']?[cid] = {
        'appName': c.appName,
        'appPackage': c.appPackage,
        'collectorId': cid,
        'membership_id': membershipId,
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
          'membership_id': membershipId,
          'demonstrated': false,
          'timeCreated': 0,
          'timelastEdited': 0,
        };
      }
    }
    return transformedData;
  }
}
