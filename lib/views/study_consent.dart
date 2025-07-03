import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:dsc_mobile_rework/storage/device/secure_storage.dart';

class StudyConsent extends StatefulWidget {
  const StudyConsent({super.key});

  @override
  State<StudyConsent> createState() => _StudyConsentState();
}

class _StudyConsentState extends State<StudyConsent> {
  final SecureStorage localStorage = SecureStorage();
  bool isOptedIn = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptInStatus();
  }

  Future<void> _loadOptInStatus() async {
    try {
      String? optInValue = await localStorage.readStorageData("isStudyOptedIn");
      setState(() {
        isOptedIn = optInValue == "true";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isOptedIn = false;
        isLoading = false;
      });
    }
  }

  Future<void> _updateOptInStatus(bool newValue) async {
    setState(() {
      isOptedIn = newValue;
    });
    await localStorage.writeStorageData("isStudyOptedIn", newValue.toString());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue 
            ? 'You have opted into the research study' 
            : 'You have opted out of the research study'),
          backgroundColor: newValue ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Study Participation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature Explanation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'About This Research Study',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This feature enables data collection for academic research purposes. When enabled, the app will collect anonymized usage patterns, accessibility interactions, and UI element information to help researchers understand how drivers interact with mobile applications.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The collected data helps improve mobile app accessibility and user experience for gig economy workers. All data is anonymized and used solely for research purposes.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // IRB Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'Institutional Review Board (IRB) Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This research study has been reviewed and approved by the Princeton University Institutional Review Board (IRB Protocol #12345). Your participation is entirely voluntary, and you may withdraw from the study at any time without penalty or loss of benefits to which you are otherwise entitled.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The research involves minimal risk to participants. Data collected will be stored securely and will be used only for academic research purposes. No personally identifiable information will be shared with third parties. You have the right to access, modify, or delete your data at any time by contacting the research team. For questions about this study or your rights as a research participant, please contact [Research Team Contact Information].',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Opt-in/Opt-out Section
            Card(
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
                            fontSize: 18,
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
                          onPressed: () => _updateOptInStatus(true),
                          child: const Text('Yes, I want to participate'),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Thank you for participating in our research study! Your contribution helps improve mobile app accessibility.',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: PlatformElevatedButton(
                          onPressed: () => _updateOptInStatus(false),
                          child: const Text('Opt Out of Study'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Back button
            SizedBox(
              width: double.infinity,
              child: PlatformTextButton(
                onPressed: () {
                  context.go('/');
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 