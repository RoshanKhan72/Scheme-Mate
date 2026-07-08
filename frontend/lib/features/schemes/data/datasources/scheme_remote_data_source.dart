import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/scheme.dart';

class SchemeRemoteDataSource {
  final http.Client client;

  SchemeRemoteDataSource({required this.client});

  /// Get list of matching schemes
  Future<List<Scheme>> getAllSchemes({
    String? search,
    String? state,
    String? category,
    String? status,
    String? beneficiaryType,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (beneficiaryType != null && beneficiaryType.isNotEmpty) {
      queryParams['beneficiaryType'] = beneficiaryType;
    }

    final uri = Uri.parse('${ApiEndpoints.baseUrl}/schemes').replace(queryParameters: queryParams);
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      final List list = body['schemes'] as List? ?? [];
      return list.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch government schemes database.');
    }
  }

  /// Get list of matching schemes evaluated against user profile
  Future<List<Scheme>> getMatchedSchemes(String token) async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}/schemes/match'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      final List list = body['schemes'] as List? ?? [];
      return list.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(body['message'] ?? 'Failed to evaluate matching schemes.');
    }
  }

  /// Get details of a single scheme
  Future<Scheme> getSchemeById(String id) async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}/schemes/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return Scheme.fromJson(body['scheme'] as Map<String, dynamic>);
    } else {
      throw Exception(body['message'] ?? 'Failed to retrieve scheme details.');
    }
  }

  /// Create a scheme (Admin guarded)
  Future<Scheme> createScheme(String token, Scheme scheme) async {
    final response = await client.post(
      Uri.parse('${ApiEndpoints.baseUrl}/schemes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(scheme.toJson()),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return Scheme.fromJson(body['scheme'] as Map<String, dynamic>);
    } else {
      throw Exception(body['message'] ?? 'Access denied or failed to create scheme.');
    }
  }

  /// Update an existing scheme (Admin guarded)
  Future<Scheme> updateScheme(String token, String id, Scheme scheme, String changeSummary) async {
    final Map<String, dynamic> reqBody = scheme.toJson();
    reqBody['change_summary'] = changeSummary;

    final response = await client.put(
      Uri.parse('${ApiEndpoints.baseUrl}/schemes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(reqBody),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return Scheme.fromJson(body['scheme'] as Map<String, dynamic>);
    } else {
      throw Exception(body['message'] ?? 'Failed to update scheme details.');
    }
  }

  /// Delete a scheme (Admin guarded)
  Future<void> deleteScheme(String token, String id) async {
    final response = await client.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/schemes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete scheme.');
    }
  }
}
