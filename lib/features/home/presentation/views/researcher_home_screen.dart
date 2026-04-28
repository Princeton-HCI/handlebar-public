import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/breakpoints.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
import '../../../../core/shared_widgets/passive_error_view.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../view_models/researcher_home_view_model.dart';
import '../widgets/study_card.dart';

class ResearcherHomeScreen extends StatefulWidget {
  const ResearcherHomeScreen({super.key});

  @override
  State<ResearcherHomeScreen> createState() => _ResearcherHomeScreenState();
}

class _ResearcherHomeScreenState extends State<ResearcherHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResearcherHomeViewModel>().loadStudies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ResearcherHomeViewModel>();
    final isDesktop = context.width > Breakpoints.mobileMax;

    return SafeScaffold(
      enableScrolling: false,
      usePadding: true,
      appBar: const HandlebarAppBar(
        title: 'Studies',
        showBackArrow: false,
        showMenu: true,
      ),
      endDrawer: const HandlebarMobileDrawer(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable:
                  Listenable.merge([vm.isLoading, vm.errorMessage, vm.studies]),
              builder: (context, _) {
                // Loading State
                if (vm.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error State
                if (vm.errorMessage.value != null) {
                  return PassiveErrorView(
                    message: "Could not load your studies.",
                    subtitle: vm.errorMessage.value,
                    onRetry: () => vm.loadStudies(),
                  );
                }

                // Success State
                final studies = vm.studies.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'You are conducting ${studies.length} ${_pluralize(studies.length)}.',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    Spacing.vSpace24,
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: vm.loadStudies,
                        child: GridView.builder(
                          padding:
                              const EdgeInsets.only(bottom: Spacing.token32),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isDesktop ? 2 : 1, // 2 on desktop, 1 on mobile
                            crossAxisSpacing:
                                Spacing.token32, // Gap between the two columns
                            mainAxisSpacing: 0,
                            // Flutter GridViews need to know how tall the items are.
                            // 180px perfectly fits the StudyCard constraints.
                            mainAxisExtent: 180,
                          ),
                          itemCount: studies.length,
                          itemBuilder: (context, index) {
                            final study = studies[index];
                            return StudyCard(
                              group: study,
                              onTap: () async {
                                // Wait for the detail screen to pop
                                final didChange = await context
                                    .push<bool>('/studies/${study.code}');

                                // If it returns true (meaning deleted or left), reload the list
                                if (didChange == true && context.mounted) {
                                  vm.loadStudies();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Create Study Button (Stays pinned to the bottom regardless of state)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.token16),
            child: Center(
              child: HandlebarButton.primary(
                label: 'Create a Study',
                onPressed: () async {
                  final didCreate = await context.push('/create-study');
                  if (didCreate == true && context.mounted) {
                    context.read<ResearcherHomeViewModel>().loadStudies();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pluralize(int count) => count == 1 ? 'study' : 'studies';
}
