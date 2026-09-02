import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:handlebar/app/app_locator.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import 'package:handlebar/features/crepe/services/ui_snapshot_recording_service.dart';
import 'package:handlebar/features/crepe/data/snapshot_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';

import '../../../crepe/models/data_field.dart';
import '../../../research_group/data/research_group_repository.dart';
import '../../../crepe/models/screen_landmark.dart';
import '../widgets/recording_session_dialog.dart';
import 'video_session_view_model.dart';

/// Stepper state for the collector creation flow.
///
/// Owns a [VideoSessionViewModel] that holds the loaded recording, snapshots,
/// and data fields used across the three steps:
///   0 — Upload Recording
///   1 — Select Frame
///   2 — Select Landmarks
///   3 — Select Data Fields
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
  static const int totalSteps = 4;
  final ValueNotifier<int> currentStep = ValueNotifier(0);

  /// Researcher-provided name for the screen this collector targets.
  final ValueNotifier<String> screenName = ValueNotifier('');

  /// Screen landmarks selected by the researcher. Each landmark's text will
  /// be injected as a `SCREEN_HAS_TEXT` clause into every data field query
  /// when the collector is created.
  final ValueNotifier<List<ScreenLandmark>> screenLandmarks = ValueNotifier([]);

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
    return session.isInitialized.value ||
        selectedFields.value.isNotEmpty ||
        screenLandmarks.value.isNotEmpty;
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

  /// Adds a landmark, deduplicating by text content.
  void addLandmark(ScreenLandmark landmark) {
    if (screenLandmarks.value.contains(landmark)) return;
    screenLandmarks.value = [...screenLandmarks.value, landmark];
  }

  void removeLandmark(int index) {
    if (index < 0 || index >= screenLandmarks.value.length) return;
    final next = [...screenLandmarks.value]..removeAt(index);
    screenLandmarks.value = next;
  }

  /// Creates the collector via the underlying session VM, using the currently
  /// viewed snapshot for app metadata. Wraps each field's query with any
  /// selected screen landmarks before sending.
  Future<bool> createCollector(
    String name, {
    int collectionIntervalSeconds = 0,
  }) async {
    final landmarks = screenLandmarks.value;
    final fields = selectedFields.value
        .map((f) => f.copyWith(
              graphQuery: wrapQueryWithLandmarks(f.graphQuery, landmarks),
            ))
        .toList();

    final ok = await session.createCollectorFromSnapshot(
      snapshotIndex: session.currSnapshotIndex.value,
      description: name,
      fields: fields,
      screenLandmarks: landmarks.map((l) => l.text).toList(),
      screenName: screenName.value.isNotEmpty ? screenName.value : null,
      collectionIntervalSeconds: collectionIntervalSeconds,
    );
    if (ok) {
      resetForAnotherCollector();
    }
    return ok;
  }

  /// Clears the in-progress collector and returns to frame selection while
  /// keeping the loaded recording session.
  void resetForAnotherCollector() {
    selectedFields.value = [];
    screenLandmarks.value = [];
    screenName.value = '';
    goToStep(1);
  }

  /// Injects `SCREEN_HAS_TEXT` clauses for each landmark into a graph query.
  static String wrapQueryWithLandmarks(
    String query,
    List<ScreenLandmark> landmarks,
  ) {
    if (landmarks.isEmpty) return query;
    final clauses = landmarks
        .map((l) => '(SCREEN_HAS_TEXT "${l.text.replaceAll('"', '\\"')}")')
        .join(' ');
    final trimmed = query.trim();
    if (trimmed.startsWith('(conj ')) {
      return '(conj $clauses ${trimmed.substring(6)}';
    }
    return '(conj $clauses $trimmed)';
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

  /// Starts in-app screen + UI snapshot recording, then loads the session.
  Future<void> startNewRecording(BuildContext context) async {
    if (!Platform.isAndroid) {
      NotificationService().showError(
        'In-app recording is only available on Android',
      );
      return;
    }

    final result = await showDialog<RecordingSessionResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordingSessionDialog(),
    );
    if (result == null) return;

    await session.initializeFromRecording(result);
    UiSnapshotRecordingService().clearSnapshots();

    if (session.isInitialized.value) {
      next();
    } else if (session.errorMessage.value != null) {
      NotificationService().showError(session.errorMessage.value!);
    }
  }

  void dispose() {
    isResolvingCode.dispose();
    errorMessage.dispose();
    currentStep.dispose();
    screenName.dispose();
    screenLandmarks.dispose();

    selectedFields.dispose();
    // Only dispose session if it was actually initialized
    if (!isResolvingCode.value && errorMessage.value == null) {
      session.dispose();
    }
  }
}
