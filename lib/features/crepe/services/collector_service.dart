import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:handlebar/features/crepe/data/crepe_event_repository.dart';
import 'package:handlebar/features/crepe/models/active_collectors.dart';
import 'package:handlebar/features/crepe/models/collector_match.dart';
import 'package:handlebar/features/crepe/models/match_result.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_sensor_repository.dart';
import '../../../app/app_locator.dart';
import '../../../core/network/api_env_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/auth_token_store.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/crepe_event.dart';
import '../models/participant_sensor_config.dart';
import 'crepe_service.dart';

class CollectorService {
  static final CollectorService _instance = CollectorService._internal();
  factory CollectorService() => _instance;
  CollectorService._internal();

  final CrepeService _crepeService = getIt<CrepeService>();
  final AuthTokenStore _authStore = getIt<AuthTokenStore>();

  ActiveCollectors? _activeCollectors;
  List<ParticipantSensorConfig>? _activeSensors;
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

      // Sensors are fetched independently of collectors: a study may configure
      // location without any screen collectors, and a collector fetch failure
      // shouldn't silently disable sensors (or vice versa).
      await fetchAndSetActiveSensors();

      if (success) {
        _isInitialized = true;
        await _enableContinuousMonitoring();
      }

      await _enableSensorMonitoring();
      await _pushSensorSyncConfig();

      return success;
    } catch (e) {
      log('❌ [CollectorService] Error syncing state: $e');
      await _stopContinuousMonitoring();
      return false;
    }
  }

  /// Hands the native uploader the endpoint and credentials for queued
  /// samples.
  ///
  /// Pushed on every sync so a refreshed token reaches native promptly: the
  /// uploader parks the queue on a 401 rather than retrying, and only a new
  /// config restarts it.
  Future<void> _pushSensorSyncConfig() async {
    try {
      final token = _authStore.token;
      if (token == null) {
        await _crepeService.setSensorSyncConfig(null);
        return;
      }

      final config = jsonEncode({
        'url': '${ApiEnvConfig.baseUrl}/api/research/points',
        'headers': {'authorization': 'Bearer $token'},
        // The points endpoint documents a 60-point cap per request.
        'batchSize': 60,
      });
      await _crepeService.setSensorSyncConfig(config);
    } catch (e) {
      log('❌ [CollectorService] Failed to push sensor sync config: $e');
    }
  }

  Future<void> _stopContinuousMonitoring() async {
    _activeCollectors = null;
    _activeSensors = null;
    _isInitialized = false;
    await _crepeService.setContinuousMonitoring(false);
    await _crepeService.setSensorMonitoring(false);
    // Clears the natively-stored bearer token. Queued samples are kept: they
    // are still this participant's data and upload once a valid config
    // returns.
    await _crepeService.setSensorSyncConfig(null);
  }

  Future<void> _enableContinuousMonitoring() async {
    if (_activeCollectors != null) {
      try {
        final pluginData = _activeCollectors!.toPluginFormat();
        final collectorsJson = jsonEncode(pluginData);
        await _crepeService.setContinuousMonitoring(true,
            collectorsJson: collectorsJson);
        // Re-apply the participant's overlay preference each time monitoring
        // starts, so it survives accessibility-service restarts.
        await _crepeService
            .setOverlayEnabled(SecureStorage().showCollectorOverlays);
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
          if (!match.hasValidIds) {
            log(
              '⚠️ [CollectorService] Skipping match with invalid ids '
              '(dataFieldId=${match.dataFieldId}, membershipId=${match.membershipId}). '
              'Live test mode does not persist events.',
            );
            continue;
          }
          unawaited(_sendCrepeEventForMatch(match));
        }
      }
    } catch (e, st) {
      log('❌ [CollectorService] Error handling continuous matches: $e',
          stackTrace: st);
    }
  }

  Future<void> _sendCrepeEventForMatch(CollectorMatch match) async {
    try {
      final content = jsonEncode(match.toContentJson());
      final crepeEvent = CrepeEvent(
        dataFieldId: match.dataFieldId,
        membershipId: match.membershipId,
        collectedAt: match.matchedAt,
        content: content,
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

  Future<void> _enableSensorMonitoring() async {
    final sensors = _activeSensors;
    if (sensors == null) return;

    try {
      if (sensors.isEmpty) {
        await _crepeService.setSensorMonitoring(false);
        log('🟡 [CollectorService] No sensors configured; sensor monitoring OFF');
        return;
      }

      final payload = jsonEncode({
        'sensors': sensors.map((s) => s.toPluginFormat()).toList(),
      });
      await _crepeService.setSensorMonitoring(true, sensorsJson: payload);
      log('🟢 [CollectorService] Sensor monitoring ENABLED (${sensors.length})');
    } catch (e) {
      log('❌ [CollectorService] Failed to enable sensor monitoring: $e');
      _showErrorToUser('Failed to enable sensor monitoring: $e');
    }
  }

  Future<bool> fetchAndSetActiveSensors() async {
    try {
      log('📡 [CollectorService] Getting active sensors from backend...');
      final result =
          await getIt<ResearchGroupSensorRepository>().listParticipantSensors();

      return result.fold(
        onSuccess: (sensors) {
          // Dormant configs (collector_match whose collector was deleted) are
          // dropped here so the native side never sees an unsatisfiable trigger.
          _activeSensors =
              sensors.where((s) => !s.sensor.isDormant).toList(growable: false);
          return true;
        },
        onFailure: (ApiError error) {
          log('❌ [CollectorService] Failed to get sensors: ${error.message}');
          return false;
        },
      );
    } catch (e) {
      log('❌ [CollectorService] Error getting sensors: $e');
      return false;
    }
  }

  ActiveCollectors? get activeCollectors => _activeCollectors;
  List<ParticipantSensorConfig>? get activeSensors => _activeSensors;
  bool get isInitialized => _isInitialized;
}
