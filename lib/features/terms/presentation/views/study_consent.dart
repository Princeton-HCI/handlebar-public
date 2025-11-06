import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_locator.dart';
import '../../../../core/shared_widgets/cards/icon_title_text_card.dart';
import '../widgets/participation_status_card.dart';

class StudyConsent extends StatefulWidget {
  const StudyConsent({super.key});

  @override
  State<StudyConsent> createState() => _StudyConsentState();
}

class _StudyConsentState extends State<StudyConsent> {
  bool isOptedIn = false;
  bool isLoading = true;
  bool isUpdating = false;
  int? currentTermsId;

  @override
  void initState() {
    super.initState();
    _loadCurrentTermsStatus();
  }

  Future<void> _loadCurrentTermsStatus() async {
    final termsRes = await termsRepo.checkCurrent();

    if (!mounted) return;

    termsRes.fold(
      onSuccess: (terms) {
        setState(() {
          isOptedIn = terms.hasAcceptedCurrentTerms;
          currentTermsId = terms.currentTermsId;
          isLoading = false;
        });
      },
      onFailure: (err) {
        setState(() {
          isOptedIn = false;
          currentTermsId = null;
          isLoading = false;
        });
      },
    );
  }

  Future<void> _acceptCurrentTerms() async {
    if (isUpdating || currentTermsId == null) return;

    setState(() {
      isUpdating = true;
    });

    final r = await termsRepo.accept(currentTermsId!);

    if (!mounted) return;

    r.fold(
      onSuccess: (_) {
        setState(() {
          isOptedIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('You have successfully opted into the research study'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting terms: ${err.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    setState(() {
      isUpdating = false;
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTitleTextCard(
                icon: Icon(Icons.science, color: Colors.blue),
                title: 'About This Research Study',
                paragraphs: [
                  'This feature enables data collection for academic research purposes. When enabled, the app will collect anonymized usage patterns, accessibility interactions, and UI element information to help researchers understand how drivers interact with mobile applications.',
                  'The collected data helps improve mobile app accessibility and user experience for gig economy workers. All data is anonymized and used solely for research purposes.'
                ]),
            const SizedBox(height: 24),
            IconTitleTextCard(
                icon: Icon(Icons.gavel, color: Colors.orange),
                title: 'Institutional Review Board (IRB) Information',
                paragraphs: [
                  'This research study has been reviewed and approved by the Princeton University Institutional Review Board (IRB Protocol #12345). Your participation is entirely voluntary, and you may withdraw from the study at any time without penalty or loss of benefits to which you are otherwise entitled.',
                  'The research involves minimal risk to participants. Data collected will be stored securely and will be used only for academic research purposes. No personally identifiable information will be shared with third parties. You have the right to access, modify, or delete your data at any time by contacting the research team. For questions about this study or your rights as a research participant, please contact [Research Team Contact Information].',
                ]),
            const SizedBox(height: 24),
            ParticipationStatusCard(
                isOptedIn: isOptedIn,
                isUpdating: isUpdating,
                onAcceptTerms: _acceptCurrentTerms)
          ],
        ),
      ),
    );
  }
}
