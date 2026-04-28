import 'package:flutter/foundation.dart';
import '../../../../core/network/api_error.dart';
import '../../../research_group/data/research_group_repository.dart';

class CreateStudyViewModel {
  final ResearchGroupRepository _rgRepo;

  CreateStudyViewModel({required ResearchGroupRepository rgRepo})
      : _rgRepo = rgRepo;

  final ValueNotifier<bool> isSubmitting = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// Returns true if a study was successfully created, false if it failed
  Future<bool> createStudy(String name, String description) async {
    isSubmitting.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.create(name: name, description: description);

    bool success = false;
    result.fold(
      onSuccess: (_) {
        success = true;
      },
      onFailure: (ApiError error) {
        errorMessage.value = error.message;
        success = false;
      },
    );

    isSubmitting.value = false;
    return success;
  }

  void dispose() {
    isSubmitting.dispose();
    errorMessage.dispose();
  }
}
