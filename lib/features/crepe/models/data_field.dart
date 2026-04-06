/// Represents a data field configuration that defines what information to collect
/// from an app using a specific graph query and associated metadata.
class DataField {
  final int? dataFieldId;
  final String graphQuery;
  final String name;

  DataField({
    this.dataFieldId,
    required this.graphQuery,
    required this.name,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataField &&
        other.dataFieldId == dataFieldId &&
        other.graphQuery == graphQuery &&
        other.name == name;
  }

  @override
  int get hashCode {
    return Object.hash(dataFieldId, graphQuery, name);
  }
}
