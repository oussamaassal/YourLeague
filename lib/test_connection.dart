import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class TestConnectionButton extends StatelessWidget {
  const TestConnectionButton({super.key});

  Future<void> testConnection(BuildContext context) async {
    try {
      print('🔵 Testing connection to: ${ApiConfig.baseUrl}');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      
      print('🔵 Response: ${response.statusCode} - ${response.body}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connected! ${response.body}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🔴 Connection failed: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => testConnection(context),
      icon: const Icon(Icons.wifi_find),
      label: Text('Test Server (${ApiConfig.baseUrl})'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
