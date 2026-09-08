import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/app_locator.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../crepe/models/sensor_config.dart';
import '../../../crepe/services/location_permission_service.dart';

/// Prompts a participant to grant location access when the study they are
/// looking at actually collects it.
///
/// Without this nothing ever asks: the permission screen is otherwise only
/// reachable from participant settings, which a participant has no reason to
/// visit. A study would silently collect nothing.
///
/// Re-checks on resume because granting "Allow all the time" happens on an
/// Android settings screen, so returning to the app is the only signal.
class LocationPermissionBanner extends StatefulWidget {
  final List<SensorConfig> sensors;

  /// Researchers see the study's configuration but never collect on their own
  /// device, so they are not prompted.
  final bool isResearcher;

  const LocationPermissionBanner({
    super.key,
    required this.sensors,
    required this.isResearcher,
  });

  @override
  State<LocationPermissionBanner> createState() =>
      _LocationPermissionBannerState();
}

class _LocationPermissionBannerState extends State<LocationPermissionBanner>
    with WidgetsBindingObserver {
  LocationPermissionStatus? _status;

  bool get _studyCollectsLocation =>
      widget.sensors.any((s) => s.isLocation && s.enabled && !s.isDormant);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didUpdateWidget(covariant LocationPermissionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sensors load asynchronously, so the first build often has none.
    if (oldWidget.sensors.length != widget.sensors.length) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (kIsWeb || widget.isResearcher || !_studyCollectsLocation) return;
    final status = await getIt<LocationPermissionService>().check();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (kIsWeb ||
        widget.isResearcher ||
        !_studyCollectsLocation ||
        status == null ||
        status == LocationPermissionStatus.always ||
        status == LocationPermissionStatus.unsupported) {
      return const SizedBox.shrink();
    }

    final theme = context.theme;
    // foregroundOnly looks granted but collects nothing, so it is called out
    // as firmly as an outright denial.
    final partial = status == LocationPermissionStatus.foregroundOnly;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.token16),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.errorContainer,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(Spacing.token8),
        ),
        child: ListTile(
          leading: Icon(Icons.location_off, color: theme.colorScheme.error),
          title: Text(
            partial
                ? 'Location access needs one more step'
                : 'This study needs location access',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            partial
                ? 'Android needs "Allow all the time". Right now nothing is '
                    'being recorded.'
                : 'No location is being recorded for this study yet.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/location-permission'),
        ),
      ),
    );
  }
}
