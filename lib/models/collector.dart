import 'data_field.dart';

/// Represents a data collector configuration for a specific app, containing
/// metadata about the target application and the data fields to collect from it.
class Collector {
  final int collectorId;
  final String appName;
  final String appPackage;
  final String? description;
  final List<DataField> dataFields;

  Collector({
    required this.collectorId,
    required this.appName,
    required this.appPackage,
    this.description,
    required this.dataFields,
  });

  factory Collector.fromJson(Map<String, dynamic> json) {
    return Collector(
      collectorId: json['collector_id'] as int,
      appName: json['app_name'] as String,
      appPackage: json['app_package'] as String,
      description: json['description'] as String?,
      dataFields: (json['datafields'] as List<dynamic>)
          .map((field) => DataField.fromJson(field))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collector_id': collectorId,
      'app_name': appName,
      'app_package': appPackage,
      'description': description,
      'datafields': dataFields.map((field) => field.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Collector(collectorId: $collectorId, appName: $appName, appPackage: $appPackage, description: $description, dataFields: $dataFields)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collector &&
        other.collectorId == collectorId &&
        other.appName == appName &&
        other.appPackage == appPackage &&
        other.description == description &&
        other.dataFields == dataFields;
  }

  @override
  int get hashCode {
    return Object.hash(
        collectorId, appName, appPackage, description, dataFields);
  }
}
