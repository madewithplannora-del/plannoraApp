import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String? result;
  bool isLoading = false;

  Future<void> testConnections() async {
    setState(() {
      isLoading = true;
      result = null;
    });

    final tests = <String, Future<String>>{}; 

    // Test 1: Direct localhost
    tests['localhost:3001'] = _testUrl('http://localhost:3001/health');

    // Test 2: 127.0.0.1
    tests['127.0.0.1:3001'] = _testUrl('http://127.0.0.1:3001/health');

    // Test 3: Android emulator host
    tests['10.0.2.2:3001'] = _testUrl('http://10.0.2.2:3001/health');

    // Test 4: Render production
    tests['Render (production)'] = _testUrl('https://plannoraapp-1.onrender.com/health');

    // Run all tests
    final results = <String>[];
    for (final entry in tests.entries) {
      try {
        final res = await entry.value;
        results.add('✅ ${entry.key}: $res');
      } catch (e) {
        results.add('❌ ${entry.key}: ${e.toString()}');
      }
    }

    setState(() {
      result = results.join('\n\n');
      isLoading = false;
    });
  }

  Future<String> _testUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return 'Status ${response.statusCode}: ${response.body}';
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Diagnostics'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Connection Test',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will test connection to backend on multiple URLs:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• localhost:3001'),
                  Text('• 127.0.0.1:3001'),
                  Text('• 10.0.2.2:3001 (Android Emulator)'),
                  Text('• Production (Render)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : testConnections,
                icon: const Icon(Icons.cloud_upload),
                label: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Tests'),
              ),
            ),
            const SizedBox(height: 32),
            if (result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
