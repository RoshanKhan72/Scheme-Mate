import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/user.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource({required this.client});

  /// Call backend register endpoint
  /// Returns a Map with {'token': String, 'user': User}
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return {
        'token': body['token'] as String,
        'user': User.fromJson(body['user'] as Map<String, dynamic>),
      };
    } else {
      throw Exception(body['message'] ?? 'Failed to register account');
    }
  }

  /// Call backend login endpoint
  /// Returns a Map with {'token': String, 'user': User}
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return {
        'token': body['token'] as String,
        'user': User.fromJson(body['user'] as Map<String, dynamic>),
      };
    } else {
      throw Exception(body['message'] ?? 'Invalid email or password');
    }
  }

  /// Call backend profile retrieval endpoint
  Future<User> getProfile(String token) async {
    final response = await client.get(
      Uri.parse(ApiEndpoints.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return User.fromJson(body['user'] as Map<String, dynamic>);
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch user profile');
    }
  }
}
