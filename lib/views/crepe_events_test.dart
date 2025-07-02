import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:crepe_plugin/crepe_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CrepeEventsTest extends StatefulWidget {
  const CrepeEventsTest({super.key});

  @override
  State<CrepeEventsTest> createState() => _CrepeEventsTestState();
}

class _CrepeEventsTestState extends State<CrepeEventsTest> with WidgetsBindingObserver {
  final _crepePlugin = CrepePlugin();
  String _testResult = 'No test performed yet';
  String _accessibilityStatus = 'Unknown';
  String _authStatus = 'Not authenticated';
  bool _isLoading = false;
  bool _isServiceEnabled = false;
  bool _isStaging = false;
  bool _isCheckingStatus = false;
  bool _isAuthenticating = false;
  String? _authToken;
  bool _termsAccepted = false;

  // Test user credentials
  final String _testEmail = 'test@example.com';
  final String _testPassword = 'password123';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessibilityStatus();
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

  Future<void> _authenticateUser() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Creating test user...';
    });

    try {
      final baseUrl = _isStaging 
          ? 'https://dsc-api-staging-23350212163.us-central1.run.app'
          : 'https://dsc-api-service-23350212163.us-central1.run.app';

      // Step 1: Create test user
      try {
        final createUserResponse = await http.post(
          Uri.parse('$baseUrl/api/users'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user': {
              'email': _testEmail,
              'password': _testPassword,
              'first_name': 'Test',
              'last_name': 'User',
              'timezone': 'America/Los_Angeles'
            }
          }),
        );
        
        if (createUserResponse.statusCode == 200 || createUserResponse.statusCode == 422) {
          // 422 might mean user already exists, which is fine
          setState(() => _authStatus = 'Logging in...');
        } else {
          throw Exception('Failed to create user: ${createUserResponse.statusCode}');
        }
      } catch (e) {
        // User might already exist, continue with login
        setState(() => _authStatus = 'User exists, logging in...');
      }

      // Step 2: Login to get auth token
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/api/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session': {
            'email': _testEmail,
            'password': _testPassword
          }
        }),
      );

      if (loginResponse.statusCode == 200) {
        print('Login response headers: ${loginResponse.headers}'); // Debug log
        
        // Get token from authorization header
        String? token = loginResponse.headers['authorization'];
        if (token != null && token.startsWith('Bearer ')) {
          token = token.substring(7); // Remove 'Bearer ' prefix
        }
        
        if (token == null || token.isEmpty) {
          throw Exception('No authorization token found in headers: ${loginResponse.headers}');
        }
        
        _authToken = token;
        if (_authToken == null) {
          throw Exception('No authorization token found in headers: ${loginResponse.headers}');
        } else {
          print('We have a token'); // Debug log
        }
        setState(() => _authStatus = 'Accepting terms...');

        // Step 3: Accept terms
        final termsResponse = await http.post(
          Uri.parse('$baseUrl/api/accepted_terms'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
          body: json.encode({
            'accepted_terms': {
              'terms_id': 2
            }
          }),
        );

        print('Terms response status: ${termsResponse.statusCode}'); // Debug log
        print('Terms response body: ${termsResponse.body}'); // Debug log

        if (termsResponse.statusCode == 200 || termsResponse.statusCode == 201 || termsResponse.statusCode == 422) {
          // 422 might mean terms already accepted
          setState(() {
            _termsAccepted = true;
            _authStatus = 'Authenticated & Terms Accepted';
          });
        } else {
          throw Exception('Failed to accept terms: ${termsResponse.statusCode} - ${termsResponse.body}');
        }
      } else {
        final loginError = loginResponse.body;
        throw Exception('Login failed: ${loginResponse.statusCode} - $loginError');
      }

    } catch (e) {
      print('Auth error: $e'); // Debug log
      setState(() => _authStatus = 'Auth failed: $e');
    } finally {
      setState(() => _isAuthenticating = false);
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
        'appPackage': 'co.wao.driversseat.app.dsc_mobile_rework',
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
          'environment': _isStaging ? 'staging' : 'production'
        }
      };

      return crepeEvent;
    } catch (e) {
      // Return a minimal dummy event if there's an error
      return {
        'eventId': 'dummy-event-${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().toIso8601String(),
        'eventType': 'test_event',
        'appPackage': 'co.wao.driversseat.app.dsc_mobile_rework',
        'error': e.toString(),
        'metadata': {
          'testMode': true,
          'environment': _isStaging ? 'staging' : 'production'
        }
      };
    }
  }

  Future<void> _sendCrepeEventToBackend(Map<String, dynamic> crepeEvent) async {
    if (_authToken == null) {
      setState(() => _testResult = 'ERROR: Not authenticated. Please authenticate first.');
      return;
    }

    try {
      final url = _isStaging 
          ? 'https://dsc-api-staging-23350212163.us-central1.run.app'
          : 'https://dsc-api-service-23350212163.us-central1.run.app';
      
      final uri = Uri.parse('$url/api/crepe/event');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'data_field_id': 3,
          'collected_at': DateTime.now().toIso8601String(),
          'content': json.encode(crepeEvent),
          'notification': 'Test CrepeEvent from Flutter app'
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _testResult = 'SUCCESS: CrepeEvent sent to backend!\n'
                      'Status: ${response.statusCode}\n'
                      'Response: ${response.body}';
        });
      } else {
        setState(() {
          _testResult = 'FAILED: HTTP ${response.statusCode}\n'
                      'Response: ${response.body}';
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Authentication Card
            _buildCard(
              title: 'Authentication',
              statusText: _authToken != null && _termsAccepted ? 'Ready' : 'Required',
              statusColor: _authToken != null && _termsAccepted ? Colors.green : Colors.red,
              children: [
                Text(
                  'Test user: $_testEmail',
                  style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authentication is required to send CrepeEvents to the backend.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PlatformElevatedButton(
                        onPressed: _isAuthenticating ? null : _authenticateUser,
                        child: _isAuthenticating 
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Authenticating...'),
                                ],
                              )
                            : const Text('Authenticate Test User'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auth Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authStatus,
                        style: const TextStyle(fontFamily: 'monospace'),
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

            // Environment Selection Card
            _buildCard(
              title: 'Environment',
              statusText: _isStaging ? 'Staging' : 'Production',
              statusColor: _isStaging ? Colors.orange : Colors.blue,
              children: [
                Row(
                  children: [
                    const Text('API Environment: '),
                    const SizedBox(width: 8),
                    const Text('Prod'),
                    Switch(
                      value: _isStaging,
                      onChanged: (value) {
                        setState(() {
                          _isStaging = value;
                          // Reset auth when changing environments
                          _authToken = null;
                          _termsAccepted = false;
                          _authStatus = 'Not authenticated';
                        });
                      },
                    ),
                    const Text('Staging'),
                  ],
                ),
              ],
            ),

            // CrepeEvents Test Card
            _buildCard(
              title: 'CrepeEvents Test',
              children: [
                Text(
                  'This will generate a dummy CrepeEvent and send it to the backend API.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                PlatformElevatedButton(
                  onPressed: (_isLoading || _authToken == null) ? null : _testCrepeEvents,
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
                      : Text(_authToken == null ? 'Authenticate First' : 'Send Test CrepeEvent'),
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
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // API Info Card
            _buildCard(
              title: 'API Information',
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
                      const Text(
                        'CrepeEvents Endpoint:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isStaging 
                            ? 'https://dsc-api-staging-23350212163.us-central1.run.app/api/crepe/event'
                            : 'https://dsc-api-service-23350212163.us-central1.run.app/api/crepe/event',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This endpoint receives authenticated CrepeEvent data from the plugin.',
                        style: TextStyle(fontSize: 12),
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