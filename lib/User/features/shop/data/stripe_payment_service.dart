import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';

class StripePaymentService {
  static String get _backendUrl => ApiConfig.baseUrl;

  // Initialize Stripe with your publishable key
  static Future<void> initialize() async {
    Stripe.publishableKey = 'pk_test_51SP3W4Kej0L6gzL0sf0Xl7eLJNcO4iyvBOIJus373rsEgf2CMhBuiUQjYV6GJBClFvAk49Q23YwRf0LdbpL4rOJQ00l5m3SDOr';
    await Stripe.instance.applySettings();
  }

  // Create payment intent on the server
  static Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Failed to create payment intent: ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  // Process payment with Stripe PaymentSheet
  static Future<bool> processPayment(
      BuildContext context, String amount, String currency) async {
    try {
      // Create payment intent via your backend
      final paymentIntent = await createPaymentIntent(amount, currency);

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'] as String,
          merchantDisplayName: 'YourLeague Shop',
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment completed successfully!')),
      );
      return true;
    } on StripeException catch (e) {
      // Payment failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.error.localizedMessage}')),
      );
      return false;
    } catch (e) {
      // Other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return false;
    }
  }
}