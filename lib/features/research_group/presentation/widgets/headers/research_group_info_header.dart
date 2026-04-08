import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../../core/shared_widgets/buttons/handlebar_button.dart';
import '../../../models/research_group.dart';
import '../../view_models/research_group_detail_view_model.dart';
import '../dialogs/delete_group_dialog.dart';

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
                  group.description,
                  style: context.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                // Researcher-only: Delete button (Edit moved to participant section)
                if (vm.isResearcher) ...[
                  Spacing.vSpace16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      HandlebarButton(
                        text: "Delete Study",
                        variant: ButtonVariant.destructive,
                        isLoading: false,
                        minHeight: Spacing.token32,
                        prefixIcon: const Icon(Icons.delete_outline,
                            size: Spacing.token16, color: Colors.white),
                        onPressed: () => _showDeleteDialog(context),
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
