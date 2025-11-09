import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MatchPushService {
  static String get _base => ApiConfig.baseUrl;

  /// Subscribe device to a match FCM topic
  static Future<void> subscribeToMatch(String matchId) async {
    final topic = 'match_${matchId}';
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  /// Unsubscribe device from a match FCM topic
  static Future<void> unsubscribeFromMatch(String matchId) async {
    final topic = 'match_${matchId}';
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  /// Trigger a push notification via backend
  static Future<bool> sendMatchPush({
    required String matchId,
    required String title,
    required String body,
  }) async {
    final uri = Uri.parse('$_base/matches/$matchId/push');
    final resp = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'body': body}),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) return true;
    throw Exception('Push failed: ${resp.statusCode} ${resp.body}');
  }
}
