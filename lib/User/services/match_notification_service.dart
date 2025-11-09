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
    print('📧 [MatchNotificationService] POST $uri recipients=${recipients.length}');
    http.Response resp;
    try {
      resp = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipients': recipients,
          'subject': subject,
          'message': message,
        }),
      );
    } on SocketException catch (e) {
      throw Exception('Network error notifying match at $_base: $e');
    }
    print('📧 [MatchNotificationService] Response ${resp.statusCode}: ${resp.body.substring(0, resp.body.length.clamp(0, 400))}');
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return true;
    }
    if (resp.statusCode == 404) {
      throw Exception('Notify failed: 404 Not Found. Check server route /matches/:matchId/notify. BaseUrl=$_base');
    }
    throw Exception('Notify failed: ${resp.statusCode} ${resp.reasonPhrase} Body=${resp.body}');
  }
}
