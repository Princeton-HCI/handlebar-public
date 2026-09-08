import 'package:flutter/material.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../crepe/models/location_point.dart';

/// One recorded location fix in the collected-data list.
class LocationPointTile extends StatelessWidget {
  final LocationPoint point;
  final EdgeInsets margin;

  const LocationPointTile({
    super.key,
    required this.point,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Card(
      margin: margin,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(Spacing.token8),
      ),
      child: ListTile(
        leading: Icon(Icons.place, color: theme.colorScheme.primary),
        title: Text(
          point.hasCoordinates
              // Six decimals is ~10cm; more is noise given GPS accuracy.
              ? '${point.latitude!.toStringAsFixed(6)}, '
                  '${point.longitude!.toStringAsFixed(6)}'
              : 'Coordinates unavailable',
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        subtitle: Text(_details(point)),
        trailing: Text(
          DateFormat.jm().format(point.recordedAt),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }

  static String _details(LocationPoint p) {
    final parts = <String>[
      DateFormat.yMMMd().format(p.recordedAt),
      if (p.accuracy != null) '±${p.accuracy!.round()}m',
      // Reported in m/s; km/h is easier to sanity-check against driving.
      if (p.speed != null) '${(p.speed! * 3.6).toStringAsFixed(1)} km/h',
      if (p.activityType != null) p.activityType!,
    ];
    return parts.join(' · ');
  }
}
