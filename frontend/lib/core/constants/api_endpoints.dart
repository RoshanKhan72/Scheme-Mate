import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  // Supports configurable build-time define for production hosting
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
      }
    } catch (_) {
      // Fallback if Platform checks are unsupported
    }
    return 'http://localhost:5000/api/v1';
  }

  // Auth paths
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get profile => '$baseUrl/auth/profile';
  static String get eligibilityProfile => '$baseUrl/profile';
}

