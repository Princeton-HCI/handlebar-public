import 'package:flutter/foundation.dart';

import '../../../crepe/models/data_field.dart';
import 'video_session_view_model.dart';

/// Stepper state for the collector creation flow.
///
/// Owns a [VideoSessionViewModel] that holds the loaded recording, snapshots,
/// and data fields used across the three steps:
///   0 — Upload Recording
///   1 — Select Frame
///   2 — Select Data Fields
class CollectorCreationViewModel extends ChangeNotifier {
  final VideoSessionViewModel session;

  CollectorCreationViewModel({required int groupId})
      : session = VideoSessionViewModel(groupId: groupId);

  static const int totalSteps = 3;

  final ValueNotifier<int> currentStep = ValueNotifier(0);

  /// Flat list of fields the user has selected for the collector under
  /// construction. Fields may originate from different snapshots in the
  /// recording — they all roll up into one collector.
  final ValueNotifier<List<DataField>> selectedFields = ValueNotifier([]);

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

  @override
  void dispose() {
    currentStep.dispose();
    selectedFields.dispose();
    session.dispose();
    super.dispose();
  }
}
