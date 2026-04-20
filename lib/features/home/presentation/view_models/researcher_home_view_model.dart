import 'package:flutter/foundation.dart';
import '../../../../app/app_locator.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../research_group/models/research_group.dart';

class ResearcherHomeViewModel {
  // TODO: Change to constructor injection for later testing
  final _rgRepo = getIt<ResearchGroupRepository>();

  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<ResearchGroup>> studies = ValueNotifier([]);

  Future<void> loadStudies() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.listUserResearchGroups();

    result.fold(
      onSuccess: (allGroups) {
        // Filter strictly for studies this user manages
        studies.value = allGroups.where((g) => g.isResearcher).toList();
      },
      onFailure: (error) {
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
