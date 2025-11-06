import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A widget that displays a user's participation status in the research study.
class ParticipationStatusCard extends StatelessWidget {
  final bool isOptedIn;
  final bool isUpdating;
  final VoidCallback onAcceptTerms;

  const ParticipationStatusCard(
      {super.key,
      required this.isOptedIn,
      required this.isUpdating,
      required this.onAcceptTerms});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isOptedIn ? Colors.green.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOptedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isOptedIn ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Status: ${isOptedIn ? "Participating" : "Not Participating"}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isOptedIn) ...[
              const Text(
                'Would you like to participate in this research study?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PlatformElevatedButton(
                  onPressed: isUpdating ? null : onAcceptTerms,
                  child: isUpdating
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Accepting Terms...'),
                          ],
                        )
                      : const Text('Yes, I want to participate'),
                ),
              ),
            ] else ...[
              const Text(
                'Thank you for participating in our research study! Your contribution helps improve mobile app accessibility.',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
