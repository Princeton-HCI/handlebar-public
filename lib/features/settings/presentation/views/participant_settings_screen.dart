import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../../crepe/models/sensor_health.dart';
import '../view_models/participant_settings_view_model.dart';

class ParticipantSettingsScreen extends StatefulWidget {
  const ParticipantSettingsScreen({super.key});

  @override
  State<ParticipantSettingsScreen> createState() =>
      _ParticipantSettingsScreenState();
}

class _ParticipantSettingsScreenState extends State<ParticipantSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ParticipantSettingsViewModel>().refreshSensorHealth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permissions can change while the participant is in Android settings.
    if (state == AppLifecycleState.resumed) {
      context.read<ParticipantSettingsViewModel>().refreshSensorHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final vm = context.read<ParticipantSettingsViewModel>();

    return SafeScaffold(
      // The ListView below scrolls itself. SafeScaffold defaults to wrapping
      // its child in a SingleChildScrollView, which would give the ListView
      // unbounded height and throw instead of rendering. Padding is off for
      // the same reason: the ListView supplies its own.
      enableScrolling: false,
      usePadding: false,
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
              Spacing.vSpace24,
              // Only rendered when something is actually wrong. A card that is
              // usually green teaches people to stop reading it.
              ValueListenableBuilder<SensorHealth?>(
                valueListenable: vm.sensorHealth,
                builder: (context, health, _) {
                  if (health == null || !health.needsAttention) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.token24),
                    child: Card(
                      elevation: 0,
                      color: theme.colorScheme.errorContainer,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.error),
                        borderRadius: BorderRadius.circular(Spacing.token8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.warning_amber,
                            color: theme.colorScheme.error),
                        title: const Text('Data collection needs attention'),
                        subtitle: Text(health.participantMessage),
                      ),
                    ),
                  );
                },
              ),
              Text(
                'Permissions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Spacing.vSpace8,
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(Spacing.token8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Location access'),
                  subtitle: const Text(
                    'Required only for studies that collect location. '
                    'Review or change what you have granted.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/location-permission'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
