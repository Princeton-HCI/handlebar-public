import 'package:flutter/material.dart';

/// A banner for displaying login/registration errors
class LoginErrorDisplay extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onDismiss;

  const LoginErrorDisplay({super.key, this.errorMessage, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
            color: Colors.red.shade700,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
