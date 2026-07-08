import 'dart:io';

class ApiEndpoints {
  // If running on an Android emulator, localhost points to 10.0.2.2.
  // Otherwise, use 10.0.2.2 or localhost based on the target execution environment.
  static String get baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
      }
    } catch (_) {
      // In web or environments where Platform.isAndroid throws, default to localhost
    }
    return 'http://localhost:5000/api/v1';
  }

  // Auth paths
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get profile => '$baseUrl/auth/profile';
  static String get eligibilityProfile => '$baseUrl/profile';
}

