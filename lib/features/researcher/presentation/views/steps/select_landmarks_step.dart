import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/shared_services/notification_service.dart';
import '../../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../crepe/models/screen_landmark.dart';
import '../../view_models/collector_creation_view_model.dart';
import '../../widgets/data_field_editor_sheet.dart';
import '../../widgets/snapshot_overlay.dart';

/// Step 3: name the screen and select landmarks to scope the collector.
///
/// Researchers name the target screen (e.g., "Offer Screen"), then tap text
/// entities on the snapshot overlay to mark them as landmarks. Each landmark's
/// text becomes a `SCREEN_HAS_TEXT` clause in every data field query.
class SelectLandmarksStep extends StatefulWidget {
  const SelectLandmarksStep({super.key});

  @override
  State<SelectLandmarksStep> createState() => _SelectLandmarksStepState();
}

class _SelectLandmarksStepState extends State<SelectLandmarksStep> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CollectorCreationViewModel>();
    _nameCtrl = TextEditingController(text: vm.screenName.value);
    _nameCtrl.addListener(() {
      vm.screenName.value = _nameCtrl.text.trim();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  double _portraitAspectRatio(double original) =>
      original > 1.0 ? 1 / original : original;

  void _addLandmark(
    CollectorCreationViewModel vm,
    List<Map<String, dynamic>> hitEntities,
  ) {
    final text = DataFieldEditorSheet.extractEntityText(hitEntities);
    if (text == null || text.isEmpty) {
      NotificationService().showError('No text found on this element');
      return;
    }
    final entity = hitEntities.first;
    final entityId = entity['entityId'] as int;
    final landmark = ScreenLandmark(entityId: entityId, text: text);
    if (vm.screenLandmarks.value.contains(landmark)) {
      NotificationService().showError('Landmark "$text" already added');
      return;
    }
    vm.addLandmark(landmark);
    NotificationService().showSuccess('Landmark added: "$text"');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen name field
              Text('Name this screen:', style: context.labelLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Offer Screen, Earnings Screen',
                ),
              ),
              Spacing.vSpace16,

              // Instruction text
              Center(
                child: Text(
                  'Tap text elements that identify this screen. '
                  'These landmarks help the collector only match on the correct screen.',
                  style: context.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Spacing.vSpace8,

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
                                return ValueListenableBuilder<
                                    List<ScreenLandmark>>(
                                  valueListenable: vm.screenLandmarks,
                                  builder: (context, landmarks, _) {
                                    return SnapshotOverlay(
                                      snapshot: snap,
                                      videoSize: videoSize,
                                      containerSize: containerSize,
                                      originalDeviceSize: session.deviceSize,
                                      landmarkEntityIds: landmarks
                                          .map((l) => l.entityId)
                                          .toSet(),
                                      onIntersectTap: (hits) =>
                                          _addLandmark(vm, hits),
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

              // Selected landmarks panel
              ValueListenableBuilder<List<ScreenLandmark>>(
                valueListenable: vm.screenLandmarks,
                builder: (context, landmarks, _) {
                  return _LandmarksPanel(
                    landmarks: landmarks,
                    onDelete: vm.removeLandmark,
                  );
                },
              ),
              Spacing.vSpace16,

              // Continue button (requires screen name)
              ValueListenableBuilder<String>(
                valueListenable: vm.screenName,
                builder: (context, name, _) {
                  final enabled = name.isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    child: HandlebarButton.primary(
                      label: 'Continue',
                      icon: enabled ? Icons.arrow_forward : null,
                      isLoading: false,
                      onPressed: enabled ? () => vm.next() : null,
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

class _LandmarksPanel extends StatelessWidget {
  final List<ScreenLandmark> landmarks;
  final void Function(int index) onDelete;

  const _LandmarksPanel({
    required this.landmarks,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.token16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, size: 20, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Screen Landmarks',
                  style: context.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Spacing.vSpace8,
          if (landmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.token16),
              child: Center(
                child: Text(
                  'No landmarks selected. Tap text elements above to add '
                  'screen context. Landmarks are optional but recommended.',
                  textAlign: TextAlign.center,
                  style: context.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < landmarks.length; i++)
                  Chip(
                    avatar: Icon(Icons.bookmark,
                        size: 16, color: Colors.amber[700]),
                    label: Text(landmarks[i].text),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onDelete(i),
                    backgroundColor: Colors.amber.withValues(alpha: 0.1),
                    side:
                        BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
