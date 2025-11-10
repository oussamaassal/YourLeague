  import 'dart:convert';
  import 'package:http/http.dart' as http;

  /// A simple EmailJS-based email sender
  /// Uses your public EmailJS API (free for limited emails)
  class EmailService {
  static const String _serviceId = 'service_vg8bt2r'; // 🔧 your Service ID
  static const String _templateId = 'template_828j00e'; // 🔧 replace once created
  static const String _userPublicKey = 'CMFiTpVy3wnyUAd74'; // 🔧 from EmailJS dashboard

  /// Sends an email using EmailJS REST API
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
  body: jsonEncode({
  'service_id': _serviceId,
  'template_id': _templateId,
  'user_id': _userPublicKey,
  'template_params': {
  'to_email': toEmail,
  'subject': subject,
  'message': message,
  },
  }),
  );

  if (response.statusCode != 200) {
  print('❌ Failed to send email: ${response.body}');
  } else {
  print('✅ Email sent successfully to $toEmail');
  }
  }
  }
