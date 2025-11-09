import 'dart:io'; // For File and SocketException
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
    print('📹 [VideoService] Uploading video to: $uri (exists=${await file.exists()})');
    print('📹 [VideoService] File size: ${await file.length()} bytes');
    final request = http.MultipartRequest('POST', uri);
    if (title != null) request.fields['title'] = title;

  // Let http infer the content type based on file extension.
  request.files.add(await http.MultipartFile.fromPath('video', file.path));

    http.StreamedResponse streamed;
    http.Response response;
    try {
      streamed = await request.send();
      response = await http.Response.fromStream(streamed);
    } on SocketException catch (e) {
      throw Exception('Network error (server unreachable at $_base): $e');
    }
    print('📹 [VideoService] Upload response ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 400))}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      throw Exception('Upload failed: 404 Not Found. Verify server running & route /matches/:matchId/videos exists. BaseUrl=$_base');
    }
    throw Exception('Upload failed: ${response.statusCode} ${response.reasonPhrase} Body=${response.body}');
  }

  // List videos for a match. Returns List<Map>.
  static Future<List<Map<String, dynamic>>> listMatchVideos(String matchId) async {
    final url = Uri.parse('$_base/matches/$matchId/videos');
    print('📹 [VideoService] Listing videos GET $url');
    http.Response resp;
    try {
      resp = await http.get(url);
    } on SocketException catch (e) {
      throw Exception('Network error listing videos (server unreachable at $_base): $e');
    }
    print('📹 [VideoService] List response ${resp.statusCode}: ${resp.body.substring(0, resp.body.length.clamp(0, 400))}');
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    if (resp.statusCode == 404) {
      throw Exception('List videos failed: 404 Not Found. Ensure server route and matchId correct. BaseUrl=$_base');
    }
    throw Exception('List videos failed: ${resp.statusCode} ${resp.reasonPhrase} Body=${resp.body}');
  }
}
