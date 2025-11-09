class ApiConfig {
  // Change this based on where you're testing
  static const bool useEmulator = true; // Set to false when testing on physical device
  
  // Your computer's local IP address (find it using 'ipconfig' on Windows)
  // Example: '192.168.1.100' - replace with YOUR actual IP
  static const String localIP = '192.168.1.100'; // ⚠️ CHANGE THIS TO YOUR IP
  
  static String get baseUrl {
    if (useEmulator) {
      return 'http://10.0.2.2:3000'; // Android emulator
    } else {
      return 'http://$localIP:3000'; // Physical device
    }
  }
}
