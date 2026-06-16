import 'package:handlebar/features/crepe/models/data_field.dart';

/// Represents the text/contentDescription values captured by a
/// [DataField] graph query match
class CrepeEventValues {
  // Captured directly from the node itself
  final String? nodeText;
  final String? nodeContentDescription;

  // Captured by looking at the node's subject-relation-object triples
  final String? relationText;
  final String? relationContentDescription;
  final String? relationChildTexts;

  const CrepeEventValues({
    this.nodeText,
    this.nodeContentDescription,
    this.relationText,
    this.relationContentDescription,
    this.relationChildTexts,
  });

  factory CrepeEventValues.fromJson(Map<String, dynamic> json) {
    return CrepeEventValues(
      nodeText: json['nodeText']?.toString(),
      nodeContentDescription: json['nodeContentDescription']?.toString(),
      relationText: json['relationText']?.toString(),
      relationContentDescription:
          json['relationContentDescription']?.toString(),
      relationChildTexts: json['relationChildTexts']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (nodeText != null) 'nodeText': nodeText,
        if (nodeContentDescription != null)
          'nodeContentDescription': nodeContentDescription,
        if (relationText != null) 'relationText': relationText,
        if (relationContentDescription != null)
          'relationContentDescription': relationContentDescription,
        if (relationChildTexts != null) 'relationChildTexts': relationChildTexts,
      };

  bool get isEmpty =>
      nodeText == null &&
      nodeContentDescription == null &&
      relationText == null &&
      relationContentDescription == null &&
      relationChildTexts == null;

  /// One-line summary of captured text for list review UI.
  String get displaySummary {
    final parts = <String>[];
    void add(String? v) {
      if (v != null && v.isNotEmpty) parts.add(v);
    }

    add(nodeText);
    add(nodeContentDescription);
    add(relationText);
    add(relationContentDescription);
    add(relationChildTexts);

    if (parts.isEmpty) return 'No captured value';
    return parts.join(' · ');
  }
}
