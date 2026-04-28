import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';

import '../../../../../app/design-system/spacing.dart';
import '../../../../crepe/models/crepe_event.dart';
import '../../../../study/data/models/research_study_member.dart';
import '../../view_models/research_group_detail_view_model.dart';
import '../cards/crepe_event_card.dart';

/// Bottom sheet for displaying a selected member's details details (name, metadata ,
/// data fields)
class MemberDetailSheet extends StatefulWidget {
  final ResearchGroupDetailViewModel vm;
  final ResearchStudyMember member;

  const MemberDetailSheet({
    super.key,
    required this.vm,
    required this.member,
  });

  @override
  State<MemberDetailSheet> createState() => _MemberDetailSheetState();
}

class _MemberDetailSheetState extends State<MemberDetailSheet> {
  String _formatDate(DateTime dt) => DateFormat.yMMMd().format(dt.toLocal());

  String _formatRetention(String pref) {
    return pref
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final member = widget.member;
    final isInactive = member.unenrolledAt != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.bottomSheetTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: Spacing.token96,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: Spacing.token8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Member info header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.token24, vertical: Spacing.token16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isInactive
                              ? Colors.grey.shade200
                              : scheme.primaryContainer,
                          child: Icon(Icons.person,
                              size: Spacing.token32,
                              color: isInactive
                                  ? Colors.grey
                                  : scheme.onPrimaryContainer),
                        ),

                        Spacing.hSpace16,

                        // Member information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Member ID (replace with first + last name eventually)
                              Text(
                                "Member #${member.membershipId}",
                                style: context.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),

                              Spacing.vSpace8,

                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.token8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: isInactive
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: isInactive
                                            ? Colors.red.shade200
                                            : Colors.green.shade200)),
                                child: Text(isInactive ? "INACTIVE" : "ACTIVE",
                                    style: context.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onErrorContainer)),
                              )
                            ],
                          ),
                        ),

                        // Close button
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close),
                        )
                      ],
                    ),

                    Spacing.vSpace16,

                    // Metadata grid
                    Wrap(
                      spacing: Spacing.token24,
                      runSpacing: 12,
                      children: [
                        // User join date
                        _MemberMetadataItem(
                          label: "Joined",
                          value: _formatDate(member.enrolledAt),
                          icon: Icons.calendar_today,
                        ),
                        // User leave date (if it exists)
                        if (member.unenrolledAt != null)
                          _MemberMetadataItem(
                            label: "Left",
                            value: _formatDate(member.unenrolledAt!),
                            icon: Icons.exit_to_app,
                            isError: true,
                          ),
                        // User retention policy
                        _MemberMetadataItem(
                          label: "Retention",
                          value: _formatRetention(member.retentionPref),
                          icon: Icons.save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Event list
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    // Trigger load more when user scrolls to bottom
                    if (!widget.vm.isMemberDetailLoading.value &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      widget.vm.loadMoreMemberEvents();
                    }
                    return false;
                  },
                  child: ValueListenableBuilder<List<CrepeEvent>>(
                    valueListenable: widget.vm.memberDetailEvents,
                    builder: (context, events, _) {
                      if (events.isEmpty &&
                          widget.vm.isMemberDetailLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Empty state
                      if (events.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: Spacing.token48),
                              Spacing.vSpace16,
                              const Text(
                                  "No data collected from this member yet."),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: events.length + 1,
                        itemBuilder: (context, index) {
                          // Bottom loader at end of list
                          if (index == events.length) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: widget.vm.isMemberDetailLoading,
                              builder: (_, isLoading, __) {
                                return isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      )
                                    : const SizedBox(height: 40);
                              },
                            );
                          }

                          final event = events[index];
                          return CrepeEventTile(
                              event: event, fromDashboard: false);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberMetadataItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isError;

  const _MemberMetadataItem(
      {required this.label,
      required this.value,
      required this.icon,
      this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isError ? Colors.red.shade700 : Colors.black87)),
      ],
    );
  }
}
