/// Represents the information for a particular research group
class ResearchGroup {
  final int id;
  final String name;
  final String description;
  final String code;

  const ResearchGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
  });

  factory ResearchGroup.fromJson(Map<String, dynamic> json) => ResearchGroup(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        code: json['code'] as String,
      );
}
