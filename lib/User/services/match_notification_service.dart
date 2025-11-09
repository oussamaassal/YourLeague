import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class MatchNotificationService {
  static String get _base => ApiConfig.baseUrl;

  // Send notification emails for a match.
  static Future<bool> notifyMatch({
    required String matchId,
    required List<String> recipients,
    String? subject,
    String? message,
  }) async {
    final uri = Uri.parse('$_base/matches/$matchId/notify');
    final resp = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipients': recipients,
        'subject': subject,
        'message': message,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return true;
    }
    throw Exception('Notify failed: ${resp.statusCode} ${resp.body}');
  }
}
