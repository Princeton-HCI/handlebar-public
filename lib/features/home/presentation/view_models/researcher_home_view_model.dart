import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../study/data/models/research_study.dart';

class ResearcherHomeViewModel {
  final ResearchGroupRepository _rgRepo;

  ResearcherHomeViewModel({required ResearchGroupRepository rgRepo})
      : _rgRepo = rgRepo;

  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<ResearchStudy>> studies = ValueNotifier([]);

  Future<void> loadStudies() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.listUserResearchGroups();

    result.fold(
      onSuccess: (allGroups) {
        // Filter strictly for studies this user manages
        studies.value = allGroups.where((g) => g.isResearcher).toList();
      },
      onFailure: (ApiError error) {
        errorMessage.value = error.message;
      },
    );

    isLoading.value = false;
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    studies.dispose();
  }
}
