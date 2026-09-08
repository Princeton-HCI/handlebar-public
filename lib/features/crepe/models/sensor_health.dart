/// How collection is actually going on this device.
///
/// Every way collection breaks in the field looks the same from outside —
/// nothing happens. This distinguishes "idle by design" from "silently
/// broken", which is otherwise only discoverable at analysis time.
enum SensorHealthStatus {
  /// No sensors configured, or configured but never triggered. Silence is correct.
  idle,

  /// Sampling and uploading recently.
  healthy,

  /// Sampling fine, but a backlog is not reaching the server.
  uploadStalled,

  /// Triggered and expected to be sampling, but no fix is landing.
  notCollecting;

  static SensorHealthStatus fromWire(String value) {
    switch (value) {
      case 'HEALTHY':
        return SensorHealthStatus.healthy;
      case 'UPLOAD_STALLED':
        return SensorHealthStatus.uploadStalled;
      case 'NOT_COLLECTING':
        return SensorHealthStatus.notCollecting;
      case 'IDLE':
      default:
        return SensorHealthStatus.idle;
    }
  }
}

class SensorHealth {
  final SensorHealthStatus status;
  final int configuredSensorCount;
  final int samplingSensorCount;
  final int pendingSampleCount;
  final DateTime? lastSampleAt;
  final DateTime? lastUploadAt;
  final String? lastSampleError;
  final String? lastUploadError;

  const SensorHealth({
    required this.status,
    required this.configuredSensorCount,
    required this.samplingSensorCount,
    required this.pendingSampleCount,
    this.lastSampleAt,
    this.lastUploadAt,
    this.lastSampleError,
    this.lastUploadError,
  });

  /// Nothing configured at all — distinct from [status] being idle, which also
  /// covers a configured sensor waiting on its trigger.
  bool get hasSensors => configuredSensorCount > 0;

  /// Whether to tell the participant something is wrong. Idle and healthy are
  /// both fine; warning on either would train them to ignore it.
  bool get needsAttention =>
      status == SensorHealthStatus.notCollecting ||
      status == SensorHealthStatus.uploadStalled;

  factory SensorHealth.fromJson(Map<String, dynamic> json) {
    return SensorHealth(
      status: SensorHealthStatus.fromWire(json['status'] as String? ?? 'IDLE'),
      configuredSensorCount: json['configuredSensorCount'] as int? ?? 0,
      samplingSensorCount: json['samplingSensorCount'] as int? ?? 0,
      pendingSampleCount: (json['pendingSampleCount'] as num?)?.toInt() ?? 0,
      lastSampleAt: _toDate(json['lastSampleAtMillis']),
      lastUploadAt: _toDate(json['lastUploadAtMillis']),
      lastSampleError: json['lastSampleError'] as String?,
      lastUploadError: json['lastUploadError'] as String?,
    );
  }

  /// The native side uses 0 for "never", which is not a real timestamp.
  static DateTime? _toDate(dynamic millis) {
    if (millis is! num || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis.toInt());
  }

  /// Participant-facing summary. Deliberately concrete about what is wrong,
  /// since the remedy differs: permissions versus connectivity.
  String get participantMessage {
    switch (status) {
      case SensorHealthStatus.notCollecting:
        return 'A study is set up to collect location, but nothing is being '
            'recorded. Check that location access is set to "Allow all the time".';
      case SensorHealthStatus.uploadStalled:
        return '$pendingSampleCount reading(s) are waiting to be sent. They '
            'will upload once you have a connection and are signed in.';
      case SensorHealthStatus.healthy:
      case SensorHealthStatus.idle:
        return 'Collection is working normally.';
    }
  }
}
