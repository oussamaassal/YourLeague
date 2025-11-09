import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _serviceId = 'service_vg8bt2r';
  static const _templateId = 'template_828j00e';
  static const _publicKey = 'CMFiTpVy3wnyUAd74';

  static Future<void> sendEmail({
    required String toEmail,
    required String subject,
    required String message,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': toEmail,
          'subject': subject,
          'message': message,
        },
      }),
    );

    if (response.statusCode != 200) {
      print('❌ Email failed: ${response.body}');
    } else {
      print('✅ Email sent to $toEmail');
    }
  }
}
