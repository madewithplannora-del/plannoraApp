import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class HealthCheckScreen extends StatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  late Future<Map<String, dynamic>> _healthCheck;

  @override
  void initState() {
    super.initState();
    _healthCheck = _checkHealth();
  }

  Future<Map<String, dynamic>> _checkHealth() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        '/health',
        requiresAuth: false,
      );
      
      return {
        'status': 'success',
        'code': 200,
        'message': 'Connected to backend',
        'response': response,
        'timestamp': DateTime.now().toString(),
      };
    } on ApiException catch (e) {
      return {
        'status': 'error',
        'code': e.statusCode,
        'message': e.message,
        'details': e.details,
        'timestamp': DateTime.now().toString(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'code': null,
        'message': 'Unexpected error: $e',
        'timestamp': DateTime.now().toString(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Check - Backend Connectivity'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _healthCheck,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testing connection to backend...'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('No response data'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _healthCheck = _checkHealth();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final status = data['status'] as String;
          final isSuccess = status == 'success';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green[50] : Colors.red[50],
                    border: Border.all(
                      color: isSuccess ? Colors.green : Colors.red,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSuccess ? '✅ Connected' : '❌ Connection Failed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSuccess ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['message'] ?? 'No message',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSuccess ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Response Details
                const Text(
                  'Response Details:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildDetailCard(
                  'Status Code',
                  '${data['code'] ?? 'N/A'}',
                  isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),

                _buildDetailCard(
                  'Endpoint',
                  '/health',
                  Colors.blue,
                ),
                const SizedBox(height: 8),

                _buildDetailCard(
                  'Timestamp',
                  data['timestamp'] ?? 'N/A',
                  Colors.grey,
                ),
                const SizedBox(height: 24),

                // Response Body
                const Text(
                  'Backend Response:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _formatJson(data['response'] ?? data['details'] ?? 'No data'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Retry Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _healthCheck = _checkHealth();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(dynamic data) {
    if (data is String) return data;
    if (data is Map || data is List) {
      return _prettyPrintJson(data);
    }
    return data.toString();
  }

  String _prettyPrintJson(dynamic json, [int indent = 0]) {
    final String indentStr = ' ' * indent;
    final String nextIndentStr = ' ' * (indent + 2);

    if (json is Map) {
      if (json.isEmpty) return '{}';
      final entries = json.entries.map((e) {
        return '$nextIndentStr"${e.key}": ${_prettyPrintJson(e.value, indent + 2)}';
      });
      return '{\n${entries.join(',\n')}\n$indentStr}';
    } else if (json is List) {
      if (json.isEmpty) return '[]';
      final items = json.map((item) {
        return nextIndentStr + _prettyPrintJson(item, indent + 2);
      });
      return '[\n${items.join(',\n')}\n$indentStr]';
    } else if (json is String) {
      return '"$json"';
    } else if (json is bool || json is num) {
      return json.toString();
    } else {
      return 'null';
    }
  }
}
