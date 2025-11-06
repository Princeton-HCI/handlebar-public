import 'dart:developer';
import 'crepe_event.dart';

/// Represents a successful match between collected data and a data field,
/// containing the matched value and metadata about when and what was matched.
class CollectorMatch {
  final int dataFieldId;
  final String value;
  final int? collectorId;
  final String? dataFieldName;
  final DateTime matchedAt;

  CollectorMatch({
    required this.dataFieldId,
    required this.value,
    this.collectorId,
    this.dataFieldName,
    DateTime? matchedAt,
  }) : matchedAt = matchedAt ?? DateTime.now();

  factory CollectorMatch.fromJson(Map<String, dynamic> json) {
    return CollectorMatch(
      dataFieldId: _parseId(json['datafieldId'] ?? json['data_field_id']),
      value: json['value']?.toString() ?? json['content']?.toString() ?? '',
      collectorId:
          json['collectorId'] != null ? _parseId(json['collectorId']) : null,
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

  Map<String, dynamic> toJson() {
    return {
      'data_field_id': dataFieldId,
      'value': value,
      'collectorId': collectorId,
      'dataFieldName': dataFieldName,
      'matchedAt': matchedAt.toIso8601String(),
    };
  }

  CrepeEvent toCrepeEvent() {
    return CrepeEvent(
      dataFieldId: dataFieldId,
      collectedAt: matchedAt,
      content: value,
    );
  }
}
