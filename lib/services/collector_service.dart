import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:handlebar/network/request_handler.dart';
import 'package:handlebar/models/Collector.dart';
import 'package:handlebar/models/CollectorResponse.dart';
import 'package:handlebar/models/CollectorMatch.dart';
import 'package:handlebar/models/CrepeEvent.dart';
import 'package:handlebar/models/MatchResult.dart';
import 'package:handlebar/models/Result.dart';

// Service to manage active collectors from the backend
// Handles fetching, parsing, and setting up collectors with the plugin
class CollectorService {

  // Singleton instance
  static final CollectorService _instance = CollectorService._internal();
  factory CollectorService() => _instance;
  CollectorService._internal();

  // Request handler for fetching collectors from the backend
  final RequestHandler _requestHandler = RequestHandler();
  final CrepePlugin _crepePlugin = CrepePlugin();
  
  // Store the current active collectors
  CollectorResponse? _activeCollectorResponse;
  bool _isInitialized = false;

  // Global scaffold messenger key for showing error messages
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  /// Show error message to user via snackbar
  static void _showErrorToUser(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('CollectorService Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Initialize the collector service and fetch active collectors
  Future<bool> initialize() async {
    try {
      // Initialize graph query system
      await _crepePlugin.initializeGraphQuery();
      
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
    if (_activeCollectorResponse != null) {
      try {
        final pluginData = _activeCollectorResponse!.toPluginFormat();
        final collectorsJson = jsonEncode(pluginData);
        await _crepePlugin.setContinuousMonitoring(true, collectorsJson: collectorsJson);
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
      final crepeEvent = match.toCrepeEvent();
      final result = await _requestHandler.sendCrepeEvent(crepeEvent);
      if (result.success) {
        log('✅ [CollectorService] CrepeEvent sent: ${match.dataFieldId}');
      } else {
        log('❌ [CollectorService] Failed to send CrepeEvent: ${result.error}');
      }
    } catch (e) {
      log('❌ [CollectorService] Error sending CrepeEvent: $e');
      _showErrorToUser('Failed to send data event: $e');
    }
  }

  /// Fetch active collectors from backend and set them up with the plugin
  Future<bool> fetchAndSetActiveCollectors() async {
    try {
      log('📡 [CollectorService] Getting active collectors from backend...');
      
      final result = await _requestHandler.getActiveCollectors();
      
      return result.fold(
        onSuccess: (response) async {
          _activeCollectorResponse = response;
          
          log('✅ [CollectorService] Got ${response.collectors.length} active collectors');
          
          // Update UI snapshot before processing collectors
          await _crepePlugin.updateSnapshot();
          
          // Process collectors with the plugin
          await processCollectorsWithPlugin();
          
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

  /// Process the fetched collectors with the plugin to check for matches
  Future<void> processCollectorsWithPlugin() async {
    if (_activeCollectorResponse == null) {
      return;
    }

    try {
      final pluginData = _activeCollectorResponse!.toPluginFormat();
      final transformedJson = jsonEncode(pluginData);
      
      // Use the plugin to match collector data against current UI
      final matchResultJson = await _crepePlugin.matchCollectorData(transformedJson);
      final matchResult = MatchResult.fromJson(matchResultJson);
      
      if (matchResult.hasMatches) {
        for (final match in matchResult.matches) {
          await _sendCrepeEventForMatch(match);
        }
      }
    } catch (e) {
      log('❌ [CollectorService] Error processing collectors: $e');
      _showErrorToUser('Error processing collectors: $e');
    }
  }


  /// Update UI snapshot and check for collector matches
  Future<void> updateUiSnapshotAndCheckForMatches() async {
    if (!_isInitialized) {
      return;
    }

    try {
      // Update the UI snapshot
      await _crepePlugin.updateSnapshot();
      // Process collectors against the new snapshot
      await processCollectorsWithPlugin();
    } catch (e) {
      log('❌ [CollectorService] Error updating and checking: $e');
      _showErrorToUser('Error updating UI snapshot: $e');
    }
  }

  /// Get the current active collectors response
  CollectorResponse? get activeCollectorResponse => _activeCollectorResponse;
  
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

  /// Test active collectors functionality - for testing/debugging
  Future<TestResult> testActiveCollectors() async {
    try {
      log('🧪 [CollectorService] Starting collector test...');
      
      // Step 1: Initialize if not already done
      if (!_isInitialized) {
        final initSuccess = await initialize();
        if (!initSuccess) {
          return TestResult(false, "Failed to initialize");
        }
      }
      
      // Step 2: Fetch fresh collectors
      final fetchSuccess = await refreshCollectors();
      if (!fetchSuccess) {
        return TestResult(false, "Failed to fetch collectors");
      }
      
      // Step 3: ALWAYS update UI snapshot to capture current screen
      log('📸 [CollectorService] Updating UI snapshot for current screen...');
      await _crepePlugin.updateSnapshot();
      
      // Step 4: Process collectors against current UI
      await processCollectorsWithPlugin();
      
      // Step 5: Report results
      final collectorsCount = _activeCollectorResponse?.collectors.length ?? 0;
      
      return TestResult(true, "Processed $collectorsCount collectors");
      
    } catch (e) {
      log('❌ [CollectorService] Test failed: $e');
      _showErrorToUser('Collector test failed: $e');
      return TestResult(false, "Test failed: $e");
    }
  }
}

/// Result class for test operations
class TestResult {
  final bool success;
  final String message;
  
  TestResult(this.success, this.message);
} 