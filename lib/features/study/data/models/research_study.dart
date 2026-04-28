/// Represents the information for a particular research group
class ResearchStudy {
  final int id;
  final String name;
  final String description;
  final String code;
  final String? role;

  final int activeComponentCount;

  const ResearchStudy(
      {required this.id,
      required this.name,
      required this.description,
      required this.code,
      this.role,
      this.activeComponentCount = 0});

  factory ResearchStudy.fromJson(Map<String, dynamic> json) => ResearchStudy(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        code: json['code'] as String,
        role: json['role'] as String?,
        activeComponentCount: json['active_component_count'] as int? ?? 0,
      );

  bool get isResearcher => role == 'researcher';

  @override
  String toString() {
    return 'ResearchGroup(id: $id, name: $name, description: $description, code: $code, role: $role, components: $activeComponentCount)';
  }
}
