import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/design-system/spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shared_widgets/handlebar_app_bar.dart';
import '../../../../core/shared_widgets/passive_error_view.dart';
import '../../../../core/shared_widgets/safe_scaffold.dart';
import '../../../research_group/presentation/widgets/cards/crepe_event_card.dart';
import '../view_models/study_collected_data_view_model.dart';

/// Paginated feed of [CrepeEvent]s collected for a study.
class StudyCollectedDataScreen extends StatefulWidget {
  const StudyCollectedDataScreen({super.key});

  @override
  State<StudyCollectedDataScreen> createState() =>
      _StudyCollectedDataScreenState();
}

class _StudyCollectedDataScreenState extends State<StudyCollectedDataScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyCollectedDataViewModel>().load();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<StudyCollectedDataViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<StudyCollectedDataViewModel>();

    return SafeScaffold(
      usePadding: true,
      enableScrolling: false,
      appBar: HandlebarAppBar(
        title: 'Data Collected',
        onReturn: () => context.pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: vm.isInitialized,
            builder: (context, isInit, _) {
              if (!isInit) {
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (vm.errorMessage.value != null && vm.events.value.isEmpty) {
                return Expanded(
                  child: PassiveErrorView(
                    message: 'Could not load collected data.',
                    subtitle: vm.errorMessage.value,
                    onRetry: () => vm.load(),
                  ),
                );
              }

              return ValueListenableBuilder<List>(
                valueListenable: vm.events,
                builder: (context, events, _) {
                  return Expanded(
                    child: RefreshIndicator(
                      onRefresh: vm.refresh,
                      child: events.isEmpty && !vm.isLoading.value
                          ? _EmptyState(isResearcher: vm.isResearcher)
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: Spacing.token16,
                              ),
                              itemCount: events.length + 1,
                              itemBuilder: (context, index) {
                                if (index == events.length) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: vm.isLoading,
                                    builder: (context, loading, _) {
                                      if (!loading) {
                                        return const SizedBox.shrink();
                                      }
                                      return const Padding(
                                        padding: EdgeInsets.all(
                                          Spacing.token8,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return CrepeEventTile(
                                  event: events[index],
                                  fromDashboard: false,
                                  showCapturedPreview: true,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                );
                              },
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isResearcher;

  const _EmptyState({required this.isResearcher});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.token48),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: scheme.onSurfaceVariant),
              Spacing.vSpace16,
              Text(
                isResearcher
                    ? 'No data collected yet'
                    : 'You have not contributed any data yet',
                style: context.titleMedium,
                textAlign: TextAlign.center,
              ),
              Spacing.vSpace8,
              Text(
                isResearcher
                    ? 'Events appear here when participants\' collectors '
                        'match on their devices.'
                    : 'When collectors in this study match on your device, '
                        'the captured values will show up here.',
                style: context.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
