import 'dart:developer';
import 'dart:convert';
import 'package:handlebar/network/request_handler.dart';
import 'package:handlebar/services/collector_service.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:handlebar/models/CrepeEvent.dart';

/// Test file to demonstrate the complete flow
/// This shows each step of the process with explanations
class TestFlow {
  
  /// Complete test flow from authentication to collector matching
  static Future<void> runCompleteFlow() async {
    log("🚀 Starting complete test flow...", name: 'TestFlow');
    
    try {
      // Step 1: Sign up (if needed)
      await _testSignUp();
      
      // Step 2: Accept terms
      await _testAcceptTerms();
      
      // Step 3: Check accessibility service
      await _testAccessibilityService();
      
      // Step 4: Initialize collectors
      await _testCollectorInitialization();
      
      // Step 5: Test collector matching
      await _testCollectorMatching();
      
      log("✅ Complete test flow finished successfully!", name: 'TestFlow');
      
    } catch (e) {
      log("❌ Test flow failed: $e", name: 'TestFlow');
    }
  }
  
  /// Step 1: Sign up a test user (or use existing authentication)
  static Future<void> _testSignUp() async {
    log("📝 Step 1: Testing authentication...", name: 'TestFlow');
    
    final requestHandler = RequestHandler();
    
    if (requestHandler.isAuthenticated()) {
      log("✅ User already authenticated", name: 'TestFlow');
      return;
    }
    
    // If not authenticated, you would sign up here:
    // final result = await requestHandler.requestNewUser(email, password);
    log("⚠️ User not authenticated - would need to sign up", name: 'TestFlow');
  }
  
  /// Step 2: Accept terms of the study
  static Future<void> _testAcceptTerms() async {
    log("📋 Step 2: Testing terms acceptance...", name: 'TestFlow');
    
    final requestHandler = RequestHandler();
    
    // Check current terms status
    final termsResult = await requestHandler.checkCurrentTerms();
    if (termsResult.success) {
      if (!termsResult.hasAcceptedCurrentTerms && termsResult.currentTermsId != null) {
        log("📝 Accepting terms...", name: 'TestFlow');
        await requestHandler.acceptTerms(termsResult.currentTermsId!);
        log("✅ Terms accepted", name: 'TestFlow');
      } else {
        log("✅ Terms already accepted", name: 'TestFlow');
      }
    } else {
      log("❌ Failed to check terms: ${termsResult.error}", name: 'TestFlow');
    }
  }
  
  /// Step 3: Check accessibility service status
  static Future<void> _testAccessibilityService() async {
    log("🔧 Step 3: Testing accessibility service...", name: 'TestFlow');
    
    final crepePlugin = CrepePlugin();
    
    try {
      final isEnabled = await crepePlugin.isAccessibilityServiceEnabled();
      if (isEnabled) {
        log("✅ Accessibility service is enabled", name: 'TestFlow');
      } else {
        log("⚠️ Accessibility service is not enabled", name: 'TestFlow');
        log("   User would need to enable it in settings", name: 'TestFlow');
      }
    } catch (e) {
      log("❌ Error checking accessibility service: $e", name: 'TestFlow');
    }
  }
  
  /// Step 4: Initialize collectors from backend
  static Future<void> _testCollectorInitialization() async {
    log("🎯 Step 4: Testing collector initialization...", name: 'TestFlow');
    
    final collectorService = CollectorService();
    
    // Initialize the service (fetches collectors from backend)
    final success = await collectorService.initialize();
    
    if (success) {
      log("✅ Collector service initialized successfully", name: 'TestFlow');
      
      // Log collector details
      final collectorsJson = collectorService.activeCollectorsJson;
      if (collectorsJson != null) {
        log("📊 Collectors JSON length: ${collectorsJson.length} characters", name: 'TestFlow');
      }
    } else {
      log("❌ Failed to initialize collector service", name: 'TestFlow');
    }
  }
  
  /// Step 5: Test collector matching against current UI
  static Future<void> _testCollectorMatching() async {
    log("🔍 Step 5: Testing collector matching...", name: 'TestFlow');
    
    final collectorService = CollectorService();
    
    if (!collectorService.isInitialized) {
      log("⚠️ Collector service not initialized, skipping matching test", name: 'TestFlow');
      return;
    }
    
    // Update UI snapshot and check for matches
    await collectorService.updateUiSnapshotAndCheckForMatches();
    
    log("✅ Collector matching test completed", name: 'TestFlow');
  }
  
  /// Simple snippet showing the core collector flow
  static Future<void> simpleCollectorTest() async {
    log("🧪 Running simple collector test...", name: 'TestFlow.Simple');
    
    // 1. Get authenticated request handler
    final requestHandler = RequestHandler();
    if (!requestHandler.isAuthenticated()) {
      log("❌ User not authenticated", name: 'TestFlow.Simple');
      return;
    }
    
    // 2. Fetch collectors from backend with authentication
    final collectorsResult = await requestHandler.getActiveCollectors();
    if (!collectorsResult.success) {
      log("❌ Failed to fetch collectors: ${collectorsResult.error}", name: 'TestFlow.Simple');
      return;
    }
    
    log("✅ Fetched collectors successfully", name: 'TestFlow.Simple');
    
    // 3. Initialize plugin and create UI snapshot
    final crepePlugin = CrepePlugin();
    await crepePlugin.initializeGraphQuery();
    await crepePlugin.updateSnapshot();
    
    log("✅ Plugin initialized and snapshot updated", name: 'TestFlow.Simple');
    
    // 4. Process collectors with plugin (uses OntologyQuery.deserialize)
    final pluginData = collectorsResult.valueOrNull?.toPluginFormat();
    final matchResult = await crepePlugin.matchCollectorData(jsonEncode(pluginData));
    
    log("✅ Collector matching completed", name: 'TestFlow.Simple');
    log("📊 Match result: ${matchResult.keys.toList()}", name: 'TestFlow.Simple');
    
    // 5. Handle any matches found
    if (matchResult.containsKey('matches')) {
      final matches = matchResult['matches'] as List<dynamic>;
      log("🎯 Found ${matches.length} matches", name: 'TestFlow.Simple');
        
        // 6. Send crepe events for matches
        for (final match in matches) {
          final matchMap = match as Map<String, dynamic>;
          final dataFieldId = int.tryParse(matchMap['datafieldId']?.toString() ?? '0') ?? 0;
          final crepeEvent = CrepeEvent(
            dataFieldId: dataFieldId,
            collectedAt: DateTime.now(),
            content: jsonEncode(match),
          );
          
          await requestHandler.sendCrepeEvent(crepeEvent);
          log("📤 Sent crepe event for datafield: $dataFieldId", name: 'TestFlow.Simple');
        }
      }
    }
    
    log("✅ Simple collector test completed!", name: 'TestFlow.Simple');
  }
} 