import 'package:handlebar/network/request_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/services/collector_service.dart';
import 'package:crepe_plugin/crepe_plugin.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final RequestHandler _requestHandler = RequestHandler();

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await _requestHandler.clearAuthToken();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showDeveloperMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🛠️ Developer Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Current Environment: ${RequestHandler.currentEnvironment}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'API URL: ${RequestHandler.apiBaseUrl}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        RequestHandler.useProduction();
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Switched to Production'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud),
                      label: const Text('Production'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RequestHandler.currentEnvironment == 'Production' 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        RequestHandler.useStaging();
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔧 Switched to Staging'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.build),
                      label: const Text('Staging'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RequestHandler.currentEnvironment == 'Staging' 
                            ? Colors.orange 
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    RequestHandler.toggleEnvironment();
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🔄 Toggled to ${RequestHandler.currentEnvironment}'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Toggle Environment'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _testCollectors() async {
    final collectorService = CollectorService();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Testing collectors...'),
            ],
          ),
        );
      },
    );
    
    final result = await collectorService.testActiveCollectors();
    
    // Hide loading dialog
    Navigator.of(context).pop();
    
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully tested collectors: ${result.message}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to test collectors: ${result.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showCollectorStatus() async {
    final collectorService = CollectorService();
    
    // Check if continuous monitoring is enabled
    bool isEnabled = false;
    try {
      final crepePlugin = CrepePlugin();
      isEnabled = await crepePlugin.isContinuousMonitoringEnabled();
    } catch (e) {
      // Handle error silently
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎯 Collector Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service Initialized: ${collectorService.isInitialized ? "✅" : "❌"}'),
              const SizedBox(height: 8),
              Text('Continuous Monitoring: ${isEnabled ? "🔄 ACTIVE" : "⏸️ INACTIVE"}'),
              const SizedBox(height: 8),
              Text('Active Collectors: ${collectorService.activeCollectorResponse != null ? "📊 LOADED (${collectorService.activeCollectorResponse!.collectors.length})" : "❌ NONE"}'),
              const SizedBox(height: 16),
              const Text(
                'When continuous monitoring is active, the app will automatically detect when you navigate to collector target screens (like Maps) and send events to the backend.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _showDeveloperMenu,
          child: const Text('Driver\'s Seat Cooperative'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Environment indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: RequestHandler.currentEnvironment == 'Production' 
                  ? Colors.green 
                  : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              RequestHandler.currentEnvironment == 'Production' ? 'PROD' : 'STAGE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_car,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Handlebar!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your driver dashboard for tracking and insights.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Environment: ${RequestHandler.currentEnvironment}',
                style: TextStyle(
                  fontSize: 12,
                  color: RequestHandler.currentEnvironment == 'Production' 
                      ? Colors.green 
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              PlatformElevatedButton(
                onPressed: () {
                  context.go('/study-consent');
                },
                child: const Text('Research Study Participation'),
              ),
              const SizedBox(height: 16),
              PlatformElevatedButton(
                onPressed: () {
                  context.go('/crepe-events-test');
                },
                child: const Text('Test CrepeEvents'),
              ),
              const SizedBox(height: 16),
              PlatformElevatedButton(
                onPressed: _testCollectors,
                child: const Text('Test Active Collectors'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showCollectorStatus,
                icon: const Icon(Icons.info_outline),
                label: const Text('Collector Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 32),
              // Logout button
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              // Developer menu hint (only in debug mode)
              if (kDebugMode) ...[
                const Text(
                  '💡 Long press the app title to access developer settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
