import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../study/data/models/research_study.dart';

class ParticipantHomeViewModel {
  final ResearchGroupRepository _rgRepo;

  ParticipantHomeViewModel({required ResearchGroupRepository rgRepo})
      : _rgRepo = rgRepo;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<ResearchStudy>> studies = ValueNotifier([]);

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

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    studies.dispose();
  }
}
