import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../../models/research_group.dart';
import '../../view_models/research_group_detail_view_model.dart';
import '../dialogs/delete_group_dialog.dart';
import '../dialogs/edit_group_dialog.dart';

/// A header for a research group that displays its details (name, description,
/// code, and management actions)
class ResearchGroupInfoHeader extends StatelessWidget {
  final ResearchGroupDetailViewModel vm;

  const ResearchGroupInfoHeader({super.key, required this.vm});

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DeleteGroupDialog(vm: vm),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditGroupDialog(vm: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ResearchGroup>(
        valueListenable: vm.group,
        builder: (context, group, _) {
          final scheme = context.colorScheme;
          return Container(
            padding: const EdgeInsets.all(Spacing.token16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  group.name,
                  style: context.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),

                Spacing.vSpace8,

                // Description
                Text(
                  "Description: ${group.description}",
                  style: context.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                // Researcher-only content
                if (vm.isResearcher) ...[
                  Spacing.vSpace16,

                  // Code
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.token16,
                              vertical: Spacing.token8),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.key, size: 18, color: scheme.primary),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("GROUP CODE",
                                      style: context.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          letterSpacing: 0.5)),
                                  Text(
                                    group.code,
                                    style: context.titleMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  Spacing.vSpace16,

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Delete button
                      HandlebarButton(
                        text: "Delete",
                        variant: ButtonVariant.destructive,
                        isLoading: false,
                        minHeight: Spacing.token32,
                        prefixIcon: const Icon(Icons.delete_outline,
                            size: Spacing.token16, color: Colors.white),
                        onPressed: () => _showDeleteDialog(context),
                      ),

                      const SizedBox(width: 12),

                      // Edit Button
                      HandlebarButton(
                        text: "Edit",
                        variant: ButtonVariant.primary,
                        isLoading: false,
                        minHeight: Spacing.token32,
                        prefixIcon: Icon(Icons.edit_outlined,
                            size: Spacing.token16, color: scheme.onSurface),
                        onPressed: () => _showEditDialog(context),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          );
        });
  }
}
