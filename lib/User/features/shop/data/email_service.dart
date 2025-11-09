import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';

class EmailService {
  static String get _backendUrl => ApiConfig.baseUrl;

  static Future<bool> sendCartConfirmation({
    required String userEmail,
    required String productName,
    required double productPrice,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/send-cart-confirmation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userEmail': userEmail,
          'productName': productName,
          'productPrice': productPrice.toStringAsFixed(2),
          'quantity': quantity,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      
      print('Failed to send email: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
