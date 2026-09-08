import 'package:flutter_test/flutter_test.dart';
import 'package:handlebar/features/crepe/models/sensor_health.dart';

void main() {
  Map<String, dynamic> json({
    String status = 'HEALTHY',
    int configured = 1,
    int sampling = 1,
    int pending = 0,
    int lastSample = 0,
    int lastUpload = 0,
    String? sampleError,
    String? uploadError,
  }) =>
      {
        'status': status,
        'configuredSensorCount': configured,
        'samplingSensorCount': sampling,
        'pendingSampleCount': pending,
        'lastSampleAtMillis': lastSample,
        'lastUploadAtMillis': lastUpload,
        if (sampleError != null) 'lastSampleError': sampleError,
        if (uploadError != null) 'lastUploadError': uploadError,
      };

  group('SensorHealth.fromJson', () {
    test('parses the native payload', () {
      final h = SensorHealth.fromJson(json(
        status: 'UPLOAD_STALLED',
        configured: 2,
        sampling: 1,
        pending: 42,
        lastSample: 1700000000000,
        sampleError: 'permission not granted',
      ));

      expect(h.status, SensorHealthStatus.uploadStalled);
      expect(h.configuredSensorCount, 2);
      expect(h.samplingSensorCount, 1);
      expect(h.pendingSampleCount, 42);
      expect(h.lastSampleAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(h.lastSampleError, 'permission not granted');
      expect(h.lastUploadError, isNull);
    });

    test('treats 0 as never, not as the epoch', () {
      // The native side uses 0 for "hasn't happened"; surfacing 1970 would be
      // worse than surfacing nothing.
      final h = SensorHealth.fromJson(json(lastSample: 0, lastUpload: 0));
      expect(h.lastSampleAt, isNull);
      expect(h.lastUploadAt, isNull);
    });

    test('an unknown status degrades to idle rather than throwing', () {
      // A newer native side must not crash an older client.
      final h = SensorHealth.fromJson(json(status: 'SOMETHING_NEW'));
      expect(h.status, SensorHealthStatus.idle);
    });

    test('tolerates a missing status', () {
      final h = SensorHealth.fromJson({'configuredSensorCount': 0});
      expect(h.status, SensorHealthStatus.idle);
      expect(h.hasSensors, isFalse);
    });
  });

  group('needsAttention', () {
    test('warns only when something is actually broken', () {
      // Warning on idle would train participants to ignore the banner — an
      // app_foreground sensor is idle most of the day by design.
      expect(
        SensorHealth.fromJson(json(status: 'IDLE')).needsAttention,
        isFalse,
      );
      expect(
        SensorHealth.fromJson(json(status: 'HEALTHY')).needsAttention,
        isFalse,
      );
      expect(
        SensorHealth.fromJson(json(status: 'NOT_COLLECTING')).needsAttention,
        isTrue,
      );
      expect(
        SensorHealth.fromJson(json(status: 'UPLOAD_STALLED')).needsAttention,
        isTrue,
      );
    });
  });

  group('participantMessage', () {
    test('points at permissions when nothing is being recorded', () {
      final h = SensorHealth.fromJson(json(status: 'NOT_COLLECTING'));
      expect(h.participantMessage, contains('Allow all the time'));
    });

    test('names the backlog size when uploads are stalled', () {
      final h = SensorHealth.fromJson(json(status: 'UPLOAD_STALLED', pending: 17));
      expect(h.participantMessage, contains('17'));
    });

    test('says nothing alarming when healthy', () {
      final h = SensorHealth.fromJson(json(status: 'HEALTHY'));
      expect(h.participantMessage, contains('working normally'));
    });
  });
}
