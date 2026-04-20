import 'package:flutter/foundation.dart';
import '../../../../app/app_locator.dart';
import '../../../research_group/data/research_group_repository.dart';

class CreateStudyViewModel {
  // TODO: Constructor injection instead for testing later
  final _rgRepo = getIt<ResearchGroupRepository>();

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
      onFailure: (error) {
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
