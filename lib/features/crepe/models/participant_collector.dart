import 'collector.dart';

/// Represents a Collector and the specific membership_id
/// that associates it with the current user.
class ParticipantCollector {
  final Collector collector;
  final int membershipId;
  final String groupName;

  ParticipantCollector({
    required this.collector,
    required this.membershipId,
    required this.groupName,
  });

  factory ParticipantCollector.fromList(List<dynamic> list) {
    if (list.length < 2) {
      throw FormatException('Invalid ParticipantCollector format');
    }
    return ParticipantCollector(
        collector: Collector.fromJson(list[0] as Map<String, dynamic>),
        membershipId: list[1] as int,
        groupName: list[2] as String);
  }
}
