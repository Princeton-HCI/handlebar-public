import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import 'package:handlebar/features/study/data/models/research_study.dart';
import 'package:handlebar/features/study/data/models/research_study_member.dart';

import '../../../../app/app_locator.dart';
import '../../../../core/network/api_error.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/sensor_config.dart';
import '../../../research_group/data/research_group_collector_repository.dart';
import '../../../research_group/data/research_group_membership_repository.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../research_group/data/research_group_sensor_repository.dart';

class StudyViewModel {
  final String studyCode;

  final _rgRepo = getIt<ResearchGroupRepository>();
  final _rgCollectorRepo = getIt<ResearchGroupCollectorRepository>();
  final _rgMembershipRepo = getIt<ResearchGroupMembershipRepository>();
  final _rgSensorRepo = getIt<ResearchGroupSensorRepository>();

  StudyViewModel({required this.studyCode});

  final ValueNotifier<ResearchStudy?> group = ValueNotifier(null);

  int? get _groupId => group.value?.id;

  bool get isResearcher {
    if (myMembership.value != null) {
      return myMembership.value!.isResearcher;
    }
    return group.value?.isResearcher ?? false;
  }

  // ================
  // State variables
  // ================
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);

  // Passive error state ONLY for initial loading failures
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  final ValueNotifier<List<ResearchStudyMember>> members = ValueNotifier([]);
  final ValueNotifier<ResearchStudyMember?> myMembership = ValueNotifier(null);
  final ValueNotifier<List<Collector>> collectors = ValueNotifier([]);
  final ValueNotifier<List<SensorConfig>> sensors = ValueNotifier([]);

  List<ResearchStudyMember> get researchers {
    final list = List<ResearchStudyMember>.from(
        members.value.where((m) => m.isResearcher));
    final me = myMembership.value;

    if (me != null && me.isResearcher) {
      if (!list.any((m) => m.membershipId == me.membershipId)) {
        list.insert(0, me);
      }
    }

    return list;
  }

  List<ResearchStudyMember> get participants {
    final list = members.value.where((m) => !m.isResearcher).toList();
    final me = myMembership.value;

    // Inject 'me' if I'm a participant and not already in the list
    if (me != null &&
        !me.isResearcher &&
        !list.any((m) => m.membershipId == me.membershipId)) {
      list.insert(0, me);
    }
    return list;
  }

  Future<void> loadDetails() async {
    isInitialized.value = false;
    errorMessage.value = null;

    final groupResult = await _rgRepo.lookupByCode(studyCode);

    ResearchStudy? fetchedGroup;
    groupResult.fold(
      onSuccess: (g) => fetchedGroup = g,
      onFailure: (ApiError e) => errorMessage.value = e.message,
    );

    if (fetchedGroup == null) {
      isInitialized.value = true;
      return;
    }

    group.value = fetchedGroup;
    final int safeGroupId = fetchedGroup!.id;

    // Only these two gate the first render: collectors are the page's main
    // content, and the membership decides whether we draw the researcher or
    // participant view at all.
    //
    // Everything else loads independently and fills in through its own
    // notifier. Awaiting all four together made the screen hostage to the
    // slowest call — one request timing out at ApiClient.timeout left the page
    // blank for a full 15 seconds even though the rest had returned in ~180ms.
    final results = await Future.wait([
      _rgCollectorRepo.listGroupCollectors(safeGroupId),
      _rgMembershipRepo.getMyMembership(safeGroupId),
    ]);

    (results[0] as CollectorsResult).fold(
      onSuccess: (list) => collectors.value = list,
      onFailure: (ApiError e) => errorMessage.value = e.message,
    );

    (results[1] as MemberResult).fold(
      onSuccess: (m) => myMembership.value = m,
      onFailure: (ApiError e) => errorMessage.value = e.message,
    );

    isInitialized.value = true;

    // Deliberately not awaited. Both are supplementary, both already treat
    // failure as non-fatal, and neither should be able to delay the page.
    unawaited(_loadMembers(safeGroupId));
    unawaited(_loadSensors(safeGroupId));
  }

  /// Researcher-only in practice: participants get a 403, which is expected
  /// and silently ignored.
  Future<void> _loadMembers(int groupId) async {
    final res = await _rgMembershipRepo.listResearchGroupMembers(groupId);
    res.fold(
      onSuccess: (list) => members.value = list,
      onFailure: (ApiError e) {},
    );
  }

  /// Non-fatal: a backend without the sensors routes, or a slow one, should
  /// not take down the study page.
  Future<void> _loadSensors(int groupId) async {
    final res = await _rgSensorRepo.listGroupSensors(groupId);
    res.fold(
      onSuccess: (list) => sensors.value = list,
      onFailure: (ApiError e) =>
          debugPrint('StudyViewModel: sensors unavailable: ${e.message}'),
    );
  }

  /// Re-fetches only the collector list, e.g. after returning from the
  /// define-collector flow, without tearing down the whole screen.
  Future<void> refreshCollectors() async {
    if (_groupId == null) return;
    final res = await _rgCollectorRepo.listGroupCollectors(_groupId!);
    res.fold(
      onSuccess: (list) => collectors.value = list,
      onFailure: (ApiError e) => NotificationService().showError(e.message),
    );
  }

  // ================
  // USER ACTIONS
  // ================

  Future<bool> addResearcher(String email) async {
    if (!isResearcher || _groupId == null) return false;
    final res = await _rgMembershipRepo.addResearcherByEmail(_groupId!, email);
    return res.fold(
      onSuccess: (newMember) {
        final currentList = List<ResearchStudyMember>.from(members.value);
        final index = currentList
            .indexWhere((m) => m.membershipId == newMember.membershipId);
        if (index != -1) {
          currentList[index] = newMember;
        } else {
          currentList.add(newMember);
        }
        members.value = currentList;

        NotificationService().showSuccess("Researcher added successfully");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> updateGroup({String? name, String? description}) async {
    if (!isResearcher || _groupId == null) return false;
    final res =
        await _rgRepo.update(_groupId!, name: name, description: description);
    return res.fold(
      onSuccess: (updatedGroup) {
        group.value = updatedGroup;
        NotificationService().showSuccess("Study successfully updated!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> deleteGroup() async {
    if (!isResearcher || _groupId == null) return false;
    final res = await _rgRepo.delete(_groupId!);
    return res.fold(
      onSuccess: (_) {
        NotificationService().showSuccess("Study successfully deleted!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> kickMember(int membershipId) async {
    if (!isResearcher || _groupId == null) return false;
    final res = await _rgMembershipRepo.kick(_groupId!, membershipId);
    return res.fold(
      onSuccess: (_) {
        members.value =
            members.value.where((m) => m.membershipId != membershipId).toList();
        NotificationService().showSuccess("Member successfully kicked!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> updateMyMembership({required String retentionPref}) async {
    if (myMembership.value == null) return false;
    final res = await _rgMembershipRepo.updateMembership(
      membershipId: myMembership.value!.membershipId,
      retentionPref: retentionPref,
    );
    return res.fold(
      onSuccess: (updated) {
        myMembership.value = updated;
        NotificationService().showSuccess("Data governance updated!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> leaveGroup() async {
    if (myMembership.value == null) return false;
    final res = await _rgMembershipRepo.leave(myMembership.value!.membershipId);
    return res.fold(
      onSuccess: (_) {
        NotificationService().showSuccess("You successfully left the study!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> deleteCollector(int collectorId) async {
    if (!isResearcher || _groupId == null) return false;
    final res = await _rgCollectorRepo.removeCollector(_groupId!, collectorId);
    return res.fold(
      onSuccess: (_) {
        collectors.value = collectors.value
            .where((c) => c.collectorId != collectorId)
            .toList();
        NotificationService().showSuccess("Collector successfully removed!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  // ================
  // SENSORS
  // ================

  Future<bool> addSensor({
    required String type,
    required int sampleIntervalSeconds,
    required SensorTriggerType triggerType,
    String? triggerAppPackage,
    int? triggerCollectorId,
    int? timeoutSeconds,
  }) async {
    if (!isResearcher || _groupId == null) return false;
    final res = await _rgSensorRepo.createSensor(
      groupId: _groupId!,
      type: type,
      sampleIntervalSeconds: sampleIntervalSeconds,
      triggerType: triggerType,
      triggerAppPackage: triggerAppPackage,
      triggerCollectorId: triggerCollectorId,
      timeoutSeconds: timeoutSeconds,
    );
    return res.fold(
      onSuccess: (created) {
        sensors.value = [...sensors.value, created];
        NotificationService().showSuccess("Sensor added!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  /// Partial update. [fields] uses backend keys (snake_case); include
  /// `timeout_seconds: null` to clear the timeout.
  Future<bool> updateSensor(int sensorId, Map<String, dynamic> fields) async {
    if (!isResearcher || _groupId == null) return false;
    if (fields.isEmpty) return true;
    final res = await _rgSensorRepo.updateSensor(_groupId!, sensorId, fields);
    return res.fold(
      onSuccess: (updated) {
        sensors.value = sensors.value
            .map((s) => s.sensorId == sensorId ? updated : s)
            .toList();
        NotificationService().showSuccess("Sensor updated!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  Future<bool> setSensorEnabled(int sensorId, bool enabled) =>
      updateSensor(sensorId, {'enabled': enabled});

  Future<bool> deleteSensor(int sensorId) async {
    if (!isResearcher || _groupId == null) return false;
    final res = await _rgSensorRepo.removeSensor(_groupId!, sensorId);
    return res.fold(
      onSuccess: (_) {
        sensors.value =
            sensors.value.where((s) => s.sensorId != sensorId).toList();
        NotificationService().showSuccess("Sensor removed!");
        return true;
      },
      onFailure: (ApiError e) {
        NotificationService().showError(e.message);
        return false;
      },
    );
  }

  void dispose() {
    group.dispose();
    isInitialized.dispose();
    errorMessage.dispose();
    members.dispose();
    myMembership.dispose();
    collectors.dispose();
    sensors.dispose();
  }
}
