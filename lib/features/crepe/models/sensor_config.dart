/// What makes a sensor start (and keep) sampling.
enum SensorTriggerType {
  /// Sample continuously while the participant is enrolled.
  always('always'),

  /// Sample while a specific app is in the foreground.
  appForeground('app_foreground'),

  /// Sample after a specific collector matches.
  collectorMatch('collector_match');

  /// Wire value used by the backend and the native plugin.
  final String wire;
  const SensorTriggerType(this.wire);

  static SensorTriggerType fromWire(String value) {
    return SensorTriggerType.values.firstWhere(
      (t) => t.wire == value,
      orElse: () => throw FormatException('Unknown trigger_type: $value'),
    );
  }
}

/// A researcher-configured device sensor attached to a study. Only
/// `location` exists today; [type] is a discriminator so future sensors reuse
/// the same endpoints and UI.
///
/// Mirrors the backend's `research_group_sensor_configs` row. See
/// SENSORS_API.md for the contract.
class SensorConfig {
  static const String typeLocation = 'location';

  final int sensorId;
  final String type;
  final bool enabled;

  /// How often to record a sample while active. Must be > 0.
  final int sampleIntervalSeconds;

  final SensorTriggerType triggerType;

  /// Required when [triggerType] is [SensorTriggerType.appForeground].
  final String? triggerAppPackage;

  /// Required when [triggerType] is [SensorTriggerType.collectorMatch].
  final int? triggerCollectorId;

  /// Stop sampling this long after the trigger was last satisfied.
  /// `null` = never stop once started.
  final int? timeoutSeconds;

  const SensorConfig({
    required this.sensorId,
    required this.type,
    required this.enabled,
    required this.sampleIntervalSeconds,
    required this.triggerType,
    this.triggerAppPackage,
    this.triggerCollectorId,
    this.timeoutSeconds,
  });

  bool get isLocation => type == typeLocation;

  /// A `collector_match` sensor whose collector was deleted (the backend nulls
  /// the FK). Treated as "do not collect" until the researcher re-targets it.
  bool get isDormant =>
      triggerType == SensorTriggerType.collectorMatch &&
      triggerCollectorId == null;

  factory SensorConfig.fromJson(Map<String, dynamic> json) {
    return SensorConfig(
      sensorId: json['sensor_id'] as int,
      type: json['type'] as String,
      enabled: json['enabled'] as bool? ?? true,
      sampleIntervalSeconds: json['sample_interval_seconds'] as int,
      triggerType: SensorTriggerType.fromWire(json['trigger_type'] as String),
      triggerAppPackage: json['trigger_app_package'] as String?,
      triggerCollectorId: json['trigger_collector_id'] as int?,
      timeoutSeconds: json['timeout_seconds'] as int?,
    );
  }

  /// Shape consumed by the native plugin (`SensorConfigData` in Java).
  /// `membershipId` is supplied by the participant wrapper.
  Map<String, dynamic> toPluginFormat() {
    return {
      'sensorId': sensorId,
      'type': type,
      'enabled': enabled,
      'sampleIntervalSeconds': sampleIntervalSeconds,
      'triggerType': triggerType.wire,
      'triggerAppPackage': triggerAppPackage,
      'triggerCollectorId': triggerCollectorId,
      'timeoutSeconds': timeoutSeconds,
    };
  }

  SensorConfig copyWith({
    int? sensorId,
    String? type,
    bool? enabled,
    int? sampleIntervalSeconds,
    SensorTriggerType? triggerType,
    String? triggerAppPackage,
    int? triggerCollectorId,
    int? timeoutSeconds,
  }) {
    return SensorConfig(
      sensorId: sensorId ?? this.sensorId,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      sampleIntervalSeconds:
          sampleIntervalSeconds ?? this.sampleIntervalSeconds,
      triggerType: triggerType ?? this.triggerType,
      triggerAppPackage: triggerAppPackage ?? this.triggerAppPackage,
      triggerCollectorId: triggerCollectorId ?? this.triggerCollectorId,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  @override
  String toString() =>
      'SensorConfig(sensorId: $sensorId, type: $type, enabled: $enabled, '
      'sampleIntervalSeconds: $sampleIntervalSeconds, '
      'triggerType: ${triggerType.wire}, triggerAppPackage: $triggerAppPackage, '
      'triggerCollectorId: $triggerCollectorId, timeoutSeconds: $timeoutSeconds)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorConfig &&
        other.sensorId == sensorId &&
        other.type == type &&
        other.enabled == enabled &&
        other.sampleIntervalSeconds == sampleIntervalSeconds &&
        other.triggerType == triggerType &&
        other.triggerAppPackage == triggerAppPackage &&
        other.triggerCollectorId == triggerCollectorId &&
        other.timeoutSeconds == timeoutSeconds;
  }

  @override
  int get hashCode => Object.hash(sensorId, type, enabled,
      sampleIntervalSeconds, triggerType, triggerAppPackage,
      triggerCollectorId, timeoutSeconds);
}
