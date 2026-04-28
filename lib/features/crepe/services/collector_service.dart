import 'dart:convert';
import 'dart:developer';
import 'package:handlebar/features/crepe/data/crepe_event_repository.dart';
import 'package:handlebar/features/crepe/models/active_collectors.dart';
import 'package:handlebar/features/crepe/models/collector_match.dart';
import 'package:handlebar/features/crepe/models/match_result.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';
import '../../../app/app_locator.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/auth_token_store.dart';
import '../models/crepe_event.dart';
import 'crepe_service.dart';

class CollectorService {
  static final CollectorService _instance = CollectorService._internal();
  factory CollectorService() => _instance;
  CollectorService._internal();

  final CrepeService _crepeService = getIt<CrepeService>();
  final AuthTokenStore _authStore = getIt<AuthTokenStore>();

  ActiveCollectors? _activeCollectors;
  bool _isInitialized = false;

  static void _showErrorToUser(String message) {
    NotificationService().showError('CollectorService Error: $message');
  }

  /// Based on compliance checks, activates collector monitoring.
  /// Terms must have been accepted, accessibility services must have been enabled,
  /// and the user must be a participant for monitoring to activate.
  ///
  /// Can be called any of the above changes on login, app startup, etc.
  Future<bool> syncMonitoringState() async {
    try {
      log('🔄 [CollectorService] Evaluating monitoring state...');

      // 1. STATE CHECK: Are they a logged-in participant?
      if (!_authStore.isAuthenticated || _authStore.userRole != 'participant') {
        log('🛑 [CollectorService] User is not an active participant. Stopping.');
        await _stopContinuousMonitoring();
        return false;
      }

      // 2. STATE CHECK: Have they accepted the legal terms?
      if (_authStore.needsTermsAcceptance) {
        log('🛑 [CollectorService] Terms not accepted. Stopping.');
        await _stopContinuousMonitoring();
        return false;
      }

      // 3. STATE CHECK: Is Accessibility Enabled in the Android OS?
      // Note: if it's not an Android OS we simply ignore this and exit the monitoring
      if (!await _crepeService.isAccessibilityServiceEnabled()) {
        log('🛑 [CollectorService] Accessibility OS permission disabled. Stopping.');
        await _stopContinuousMonitoring();
        return false;
      }

      // 4. Fetch data and start
      _crepeService.setCollectorMatchesCallback(_handleContinuousMatches);
      final success = await fetchAndSetActiveCollectors();

      if (success) {
        _isInitialized = true;
        await _enableContinuousMonitoring();
      }

      return success;
    } catch (e) {
      log('❌ [CollectorService] Error syncing state: $e');
      await _stopContinuousMonitoring();
      return false;
    }
  }

  Future<void> _stopContinuousMonitoring() async {
    _activeCollectors = null;
    _isInitialized = false;
    await _crepeService.setContinuousMonitoring(false);
  }

  Future<void> _enableContinuousMonitoring() async {
    if (_activeCollectors != null) {
      try {
        final pluginData = _activeCollectors!.toPluginFormat();
        final collectorsJson = jsonEncode(pluginData);
        await _crepeService.setContinuousMonitoring(true,
            collectorsJson: collectorsJson);
        log('🟢 [CollectorService] Continuous monitoring ENABLED');
      } catch (e) {
        log('❌ [CollectorService] Failed to enable continuous monitoring: $e');
        _showErrorToUser('Failed to enable continuous monitoring: $e');
      }
    }
  }

  void _handleContinuousMatches(Map<String, dynamic> eventData) {
    try {
      final matchResult = MatchResult.fromJson(eventData);
      if (matchResult.hasMatches) {
        log('🎯 [CollectorService] Found ${matchResult.matches.length} continuous matches!');
        for (final match in matchResult.matches) {
          _sendCrepeEventForMatch(match);
        }
      }
    } catch (e) {
      log('❌ [CollectorService] Error handling continuous matches: $e');
    }
  }

  Future<void> _sendCrepeEventForMatch(CollectorMatch match) async {
    try {
      final crepeEvent = CrepeEvent(
        dataFieldId: match.dataFieldId,
        membershipId: match.membershipId,
        collectedAt: match.matchedAt,
        content: jsonEncode(match.toContentJson()),
      );

      final result = await getIt<CrepeEventRepository>().send(crepeEvent);

      result.fold(
        onSuccess: (_) =>
            log('✅ [CollectorService] CrepeEvent sent: ${match.dataFieldId}'),
        onFailure: (error) => log(
            '❌ [CollectorService] Failed to send CrepeEvent: ${error.message}'),
      );
    } catch (e) {
      log('❌ [CollectorService] Error sending CrepeEvent: $e');
    }
  }

  Future<bool> fetchAndSetActiveCollectors() async {
    try {
      log('📡 [CollectorService] Getting active collectors from backend...');
      final result = await getIt<ResearchGroupCollectorRepository>()
          .listParticipantCollectors();

      return result.fold(
        onSuccess: (response) {
          _activeCollectors = ActiveCollectors(collectors: response);
          return true;
        },
        onFailure: (ApiError error) {
          log('❌ [CollectorService] Failed to get collectors: ${error.message}');
          return false;
        },
      );
    } catch (e) {
      log('❌ [CollectorService] Error getting collectors: $e');
      return false;
    }
  }

  ActiveCollectors? get activeCollectors => _activeCollectors;
  bool get isInitialized => _isInitialized;
}
