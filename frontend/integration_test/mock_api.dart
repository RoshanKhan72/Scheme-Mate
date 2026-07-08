import 'dart:convert';
import 'package:http/http.dart' as http;

/**
 * Mock HTTP Client to run integration tests without hitting a real backend.
 */
class MockHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final method = request.method;

    // 1. Auth endpoints
    if (path.endsWith('/api/v1/auth/login') && method == 'POST') {
      return _jsonResponse({
        'success': true,
        'message': 'Login successful.',
        'token': 'mock-jwt-token-123',
        'user': {
          'id': 'user-uuid-123',
          'name': 'Mock User',
          'email': 'mock@example.com',
          'role': 'user'
        }
      }, 200);
    }

    if (path.endsWith('/api/v1/auth/register') && method == 'POST') {
      return _jsonResponse({
        'success': true,
        'message': 'Registration successful.',
        'token': 'mock-jwt-token-123',
        'user': {
          'id': 'user-uuid-123',
          'name': 'Mock User',
          'email': 'mock@example.com',
          'role': 'user'
        }
      }, 201);
    }

    // 2. Profile endpoints
    if (path.endsWith('/api/v1/profile') && method == 'GET') {
      return _jsonResponse({
        'success': true,
        'profile': {
          'dob': '1995-10-15',
          'gender': 'Male',
          'state': 'Karnataka',
          'district': 'Bangalore',
          'village_city': 'Bangalore City',
          'occupation': 'Student',
          'education': 'Undergraduate',
          'annual_income': 350000.00,
          'marital_status': 'Single',
          'category': 'General',
          'minority_status': false,
          'disability_status': false,
          'is_student': true,
          'is_farmer': false,
          'is_business_owner': false,
          'bpl_apl_status': 'APL',
          'documents': {},
          'extra_eligibility': {}
        }
      }, 200);
    }

    if (path.endsWith('/api/v1/profile') && method == 'PUT') {
      return _jsonResponse({
        'success': true,
        'message': 'Profile updated successfully.',
        'profile': {
          'dob': '1995-10-15',
          'gender': 'Male',
          'state': 'Karnataka',
          'district': 'Bangalore',
          'village_city': 'Bangalore City',
          'occupation': 'Student',
          'education': 'Undergraduate',
          'annual_income': 350000.00,
          'marital_status': 'Single',
          'category': 'General',
          'minority_status': false,
          'disability_status': false,
          'is_student': true,
          'is_farmer': false,
          'is_business_owner': false,
          'bpl_apl_status': 'APL'
        }
      }, 200);
    }

    // 3. Schemes endpoints
    if (path.endsWith('/api/v1/schemes') && method == 'GET') {
      return _jsonResponse({
        'success': true,
        'count': 1,
        'schemes': [
          {
            'id': 'scheme-uuid-111',
            'name': 'Central Post-Matric Scholarship',
            'description': 'Scholarship for students.',
            'state': 'All India',
            'category': 'Education',
            'eligibility_rules': {},
            'required_documents': ['Aadhaar'],
            'benefits': 'Tuition coverage',
            'application_mode': 'Online',
            'status': 'Open',
            'source_type': 'Central',
            'official_department': 'Ministry of Education',
            'views_count': 15,
            'saves_count': 3,
            'beneficiary_types': ['Student'],
            'tags': ['scholarship', 'education']
          }
        ]
      }, 200);
    }

    // 4. Saved schemes endpoints
    if (path.endsWith('/api/v1/saved') && method == 'GET') {
      return _jsonResponse({
        'success': true,
        'count': 0,
        'schemes': []
      }, 200);
    }

    // 5. Notifications preferences
    if (path.endsWith('/api/v1/notifications/preferences') && method == 'GET') {
      return _jsonResponse({
        'success': true,
        'preferences': {
          'notify_new_matches': true,
          'notify_scheme_updates': true,
          'notify_closing_soon': true,
          'notify_profile_reminders': true,
          'notify_system': true
        }
      }, 200);
    }

    if (path.endsWith('/api/v1/notifications') && method == 'GET') {
      return _jsonResponse({
        'success': true,
        'count': 0,
        'notifications': []
      }, 200);
    }

    // Default successful JSON response helper
    return _jsonResponse({'success': true}, 200);
  }

  http.StreamedResponse _jsonResponse(Map<String, dynamic> data, int statusCode) {
    final bodyString = json.encode(data);
    final bodyBytes = utf8.encode(bodyString);
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      statusCode,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'content-length': bodyBytes.length.toString(),
      },
    );
  }
}
