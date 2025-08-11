import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'dart:convert';
import 'package:handlebar/network/request_handler.dart';
import 'package:handlebar/storage/device/secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/models/CrepeEvent.dart';

class CrepeEventsTest extends StatefulWidget {
  const CrepeEventsTest({super.key});

  @override
  State<CrepeEventsTest> createState() => _CrepeEventsTestState();
}

class _CrepeEventsTestState extends State<CrepeEventsTest> with WidgetsBindingObserver {
  final _crepePlugin = CrepePlugin();
  final _requestHandler = RequestHandler();
  final _secureStorage = SecureStorage();
  String _testResult = 'No test performed yet';
  String _accessibilityStatus = 'Unknown';
  String _authStatus = 'Checking authentication...';
  bool _isLoading = false;
  bool _isServiceEnabled = false;
  bool _isCheckingStatus = false;
  bool _isCheckingAuth = false;
  String? _userEmail;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuthAndAccessibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes from background (e.g., returning from settings)
    if (state == AppLifecycleState.resumed) {
      _checkAccessibilityStatus();
    }
  }

  Future<void> _initializeAuthAndAccessibility() async {
    await _checkAuthenticationStatus();
    await _checkAccessibilityStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    setState(() {
      _isCheckingAuth = true;
    });

    try {
      final isAuthenticated = _requestHandler.isAuthenticated();
      _userEmail = _secureStorage.email;
      
      setState(() {
        _isAuthenticated = isAuthenticated;
        _authStatus = isAuthenticated 
            ? 'Authenticated as: $_userEmail'
            : 'Not authenticated. Please log in through the main app.';
        _isCheckingAuth = false;
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error checking authentication: $e';
        _isAuthenticated = false;
        _isCheckingAuth = false;
      });
    }
  }

  Future<void> _checkAccessibilityStatus() async {
    if (_isCheckingStatus) return; // Prevent multiple simultaneous checks
    
    setState(() => _isCheckingStatus = true);
    
    try {
      final enabled = await _crepePlugin.isAccessibilityServiceEnabled();
      if (mounted) {
        setState(() {
          _isServiceEnabled = enabled;
          _accessibilityStatus = enabled ? 'Enabled' : 'Disabled';
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _accessibilityStatus = 'Error: $e';
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      await _crepePlugin.requestAccessibilityPermission();
      setState(() => _accessibilityStatus = 'Permission requested - check system settings');
      
      // Check status again after a delay to give user time to enable it
      Future.delayed(const Duration(seconds: 1), _checkAccessibilityStatus);
    } catch (e) {
      setState(() => _accessibilityStatus = 'Error requesting permission: $e');
    }
  }

  Future<Map<String, dynamic>> _generateDummyCrepeEvent() async {
    try {
      // Get accessibility data from the plugin
      final accessibilityData = await _crepePlugin.getAccessibilityData();
      
      // Generate a dummy CrepeEvent payload
      final crepeEvent = {
        'eventId': 'test-event-${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().toIso8601String(),
        'eventType': 'accessibility_event',
        'appPackage': 'co.wao.handlebar',
        'activityName': 'CrepeEventsTest',
        'eventData': {
          'accessibilityData': accessibilityData ?? 'No accessibility data available',
          'screenData': {
            'screenId': 'crepe_events_test_screen',
            'screenName': 'CrepeEvents Test Screen',
            'userInteraction': 'test_button_press'
          },
          'uiElements': [
            {
              'elementType': 'button',
              'text': 'Test CrepeEvents',
              'elementId': 'test_button',
              'bounds': '0,100,200,150',
              'isClickable': true
            },
            {
              'elementType': 'text',
              'text': _testResult,
              'elementId': 'result_text',
              'bounds': '0,200,400,250',
              'isClickable': false
            }
          ]
        },
        'metadata': {
          'pluginVersion': '1.0.0',
          'testMode': true,
          'environment': RequestHandler.currentEnvironment.toLowerCase(),
          'userEmail': _userEmail ?? 'unknown'
        }
      };

      return crepeEvent;
    } catch (e) {
      // Return a minimal dummy event if there's an error
      return {
        'eventId': 'dummy-event-${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().toIso8601String(),
        'eventType': 'test_event',
        'appPackage': 'co.wao.handlebar',
        'error': e.toString(),
        'metadata': {
          'testMode': true,
          'environment': RequestHandler.currentEnvironment.toLowerCase(),
          'userEmail': _userEmail ?? 'unknown'
        }
      };
    }
  }

  Future<void> _sendCrepeEventToBackend(Map<String, dynamic> crepeEventData) async {
    if (!_isAuthenticated) {
      setState(() => _testResult = 'ERROR: Not authenticated. Please log in through the main app.');
      return;
    }

    try {
      final crepeEvent = CrepeEvent(
        dataFieldId: 3,
        collectedAt: DateTime.now(),
        content: jsonEncode(crepeEventData),
      );
      final result = await _requestHandler.sendCrepeEvent(crepeEvent);

      if (result.success) {
        setState(() {
          _testResult = 'SUCCESS: CrepeEvent sent to backend!\n'
                      'Environment: ${RequestHandler.currentEnvironment}\n'
                      'User: $_userEmail\n'
                      'Response: ${result.userData?.toString() ?? 'No response data'}';
        });
      } else {
        setState(() {
          _testResult = 'FAILED: ${result.error ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = 'ERROR: Failed to send CrepeEvent\n'
                    'Error: $e';
      });
    }
  }

  Future<void> _testCrepeEvents() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Generating and sending CrepeEvent...';
    });

    try {
      // Generate dummy CrepeEvent
      final crepeEvent = await _generateDummyCrepeEvent();
      
      // Send to backend
      await _sendCrepeEventToBackend(crepeEvent);
      
    } catch (e) {
      setState(() {
        _testResult = 'ERROR: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    Color? statusColor,
    String? statusText,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (statusText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor ?? Colors.grey),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor ?? Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('CrepeEvents Test'),
        backgroundColor: Colors.green[600],
        leading: PlatformIconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Authentication Status Card
            _buildCard(
              title: 'Authentication Status',
              statusText: _isAuthenticated ? 'Authenticated' : 'Not Authenticated',
              statusColor: _isAuthenticated ? Colors.green : Colors.red,
              children: [
                if (_userEmail != null) ...[
                  Text(
                    'Logged in as: $_userEmail',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _isAuthenticated 
                      ? 'Using existing user session for CrepeEvents testing.'
                      : 'Please log in through the main app to test CrepeEvents.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PlatformElevatedButton(
                        onPressed: _isCheckingAuth ? null : _checkAuthenticationStatus,
                        child: _isCheckingAuth 
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Checking...'),
                                ],
                              )
                            : const Text('Refresh Auth Status'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isAuthenticated ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isAuthenticated ? Colors.green[200]! : Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isAuthenticated ? Icons.check_circle : Icons.warning,
                            color: _isAuthenticated ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Auth Status:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authStatus,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Accessibility Status Card
            _buildCard(
              title: 'Accessibility Service',
              statusText: _isCheckingStatus ? 'Checking...' : _accessibilityStatus,
              statusColor: _isCheckingStatus 
                  ? Colors.orange 
                  : (_isServiceEnabled ? Colors.green : Colors.red),
              children: [
                Text(
                  'Accessibility service is required to collect CrepeEvents data.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status auto-refreshes when you return from settings.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!_isServiceEnabled)
                      Expanded(
                        child: PlatformElevatedButton(
                          onPressed: _requestAccessibilityPermission,
                          child: const Text('Enable Accessibility Service'),
                        ),
                      ),
                    if (!_isServiceEnabled) const SizedBox(width: 8),
                    PlatformElevatedButton(
                      onPressed: _isCheckingStatus ? null : _checkAccessibilityStatus,
                      child: _isCheckingStatus 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                    ),
                  ],
                ),
                if (_isServiceEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Accessibility service is enabled'),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Environment Info Card
            _buildCard(
              title: 'Environment Info',
              statusText: RequestHandler.currentEnvironment,
              statusColor: RequestHandler.currentEnvironment == 'Production' ? Colors.blue : Colors.orange,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'API Environment: ${RequestHandler.currentEnvironment}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Base URL: ${RequestHandler.apiBaseUrl}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Endpoint: ${RequestHandler.apiBaseUrl}/api/crepe/event',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // CrepeEvents Test Card
            _buildCard(
              title: 'CrepeEvents Test',
              children: [
                Text(
                  'This will generate a dummy CrepeEvent and send it to the backend using your current login session.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                PlatformElevatedButton(
                  onPressed: (_isLoading || !_isAuthenticated) ? null : _testCrepeEvents,
                  child: _isLoading 
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Testing...'),
                          ],
                        )
                      : Text(!_isAuthenticated ? 'Log In Required' : 'Send Test CrepeEvent'),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Result:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _testResult,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 