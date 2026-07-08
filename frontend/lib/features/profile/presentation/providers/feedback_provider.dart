import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final feedbackProvider = Provider((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(httpClientProvider);
  return FeedbackNotifier(sharedPreferences: sharedPrefs, client: client);
});

class FeedbackNotifier {
  final SharedPreferences _sharedPrefs;
  final http.Client _client;

  static const String _tokenKey = 'auth_token';

  FeedbackNotifier({required SharedPreferences sharedPreferences, required http.Client client})
      : _sharedPrefs = sharedPreferences,
        _client = client;

  String _getToken() {
    final token = _sharedPrefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  /// Submit user feedback or bug report to the backend database
  Future<bool> submitFeedback({
    required String screen,
    required String type,
    required String details,
    String? targetId,
  }) async {
    try {
      final token = _getToken();
      final response = await _client.post(
        Uri.parse('${ApiEndpoints.baseUrl}/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'screen': screen,
          'type': type,
          'details': details,
          'targetId': targetId,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return response.statusCode == 201 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
