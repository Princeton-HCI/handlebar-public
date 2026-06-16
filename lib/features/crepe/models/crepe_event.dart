import 'dart:convert';

import 'crepe_event_values.dart';

/// Represents a collected data event that contains the actual content gathered
/// from an app at a specific timestamp, associated with a particular data field
/// and research group membership.
class CrepeEvent {
  final int? id;
  final int dataFieldId;
  final int membershipId;
  final DateTime collectedAt;
  final String content;

  // when coming from backend for display
  final int? groupId;
  final String? groupName;

  CrepeEvent({
    this.id,
    required this.dataFieldId,
    required this.membershipId,
    required this.collectedAt,
    required this.content,
    this.groupId,
    this.groupName,
  });

  factory CrepeEvent.fromJson(Map<String, dynamic> json) {
    final dataField = json['data_field'] as Map<String, dynamic>;
    final membership = json['membership'] as Map<String, dynamic>;
    final researchGroup = json['research_group'] as Map<String, dynamic>?;

    return CrepeEvent(
      id: json['id'] as int,
      dataFieldId: dataField['id'] as int,
      membershipId: membership['id'] as int,
      collectedAt: DateTime.parse(json['collected_at'] as String),
      content: json['content'] as String,
      groupId: researchGroup == null ? null : researchGroup['id'] as int,
      groupName: researchGroup == null ? null : researchGroup['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data_field_id': dataFieldId,
      'membership_id': membershipId,
      'collected_at': collectedAt.toUtc().toIso8601String(),
      'content': content,
    };
  }

  Map<String, dynamic> get parsedContent {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String get dataFieldName {
    final json = parsedContent;
    return json['dataFieldName'] ?? 'Unknown Field';
  }

  CrepeEventValues get capturedValues {
    final contentJson = parsedContent;
    final raw = contentJson['values'];
    if (raw is Map) {
      return CrepeEventValues.fromJson(Map<String, dynamic>.from(raw));
    }
    return const CrepeEventValues();
  }

  @override
  String toString() {
    return 'CrepeEvent(id: $id, dataFieldId: $dataFieldId, membershipId: $membershipId, '
        'collectedAt: $collectedAt, content: $content, groupId: $groupId, groupName: $groupName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrepeEvent &&
        other.id == id &&
        other.dataFieldId == dataFieldId &&
        other.membershipId == membershipId &&
        other.collectedAt == collectedAt &&
        other.content == content &&
        other.groupId == groupId &&
        other.groupName == groupName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      dataFieldId,
      membershipId,
      collectedAt,
      content,
      groupId,
      groupName,
    );
  }
}
