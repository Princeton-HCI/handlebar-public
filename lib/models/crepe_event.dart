/// Represents a collected data event that contains the actual content gathered
/// from an app at a specific timestamp, associated with a particular data field.
class CrepeEvent {
  final int dataFieldId;
  final DateTime collectedAt;
  final String content;

  CrepeEvent({
    required this.dataFieldId,
    required this.collectedAt,
    required this.content,
  });

  factory CrepeEvent.fromJson(Map<String, dynamic> json) {
    return CrepeEvent(
      dataFieldId: json['data_field_id'] as int,
      collectedAt: DateTime.parse(json['collected_at'] as String),
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data_field_id': dataFieldId,
      'collected_at': collectedAt.toIso8601String(),
      'content': content,
    };
  }

  @override
  String toString() {
    return 'CrepeEvent(dataFieldId: $dataFieldId, collectedAt: $collectedAt, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrepeEvent &&
        other.dataFieldId == dataFieldId &&
        other.collectedAt == collectedAt &&
        other.content == content;
  }

  @override
  int get hashCode {
    return Object.hash(dataFieldId, collectedAt, content);
  }
}
