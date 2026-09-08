import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../crepe/services/location_permission_service.dart';
import '../../../research_group/data/research_group_sensor_repository.dart';
import '../../../study/data/models/research_study.dart';

class ParticipantHomeViewModel {
  final ResearchGroupRepository _rgRepo;
  final ResearchGroupSensorRepository _sensorRepo;
  final LocationPermissionService _locationPermissions;

  ParticipantHomeViewModel({
    required ResearchGroupRepository rgRepo,
    required ResearchGroupSensorRepository sensorRepo,
    required LocationPermissionService locationPermissions,
  })  : _rgRepo = rgRepo,
        _sensorRepo = sensorRepo,
        _locationPermissions = locationPermissions;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<ResearchStudy>> studies = ValueNotifier([]);

  /// True when a study this participant is in collects location but the OS
  /// permission is not usable. Surfaced on the home screen, which they hit
  /// every session — the join-time prompt only fires once, and misses anyone
  /// who joined before the researcher added the sensor.
  final ValueNotifier<bool> needsLocationSetup = ValueNotifier(false);

  Future<void> loadStudies() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.listUserResearchGroups();

    result.fold(
      onSuccess: (allGroups) {
        // Filter strictly for studies this user is participating in
        studies.value = allGroups.where((g) => !g.isResearcher).toList();
      },
      onFailure: (ApiError error) {
        errorMessage.value = error.message;
      },
    );

    isLoading.value = false;

    // Not awaited: the study list should render immediately, and this only
    // controls a banner.
    unawaited(refreshLocationSetupState());
  }

  // ==========================================
  // JOIN STUDY LOGIC
  // ==========================================

  /// Step 1: Verify the code exists and get the study info
  Future<ResearchStudy?> lookupGroup(String code) async {
    errorMessage.value = null;

    final result = await _rgRepo.lookupByCode(code);

    return result.fold(
      onSuccess: (group) => group,
      onFailure: (ApiError error) {
        NotificationService().showError(error.message);
        return null;
      },
    );
  }

  /// Step 2: Actually enroll the user
  Future<bool> joinGroup(String code) async {
    errorMessage.value = null;

    final result = await _rgRepo.joinByCode(code);

    return result.fold(
      onSuccess: (_) async {
        // Refresh the list locally so the new study appears when the dialog closes
        await loadStudies();
        return true;
      },
      onFailure: (error) {
        NotificationService().showError(error.message);
        return false;
      },
    );
  }

  /// True when a study the participant is now in collects location, but the
  /// OS permission is not yet in a state where anything would actually be
  /// recorded.
  ///
  /// Checked right after joining, because that is the only moment we know the
  /// participant is engaged and expecting setup steps. Left to chance, a
  /// location study silently collects nothing.
  Future<bool> needsLocationPermission() async {
    final res = await _sensorRepo.listParticipantSensors();

    final collectsLocation = res.fold(
      onSuccess: (sensors) => sensors.any((p) =>
          p.sensor.isLocation && p.sensor.enabled && !p.sensor.isDormant),
      onFailure: (_) => false,
    );
    if (!collectsLocation) return false;

    final status = await _locationPermissions.check();
    // foregroundOnly counts as "needs setup": it looks granted but records
    // nothing, since the app is never on screen while a trigger is active.
    return status != LocationPermissionStatus.always &&
        status != LocationPermissionStatus.unsupported;
  }

  /// Re-evaluates the location permission prompt. Safe to call often;
  /// failures leave the banner hidden rather than nagging.
  Future<void> refreshLocationSetupState() async {
    needsLocationSetup.value = await needsLocationPermission();
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    studies.dispose();
    needsLocationSetup.dispose();
  }
}
