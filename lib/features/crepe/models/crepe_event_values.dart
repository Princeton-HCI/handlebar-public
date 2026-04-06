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

  bool get isEmpty =>
      nodeText == null &&
      nodeContentDescription == null &&
      relationText == null &&
      relationContentDescription == null &&
      relationChildTexts == null;
}
