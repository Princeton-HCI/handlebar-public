import 'dart:convert';
import 'dart:developer';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:handlebar/features/crepe/models/active_collectors.dart';
import 'package:handlebar/features/crepe/models/collector_match.dart';
import 'package:handlebar/features/crepe/models/match_result.dart';
import 'package:handlebar/core/shared_services/notification_service.dart';
import '../../../app/app_locator.dart';
import '../models/crepe_event.dart';

// Service to manage active collectors from the backend
// Handles fetching, parsing, and setting up collectors with the plugin
class CollectorService {
  // Singleton instance
  static final CollectorService _instance = CollectorService._internal();
  factory CollectorService() => _instance;
  CollectorService._internal();

  final CrepePlugin _crepePlugin = CrepePlugin();

  // Store the current active collectors
  ActiveCollectors? _activeCollectors;
  bool _isInitialized = false;

  /// Show error message to user via notification service
  static void _showErrorToUser(String message) {
    NotificationService().showError('CollectorService Error: $message');
  }

  /// Initialize the collector service and fetch active collectors
  Future<bool> initialize() async {
    try {
      // Set up callback for continuous monitoring matches
      _crepePlugin.setCollectorMatchesCallback(_handleContinuousMatches);

      // Fetch and set active collectors
      final success = await fetchAndSetActiveCollectors();

      if (success) {
        _isInitialized = true;
        // Enable continuous monitoring with the fetched collectors
        await _enableContinuousMonitoring();
      }

      return success;
    } catch (e) {
      log('❌ [CollectorService] Error initializing: $e');
      _showErrorToUser('Failed to initialize collector service: $e');
      return false;
    }
  }

  // Enable continuous monitoring in the accessibility service
  Future<void> _enableContinuousMonitoring() async {
    if (_activeCollectors != null) {
      try {
        final pluginData = _activeCollectors!.toPluginFormat();
        final collectorsJson = jsonEncode(pluginData);
        await _crepePlugin.setContinuousMonitoring(true,
            collectorsJson: collectorsJson);
        log('🔄 [CollectorService] Continuous monitoring enabled');
      } catch (e) {
        log('❌ [CollectorService] Failed to enable continuous monitoring: $e');
        _showErrorToUser('Failed to enable continuous monitoring: $e');
      }
    }
  }

  // Handle matches found by continuous monitoring
  void _handleContinuousMatches(Map<String, dynamic> eventData) {
    try {
      final matchResult = MatchResult.fromJson(eventData);
      if (matchResult.hasMatches) {
        log('🎯 [CollectorService] Found ${matchResult.matches.length} continuous matches!');

        // Send events for each match
        for (final match in matchResult.matches) {
          _sendCrepeEventForMatch(match);
        }
      }
    } catch (e) {
      log('❌ [CollectorService] Error handling continuous matches: $e');
      _showErrorToUser('Error processing data matches: $e');
    }
  }

  // Send a CrepeEvent for a specific match
  Future<void> _sendCrepeEventForMatch(CollectorMatch match) async {
    try {
      final crepeEvent = CrepeEvent(
        dataFieldId: match.dataFieldId,
        membershipId: match.membershipId,
        collectedAt: match.matchedAt,
        content: jsonEncode(match.toContentJson()),
      );

      final result = await crepeRepo.send(crepeEvent);

      result.fold(onSuccess: (_) {
        log('✅ [CollectorService] CrepeEvent sent: ${match.dataFieldId}');
      }, onFailure: (error) {
        log('❌ [CollectorService] Failed to send CrepeEvent: ${error.message}');
      });
    } catch (e) {
      log('❌ [CollectorService] Error sending CrepeEvent: $e');
      _showErrorToUser('Failed to send data event: $e');
    }
  }

  /// Fetch active collectors from backend and set them up with the plugin
  Future<bool> fetchAndSetActiveCollectors() async {
    try {
      log('📡 [CollectorService] Getting active collectors from backend...');

      final result = await rgCollectorRepo.listParticipantCollectors();

      return result.fold(
        onSuccess: (response) async {
          _activeCollectors = ActiveCollectors(collectors: response);
          return true;
        },
        onFailure: (error) {
          log('❌ [CollectorService] Failed to get collectors: ${error.message}');
          _showErrorToUser('Failed to fetch collectors: ${error.message}');
          return false;
        },
      );
    } catch (e) {
      log('❌ [CollectorService] Error getting collectors: $e');
      _showErrorToUser('Error fetching collectors: $e');
      return false;
    }
  }

  /// Get the current active collectors response
  ActiveCollectors? get activeCollectors => _activeCollectors;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Manually trigger a refresh of collectors from the backend
  Future<bool> refreshCollectors() async {
    final success = await fetchAndSetActiveCollectors();

    if (success) {
      // Update continuous monitoring with new collectors
      await _enableContinuousMonitoring();
    }

    return success;
  }
}
