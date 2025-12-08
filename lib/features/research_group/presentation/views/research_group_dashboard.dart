import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/crepe/models/participant_collector.dart';
import 'package:handlebar/features/research_group/presentation/widgets/cards/crepe_event_card.dart';
import 'package:handlebar/features/research_group/presentation/widgets/cards/research_group_card.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/scaffolds/dynamic_responsive_scaffold.dart';
import '../../../crepe/models/crepe_event.dart';
import '../../models/research_group.dart';
import '../view_models/research_group_dashboard_view_model.dart';
import '../widgets/dialogs/create_group_dialog.dart';
import '../widgets/dialogs/join_group_dialog.dart';
import '../widgets/cards/collector_card.dart';
import '../widgets/headers/sliver_section_header.dart';

/// Stateful container for the research group dashboard
class ResearchGroupDashboard extends StatelessWidget {
  const ResearchGroupDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide VideoSessionViewModel to all children
    return ChangeNotifierProvider(
        create: (_) => ResearchGroupDashboardViewModel(),
        child: const _ResearchGroupDashboardContainer());
  }
}

class _ResearchGroupDashboardContainer extends StatefulWidget {
  const _ResearchGroupDashboardContainer();

  @override
  State<StatefulWidget> createState() =>
      _ResearchGroupDashboardContainerState();
}

class _ResearchGroupDashboardContainerState
    extends State<_ResearchGroupDashboardContainer> {
  late ScrollController _scrollController;
  late ResearchGroupDashboardViewModel vm;

  @override
  void initState() {
    super.initState();
    NotificationService().setContext(context);

    vm = context.read<ResearchGroupDashboardViewModel>();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Trigger initial load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.loadDashboard();
    });
  }

  void _onScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    if (vm.isEventsLoading.value || !vm.hasMoreEvents.value) {
      return;
    }

    final distanceToBottom = _scrollController.position.extentAfter;

    if (distanceToBottom < 200) {
      // Load more events as we reach the bottom of the Crepe event list
      vm.loadMoreEvents();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(vm: vm),
    );
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => JoinGroupDialog(vm: vm),
    );
  }

  Widget _buildGroupsList(ValueNotifier<List<ResearchGroup>> notifier) {
    return ValueListenableBuilder<List<ResearchGroup>>(
      valueListenable: notifier,
      builder: (ctx1, groups, _) {
        if (groups.isEmpty) {
          return const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(Spacing.token16),
                  child: Text("No groups found.")));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx2, index) {
              final group = groups[index];
              return ResearchGroupTile(
                  group: group,
                  onTap: () async {
                    await context.push('/group-detail', extra: group);

                    if (mounted) {
                      NotificationService().setContext(context);
                      vm.loadDashboard();
                    }
                  });
            },
            childCount: groups.length,
          ),
        );
      },
    );
  }

  Widget _buildCollectorsSection() {
    return ValueListenableBuilder<List<ParticipantCollector>>(
      valueListenable: vm.participantCollectors,
      builder: (context, collectors, _) {
        if (collectors.isEmpty) {
          return const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(Spacing.token16),
                  child: Text("No collectors found.")));
        }

        return SliverList(
            delegate: SliverChildBuilderDelegate(
          (context, index) {
            final participantCollector = collectors[index];
            return CollectorTile.participant(
              participantCollector,
            );
          },
          childCount: collectors.length,
        ));
      },
    );
  }

  Widget _buildEventFeed() {
    return ValueListenableBuilder<List<CrepeEvent>>(
      valueListenable: vm.events,
      builder: (context, events, _) {
        if (events.isEmpty) {
          return const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(Spacing.token16),
                  child: Text("No events yet.")));
        }

        return SliverList(
            delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = events[index];
            return CrepeEventTile(
              event: event,
              fromDashboard: true,
            );
          },
          childCount: events.length,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for any errors encountered in the viewmodel
    final errorListener = ValueListenableBuilder<String?>(
        valueListenable: vm.errorMessage,
        builder: (_, msg, __) {
          if (msg != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService().showError(msg);
            });
          }
          return const SizedBox.shrink();
        });

    return DynamicResponsiveScaffold(
        appBar: HandlebarAppBar(
            title: "Research Group Dashboard", onReturn: () => context.go('/')),
        child: Column(children: [
          Expanded(
              child: ValueListenableBuilder(
                  valueListenable: vm.isInitialized,
                  builder: (context, isInit, child) {
                    if (!isInit) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return RefreshIndicator(
                      onRefresh: () => vm.loadDashboard(),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Researcher groups
                          SliverSectionHeader(
                              title: "My Researcher Groups",
                              actionLabel: "Create",
                              onAction: () => _showCreateGroupDialog()),
                          _buildGroupsList(vm.researcherGroups),

                          // Participant groups
                          SliverSectionHeader(
                              title: "My Participant Groups",
                              actionLabel: "Join",
                              onAction: () => _showJoinGroupDialog()),
                          _buildGroupsList(vm.participantGroups),

                          // All active participant collectors
                          const SliverSectionHeader(
                              title: "Active Participant Collectors"),
                          _buildCollectorsSection(),

                          // Recent Crepe events across all groups
                          const SliverSectionHeader(
                              title: "My Participant Recent Events"),
                          _buildEventFeed(),

                          // Loading indicator when fetching Crepe events
                          // beyond first load
                          SliverToBoxAdapter(
                            child: ValueListenableBuilder<bool>(
                                valueListenable: vm.isEventsLoading,
                                builder: (_, isLoading, __) => isLoading
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.all(Spacing.token24),
                                        child: SizedBox(
                                          height: Spacing.token64,
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        ),
                                      )
                                    : Spacing.vSpace64),
                          )
                        ],
                      ),
                    );
                  })),
          errorListener
        ]));
  }
}
