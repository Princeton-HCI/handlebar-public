import 'package:flutter/material.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';

class HandlebarInfoDialog extends StatelessWidget {
  final String title;
  final String text;

  const HandlebarInfoDialog({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.token8)),
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
      actions: [
        HandlebarButton.primary(
          label: 'Close',
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
