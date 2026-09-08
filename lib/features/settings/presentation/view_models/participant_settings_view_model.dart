import 'package:flutter/foundation.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../../crepe/models/sensor_health.dart';
import '../../../crepe/services/crepe_service.dart';

/// Backing state for the participant settings screen.
class ParticipantSettingsViewModel {
  final SecureStorage _storage;
  final CrepeService _crepeService;

  /// Whether on-screen highlight cards are shown during data collection.
  final ValueNotifier<bool> showCollectorOverlays;

  /// Device-local collection health, or null while unknown.
  final ValueNotifier<SensorHealth?> sensorHealth = ValueNotifier(null);

  ParticipantSettingsViewModel(this._storage, this._crepeService)
      : showCollectorOverlays = ValueNotifier(_storage.showCollectorOverlays);

  /// Persist the preference and apply it to the running accessibility service.
  Future<void> setShowCollectorOverlays(bool show) async {
    showCollectorOverlays.value = show;
    await _storage.saveShowCollectorOverlays(show);
    await _crepeService.setOverlayEnabled(show);
  }

  /// Re-reads health from the native side. Cheap: it is a few values out of
  /// SharedPreferences plus a queue count.
  Future<void> refreshSensorHealth() async {
    sensorHealth.value = await _crepeService.getSensorHealth();
  }

  void dispose() {
    showCollectorOverlays.dispose();
    sensorHealth.dispose();
  }
}
