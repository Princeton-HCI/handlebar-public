/// Represents the information for a particular research group
class ResearchGroup {
  final int id;
  final String name;
  final String description;
  final String code;
  final String? role;

  const ResearchGroup(
      {required this.id,
      required this.name,
      required this.description,
      required this.code,
      this.role});

  factory ResearchGroup.fromJson(Map<String, dynamic> json) => ResearchGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      code: json['code'] as String,
      role: json['role'] as String?);

  bool get isResearcher => role == 'researcher';

  @override
  String toString() {
    return 'ResearchGroup(id: $id, name: $name, description: $description, code: $code, role: $role)';
  }
}
