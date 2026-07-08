import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/user_profile.dart';

class ProfileRemoteDataSource {
  final http.Client client;

  ProfileRemoteDataSource({required this.client});

  /// Fetch user profile details
  Future<UserProfile?> getProfile(String token) async {
    final response = await client.get(
      Uri.parse(ApiEndpoints.eligibilityProfile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      if (body['profile'] == null) {
        return null;
      }
      return UserProfile.fromJson(body['profile'] as Map<String, dynamic>);
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch user profile parameters');
    }
  }

  /// Create or update user profile parameters
  Future<UserProfile> updateProfile(String token, UserProfile profile) async {
    final response = await client.put(
      Uri.parse(ApiEndpoints.eligibilityProfile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profile.toJson()),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return UserProfile.fromJson(body['profile'] as Map<String, dynamic>);
    } else {
      throw Exception(body['message'] ?? 'Failed to update user profile parameters');
    }
  }
}
