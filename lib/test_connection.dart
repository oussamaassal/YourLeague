import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'dart:convert';

class TestConnectionButton extends StatelessWidget {
  const TestConnectionButton({super.key});

  Future<void> testConnection(BuildContext context) async {
    try {
      print('🔵 Testing connection to: ${ApiConfig.baseUrl}');
      
      final healthUri = Uri.parse('${ApiConfig.baseUrl}/health');
      final response = await http.get(healthUri).timeout(const Duration(seconds: 5));
      print('🔵 /health ${response.statusCode}: ${response.body}');

      // Attempt a lightweight payment intent (amount 100 = $1.00) to verify Stripe backend chain
      final paymentIntentUri = Uri.parse('${ApiConfig.baseUrl}/create-payment-intent');
      http.Response paymentResp;
      try {
        paymentResp = await http.post(
          paymentIntentUri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'amount': '100', 'currency': 'usd'}),
        ).timeout(const Duration(seconds: 6));
        print('🔵 /create-payment-intent ${paymentResp.statusCode}: ${paymentResp.body}');
      } catch (e) {
        print('🔴 Payment intent test failed: $e');
        paymentResp = http.Response('error: $e', 500);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentResp.statusCode >= 200 && paymentResp.statusCode < 300
                ? '✅ Server OK & PaymentIntent OK'
                : '⚠️ Health ${response.statusCode}; PaymentIntent ${paymentResp.statusCode}'),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => testConnection(context),
          icon: const Icon(Icons.wifi_find),
          label: Text('Test Server (${ApiConfig.baseUrl})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Override base with: --dart-define=API_BASE_URL=https://your-tunnel.ngrok-free.app',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
