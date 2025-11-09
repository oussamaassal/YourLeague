class ApiConfig {
  // Change this based on where you're testing
  static const bool useEmulator = false; // Set to false when testing on physical device
  static const bool useNgrok = false; // Set to true when testing remotely
  
  // Your computer's local IP address (find it using 'ipconfig' on Windows)
  static const String localIP = '10.219.75.111'; // Your WiFi IP address
  
  // Your ngrok URL (get this from ngrok terminal after running 'ngrok http 3000')
  static const String ngrokUrl = 'https://YOUR-NGROK-URL.ngrok.io'; // ⚠️ UPDATE THIS
  
  static String get baseUrl {
    if (useNgrok) {
      return ngrokUrl; // Remote testing via ngrok
    } else if (useEmulator) {
      return 'http://10.0.2.2:3000'; // Android emulator
    } else {
      return 'http://$localIP:3000'; // Physical device on same WiFi
    }
  }
}
