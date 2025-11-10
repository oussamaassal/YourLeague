import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple current weather model
class WeatherInfo {
  final double tempC;
  final String description;
  final String iconCode;
  final double windSpeed;
  final int humidity;

  const WeatherInfo({
    required this.tempC,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.humidity,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}

/// OpenWeather-based weather service. Uses 2.5 current weather (free).
class WeatherService {
  static const String _apiKey = '7adb9232e48639dfb0080fbcb6132b0a';
  static bool get isEnabled => _apiKey.isNotEmpty;
  static String? lastError;
  static String? lastRawResponse;

  static Future<WeatherInfo?> getCurrent({required double lat, required double lon}) async {
    if (!isEnabled) {
      lastError = 'API key not set';
      return null;
    }
    return await _getCurrentWeather(lat: lat, lon: lon);
  }

  static Future<WeatherInfo?> _getCurrentWeather({required double lat, required double lon}) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
    );
    try {
      final res = await http.get(uri);
      lastRawResponse = res.body;
      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('[Weather] GET $uri -> ${res.statusCode}: ${res.body}');
        if (res.statusCode == 401) {
          final msg = _extractMessage(res.body) ?? 'Unauthorized';
          lastError = 'Current weather 2.5 -> 401 Unauthorized: $msg';
        } else if (res.statusCode == 429) {
          lastError = 'Current weather 2.5 -> 429 Rate limit';
        } else if (res.statusCode == 404) {
          lastError = 'Current weather 2.5 -> 404 Not found (invalid coordinates?)';
        } else {
          lastError = 'Current weather 2.5 -> HTTP ${res.statusCode}: ${res.body}';
        }
        return null;
      }
      final Map<String, dynamic> json = jsonDecode(res.body);
      final double temp = (json['main']?['temp'] as num?)?.toDouble() ?? 0.0;
      final int humidity = (json['main']?['humidity'] as num?)?.toInt() ?? 0;
      final double wind = (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0;
      final List weather = (json['weather'] as List?) ?? const [];
      final Map<String, dynamic>? first = weather.isNotEmpty ? weather.first as Map<String, dynamic> : null;
      final String description = (first?['description'] as String?) ?? 'Unknown';
      final String icon = (first?['icon'] as String?) ?? '01d';
      lastError = null;
      return WeatherInfo(
        tempC: temp,
        description: description,
        iconCode: icon,
        windSpeed: wind,
        humidity: humidity,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[Weather] GET $uri -> exception: $e');
      lastError = 'Current weather 2.5 -> Network error: $e';
      return null;
    }
  }

  static String? _extractMessage(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map && map['message'] is String) return map['message'] as String;
    } catch (_) {}
    return null;
  }
}
