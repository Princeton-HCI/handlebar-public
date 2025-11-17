import 'collector.dart';

/// Represents a Collector and the specific membership_id
/// that associates it with the current user.
class ParticipantCollector {
  final Collector collector;
  final int membershipId;

  ParticipantCollector({
    required this.collector,
    required this.membershipId,
  });

  factory ParticipantCollector.fromList(List<dynamic> list) {
    if (list.length < 2) {
      throw FormatException('Invalid ParticipantCollector format');
    }
    return ParticipantCollector(
      collector: Collector.fromJson(list[0] as Map<String, dynamic>),
      membershipId: list[1] as int,
    );
  }
}
