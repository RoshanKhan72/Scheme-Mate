import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dashboard_summary.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardSummary? summary;
  final String? errorMessage;

  const DashboardState({
    required this.status,
    this.summary,
    this.errorMessage,
  });

  factory DashboardState.initial() => const DashboardState(status: DashboardStatus.initial);
  factory DashboardState.loading() => const DashboardState(status: DashboardStatus.loading);
  factory DashboardState.loaded(DashboardSummary summary) => DashboardState(status: DashboardStatus.loaded, summary: summary);
  factory DashboardState.error(String msg) => DashboardState(status: DashboardStatus.error, errorMessage: msg);

  @override
  List<Object?> get props => [status, summary, errorMessage];
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(httpClientProvider);
  return DashboardNotifier(sharedPreferences: sharedPrefs, client: client);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final SharedPreferences _sharedPrefs;
  final http.Client _client;

  static const String _tokenKey = 'auth_token';

  DashboardNotifier({required SharedPreferences sharedPreferences, required http.Client client})
      : _sharedPrefs = sharedPreferences,
        _client = client,
        super(DashboardState.initial()) {
    fetchDashboardSummary();
  }

  /// Fetch compiled dashboard metrics from server
  Future<void> fetchDashboardSummary() async {
    state = DashboardState.loading();
    try {
      final token = _sharedPrefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      final response = await _client.get(
        Uri.parse('${ApiEndpoints.baseUrl}/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final summary = DashboardSummary.fromJson(body['dashboard'] as Map<String, dynamic>);
        state = DashboardState.loaded(summary);
      } else {
        throw Exception(body['message'] ?? 'Failed to load dashboard metrics.');
      }
    } catch (e) {
      state = DashboardState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
