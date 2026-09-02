import 'data_field.dart';

/// Represents a data collector configuration for a specific app, containing
/// metadata about the target application and the data fields to collect from it.
class Collector {
  final int collectorId;
  final String appName;
  final String appPackage;
  final String description;
  final List<DataField> dataFields;

  /// Minimum seconds between captures for this collector. `null` or `0` means
  /// "collect every time it matches" (the default behavior).
  final int? collectionIntervalSeconds;

  Collector({
    required this.collectorId,
    required this.appName,
    required this.appPackage,
    required this.description,
    required this.dataFields,
    this.collectionIntervalSeconds,
  });

  factory Collector.fromJson(Map<String, dynamic> json) {
    return Collector(
      collectorId: json['collector_id'] as int,
      appName: json['app_name'] as String,
      appPackage: json['app_package'] as String,
      description: json['description'] as String,
      collectionIntervalSeconds: json['collection_interval_seconds'] as int?,
      dataFields: (json['datafields'] as List<dynamic>)
          .map((field) => DataField.fromJson(field))
          .toList(),
    );
  }

  Map<String, dynamic> toPluginFormat() {
    return {
      'collectorId': collectorId,
      'appName': appName,
      'appPackage': appPackage,
      'description': description,
      'collectionIntervalSeconds': collectionIntervalSeconds ?? 0,
      'datafields': dataFields.map((field) => field.toPluginFormat()).toList(),
    };
  }

  Collector copyWith({
    int? collectorId,
    String? appName,
    String? appPackage,
    String? description,
    List<DataField>? dataFields,
    int? collectionIntervalSeconds,
  }) {
    return Collector(
      collectorId: collectorId ?? this.collectorId,
      appName: appName ?? this.appName,
      appPackage: appPackage ?? this.appPackage,
      description: description ?? this.description,
      dataFields: dataFields ?? this.dataFields,
      collectionIntervalSeconds:
          collectionIntervalSeconds ?? this.collectionIntervalSeconds,
    );
  }

  @override
  String toString() {
    return 'Collector(collectorId: $collectorId, appName: $appName, appPackage: $appPackage, description: $description, collectionIntervalSeconds: $collectionIntervalSeconds, dataFields: $dataFields)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collector &&
        other.collectorId == collectorId &&
        other.appName == appName &&
        other.appPackage == appPackage &&
        other.description == description &&
        other.collectionIntervalSeconds == collectionIntervalSeconds &&
        other.dataFields == dataFields;
  }

  @override
  int get hashCode {
    return Object.hash(collectorId, appName, appPackage, description,
        collectionIntervalSeconds, dataFields);
  }
}
