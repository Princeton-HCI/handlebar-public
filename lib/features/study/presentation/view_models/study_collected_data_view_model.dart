import 'package:flutter/foundation.dart';

import '../../../../app/app_locator.dart';
import '../../../../core/network/api_error.dart';
import '../../../crepe/data/crepe_event_repository.dart';
import '../../../crepe/data/point_repository.dart';
import '../../../crepe/models/crepe_event.dart';
import '../../../crepe/models/location_point.dart';
import '../../../research_group/data/research_group_membership_repository.dart';
import '../../../research_group/data/research_group_repository.dart';

/// Loads paginated [CrepeEvent]s for a study — participant's own events or
/// all group events for researchers.
class StudyCollectedDataViewModel {
  final String studyCode;
  final _rgRepo = getIt<ResearchGroupRepository>();
  final _membershipRepo = getIt<ResearchGroupMembershipRepository>();
  final _crepeEventRepo = getIt<CrepeEventRepository>();
  final _pointRepo = getIt<PointRepository>();

  StudyCollectedDataViewModel({required this.studyCode});

  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<CrepeEvent>> events = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> hasMore = ValueNotifier(true);

  // Location points page independently of screen events: separate endpoints,
  // separate cursors, and a study may have one kind of data and not the other.
  final ValueNotifier<List<LocationPoint>> points = ValueNotifier([]);
  final ValueNotifier<bool> isLoadingPoints = ValueNotifier(false);
  final ValueNotifier<bool> hasMorePoints = ValueNotifier(true);
  final ValueNotifier<String?> pointsErrorMessage = ValueNotifier(null);

  int? _groupId;
  bool _isResearcher = false;
  String? _cursor;
  String? _pointsCursor;

  bool get isResearcher => _isResearcher;
  int? get groupId => _groupId;

  Future<void> load() async {
    isInitialized.value = false;
    errorMessage.value = null;
    events.value = [];
    _cursor = null;
    hasMore.value = true;

    final groupResult = await _rgRepo.lookupByCode(studyCode);
    await groupResult.fold(
      onSuccess: (group) async {
        _groupId = group.id;
        final membershipRes = await _membershipRepo.getMyMembership(group.id);
        membershipRes.fold(
          onSuccess: (m) => _isResearcher = m.isResearcher,
          onFailure: (_) => _isResearcher = group.isResearcher,
        );
        isInitialized.value = true;
        await refresh();
        // Independent of events: a study may collect location and no screen
        // data, so a failure in one must not hide the other.
        await refreshPoints();
      },
      onFailure: (ApiError e) {
        errorMessage.value = e.message;
        isInitialized.value = true;
      },
    );
  }

  Future<void> refresh() async {
    _cursor = null;
    hasMore.value = true;
    await _fetch(clearList: true);
  }

  Future<void> refreshPoints() async {
    _pointsCursor = null;
    hasMorePoints.value = true;
    await _fetchPoints(clearList: true);
  }

  Future<void> loadMorePoints() async {
    if (!hasMorePoints.value || isLoadingPoints.value || _groupId == null) {
      return;
    }
    await _fetchPoints(clearList: false);
  }

  Future<void> _fetchPoints({required bool clearList}) async {
    if (_groupId == null) return;

    isLoadingPoints.value = true;
    pointsErrorMessage.value = null;
    if (clearList) points.value = [];

    final request = _isResearcher
        ? _pointRepo.listResearcherPointsForGroup(
            _groupId!,
            cursor: _pointsCursor,
            limit: 30,
          )
        : _pointRepo.listParticipantPoints(
            groupId: _groupId,
            cursor: _pointsCursor,
            limit: 30,
          );

    final res = await request;
    res.fold(
      onSuccess: (page) {
        points.value =
            clearList ? page.items : [...points.value, ...page.items];
        _pointsCursor = page.nextCursor;
        hasMorePoints.value = page.hasNextPage;
      },
      onFailure: (ApiError e) => pointsErrorMessage.value = e.message,
    );

    isLoadingPoints.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value || _groupId == null) return;
    await _fetch(clearList: false);
  }

  Future<void> _fetch({required bool clearList}) async {
    if (_groupId == null) return;

    isLoading.value = true;
    if (clearList) events.value = [];

    final request = _isResearcher
        ? _crepeEventRepo.listResearcherEventsForGroup(
            _groupId!,
            cursor: _cursor,
            limit: 30,
          )
        : _crepeEventRepo.listParticipantEvents(
            groupId: _groupId,
            cursor: _cursor,
            limit: 30,
          );

    final res = await request;
    res.fold(
      onSuccess: (page) {
        if (clearList) {
          events.value = page.items;
        } else {
          events.value = [...events.value, ...page.items];
        }
        _cursor = page.nextCursor;
        hasMore.value = page.hasNextPage;
      },
      onFailure: (ApiError e) => errorMessage.value = e.message,
    );

    isLoading.value = false;
  }

  void dispose() {
    isInitialized.dispose();
    errorMessage.dispose();
    events.dispose();
    isLoading.dispose();
    hasMore.dispose();
    points.dispose();
    isLoadingPoints.dispose();
    hasMorePoints.dispose();
    pointsErrorMessage.dispose();
  }
}
