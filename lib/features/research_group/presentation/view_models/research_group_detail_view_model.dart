import 'package:flutter/material.dart';
import 'package:handlebar/app/app_locator.dart';
import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';

import '../../../../core/network/api_client.dart';
import '../../../crepe/data/crepe_event_repository.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/crepe_event.dart';
import '../../data/research_group_membership_repository.dart';
import '../../models/research_group.dart';
import '../../models/research_group_member.dart';

class ResearchGroupDetailViewModel extends ChangeNotifier {
  final ValueNotifier<ResearchGroup> group;

  ResearchGroupDetailViewModel({
    required ResearchGroup initialGroup,
  }) : group = ValueNotifier(initialGroup);

  int get _groupId => group.value.id;

  // ================
  // State variables
  // ================

  // ---- Screen-level state ----
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // ---- Membership state ----
  final ValueNotifier<List<ResearchGroupMember>> members = ValueNotifier([]);
  final ValueNotifier<ResearchGroupMember?> myMembership = ValueNotifier(null);
  bool get isResearcher {
    if (myMembership.value != null) {
      return myMembership.value!.isResearcher;
    }
    return group.value.isResearcher;
  }

  // ---- Collector state ----
  final ValueNotifier<List<Collector>> collectors = ValueNotifier([]);

  // ---- Group event state ----
  final ValueNotifier<List<CrepeEvent>> groupEvents = ValueNotifier([]);
  final ValueNotifier<bool> isGroupEventsLoading = ValueNotifier(false);
  final ValueNotifier<bool> hasMoreGroupEvents = ValueNotifier(true);
  String? _groupEventsCursor;

  // ---- Member event state ----
  final ValueNotifier<List<CrepeEvent>> memberDetailEvents = ValueNotifier([]);
  final ValueNotifier<bool> isMemberDetailLoading = ValueNotifier(false);
  final ValueNotifier<bool> hasMoreMemberEvents = ValueNotifier(true);
  List<ResearchGroupMember> get otherMembers {
    final myId = myMembership.value?.membershipId;
    if (myId == null) return members.value;

    // Filter own membership out
    return members.value.where((m) => m.membershipId != myId).toList();
  }

  ResearchGroupMember? _currentDetailMember;
  String? _memberEventsCursor;

  // ================
  // INITIALIZATION
  // ================

  /// Loads the initial state of the research group dashboard
  Future<void> loadDetails() async {
    isInitialized.value = false;
    errorMessage.value = null;

    // Fetch group collectors, own membership, and group's Crepe events
    final futures = <Future>[
      rgCollectorRepo.listGroupCollectors(_groupId),
      membershipRepo.getMyMembership(_groupId),
      _loadGroupEvents(clearList: true)
    ];

    // Fetch membership list if researcher
    Future<MembersResult>? memberFuture;
    if (isResearcher) {
      memberFuture = membershipRepo.listResearchGroupMembers(_groupId);
      futures.add(memberFuture);
    }

    final results = await Future.wait(futures);

    // Handle collector result
    final collectorsRes = results[0] as CollectorsResult;
    collectorsRes.fold(
        onSuccess: (list) => collectors.value = list,
        onFailure: (ApiError e) => errorMessage.value = e.message);

    // Handle own membership result
    final ownMembershipRes = results[1] as MemberResult;
    ownMembershipRes.fold(
        onSuccess: (membership) => myMembership.value = membership,
        onFailure: (ApiError e) => errorMessage.value = e.message);

    // Handle membership list result if researcher
    if (memberFuture != null) {
      (results.last as MembersResult).fold(
          onSuccess: (list) => members.value = list,
          onFailure: (ApiError e) => errorMessage.value = e.message);
    }

    isInitialized.value = true;
  }

  // ================
  // RESEARCH GROUP
  // ================

  /// Adds a researcher member to the research group
  Future<bool> addResearcher(String email) async {
    if (!isResearcher) return false;

    final res = await membershipRepo.addResearcherByEmail(_groupId, email);

    return res.fold(onSuccess: (newMember) {
      final currentList = List<ResearchGroupMember>.from(members.value);

      // Upsert the member into current list
      final index = currentList
          .indexWhere((m) => m.membershipId == newMember.membershipId);

      if (index != -1) {
        currentList[index] =
            newMember; // Replace existing (promoting participant)
      } else {
        currentList.add(newMember); // Add new
      }

      // Sort to match backend
      currentList.sort((a, b) {
        final nameA = a.lastName.toLowerCase();
        final nameB = b.lastName.toLowerCase();
        int cmp = nameA.compareTo(nameB);
        if (cmp != 0) return cmp;
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      });

      members.value = currentList;
      return true;
    }, onFailure: (e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  /// Updates the research group's name and description
  Future<bool> updateGroup({String? name, String? description}) async {
    if (!isResearcher) return false;

    final res =
        await groupRepo.update(_groupId, name: name, description: description);

    return res.fold(onSuccess: (updatedGroup) {
      group.value = updatedGroup;
      return true;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  /// Deletes the research group and all related data
  Future<bool> deleteGroup() async {
    if (!isResearcher) return false;

    final res = await groupRepo.delete(_groupId);

    return res.fold(
        onSuccess: (_) => true,
        onFailure: (ApiError e) {
          errorMessage.value = e.message;
          return false;
        });
  }

  // ================
  // RESEARCH GROUP MEMBERSHIP
  // ================

  /// Retrieves the selected member's details and Crepe events for display
  Future<void> openMemberDetails(ResearchGroupMember member) async {
    _currentDetailMember = member;
    _memberEventsCursor = null;
    hasMoreMemberEvents.value = true;

    await _loadMemberEvents(clearList: true);
  }

  /// Kicks a member from the research group
  Future<bool> kickMember(int membershipId) async {
    if (!isResearcher) return false;

    final res = await membershipRepo.kick(_groupId, membershipId);
    return res.fold(onSuccess: (_) {
      final updatedList = members.value.map((m) {
        if (m.membershipId == membershipId) {
          // Make a copy with the unenrolled date set for the UI to update
          return m.copyWith(unenrolledAt: DateTime.now());
        }
        return m;
      }).toList();

      members.value = updatedList;
      return true;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  /// Updates the user's own membership details
  Future<bool> updateMyMembership({required String retentionPref}) async {
    final res = await membershipRepo.updateMembership(
      membershipId: myMembership.value!.membershipId,
      retentionPref: retentionPref,
    );

    return res.fold(onSuccess: (updated) {
      myMembership.value = updated;
      return true;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  /// Removes the user from the research group
  Future<bool> leaveGroup() async {
    final res = await membershipRepo.leave(myMembership.value!.membershipId);
    return res.fold(
        onSuccess: (_) => true,
        onFailure: (ApiError e) {
          errorMessage.value = e.message;
          return false;
        });
  }

  // ================
  // COLLECTORS
  // ================

  /// Deletes a collector from the research group
  Future<bool> deleteCollector(int collectorId) async {
    if (!isResearcher) return false;

    final res = await rgCollectorRepo.removeCollector(_groupId, collectorId);
    return res.fold(onSuccess: (_) {
      collectors.value =
          collectors.value.where((c) => c.collectorId != collectorId).toList();
      return true;
    }, onFailure: (ApiError e) {
      errorMessage.value = e.message;
      return false;
    });
  }

  // ================
  // CREPE EVENTS - GROUP FEED
  // ================

  /// Refreshes the list of the group's Crepe events
  Future<void> refreshGroupEvents() async {
    _groupEventsCursor = null;
    hasMoreGroupEvents.value = true;
    await _loadGroupEvents(clearList: true);
  }

  /// Loads more group Crepe events following the latest paginated result
  Future<void> loadMoreGroupEvents() async {
    if (!hasMoreGroupEvents.value || isGroupEventsLoading.value) return;
    await _loadGroupEvents(clearList: false);
  }

  Future<void> _loadGroupEvents({required bool clearList}) async {
    isGroupEventsLoading.value = true;
    if (clearList) groupEvents.value = [];

    Future<CrepeEventsPageResult> request;

    if (isResearcher) {
      // Researcher: main feed = all group events
      request = crepeRepo.listResearcherEventsForGroup(_groupId,
          cursor: _groupEventsCursor, limit: 30);
    } else {
      // Participant: main feed = my events
      request = crepeRepo.listParticipantEvents(
          groupId: _groupId, cursor: _groupEventsCursor, limit: 30);
    }

    final res = await request;
    res.fold(
        onSuccess: (page) {
          if (clearList) {
            groupEvents.value = page.items;
          } else {
            groupEvents.value = [...groupEvents.value, ...page.items];
          }
          _groupEventsCursor = page.nextCursor;
          hasMoreGroupEvents.value = page.hasNextPage;
        },
        onFailure: (ApiError e) => errorMessage.value = e.message);

    isGroupEventsLoading.value = false;
  }

  // ================
  // CREPE EVENTS - MEMBER FEED
  // ================

  /// Loads more Crepe events for the selected member following the
  /// latest paginated result
  Future<void> loadMoreMemberEvents() async {
    if (!hasMoreMemberEvents.value ||
        isMemberDetailLoading.value ||
        _currentDetailMember == null) {
      return;
    }

    await _loadMemberEvents(clearList: false);
  }

  Future<void> _loadMemberEvents({required bool clearList}) async {
    isMemberDetailLoading.value = true;

    if (clearList) {
      memberDetailEvents.value = [];
    }

    final requestedMemberId = _currentDetailMember?.membershipId;
    if (requestedMemberId == null) return;

    final res = await crepeRepo.listResearcherEventsForParticipant(
        groupId: _groupId,
        membershipId: requestedMemberId,
        cursor: _memberEventsCursor,
        limit: 15);

    res.fold(
        onSuccess: (page) {
          // Check we haven't switched members while loading
          if (_currentDetailMember?.membershipId != requestedMemberId) return;

          if (clearList) {
            memberDetailEvents.value = page.items;
          } else {
            memberDetailEvents.value = [
              ...memberDetailEvents.value,
              ...page.items
            ];
          }

          _memberEventsCursor = page.nextCursor;
          hasMoreMemberEvents.value = page.hasNextPage;
        },
        onFailure: (ApiError e) => errorMessage.value = e.message);

    isMemberDetailLoading.value = false;
  }
}
