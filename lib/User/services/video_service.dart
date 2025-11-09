import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class VideoService {
  static String get _base => ApiConfig.baseUrl;

  // Upload a video file for a match. Returns record map.
  static Future<Map<String, dynamic>> uploadMatchVideo({
    required String matchId,
    required File file,
    String? title,
  }) async {
    final uri = Uri.parse('$_base/matches/$matchId/videos');
    final request = http.MultipartRequest('POST', uri);
    if (title != null) request.fields['title'] = title;

  // Let http infer the content type based on file extension.
  request.files.add(await http.MultipartFile.fromPath('video', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }

  // List videos for a match. Returns List<Map>.
  static Future<List<Map<String, dynamic>>> listMatchVideos(String matchId) async {
    final resp = await http.get(Uri.parse('$_base/matches/$matchId/videos'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('List videos failed: ${resp.statusCode} ${resp.body}');
  }
}
