import 'sensor_config.dart';

/// A [SensorConfig] plus the membership that ties it to the current user.
/// The device echoes `membershipId` back on every uploaded sample so the
/// backend can attribute it to a study (and cover it under that study's
/// retention policy).
class ParticipantSensorConfig {
  final SensorConfig sensor;
  final int membershipId;
  final String groupName;

  const ParticipantSensorConfig({
    required this.sensor,
    required this.membershipId,
    required this.groupName,
  });

  /// Parses one positional entry of `GET /me/sensors`:
  /// `[ <sensor>, <membership_id>, <group_name> ]`.
  factory ParticipantSensorConfig.fromList(List<dynamic> list) {
    if (list.length < 3) {
      throw const FormatException('Invalid ParticipantSensorConfig format');
    }
    return ParticipantSensorConfig(
      sensor: SensorConfig.fromJson(list[0] as Map<String, dynamic>),
      membershipId: list[1] as int,
      groupName: list[2] as String,
    );
  }

  Map<String, dynamic> toPluginFormat() => {
        ...sensor.toPluginFormat(),
        'membershipId': membershipId,
        'groupName': groupName,
      };
}
