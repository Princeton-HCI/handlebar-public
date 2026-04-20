/// Represents a record of one legal terms document
class Terms {
  final int id;
  final String title;
  final String text;
  final DateTime? requiredAt;

  Terms({
    required this.id,
    required this.title,
    required this.text,
    required this.requiredAt,
  });

  factory Terms.fromJson(Map<String, dynamic> json) {
    return Terms(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      requiredAt: json['required_at'] != null
          ? DateTime.parse(json['required_at'] as String)
          : null,
    );
  }
}
