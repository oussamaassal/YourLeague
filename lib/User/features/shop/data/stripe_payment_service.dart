import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';
import '../../../../config/stripe_config.dart';

class StripePaymentService {
  static String get _backendUrl => ApiConfig.baseUrl;

  /// Initialize Stripe (called in main before runApp)
  static Future<void> initialize() async {
    Stripe.publishableKey = StripeConfig.publishableKey; // centralized
    // Apple Pay merchantIdentifier used only on iOS; safe to set anyway
    Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
    // Set return URL for deep linking back to app
    Stripe.urlScheme = 'yourleague';
    await Stripe.instance.applySettings();
  }

  /// Quick health check so we fail fast with a friendly message instead of crashing.
  static Future<void> _ensureBackendReachable() async {
    final uri = Uri.parse('$_backendUrl/health');
    try {
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode >= 400) {
        throw Exception('Health endpoint returned ${resp.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Backend timeout. Ensure server at $_backendUrl is running or switch to ngrok.');
    } on SocketException {
      throw Exception('Cannot reach $_backendUrl. Device and server must be on same WiFi (current IP ${ApiConfig.localIP}).');
    }
  }

  /// Create payment intent on the Node backend.
  static Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    try {
      print('🔵 Attempting to connect to: $_backendUrl/create-payment-intent');
      print('🔵 Amount (minor units): $amount, Currency: $currency');

      final response = await http
          .post(
            Uri.parse('$_backendUrl/create-payment-intent'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'amount': amount, 'currency': currency}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (!decoded.containsKey('clientSecret')) {
          throw Exception('Malformed response: missing clientSecret');
        }
        return decoded;
      }
      throw Exception('Failed (${response.statusCode}): ${response.body}');
    } on TimeoutException {
      throw Exception('Request to backend timed out.');
    } on SocketException {
      throw Exception('Network error (no internet or backend unreachable).');
    } catch (e) {
      print('🔴 Error creating payment intent: $e');
      rethrow; // propagate for UI handling
    }
  }

  /// Process payment with Stripe PaymentSheet. Returns true if successful.
  static Future<bool> processPayment(
      BuildContext context, String amount, String currency) async {
    try {
      // 1. Ensure backend reachable
      await _ensureBackendReachable();

      // 2. Create payment intent via backend
      final paymentIntent = await createPaymentIntent(amount, currency);

      // 3. Init payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'] as String,
          merchantDisplayName: 'YourLeague Shop',
          style: ThemeMode.system,
          returnURL: 'yourleague://stripe-redirect',
          allowsDelayedPaymentMethods: true,
        ),
      );

      // 4. Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      if (!context.mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment completed successfully!')),
      );
      return true;
    } on StripeException catch (e) {
      print('🔴 Stripe Exception: ${e.error.code} - ${e.error.message}');
      
      // User cancelled the payment
      if (e.error.code == FailureCode.Canceled) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled')),
        );
        return false;
      }
      
      if (!context.mounted) return false;
      final msg = e.error.message ?? e.error.localizedMessage ?? 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Stripe: $msg')),
      );
      return false;
    } catch (e) {
      print('🔴 Payment error: $e');
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Payment error: $e')),
      );
      return false;
    }
  }
}