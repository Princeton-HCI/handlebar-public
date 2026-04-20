import 'package:flutter/foundation.dart';
import 'package:handlebar/features/research_group/data/research_group_membership_repository.dart';
import '../../../../app/app_locator.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../research_group/models/research_group.dart';

class ParticipantHomeViewModel {
  final _rgRepo = getIt<ResearchGroupRepository>();
  final _rgMembershipRepo = getIt<ResearchGroupMembershipRepository>();

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<ResearchGroup>> studies = ValueNotifier([]);

  Future<void> loadStudies() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.listUserResearchGroups();

    result.fold(
      onSuccess: (allGroups) {
        // Filter strictly for studies this user is participating in
        studies.value = allGroups.where((g) => !g.isResearcher).toList();
      },
      onFailure: (error) {
        errorMessage.value = error.message;
      },
    );

    isLoading.value = false;
  }

  // ==========================================
  // JOIN STUDY LOGIC
  // ==========================================

  /// Step 1: Verify the code exists and get the study info
  Future<ResearchGroup?> lookupGroup(String code) async {
    errorMessage.value = null;

    final result = await _rgRepo.lookupByCode(code);

    return result.fold(
      onSuccess: (group) => group,
      onFailure: (error) {
        errorMessage.value = error.message;
        return null;
      },
    );
  }

  /// Step 2: Actually enroll the user
  Future<bool> joinGroup(String code) async {
    errorMessage.value = null;

    final result = await _rgMembershipRepo.joinByCode(code);

    return result.fold(
      onSuccess: (_) async {
        // Refresh the list locally so the new study appears when the dialog closes
        await loadStudies();
        return true;
      },
      onFailure: (error) {
        errorMessage.value = error.message;
        return false;
      },
    );
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    studies.dispose();
  }
}
