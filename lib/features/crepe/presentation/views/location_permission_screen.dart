import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../services/location_permission_service.dart';
import '../view_models/location_permission_view_model.dart';

/// Walks a participant through Android's two-step location grant.
///
/// Modelled on [AccessibilityScreen]: re-checks on resume, because the
/// "Allow all the time" step on API 30+ hands the participant off to a
/// settings screen and returns nothing useful.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      context.read<LocationPermissionViewModel>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The settings-screen handoff means this is the only reliable way to learn
    // that background access was granted.
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      context.read<LocationPermissionViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final vm = context.read<LocationPermissionViewModel>();

    return ListenableBuilder(
      listenable: Listenable.merge([
        vm.status,
        vm.isLoading,
        vm.hasNotifications,
      ]),
      builder: (context, _) {
        return SafeScaffold(
          usePadding: true,
          enableScrolling: true,
          appBar: const HandlebarAppBar(
            title: 'Location Access',
            showBackArrow: true,
          ),
          child: _buildBody(context, theme, vm),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    LocationPermissionViewModel vm,
  ) {
    final status = vm.status.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Spacing.vSpace24,
        Icon(
          status == LocationPermissionStatus.always
              ? Icons.check_circle
              : Icons.location_on,
          size: 64,
          color: status == LocationPermissionStatus.always
              ? Colors.green
              : theme.colorScheme.primary,
        ),
        Spacing.vSpace24,
        Text(
          _title(status),
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Spacing.vSpace16,
        Text(
          _explanation(status),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        Spacing.vSpace24,
        _StepList(status: status),
        Spacing.vSpace24,
        if (status != LocationPermissionStatus.always)
          HandlebarButton.primary(
            label: _actionLabel(status),
            isLoading: vm.isLoading.value,
            onPressed: vm.isLoading.value ? null : () => vm.requestNext(),
          ),
        if (status == LocationPermissionStatus.always &&
            !vm.hasNotifications.value) ...[
          Spacing.vSpace8,
          Text(
            'Notifications are turned off, so you will not see when location '
            'is being collected. Collection still works.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          Spacing.vSpace8,
          HandlebarButton.neutral(
            label: 'Turn on notifications',
            onPressed: () => vm.openSettings(),
          ),
        ],
        if (status == LocationPermissionStatus.always) ...[
          Spacing.vSpace24,
          HandlebarButton.primary(
            label: 'Done',
            onPressed: () => context.pop(),
          ),
        ],
        Spacing.vSpace48,
      ],
    );
  }

  String _title(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.always:
        return 'Location access is set up';
      case LocationPermissionStatus.foregroundOnly:
        return 'One more step';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Location access is blocked';
      case LocationPermissionStatus.unsupported:
        return 'Not available on this device';
      case LocationPermissionStatus.denied:
        return 'This study collects location';
    }
  }

  String _explanation(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.always:
        return 'Location is only recorded while a study you joined is actively '
            'collecting. You can turn it off any time in Android settings.';
      case LocationPermissionStatus.foregroundOnly:
        return 'Android needs "Allow all the time" to record location while '
            'you are using other apps. Without it, nothing is recorded — the '
            'app is never on screen while you work.';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Android will not ask again. You can still grant it from the '
            'app settings screen.';
      case LocationPermissionStatus.unsupported:
        return 'Location collection is only available on Android.';
      case LocationPermissionStatus.denied:
        return 'Location is recorded only while a study is actively '
            'collecting — not all the time.';
    }
  }

  String _actionLabel(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.foregroundOnly:
        return 'Choose "Allow all the time"';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Open app settings';
      default:
        return 'Allow location access';
    }
  }
}

/// Makes the two-step grant legible, so a participant who lands in Android
/// settings knows which step they are on.
class _StepList extends StatelessWidget {
  final LocationPermissionStatus status;

  const _StepList({required this.status});

  @override
  Widget build(BuildContext context) {
    final foregroundDone = status == LocationPermissionStatus.foregroundOnly ||
        status == LocationPermissionStatus.always;
    final backgroundDone = status == LocationPermissionStatus.always;

    return Column(
      children: [
        _StepRow(
          done: foregroundDone,
          label: 'Allow location while using the app',
        ),
        Spacing.vSpace8,
        _StepRow(
          done: backgroundDone,
          label: 'Change it to "Allow all the time"',
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final bool done;
  final String label;

  const _StepRow({required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: done ? Colors.green : theme.disabledColor,
        ),
        Spacing.hSpace8,
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
