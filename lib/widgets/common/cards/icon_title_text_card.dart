import 'package:flutter/material.dart';

/// A widget that displays an icon, title, and paragraph text.
class IconTitleTextCard extends StatelessWidget {
  final Icon icon;
  final List<String> paragraphs;
  final TextStyle paragraphStyle;
  final String title;
  final TextStyle titleStyle;

  const IconTitleTextCard(
      {super.key,
      required this.icon,
      required this.paragraphs,
      this.paragraphStyle = const TextStyle(fontSize: 16),
      required this.title,
      this.titleStyle =
          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: titleStyle),
                )
              ],
            ),
            const SizedBox(height: 16),
            ...paragraphs.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(text, style: paragraphStyle)))
          ],
        ),
      ),
    );
  }
}
