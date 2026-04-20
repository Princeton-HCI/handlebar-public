import 'package:flutter/foundation.dart';
import 'package:handlebar/app/app_locator.dart';
import 'package:handlebar/features/crepe/data/snapshot_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';

import '../../../crepe/models/data_field.dart';
import '../../../research_group/data/research_group_repository.dart';
import 'video_session_view_model.dart';

/// Stepper state for the collector creation flow.
///
/// Owns a [VideoSessionViewModel] that holds the loaded recording, snapshots,
/// and data fields used across the three steps:
///   0 — Upload Recording
///   1 — Select Frame
///   2 — Select Data Fields
class CollectorCreationViewModel {
  final String studyCode;
  final _rgRepo = getIt<ResearchGroupRepository>();

  // Use Late because we can't initialize it until we resolve the studyCode to an ID
  late final VideoSessionViewModel session;

  CollectorCreationViewModel({required this.studyCode});

  // ---- Resolution State ----
  final ValueNotifier<bool> isResolvingCode = ValueNotifier(true);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // ---- Stepper State ----
  static const int totalSteps = 3;
  final ValueNotifier<int> currentStep = ValueNotifier(0);

  /// Flat list of fields the user has selected for the collector under
  /// construction. Fields may originate from different snapshots in the
  /// recording — they all roll up into one collector.
  final ValueNotifier<List<DataField>> selectedFields = ValueNotifier([]);

  /// Resolves the study code to a group ID and initializes the session VM.
  /// Call this from initState in your Screen.
  Future<void> initialize() async {
    isResolvingCode.value = true;
    errorMessage.value = null;

    final result = await _rgRepo.lookupByCode(studyCode);

    result.fold(
      onSuccess: (group) {
        // Now that we have the real ID, we can spin up the session VM
        session = VideoSessionViewModel(
          groupId: group.id,
          rgCollectorRepo: getIt<ResearchGroupCollectorRepository>(),
          snapshotRepo: getIt<SnapshotRepository>(),
        );
        isResolvingCode.value = false;
      },
      onFailure: (error) {
        errorMessage.value = error.message;
        isResolvingCode.value = false;
      },
    );
  }

  /// True if there is unsaved progress that should warn the user on exit.
  bool get hasUnsavedProgress {
    return session.isInitialized.value || selectedFields.value.isNotEmpty;
  }

  void addField(DataField field) {
    selectedFields.value = [...selectedFields.value, field];
  }

  void updateField(int index, DataField field) {
    if (index < 0 || index >= selectedFields.value.length) return;
    final next = [...selectedFields.value];
    next[index] = field;
    selectedFields.value = next;
  }

  void removeField(int index) {
    if (index < 0 || index >= selectedFields.value.length) return;
    final next = [...selectedFields.value]..removeAt(index);
    selectedFields.value = next;
  }

  /// Creates the collector via the underlying session VM, using the currently
  /// viewed snapshot for app metadata.
  Future<bool> createCollector(String name) async {
    final ok = await session.createCollectorFromSnapshot(
      snapshotIndex: session.currSnapshotIndex.value,
      description: name,
      fields: selectedFields.value,
    );
    if (ok) {
      selectedFields.value = [];
    }
    return ok;
  }

  void goToStep(int step) {
    if (step < 0 || step >= totalSteps) return;
    currentStep.value = step;
  }

  void next() => goToStep(currentStep.value + 1);
  void back() => goToStep(currentStep.value - 1);

  /// Called by Step 1 once a recording has been loaded successfully.
  Future<void> uploadRecording() async {
    await session.loadFilesAndInitializeSession();
    if (session.isInitialized.value) {
      next();
    }
  }

  /// Placeholder for the in-app screen-recording flow. Wired up in a follow-up.
  Future<void> startNewRecording() async {
    // TODO(hb-collector-stepper): integrate UiSnapshotRecordingService flow,
    // then call session loader and advance the step.
  }

  void dispose() {
    isResolvingCode.dispose();
    errorMessage.dispose();
    currentStep.dispose();
    selectedFields.dispose();
    // Only dispose session if it was actually initialized
    if (!isResolvingCode.value && errorMessage.value == null) {
      session.dispose();
    }
  }
}
