import 'package:flutter/material.dart';
import 'package:handlebar/features/crepe/data/crepe_event_repository.dart';
import 'package:handlebar/features/crepe/models/participant_collector.dart';
import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_repository.dart';
import 'package:logging/logging.dart';

import '../../../../core/network/api_error.dart';
import '../../../crepe/models/crepe_event.dart';
import '../../../study/data/models/research_study.dart';

class OldResearchGroupDashboardViewModel extends ChangeNotifier {
  static final _logger = Logger('VideoSessionViewModel');

  final ResearchGroupRepository _rgRepo;
  final ResearchGroupCollectorRepository _rgCollectorRepo;
  final CrepeEventRepository _crepeEventRepository;

  OldResearchGroupDashboardViewModel(
      this._rgRepo, this._rgCollectorRepo, this._crepeEventRepository);

  // ================
  // State variables
  // ================

  // ---- Public screen-level state ----
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // ---- Public researcher group state ----
  final ValueNotifier<List<ResearchStudy>> researcherGroups = ValueNotifier([]);
  final ValueNotifier<List<ResearchStudy>> participantGroups =
      ValueNotifier([]);

  // ---- Public collector state ----
  final ValueNotifier<List<ParticipantCollector>> participantCollectors =
      ValueNotifier([]);

  // ---- Public event state ----
  final ValueNotifier<List<CrepeEvent>> events = ValueNotifier([]);
  final ValueNotifier<bool> isEventsLoading = ValueNotifier(false);
  final ValueNotifier<bool> hasMoreEvents = ValueNotifier(true);

  // ---- Private researcher group state ----
  ResearchStudy? _lookupGroup;

  // ---- Private event state ----
  String? _nextEventCursor; // for paginated event requests

  // ================
  // INITIALIZATION
  // ================

  /// Loads the initial state of the research group dashboard
  Future<void> loadDashboard() async {
    isInitialized.value = false;

    errorMessage.value = null;

    // Fetch research groups, participant collectors, and own Crepe events
    final results = await Future.wait([
      _rgRepo.listUserResearchGroups(),
      _rgCollectorRepo.listParticipantCollectors(),
      _loadEvents(clearList: true)
    ]);

    final groupRes = results[0] as GroupsResult;
    final collectorRes = results[1] as ParticipantCollectorsResult;

    // Handle group result
    groupRes.fold(onSuccess: (allGroups) {
      final researchers = <ResearchStudy>[];
      final participants = <ResearchStudy>[];

      // Differentiate between participant groups and researcher groups
      for (var g in allGroups) {
        if (g.isResearcher) {
          researchers.add(g);
        } else {
          participants.add(g);
        }
      }

      researcherGroups.value = researchers;
      participantGroups.value = participants;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
    });

    // Handle collector result
    collectorRes.fold(onSuccess: (collectors) {
      participantCollectors.value = collectors;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
    });

    isInitialized.value = true;
  }

  // ================
  // RESEARCH GROUPS
  // ================

  /// Creates a research group
  Future<bool> createGroup(String name, String desc) async {
    final res = await _rgRepo.create(name: name, description: desc);
    return res.fold(onSuccess: (group) {
      final updated = [...researcherGroups.value, group];
      updated.sort((a, b) => a.name.compareTo(b.name));
      researcherGroups.value = updated;
      return true;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  /// Looks up a research group
  Future<ResearchStudy?> lookupGroup(String code) async {
    final res = await _rgRepo.lookupByCode(code);

    return res.fold(onSuccess: (group) {
      _lookupGroup = group;
      return group;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return null;
    });
  }

  /// Joins the user to a research group
  Future<bool> joinGroup(String code) async {
    final res = await _rgRepo.joinByCode(code);
    return res.fold(onSuccess: (_) {
      if (_lookupGroup == null) {
        _logger.severe(
            "lookupGroup was null when trying to join a group. Always use lookupGroup before joinGroup");
      } else {
        participantGroups.value = [_lookupGroup!, ...participantGroups.value];
      }
      return true;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  // ================
  // CREPE EVENTS
  // ================

  /// Refreshes the list of Crepe events
  Future<void> refreshEvents() async {
    _nextEventCursor = null;
    hasMoreEvents.value = true;
    await _loadEvents(clearList: true);
  }

  /// Loads more Crepe events following the latest paginated result
  Future<void> loadMoreEvents() async {
    if (!hasMoreEvents.value || isEventsLoading.value) return;
    await _loadEvents(clearList: false);
  }

  Future<void> _loadEvents({required bool clearList}) async {
    if (isEventsLoading.value) return;

    isEventsLoading.value = true;
    if (clearList) {
      events.value = [];
    }

    final res = await _crepeEventRepository.listParticipantEvents(
        cursor: _nextEventCursor, limit: 30);

    res.fold(
        onSuccess: (page) {
          if (clearList) {
            events.value = page.items;
          } else {
            events.value = [...events.value, ...page.items];
          }

          _nextEventCursor = page.nextCursor;
          hasMoreEvents.value = page.hasNextPage;
        },
        onFailure: (ApiError e) => errorMessage.value = e.message);

    isEventsLoading.value = false;
  }
}
