import 'package:flutter/material.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/sensor_config.dart';
import '../../../crepe/utils/collector_grouping.dart';
import '../../../crepe/utils/sensor_options.dart';

/// What the researcher chose in [SensorConfigDialog]. The caller performs the
/// network call (same convention as NameCollectorDialog).
class SensorConfigDraft {
  final int sampleIntervalSeconds;
  final SensorTriggerType triggerType;
  final String? triggerAppPackage;
  final int? triggerCollectorId;
  final int? timeoutSeconds;

  const SensorConfigDraft({
    required this.sampleIntervalSeconds,
    required this.triggerType,
    this.triggerAppPackage,
    this.triggerCollectorId,
    this.timeoutSeconds,
  });

  /// Backend-keyed map of only the fields that differ from [existing].
  /// Trigger target keys are always included when the trigger type changes so
  /// the server validates against a consistent pair.
  Map<String, dynamic> diffAgainst(SensorConfig existing) {
    final out = <String, dynamic>{};
    if (sampleIntervalSeconds != existing.sampleIntervalSeconds) {
      out['sample_interval_seconds'] = sampleIntervalSeconds;
    }
    final triggerChanged = triggerType != existing.triggerType ||
        triggerAppPackage != existing.triggerAppPackage ||
        triggerCollectorId != existing.triggerCollectorId;
    if (triggerChanged) {
      out['trigger_type'] = triggerType.wire;
      out['trigger_app_package'] = triggerAppPackage;
      out['trigger_collector_id'] = triggerCollectorId;
    }
    if (timeoutSeconds != existing.timeoutSeconds) {
      out['timeout_seconds'] = timeoutSeconds;
    }
    return out;
  }
}

/// Sentinel dropdown value meaning "type a package name".
const String _kOtherApp = '__other__';

/// Add/edit dialog for a location sensor. Returns a [SensorConfigDraft] on
/// save, or null if cancelled. Presets only for interval and timeout for now
/// (see the note in sensor_options.dart).
class SensorConfigDialog extends StatefulWidget {
  /// When non-null, the dialog edits this sensor and pre-fills its values.
  final SensorConfig? existing;

  /// The study's collectors, used to offer app packages and collector
  /// targets for the trigger.
  final List<Collector> collectors;

  const SensorConfigDialog({
    super.key,
    this.existing,
    required this.collectors,
  });

  @override
  State<SensorConfigDialog> createState() => _SensorConfigDialogState();
}

class _SensorConfigDialogState extends State<SensorConfigDialog> {
  late SensorTriggerType _triggerType;
  late int _intervalSeconds;
  late int? _timeoutSeconds;
  late String? _appChoice; // a package, _kOtherApp, or null
  late int? _collectorId;
  final _customPackageCtrl = TextEditingController();

  late final List<TriggerAppOption> _apps;

  @override
  void initState() {
    super.initState();
    // Known gig apps first, then any other app this study collects from.
    _apps = triggerAppOptions(groupCollectorsByApp(widget.collectors));
    // Re-evaluate validity as the custom package is typed.
    _customPackageCtrl.addListener(() => setState(() {}));

    final e = widget.existing;
    // _apps always has the known gig apps, so app_foreground is a usable
    // default even for a study with no collectors yet.
    _triggerType = e?.triggerType ?? SensorTriggerType.appForeground;
    _intervalSeconds =
        e?.sampleIntervalSeconds ?? kLocationSampleIntervalOptions[1].seconds;
    _timeoutSeconds = e == null
        ? kLocationTimeoutOptions[1].seconds
        : e.timeoutSeconds; // null = never, preserved on edit
    _collectorId = e?.triggerCollectorId;

    final pkg = e?.triggerAppPackage;
    if (pkg != null && _apps.any((a) => a.appPackage == pkg)) {
      _appChoice = pkg;
    } else if (pkg != null) {
      _appChoice = _kOtherApp;
      _customPackageCtrl.text = pkg;
    } else {
      _appChoice = _apps.first.appPackage;
    }
  }

  @override
  void dispose() {
    _customPackageCtrl.dispose();
    super.dispose();
  }

  String? get _resolvedPackage {
    if (_appChoice == _kOtherApp) {
      final t = _customPackageCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return _appChoice;
  }

  bool get _isValid => switch (_triggerType) {
        SensorTriggerType.always => true,
        SensorTriggerType.appForeground => _resolvedPackage != null,
        SensorTriggerType.collectorMatch => _collectorId != null,
      };

  void _submit() {
    if (!_isValid) return;
    Navigator.of(context).pop(SensorConfigDraft(
      sampleIntervalSeconds: _intervalSeconds,
      triggerType: _triggerType,
      triggerAppPackage: _triggerType == SensorTriggerType.appForeground
          ? _resolvedPackage
          : null,
      triggerCollectorId: _triggerType == SensorTriggerType.collectorMatch
          ? _collectorId
          : null,
      // null for `always`: a stored timeout there is dead config that
      // would silently reappear if the trigger type changed later.
      timeoutSeconds:
          _triggerType == SensorTriggerType.always ? null : _timeoutSeconds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Location Sensor' : 'Add Location Sensor'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Location is recorded on the participant's device while the trigger below is satisfied, and stops once it has not been satisfied for the timeout period.",
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
              Spacing.vSpace16,

              // ---- Trigger ----
              const Text('Start collecting:'),
              Spacing.vSpace8,
              DropdownButtonFormField<SensorTriggerType>(
                initialValue: _triggerType,
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                    value: SensorTriggerType.appForeground,
                    child: Text('While a specific app is open'),
                  ),
                  DropdownMenuItem(
                    value: SensorTriggerType.collectorMatch,
                    child: Text('When a data collector matches'),
                  ),
                  DropdownMenuItem(
                    value: SensorTriggerType.always,
                    child: Text('Always (while enrolled)'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _triggerType = v ?? _triggerType),
              ),

              if (_triggerType == SensorTriggerType.appForeground) ...[
                Spacing.vSpace16,
                const Text('App:'),
                Spacing.vSpace8,
                DropdownButtonFormField<String>(
                  initialValue: _appChoice,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    ..._apps.map((a) => DropdownMenuItem(
                          value: a.appPackage,
                          child: Text(
                            a.appName == a.appPackage
                                ? a.appPackage
                                : '${a.appName} (${a.appPackage})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                    const DropdownMenuItem(
                      value: _kOtherApp,
                      child: Text('Other app (enter package name)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _appChoice = v),
                ),
                if (_appChoice == _kOtherApp) ...[
                  Spacing.vSpace8,
                  HandlebarTextField(
                    controller: _customPackageCtrl,
                    hintText: 'e.g. com.dd.doordash',
                  ),
                ],
              ],

              if (_triggerType == SensorTriggerType.collectorMatch) ...[
                Spacing.vSpace16,
                const Text('Data collector:'),
                Spacing.vSpace8,
                if (widget.collectors.isEmpty)
                  Text(
                    'This study has no data collectors yet. Create one first, or choose a different trigger.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: widget.collectors
                            .any((c) => c.collectorId == _collectorId)
                        ? _collectorId
                        : null,
                    isExpanded: true,
                    hint: const Text('Choose a collector'),
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: widget.collectors
                        .map((c) => DropdownMenuItem(
                              value: c.collectorId,
                              child: Text(
                                c.description.isNotEmpty
                                    ? '${c.description} (${c.appPackage})'
                                    : c.appPackage,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _collectorId = v),
                  ),
              ],

              // ---- Interval ----
              Spacing.vSpace16,
              const Text('Record a location:'),
              Spacing.vSpace8,
              DropdownButtonFormField<int>(
                initialValue: kLocationSampleIntervalOptions
                        .any((o) => o.seconds == _intervalSeconds)
                    ? _intervalSeconds
                    : null,
                hint: Text(sensorIntervalLabel(_intervalSeconds)),
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: kLocationSampleIntervalOptions
                    .map((o) => DropdownMenuItem(
                          value: o.seconds,
                          child: Text(o.label),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _intervalSeconds = v ?? _intervalSeconds),
              ),

              // ---- Timeout ----
              //
              // Hidden entirely for an `always` trigger: that trigger is
              // satisfied on every tick, so the deadline can never expire.
              // Showing the control would imply collection stops when it
              // never would.
              if (_triggerType != SensorTriggerType.always) ...[
                Spacing.vSpace16,
                const Text('After the trigger is no longer satisfied:'),
                Spacing.vSpace8,
                DropdownButtonFormField<SensorTimeoutOption>(
                initialValue: kLocationTimeoutOptions
                    .where((o) => o.seconds == _timeoutSeconds)
                    .firstOrNull,
                hint: Text(sensorTimeoutLabel(_timeoutSeconds)),
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: kLocationTimeoutOptions
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _timeoutSeconds = v.seconds);
                },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        HandlebarButton.neutral(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        Spacing.hSpace16,
        HandlebarButton.primary(
          label: isEdit ? 'Save' : 'Add',
          onPressed: _isValid ? _submit : null,
        ),
      ],
    );
  }
}
