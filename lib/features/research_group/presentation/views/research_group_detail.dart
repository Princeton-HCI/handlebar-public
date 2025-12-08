import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/research_group/presentation/widgets/headers/sliver_section_header.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/scaffolds/dynamic_responsive_scaffold.dart';
import '../../../crepe/models/collector.dart';
import '../../../crepe/models/crepe_event.dart';
import '../../models/research_group_member.dart';
import '../view_models/research_group_detail_view_model.dart';
import '../widgets/bottom-sheets/member_detail_bottom_sheet.dart';
import '../widgets/dialogs/add_researcher_dialog.dart';
import '../widgets/dialogs/delete_collector_dialog.dart';
import '../widgets/dialogs/kick_member_dialog.dart';
import '../widgets/dialogs/my_membership_dialog.dart';
import '../widgets/headers/research_group_info_header.dart';
import '../widgets/cards/collector_card.dart';
import '../widgets/cards/crepe_event_card.dart';
import '../widgets/cards/member_card.dart';

/// Stateful container for a research group detailed view
class ResearchGroupDetail extends StatefulWidget {
  const ResearchGroupDetail({super.key});

  @override
  State<ResearchGroupDetail> createState() => _ResearchGroupDetailState();
}

class _ResearchGroupDetailState extends State<ResearchGroupDetail> {
  late ScrollController _scrollController;
  late ResearchGroupDetailViewModel vm;

  @override
  void initState() {
    super.initState();
    NotificationService().setContext(context);

    vm = context.read<ResearchGroupDetailViewModel>();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Trigger initial load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.loadDetails();
    });
  }

  void _onScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    if (vm.isGroupEventsLoading.value || !vm.hasMoreGroupEvents.value) {
      return;
    }

    final distanceToBottom = _scrollController.position.extentAfter;

    if (distanceToBottom < 200) {
      // Load more events as we reach the bottom of the Crepe event list
      vm.loadMoreGroupEvents();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showMyMembershipDialog(ResearchGroupMember member) {
    showDialog(
      context: context,
      builder: (ctx) => MyMembershipDialog(vm: vm, member: member),
    );
  }

  void _showAddResearcherDialog() {
    showDialog(
      context: context,
      builder: (context) => AddResearcherDialog(vm: vm),
    );
  }

  void _showMemberDetailSheet(ResearchGroupMember member) {
    vm.openMemberDetails(member);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MemberDetailSheet(vm: vm, member: member),
    );
  }

  void _showKickMemberDialog(int membershipId) {
    showDialog(
      context: context,
      builder: (ctx) => KickMemberDialog(vm: vm, membershipId: membershipId),
    );
  }

  void _showDeleteCollectorDialog(int collectorId) {
    showDialog(
      context: context,
      builder: (context) =>
          DeleteCollectorDialog(vm: vm, collectorId: collectorId),
    );
  }

  Widget _buildMyMembership() {
    return SliverToBoxAdapter(
      child: ValueListenableBuilder<ResearchGroupMember?>(
        valueListenable: vm.myMembership,
        builder: (context, myMember, _) {
          if (myMember == null) return const SizedBox.shrink();

          return MemberTile(
            member: myMember,
            isResearcher: false,
            onTap: () => _showMyMembershipDialog(myMember),
            onKick: () {},
          );
        },
      ),
    );
  }

  Widget _buildMembersList() {
    return ValueListenableBuilder<List<ResearchGroupMember>>(
      valueListenable: vm.members,
      builder: (context, _, __) {
        final others = vm.otherMembers;

        if (others.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(Spacing.token16),
              child: Text(
                "No other members yet.",
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final member = others[index];
              return MemberTile(
                member: member,
                isResearcher: true,
                onTap: () => _showMemberDetailSheet(member),
                onKick: () => _showKickMemberDialog(member.membershipId),
              );
            },
            childCount: others.length,
          ),
        );
      },
    );
  }

  Widget _buildCollectorsList() {
    return ValueListenableBuilder<List<Collector>>(
      valueListenable: vm.collectors,
      builder: (context, collectors, _) {
        if (collectors.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(Spacing.token16),
              child: Text("No collectors configured for this group yet."),
            ),
          );
        }

        return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
          final c = collectors[index];
          return CollectorTile(
            collector: c,
            onDelete: vm.isResearcher
                ? () => _showDeleteCollectorDialog(c.collectorId)
                : null,
          );
        }, childCount: collectors.length));
      },
    );
  }

  Widget _buildEventFeed() {
    return ValueListenableBuilder<List<CrepeEvent>>(
      valueListenable: vm.groupEvents,
      builder: (context, events, _) {
        if (events.isEmpty) {
          return const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(Spacing.token16),
                  child: Text("No events for this group yet.")));
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                CrepeEventTile(event: events[index], fromDashboard: false),
            childCount: events.length,
          ),
        );
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
            title: "Group Detail", onReturn: () => context.pop()),
        child: Column(
          children: [
            Expanded(
                child: ValueListenableBuilder(
                    valueListenable: vm.isInitialized,
                    builder: (_, isInit, __) {
                      if (!isInit) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return RefreshIndicator(
                          onRefresh: vm.loadDetails,
                          child: CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                // Group information
                                SliverToBoxAdapter(
                                    child: ResearchGroupInfoHeader(vm: vm)),

                                // User's own membership
                                const SliverSectionHeader(
                                    title: "My Membership"),
                                _buildMyMembership(),

                                if (vm.isResearcher) ...[
                                  // Membership list
                                  SliverSectionHeader(
                                    title: "Members",
                                    actionLabel: "Add Researcher",
                                    onAction: () => _showAddResearcherDialog(),
                                  ),
                                  _buildMembersList(),
                                ],

                                // Group's active collectors
                                SliverSectionHeader(
                                  title: "Active Group Collectors",
                                  actionLabel:
                                      vm.isResearcher ? "Create" : null,
                                  onAction: vm.isResearcher
                                      ? () async {
                                          await context.push(
                                              '/define-collector',
                                              extra: vm.group.value.id);

                                          if (context.mounted) {
                                            NotificationService()
                                                .setContext(context);
                                            // Refresh dashboard after pop
                                            vm.loadDetails();
                                          }
                                        }
                                      : null,
                                ),
                                _buildCollectorsList(),

                                // Group's recent participant Crepe events
                                const SliverSectionHeader(
                                    title: "Recent Participant Events"),
                                _buildEventFeed(),

                                // Loading indicator when fetching Crepe events
                                // beyond first load
                                SliverToBoxAdapter(
                                  child: ValueListenableBuilder<bool>(
                                      valueListenable: vm.isGroupEventsLoading,
                                      builder: (_, isLoading, __) => isLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(
                                                  Spacing.token24),
                                              child: SizedBox(
                                                height: Spacing.token64,
                                                child: Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                              ),
                                            )
                                          : Spacing.vSpace64),
                                )
                              ]));
                    })),
            errorListener
          ],
        ));
  }
}
