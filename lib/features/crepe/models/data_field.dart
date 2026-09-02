import 'crepe_event_values.dart';

/// Represents a data field configuration that defines what information to collect
/// from an app using a specific graph query and associated metadata.
class DataField {
  final int? dataFieldId;
  final String graphQuery;
  final String name;

  /// Entity the researcher tapped when defining this field (collector UI only).
  final int? sourceEntityId;

  /// Snapshot index in the recording where [sourceEntityId] was selected.
  final int? sourceSnapshotIndex;

  /// Text values captured when the field was defined (collector UI only).
  final CrepeEventValues? capturedValues;

  DataField({
    this.dataFieldId,
    required this.graphQuery,
    required this.name,
    this.sourceEntityId,
    this.sourceSnapshotIndex,
    this.capturedValues,
  });

  factory DataField.fromJson(Map<String, dynamic> json) {
    return DataField(
      dataFieldId: json['data_field_id'] as int?,
      graphQuery: json['graph_query'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toPluginFormat() {
    return {
      'datafieldId': dataFieldId?.toString(),
      'graphQuery': graphQuery,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'DataField(dataFieldId: $dataFieldId, graphQuery: $graphQuery, name: $name)';
  }

  DataField copyWith({
    int? dataFieldId,
    String? graphQuery,
    String? name,
    int? sourceEntityId,
    int? sourceSnapshotIndex,
    CrepeEventValues? capturedValues,
  }) {
    return DataField(
      dataFieldId: dataFieldId ?? this.dataFieldId,
      graphQuery: graphQuery ?? this.graphQuery,
      name: name ?? this.name,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      sourceSnapshotIndex: sourceSnapshotIndex ?? this.sourceSnapshotIndex,
      capturedValues: capturedValues ?? this.capturedValues,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataField &&
        other.dataFieldId == dataFieldId &&
        other.graphQuery == graphQuery &&
        other.name == name &&
        other.sourceEntityId == sourceEntityId &&
        other.sourceSnapshotIndex == sourceSnapshotIndex &&
        other.capturedValues == capturedValues;
  }

  @override
  int get hashCode {
    return Object.hash(
      dataFieldId,
      graphQuery,
      name,
      sourceEntityId,
      sourceSnapshotIndex,
      capturedValues,
    );
  }
}
