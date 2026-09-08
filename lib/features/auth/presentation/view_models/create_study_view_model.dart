import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../study/data/models/research_study.dart';

class CreateStudyViewModel {
  final ResearchGroupRepository _rgRepo;

  CreateStudyViewModel({required ResearchGroupRepository rgRepo})
      : _rgRepo = rgRepo;

  final ValueNotifier<bool> isSubmitting = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// Returns the created study, or null if creation failed (with
  /// [errorMessage] set).
  Future<ResearchStudy?> createStudy(String name, String description) async {
    isSubmitting.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.create(name: name, description: description);

    ResearchStudy? created;
    result.fold(
      onSuccess: (study) => created = study,
      onFailure: (ApiError error) => errorMessage.value = error.message,
    );

    isSubmitting.value = false;
    return created;
  }

  void dispose() {
    isSubmitting.dispose();
    errorMessage.dispose();
  }
}
