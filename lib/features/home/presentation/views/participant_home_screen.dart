import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/home/presentation/widgets/join_group_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/breakpoints.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
import '../../../../core/shared_widgets/passive_error_view.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../view_models/participant_home_view_model.dart';
import '../widgets/study_card.dart';

class ParticipantHomeScreen extends StatefulWidget {
  const ParticipantHomeScreen({super.key});

  @override
  State<ParticipantHomeScreen> createState() => _ParticipantHomeScreenState();
}

class _ParticipantHomeScreenState extends State<ParticipantHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParticipantHomeViewModel>().loadStudies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ParticipantHomeViewModel>();

    // Check if we are on desktop to determine column count
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
          // Shown on every visit, not just at join time: a participant who
          // joined before the researcher added a location sensor would
          // otherwise never be asked, and would silently collect nothing.
          ValueListenableBuilder<bool>(
            valueListenable: vm.needsLocationSetup,
            builder: (context, needsSetup, _) {
              if (!needsSetup) return const SizedBox.shrink();
              final scheme = Theme.of(context).colorScheme;
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.token16),
                child: Card(
                  elevation: 0,
                  color: scheme.errorContainer,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: scheme.error),
                    borderRadius: BorderRadius.circular(Spacing.token8),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.location_off, color: scheme.error),
                    title: const Text('Location access needed'),
                    subtitle: const Text(
                      'A study you joined collects location, but nothing is '
                      'being recorded yet.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/location-permission');
                      await vm.refreshLocationSetupState();
                    },
                  ),
                ),
              );
            },
          ),
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
                    // Headline placed inside the success block
                    Text(
                      'You are participating in ${studies.length} ${_pluralize(studies.length)}.',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    Spacing.vSpace24,

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: vm.loadStudies,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(Spacing.token16),
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

          // Join Study Button (Stays pinned to the bottom regardless of state)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.token16),
            child: Center(
              child: HandlebarButton.primary(
                label: 'Join a Study',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => JoinGroupDialog(vm: vm),
                  );
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
