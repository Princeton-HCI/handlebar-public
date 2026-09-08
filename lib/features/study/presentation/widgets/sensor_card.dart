import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/sensor_config.dart';
import '../../../crepe/utils/sensor_options.dart';

/// One row in the study's Sensors section. Rendered flat (not grouped by
/// app) because a sensor belongs to the study, not to a collector.
class SensorCard extends StatelessWidget {
  final SensorConfig sensor;
  final List<Collector> collectors;
  final bool isResearcher;
  final VoidCallback onEdit;
  final VoidCallback onToggleEnabled;
  final VoidCallback onDelete;

  const SensorCard({
    super.key,
    required this.sensor,
    required this.collectors,
    required this.isResearcher,
    required this.onEdit,
    required this.onToggleEnabled,
    required this.onDelete,
  });

  static String titleFor(SensorConfig s) => switch (s.type) {
        SensorConfig.typeLocation => 'Location',
        _ => s.type,
      };

  /// e.g. "While com.dd.doordash is open · every 30s · stops after 30m"
  static String describe(SensorConfig s, List<Collector> collectors) {
    final trigger = switch (s.triggerType) {
      SensorTriggerType.always => 'Always on',
      SensorTriggerType.appForeground =>
        'While ${triggerAppLabel(s.triggerAppPackage)} is open',
      SensorTriggerType.collectorMatch => () {
          final c = collectors
              .where((c) => c.collectorId == s.triggerCollectorId)
              .firstOrNull;
          if (c == null) return 'When a deleted collector matches';
          final name = c.description.isNotEmpty ? c.description : 'collector';
          return 'When "$name" matches';
        }(),
    };
    final interval = 'every ${formatDurationShort(s.sampleIntervalSeconds)}';

    // An `always` trigger is satisfied on every tick, so its deadline can
    // never expire. 
    if (s.triggerType == SensorTriggerType.always) {
      return '$trigger · $interval';
    }

    final timeout = switch (s.timeoutSeconds) {
      null => 'never stops',
      final t => 'stops after ${formatDurationShort(t)}',
    };
    return '$trigger · $interval · $timeout';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final muted = !sensor.enabled || sensor.isDormant;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.token8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: muted ? theme.colorScheme.outline : theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(Spacing.token8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.token16,
          vertical: Spacing.token16,
        ),
        leading: Icon(
          sensor.isLocation ? Icons.location_on : Icons.sensors,
          size: 28,
          color: muted
              ? theme.colorScheme.outline
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Text(
              titleFor(sensor),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: muted
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (!sensor.enabled) ...[
              Spacing.hSpace8,
              _chip(theme, 'Disabled'),
            ] else if (sensor.isDormant) ...[
              Spacing.hSpace8,
              _chip(theme, 'Needs a collector', isWarning: true),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            describe(sensor, collectors),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: isResearcher
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'toggle') onToggleEnabled();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 20, color: Colors.black87),
                        SizedBox(width: 12),
                        Text('Edit Sensor'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          sensor.enabled
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 20,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(sensor.enabled ? 'Disable' : 'Enable'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Sensor',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, {bool isWarning = false}) {
    final color =
        isWarning ? theme.colorScheme.error : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(Spacing.token8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
