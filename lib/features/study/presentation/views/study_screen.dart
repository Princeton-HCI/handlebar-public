import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handlebar/app/design-system/breakpoints.dart';
import 'package:handlebar/core/extensions/context_extensions.dart';
import 'package:handlebar/features/crepe/utils/collector_grouping.dart';
import 'package:handlebar/features/study/data/models/research_study.dart';
import 'package:handlebar/features/study/presentation/view_models/study_view_model.dart';
import 'package:handlebar/features/study/presentation/widgets/collector_details_bottom_sheet.dart';
import 'package:handlebar/features/study/presentation/widgets/member_detail_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/shared_services/notification_service.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/handlebar_bottom_sheet.dart';
import '../../../../core/shared_widgets/handlebar_button.dart';
import '../../../../core/shared_widgets/handlebar_info_dialog.dart';
import '../../../../core/shared_widgets/handlebar_text_field.dart';
import '../../../../core/shared_widgets/passive_error_view.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../data/models/research_study_member.dart';
import '../widgets/collector_card.dart';
import '../widgets/member_card.dart';
import '../widgets/section_header.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyViewModel>().loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final vm = context.read<StudyViewModel>();
    final isDesktop = context.width > Breakpoints.mobileMax;

    return ListenableBuilder(
      listenable: Listenable.merge([
        vm.isInitialized,
        vm.errorMessage,
        vm.group,
        vm.myMembership,
        vm.members,
        vm.collectors
      ]),
      builder: (context, _) {
        if (!vm.isInitialized.value) {
          return const SafeScaffold(
            usePadding: true,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.errorMessage.value != null) {
          return SafeScaffold(
            usePadding: true,
            child: Center(
              child: PassiveErrorView(
                message: "Could not load the study's details.",
                subtitle: vm.errorMessage.value,
                onRetry: () => vm.loadDetails(),
              ),
            ),
          );
        }

        final group = vm.group.value;
        if (group == null) return const SizedBox.shrink();

        final myId = vm.myMembership.value?.membershipId;

        return SafeScaffold(
          usePadding: true,
          enableScrolling: true,
          appBar: HandlebarAppBar(
            title: group.name,
            showBackArrow: true,
            actions: vm.isResearcher
                ? [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditStudyDialog(context, group, vm);
                        } else if (value == 'delete') {
                          _showConfirmationDialog(
                              context: context,
                              title: 'Delete Study?',
                              content:
                                  'This action cannot be undone. All data, including memberships and collected events, will be lost.',
                              actionLabel: 'Delete',
                              onConfirm: () => vm.deleteGroup(),
                              onSuccess: () {
                                if (context.mounted) {
                                  context.pop(true);
                                }
                              });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 20, color: Colors.black87),
                              SizedBox(width: 12),
                              Text('Edit Name/Description'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete Study',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==============================
              // STUDY DESCRIPTION
              // ==============================

              if (isDesktop) ...[
                Text(
                  group.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Ensures stark Handlebar styling
                  ),
                ),
                Spacing.vSpace16,
              ],

              if (group.description.isNotEmpty) ...[
                Text(
                  "Description: ${group.description}",
                  style: theme.textTheme.bodyLarge,
                ),
                Spacing.vSpace16,
              ],

              if (vm.isResearcher) ...[
                Align(
                  alignment:
                      Alignment.centerRight, // Pushes the block to the right
                  child: Wrap(
                    spacing: Spacing.token16,
                    runSpacing: Spacing.token8,
                    alignment: WrapAlignment
                        .end, // Aligns items inside the wrap to the right
                    children: [
                      HandlebarButton.primary(
                        label: 'Pause Recruitment',
                        onPressed: () {/* TODO */},
                      ),
                      if (isDesktop) ...[
                        HandlebarButton.primary(
                          label: 'Edit Study',
                          onPressed: () =>
                              _showEditStudyDialog(context, group, vm),
                        ),
                        HandlebarButton.danger(
                          label: 'Delete Study',
                          onPressed: () => _showConfirmationDialog(
                              context: context,
                              title: 'Delete Study?',
                              content:
                                  'This action cannot be undone. All data, including memberships and collected events, will be lost.',
                              actionLabel: 'Delete',
                              onConfirm: () => vm.deleteGroup(),
                              onSuccess: () {
                                if (context.mounted) {
                                  context.pop(true);
                                }
                              }),
                        ),
                      ]
                    ],
                  ),
                ),
                Spacing.vSpace16,
              ],

              const Divider(height: 1, color: Colors.black, thickness: 1.0),
              Spacing.vSpace16,

              // ==============================
              // PARTICIPANTS SECTION
              // ==============================
              SectionHeader(
                title: 'Participants:',
                actions: vm.isResearcher
                    ? [
                        HandlebarButton.primary(
                          label: 'Add Participants',
                          onPressed: () =>
                              _showAddParticipantDialog(context, vm.studyCode),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const HandlebarInfoDialog(
                                title: "Add Participants Information",
                                text:
                                    "Participants can view the group's details, list of researchers, Data Collectors that run automatically on their device, and data they have contributed. Participants can also edit their data governance policy, which determines what happens to their data if they leave / are kicked.",
                              ),
                            );
                          },
                        )
                      ]
                    : [],
              ),
              if (vm.participants.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: Spacing.token16),
                  child: Text("This study has no participants, yet.",
                      style: TextStyle(fontStyle: FontStyle.italic)),
                )
              else
                ...vm.participants.map((m) => MemberCard(
                      member: m,
                      isUs: m.membershipId == myId,
                      isCurrentUserResearcher: vm.isResearcher,
                      onKick: () => _showConfirmationDialog(
                        context: context,
                        title: 'Kick Participant?',
                        content:
                            'This participant will lose access to the group immediately. Any data they have already contributed will be retained or deleted according to their personal retention preference.',
                        actionLabel: 'Kick',
                        onConfirm: () => vm.kickMember(m.membershipId),
                      ),
                      onLeave: () => vm.leaveGroup().then((success) {
                        if (success && context.mounted) {
                          context.pop(true);
                        }
                      }),
                      onEditDataGov: () =>
                          _showEditDataGovDialog(context, vm, m),
                      onViewDetails: () {
                        HandlebarBottomSheet.show(
                          context: context,
                          child: MemberDetailBottomSheet(member: m),
                        );
                      },
                    )),

              Divider(height: Spacing.token48),

              // ==============================
              // RESEARCHERS SECTION
              // ==============================
              SectionHeader(
                title: 'Researchers:',
                actions: vm.isResearcher
                    ? [
                        HandlebarButton.primary(
                          label: 'Add Researcher',
                          onPressed: () =>
                              _showAddResearcherDialog(context, vm),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const HandlebarInfoDialog(
                                title: "Add Researcher Information",
                                text:
                                    "Additional researchers can edit and delete the group, view and remove participants, pause recruitment, and view, edit and create Data Collectors.",
                              ),
                            );
                          },
                        )
                      ]
                    : [],
              ),
              if (vm.researchers.isEmpty)
                // NOTE: This should never show, otherwise something bad happened
                const Padding(
                  padding: EdgeInsets.only(left: Spacing.token16),
                  child: Text("This study has no researchers.",
                      style: TextStyle(fontStyle: FontStyle.italic)),
                )
              else
                ...vm.researchers.map((m) => MemberCard(
                      member: m,
                      isUs: m.membershipId == myId,
                      isCurrentUserResearcher: vm.isResearcher,
                      onKick: () => _showConfirmationDialog(
                        context: context,
                        title: 'Kick Researcher?',
                        content:
                            'This researcher will lose access to the group immediately.',
                        actionLabel: 'Kick',
                        onConfirm: () => vm.kickMember(m.membershipId),
                      ),
                      onLeave: () => vm.leaveGroup().then((success) {
                        if (success && context.mounted) {
                          context.pop(true);
                        }
                      }),
                      onEditDataGov: () {}, // Not applicable to researchers
                      onViewDetails: () {
                        HandlebarBottomSheet.show(
                          context: context,
                          child: MemberDetailBottomSheet(member: m),
                        );
                      },
                    )),

              Divider(height: Spacing.token48),

              // ==============================
              // DATA COLLECTORS SECTION
              // ==============================
              SectionHeader(
                title: 'Data Collectors:',
                actions: vm.isResearcher
                    ? [
                        HandlebarButton.primary(
                          label: 'Create',
                          onPressed: kIsWeb
                              ? null
                              : () => context.push(
                                  '/studies/${vm.studyCode}/define-collector'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const HandlebarInfoDialog(
                                title: "Data Collectors Information",
                                text:
                                    "Data Collectors define what UI elements are captured in the background from specific screens using Android's Accessibility Service. This allows Handlebar to NOT capture any image screenshots or video feeds, instead targeting elements from the UI hierarchy tree directly.",
                              ),
                            );
                          },
                        )
                      ]
                    : [],
              ),
              if (vm.collectors.value.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: Spacing.token16),
                  child: Text("This study has no data collectors, yet.",
                      style: TextStyle(fontStyle: FontStyle.italic)),
                )
              else
                ..._buildCollectorsByApp(context, vm),
              Divider(height: Spacing.token48),

              const SectionHeader(title: 'Data Collected:'),

              Card(
                margin: const EdgeInsets.only(bottom: Spacing.token8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(Spacing.token8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.token16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        vm.isResearcher
                            ? "Review and manage the data events collected from participants in this study."
                            : "Review the data events you have contributed to this study.",
                        style: theme.textTheme.bodyMedium,
                      ),
                      Spacing.vSpace16,
                      HandlebarButton.primary(
                        label: 'View Data Collected',
                        onPressed: () =>
                            context.push('/studies/${vm.studyCode}/data'),
                      ),
                    ],
                  ),
                ),
              ),

              Spacing.vSpace48,
            ],
          ),
        );
      },
    );
  }

  void _showAddParticipantDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participants'),
        content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Share this code with participants to join this study.'),
                Spacing.vSpace24,
                Center(
                  child: InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: code));

                      if (context.mounted) {
                        NotificationService()
                            .showSuccess('Code copied to clipboard!');
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.token24,
                        vertical: Spacing.token12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        border: Border.all(color: Colors.black, width: 1.0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(code,
                              style: context.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              )),
                          const SizedBox(width: Spacing.token16),
                          const Icon(Icons.copy,
                              size: 20, color: Colors.black87),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )),
        actions: [
          HandlebarButton.neutral(
              label: "Cancel", onPressed: () => context.pop()),
          Spacing.hSpace8,
        ],
      ),
    );
  }

  void _showAddResearcherDialog(BuildContext context, StudyViewModel vm) {
    final emailController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add a Researcher'),
            content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter the email of the researcher:'),
                    Spacing.vSpace16,
                    HandlebarTextField(
                      controller: emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isSubmitting,
                    ),
                  ],
                )),
            actions: [
              HandlebarButton.neutral(
                  label: "Cancel",
                  onPressed: isSubmitting ? null : () => context.pop()),
              Spacing.hSpace16,
              HandlebarButton.primary(
                label: 'Next',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (emailController.text.trim().isEmpty) return;
                  setState(() => isSubmitting = true);

                  final success =
                      await vm.addResearcher(emailController.text.trim());

                  if (success && context.mounted) context.pop();
                  if (!success && context.mounted) {
                    setState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditStudyDialog(
      BuildContext context, ResearchStudy currentGroup, StudyViewModel vm) {
    final nameController = TextEditingController(text: currentGroup.name);
    final descController =
        TextEditingController(text: currentGroup.description);
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Study'),
            content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HandlebarTextField(
                      controller: nameController,
                      hintText: 'Study Name',
                      enabled: !isSubmitting,
                    ),
                    Spacing.vSpace16,
                    HandlebarTextField(
                      controller: descController,
                      hintText: 'Description',
                      maxLines: 3,
                      enabled: !isSubmitting,
                    ),
                  ],
                )),
            actions: [
              HandlebarButton.neutral(
                  label: "Cancel",
                  onPressed: isSubmitting ? null : () => context.pop()),
              Spacing.hSpace16,
              HandlebarButton.primary(
                label: 'Save',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  setState(() => isSubmitting = true);

                  final success = await vm.updateGroup(
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                  );

                  if (success && context.mounted) context.pop();
                  if (!success && context.mounted) {
                    setState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDataGovDialog(BuildContext context, StudyViewModel vm,
      ResearchStudyMember currentMember) {
    String currentPref = currentMember.retentionPref;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Data Governance'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "If you leave or are kicked from this study, what should happen to the data you already contributed?",
                  ),
                  Spacing.vSpace16,
                  RadioGroup<String>(
                    groupValue: currentPref,
                    onChanged: (String? val) =>
                        setState(() => currentPref = val!),
                    child: Column(
                      children: [
                        // Keep Collected Option
                        RadioListTile<String>(
                          title: const Text("Keep Collected",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              const Text("Researchers keep existing data"),
                          value: "keep_collected",
                          activeColor: Colors.black, // Handlebar styling
                          contentPadding: EdgeInsets.zero,
                        ),

                        // Delete All Option
                        RadioListTile<String>(
                          title: const Text("Delete All",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              const Text("Remove all my data immediately"),
                          value: "delete_all",
                          activeColor: Colors.black, // Handlebar styling
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              HandlebarButton.neutral(
                  label: "Cancel",
                  onPressed: isSubmitting ? null : () => context.pop()),
              Spacing.hSpace16,
              HandlebarButton.primary(
                label: 'Save',
                isLoading: isSubmitting,
                onPressed: () async {
                  // If they didn't actually change anything, just close the dialog
                  if (currentPref == currentMember.retentionPref) {
                    context.pop();
                    return;
                  }

                  setState(() => isSubmitting = true);

                  final success =
                      await vm.updateMyMembership(retentionPref: currentPref);

                  if (success && context.mounted) context.pop();
                  if (!success && context.mounted) {
                    setState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Renders the study's collectors grouped by app, each app in a collapsible
  /// section so participants can expand an app to see what is being collected.
  List<Widget> _buildCollectorsByApp(BuildContext context, StudyViewModel vm) {
    final groups = groupCollectorsByApp(vm.collectors.value);
    final scheme = Theme.of(context).colorScheme;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.token16, 0, Spacing.token16, Spacing.token8),
        child: Text(
          groups.length == 1
              ? 'This study collects data from 1 app.'
              : 'This study collects data from ${groups.length} apps.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      ...groups.map((group) {
        final count = group.collectors.length;
        return Card(
          margin: const EdgeInsets.only(bottom: Spacing.token8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: scheme.outline),
            borderRadius: BorderRadius.circular(Spacing.token8),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.android, color: scheme.primary),
            title: Text(
              group.appName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(count == 1 ? '1 collector' : '$count collectors'),
            childrenPadding: const EdgeInsets.fromLTRB(
                Spacing.token8, 0, Spacing.token8, Spacing.token8),
            children: group.collectors
                .map((c) => CollectorCard(
                      collector: c,
                      isResearcher: vm.isResearcher,
                      onViewDetails: () {
                        HandlebarBottomSheet.show(
                          context: context,
                          child: CollectorDetailsBottomSheet(
                            collector: c,
                            isResearcher: vm.isResearcher,
                          ),
                        );
                      },
                      onDelete: () => _showConfirmationDialog(
                        context: context,
                        title: 'Delete Collector?',
                        content:
                            'This action cannot be undone. All data tied to this collector will be lost.',
                        actionLabel: 'Delete',
                        onConfirm: () => vm.deleteCollector(c.collectorId),
                      ),
                    ))
                .toList(),
          ),
        );
      }),
    ];
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String actionLabel,
    required Future<bool> Function() onConfirm,
    VoidCallback? onSuccess,
  }) {
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(width: 500, child: Text(content)),
            actions: [
              HandlebarButton.neutral(
                  label: "Cancel",
                  onPressed: isSubmitting ? null : () => context.pop()),
              Spacing.hSpace16,
              HandlebarButton.primary(
                label: actionLabel,
                isLoading: isSubmitting,
                onPressed: () async {
                  setState(() => isSubmitting = true);
                  final success = await onConfirm();
                  if (success && context.mounted) {
                    context.pop();
                    onSuccess?.call();
                  } else if (context.mounted) {
                    setState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
