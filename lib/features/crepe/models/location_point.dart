/// One recorded location fix, as returned by the study point endpoints.
///
/// Mirrors `PointView.render("point.json", ...)` on the backend. Only
/// latitude, longitude and recordedAt are guaranteed — everything else depends
/// on what the device could determine at the time, and a missing bearing must
/// stay null rather than becoming 0.0 (which means due north).
class LocationPoint {
  final int id;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final bool? isMoving;
  final String? activityType;
  final double? batteryLevel;
  final String? status;
  final DateTime recordedAt;
  final int? membershipId;
  final int? userId;

  const LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.isMoving,
    this.activityType,
    this.batteryLevel,
    this.status,
    this.membershipId,
    this.userId,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'] as int,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: _toDouble(json['accuracy']),
      altitude: _toDouble(json['altitude']),
      speed: _toDouble(json['speed']),
      heading: _toDouble(json['heading']),
      isMoving: json['is_moving'] as bool?,
      activityType: json['activity_type'] as String?,
      batteryLevel: _toDouble(json['battery_level']),
      status: json['status'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
      membershipId: json['membership_id'] as int?,
      userId: json['user_id'] as int?,
    );
  }

  /// Postgres may serialise a float column as an int when the value is whole,
  /// so a plain `as double?` cast would throw on, say, an accuracy of 12.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
