import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/research_group/presentation/widgets/dialogs/join_group_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/breakpoints.dart';
import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_layout.dart';
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
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Keeps text/grid full width
        children: [
          ValueListenableBuilder(
            valueListenable: vm.studies,
            builder: (context, studies, _) {
              return Text(
                'You are part of ${studies.length} ${_pluralize(studies.length)}.',
                style: context.textTheme.titleLarge,
                textAlign: TextAlign.center,
              );
            },
          ),
          Spacing.vSpace24,
          Expanded(
            child: ListenableBuilder(
              listenable:
                  Listenable.merge([vm.isLoading, vm.errorMessage, vm.studies]),
              builder: (context, _) {
                if (vm.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.errorMessage.value != null) {
                  return Center(child: Text(vm.errorMessage.value!));
                }

                return RefreshIndicator(
                  onRefresh: vm.loadStudies,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(Spacing.token16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          isDesktop ? 2 : 1, // 2 on desktop, 1 on mobile
                      crossAxisSpacing:
                          Spacing.token24, // Gap between the two columns
                      mainAxisSpacing: 0,
                      // Flutter GridViews need to know how tall the items are.
                      // 180px perfectly fits the StudyCard constraints.
                      mainAxisExtent: 180,
                    ),
                    itemCount: vm.studies.value.length,
                    itemBuilder: (context, index) {
                      final study = vm.studies.value[index];
                      return StudyCard(
                        group: study,
                        onTap: () => context.push('/studies/${study.code}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
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
