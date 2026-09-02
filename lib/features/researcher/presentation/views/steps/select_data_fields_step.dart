import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../../../crepe/models/data_field.dart';
import '../../../../crepe/models/screen_landmark.dart';
import '../../view_models/collector_creation_view_model.dart';
import '../../widgets/data_field_editor_sheet.dart';
import '../../widgets/name_collector_dialog.dart';
import '../../widgets/selected_fields_panel.dart';
import '../../widgets/snapshot_overlay.dart';

/// Step 3: tap red bounding boxes to add data fields, navigate snapshots
/// to select fields from multiple frames, then create the collector.
class SelectDataFieldsStep extends StatelessWidget {
  const SelectDataFieldsStep({super.key});

  double _portraitAspectRatio(double original) =>
      original > 1.0 ? 1 / original : original;

  Future<void> _openEditor(
    BuildContext context, {
    required CollectorCreationViewModel vm,
    required List<Map<String, dynamic>> hitEntities,
    DataField? initial,
    int? editIndex,
  }) async {
    final session = vm.session;
    final snapshot = session.snapshots[session.currSnapshotIndex.value];

    // Exclude SCREEN_HAS_TEXT since landmarks handle screen scoping
    const relationsToExclude = ['SCREEN_HAS_TEXT'];

    final result = await showModalBottomSheet<DataField>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (_) => DataFieldEditorSheet(
        session: session,
        snapshot: snapshot,
        hitEntities: hitEntities,
        sourceSnapshotIndex: session.currSnapshotIndex.value,
        initial: initial,
        relationsToExclude: relationsToExclude,
      ),
    );

    if (result == null) return;
    if (editIndex != null) {
      vm.updateField(editIndex, result);
    } else {
      vm.addField(result);
    }
  }

  Future<void> _editExisting(
    BuildContext context,
    CollectorCreationViewModel vm,
    int index,
  ) async {
    final field = vm.selectedFields.value[index];
    // For edit, we don't have the original hit entities — pass empty so the
    // editor uses the existing field's name/query as the initial values.
    await _openEditor(
      context,
      vm: vm,
      hitEntities: const [],
      initial: field,
      editIndex: index,
    );
  }

  Future<void> _createCollector(
      BuildContext context, CollectorCreationViewModel vm) async {
    final result = await showDialog<CollectorNamingResult>(
      context: context,
      builder: (_) => const NameCollectorDialog(),
    );
    if (result == null || result.name.isEmpty) return;
    final ok = await vm.createCollector(
      result.name,
      collectionIntervalSeconds: result.collectionIntervalSeconds,
    );
    if (!context.mounted) return;
    if (ok) {
      NotificationService().showSuccess(
        'Collector created! Pick a frame to define another collector.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CollectorCreationViewModel>();
    final session = vm.session;

    return ValueListenableBuilder<bool>(
      valueListenable: session.isInitialized,
      builder: (context, isInit, _) {
        if (!isInit || session.videoController == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final controller = session.videoController!;
        final aspectRatio = _portraitAspectRatio(controller.value.aspectRatio);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.token16),
          child: Column(
            children: [
              // Snapshot with interactive bounding boxes
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  color: Colors.black,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final videoSize = controller.value.size;
                      final containerSize =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: videoSize.width,
                              height: videoSize.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                          SizedBox(
                            width: containerSize.width,
                            height: containerSize.height,
                            child: ValueListenableBuilder<int>(
                              valueListenable: session.currSnapshotIndex,
                              builder: (context, index, _) {
                                if (index >= session.snapshots.length) {
                                  return const SizedBox.shrink();
                                }
                                final snap = session.snapshots[index];
                                return ValueListenableBuilder<List<DataField>>(
                                  valueListenable: vm.selectedFields,
                                  builder: (context, fields, _) {
                                    return ValueListenableBuilder<
                                        List<ScreenLandmark>>(
                                      valueListenable: vm.screenLandmarks,
                                      builder: (context, landmarks, _) {
                                        final markers =
                                            <int, SelectedFieldMarker>{};
                                        for (var i = 0;
                                            i < fields.length;
                                            i++) {
                                          final f = fields[i];
                                          if (f.sourceSnapshotIndex == index &&
                                              f.sourceEntityId != null) {
                                            markers[f.sourceEntityId!] =
                                                SelectedFieldMarker(
                                              badgeNumber: i + 1,
                                            );
                                          }
                                        }
                                        return SnapshotOverlay(
                                          snapshot: snap,
                                          videoSize: videoSize,
                                          containerSize: containerSize,
                                          originalDeviceSize:
                                              session.deviceSize,
                                          landmarkEntityIds: landmarks
                                              .map((l) => l.entityId)
                                              .toSet(),
                                          selectedFieldMarkers: markers,
                                          onIntersectTap: (hits) => _openEditor(
                                            context,
                                            vm: vm,
                                            hitEntities: hits,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Spacing.vSpace8,
              Text(
                'Green numbered boxes are selected fields.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Spacing.vSpace8,

              // Snapshot navigation arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: Spacing.token32,
                    onPressed: () => session.seekBySnapshots(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: Spacing.token32,
                    onPressed: () => session.seekBySnapshots(1),
                  ),
                ],
              ),
              Spacing.vSpace8,

              // Selected fields panel
              ValueListenableBuilder<List<DataField>>(
                valueListenable: vm.selectedFields,
                builder: (context, fields, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: session.currSnapshotIndex,
                    builder: (context, idx, _) => SelectedFieldsPanel(
                      fields: fields,
                      currentSnapshot: idx,
                      totalSnapshots: session.snapshots.length,
                      onEdit: (i) => _editExisting(context, vm, i),
                      onDelete: vm.removeField,
                    ),
                  );
                },
              ),
              Spacing.vSpace16,

              // Create Collector
              ValueListenableBuilder<List<DataField>>(
                valueListenable: vm.selectedFields,
                builder: (context, fields, _) {
                  final enabled = fields.isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    child: HandlebarOldButton(
                      text: 'Create Collector',
                      variant: ButtonVariant.primary,
                      isLoading: false,
                      prefixIcon: enabled
                          ? const Icon(Icons.check, size: Spacing.token24)
                          : null,
                      onPressed:
                          enabled ? () => _createCollector(context, vm) : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
