import 'dart:developer';

/// Represents a successful match between collected data and a data field,
/// containing the matched value and metadata about who triggered the match
/// and when it occurred
class CollectorMatch {
  final int dataFieldId;
  final int membershipId;
  final int? collectorId;
  final String value;
  final List<dynamic> matchedNodes;
  final String? dataFieldName;
  final DateTime matchedAt;

  CollectorMatch({
    required this.dataFieldId,
    required this.membershipId,
    this.collectorId,
    required this.value,
    required this.matchedNodes,
    this.dataFieldName,
    DateTime? matchedAt,
  }) : matchedAt = matchedAt ?? DateTime.now();

  factory CollectorMatch.fromJson(Map<String, dynamic> json) {
    return CollectorMatch(
      dataFieldId: _parseId(json['datafieldId'] ?? json['data_field_id']),
      membershipId: _parseId(json['membership_id']),
      collectorId:
          json['collectorId'] != null ? _parseId(json['collectorId']) : null,
      value: json['value']?.toString() ?? json['content']?.toString() ?? '',
      matchedNodes: json['matchedNodes'] as List<dynamic>? ?? [],
      dataFieldName: json['name']?.toString(),
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'])
          : DateTime.now(),
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        log('Failed to parse ID from string: "$value", defaulting to -1',
            name: 'CollectorMatch');
      }
      return parsed ?? -1;
    }
    log('Unexpected ID type: ${value.runtimeType} (value: $value), defaulting to -1',
        name: 'CollectorMatch');
    return -1;
  }

  Map<String, dynamic> toContentJson() {
    return {
      'value': value,
      'matchedNodes': matchedNodes,
      'dataFieldName': dataFieldName,
      'matchedAt': matchedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'data_field_id': dataFieldId,
      'membership_id': membershipId,
      'collectorId': collectorId,
      'value': value,
      'matchedNodes': matchedNodes,
      'dataFieldName': dataFieldName,
      'matchedAt': matchedAt.toIso8601String(),
    };
  }
}
