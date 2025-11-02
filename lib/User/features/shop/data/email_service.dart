import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _backendUrl = 'http://10.0.2.2:3000';

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
