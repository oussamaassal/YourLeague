import 'dart:io' show Platform; // For runtime platform checks

/// Centralized API configuration with multi-developer & multi-runtime support.
///
/// Priority order for resolving the base URL:
/// 1. Compile-time override: --dart-define=API_BASE_URL=https://example.com
/// 2. ngrok URL (if set & not the placeholder)
/// 3. Android emulator (10.0.2.2) / iOS simulator (localhost)
/// 4. Local LAN IP (for physical devices on same WiFi)
class ApiConfig {
  // Legacy feature toggles (kept for backward compatibility)
  static const bool useEmulator = false; // Force emulator host mapping
  static const bool useNgrok = false;    // Force ngrok even if placeholder

  // Compile-time override (use: flutter run --dart-define=API_BASE_URL=https://xyz)
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Your computer's local IP address (update for each developer).
  /// Each developer should change only this line OR use --dart-define.
  static const String localIP = '192.168.1.8';

  /// ngrok tunnel URL. Replace placeholder after running: ngrok http 3000
  static const String ngrokUrl = 'https://YOUR-NGROK-URL.ngrok.io'; // ⚠️ UPDATE THIS WHEN USING NGROK

  static const int _port = 3000; // Single source of truth for backend port

  /// Resolved base URL (lazy evaluation via getter)
  static String get baseUrl {
    // 1. Dart define override
    if (_envBaseUrl.isNotEmpty) {
      return _withProtocol(_envBaseUrl.trim());
    }

    // 2. Explicit toggles
    if (useNgrok && _isValidNgrok(ngrokUrl)) {
      return _stripTrailingSlash(ngrokUrl);
    }

    // 3. Automatic environment detection
    if (_isValidNgrok(ngrokUrl)) {
      // Allow seamless switch if developer already replaced placeholder
      return _stripTrailingSlash(ngrokUrl);
    }

    // 4. Emulator detection / forced emulator
    if (useEmulator || _looksLikeEmulator()) {
      // Android emulator uses 10.0.2.2 to reach host machine
      if (_isAndroid) return 'http://10.0.2.2:$_port';
      // iOS simulator can use localhost
      if (_isIOS) return 'http://localhost:$_port';
    }

    // 5. Physical device on same LAN
    return 'http://$localIP:$_port';
  }

  /// Helper to detect Android emulator heuristically (very lightweight).
  static bool _looksLikeEmulator() {
    // We cannot access Build.* here without platform channels; rely on Platform.
    // If running on Android & not a physical device (developer tends to set useEmulator), return false by default.
    // Provide a manual toggle via useEmulator.
    return false; // Keep simple; developer can set useEmulator=true
  }

  static bool get _isAndroid => Platform.isAndroid;
  static bool get _isIOS => Platform.isIOS;

  static bool _isValidNgrok(String url) {
    return url.startsWith('https://') && !url.contains('YOUR-NGROK-URL');
  }

  static String _withProtocol(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return _stripTrailingSlash(url);
    // Default to http for local overrides unless explicitly https
    return 'http://${_stripTrailingSlash(url)}';
  }

  static String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
