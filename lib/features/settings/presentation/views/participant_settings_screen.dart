import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../view_models/participant_settings_view_model.dart';

class ParticipantSettingsScreen extends StatelessWidget {
  const ParticipantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final vm = context.read<ParticipantSettingsViewModel>();

    return SafeScaffold(
      appBar: const HandlebarAppBar(
        title: 'Settings',
        showBackArrow: false,
        showMenu: true,
      ),
      endDrawer: const HandlebarMobileDrawer(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.token768),
          child: ListView(
            padding: const EdgeInsets.all(Spacing.token24),
            children: [
              Text(
                'Data Collection',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Spacing.vSpace8,
              ValueListenableBuilder<bool>(
                valueListenable: vm.showCollectorOverlays,
                builder: (context, show, _) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(Spacing.token8),
                    ),
                    child: SwitchListTile(
                      title: const Text('Show collection cards'),
                      subtitle: const Text(
                        'Briefly highlight on screen when data is collected. '
                        'Turning this off does not change what is collected.',
                      ),
                      value: show,
                      onChanged: (value) => vm.setShowCollectorOverlays(value),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
