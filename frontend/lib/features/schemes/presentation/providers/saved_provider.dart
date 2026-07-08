import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/scheme.dart';

enum SavedStatus { initial, loading, loaded, error }

class SavedSchemesState extends Equatable {
  final SavedStatus status;
  final List<Scheme> schemes;
  final bool isOffline;
  final DateTime? cachedAt;
  final String? errorMessage;

  const SavedSchemesState({
    required this.status,
    required this.schemes,
    required this.isOffline,
    this.cachedAt,
    this.errorMessage,
  });

  factory SavedSchemesState.initial() => const SavedSchemesState(
        status: SavedStatus.initial,
        schemes: [],
        isOffline: false,
      );

  factory SavedSchemesState.loading(List<Scheme> current) => SavedSchemesState(
        status: SavedStatus.loading,
        schemes: current,
        isOffline: false,
      );

  SavedSchemesState copyWith({
    SavedStatus? status,
    List<Scheme>? schemes,
    bool? isOffline,
    DateTime? cachedAt,
    String? errorMessage,
  }) {
    return SavedSchemesState(
      status: status ?? this.status,
      schemes: schemes ?? this.schemes,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt ?? this.cachedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, schemes, isOffline, cachedAt, errorMessage];
}

final savedSchemesProvider = StateNotifierProvider<SavedNotifier, SavedSchemesState>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(httpClientProvider);
  return SavedNotifier(sharedPreferences: sharedPrefs, client: client);
});

class SavedNotifier extends StateNotifier<SavedSchemesState> {
  final SharedPreferences _sharedPrefs;
  final http.Client _client;

  static const String _tokenKey = 'auth_token';
  static const String _cacheKey = 'cached_saved_schemes';
  static const String _cacheTimeKey = 'cached_saved_at';

  SavedNotifier({required SharedPreferences sharedPreferences, required http.Client client})
      : _sharedPrefs = sharedPreferences,
        _client = client,
        super(SavedSchemesState.initial()) {
    fetchSavedSchemes();
  }

  String _getToken() {
    final token = _sharedPrefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  /// Check if a scheme is currently bookmarked locally
  bool isSaved(String schemeId) {
    return state.schemes.any((s) => s.id == schemeId);
  }

  /// Get note contents for a saved scheme
  String getNote(String schemeId) {
    try {
      final scheme = state.schemes.firstWhere((s) => s.id == schemeId);
      return scheme.privateNote ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Retrieve saved schemes. Cascades to local SharedPreferences cache on offline errors
  Future<void> fetchSavedSchemes() async {
    state = SavedSchemesState.loading(state.schemes);
    try {
      final token = _getToken();
      final response = await _client.get(
        Uri.parse('${ApiEndpoints.baseUrl}/saved'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final List list = body['schemes'] as List? ?? [];
        final schemesList = list.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList();
        
        // Save to SharedPreferences local sync cache
        final jsonStr = jsonEncode(schemesList.map((s) => s.toJson()).toList());
        await _sharedPrefs.setString(_cacheKey, jsonStr);
        await _sharedPrefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());

        state = SavedSchemesState(
          status: SavedStatus.loaded,
          schemes: schemesList,
          isOffline: false,
        );
      } else {
        throw Exception(body['message'] ?? 'Failed to load saved schemes.');
      }
    } catch (e) {
      // Offline fallback sequence
      final cachedStr = _sharedPrefs.getString(_cacheKey);
      final cachedTimeStr = _sharedPrefs.getString(_cacheTimeKey);
      
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List decoded = jsonDecode(cachedStr);
        final cachedSchemes = decoded.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList();
        final cachedAt = cachedTimeStr != null ? DateTime.parse(cachedTimeStr) : DateTime.now();

        state = SavedSchemesState(
          status: SavedStatus.loaded,
          schemes: cachedSchemes,
          isOffline: true,
          cachedAt: cachedAt,
        );
      } else {
        state = state.copyWith(
          status: SavedStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  /// Toggle bookmark status: Saves or removes bookmark
  Future<void> toggleBookmark(Scheme scheme, {String note = ''}) async {
    final currentlySaved = isSaved(scheme.id);
    if (currentlySaved) {
      await removeBookmark(scheme.id);
    } else {
      await addBookmark(scheme, note: note);
    }
  }

  /// Add bookmark with optional note
  Future<void> addBookmark(Scheme scheme, {String note = ''}) async {
    final token = _getToken();
    
    // Optimistic local state update
    final tempScheme = Scheme(
      id: scheme.id,
      name: scheme.name,
      description: scheme.description,
      state: scheme.state,
      category: scheme.category,
      eligibilityRules: scheme.eligibilityRules,
      requiredDocuments: scheme.requiredDocuments,
      benefits: scheme.benefits,
      officialWebsite: scheme.officialWebsite,
      applicationLink: scheme.applicationLink,
      pdfNotificationLink: scheme.pdfNotificationLink,
      applicationMode: scheme.applicationMode,
      status: scheme.status,
      sourceType: scheme.sourceType,
      officialDepartment: scheme.officialDepartment,
      lastVerifiedDate: scheme.lastVerifiedDate,
      startDate: scheme.startDate,
      endDate: scheme.endDate,
      viewsCount: scheme.viewsCount,
      savesCount: scheme.savesCount + 1,
      beneficiaryTypes: scheme.beneficiaryTypes,
      tags: scheme.tags,
      versionNumber: scheme.versionNumber,
      createdAt: scheme.createdAt,
      updatedAt: scheme.updatedAt,
      eligibilityResult: scheme.eligibilityResult,
      privateNote: note,
      savedAt: DateTime.now(),
      lastViewedAt: DateTime.now(),
    );

    state = state.copyWith(schemes: [...state.schemes, tempScheme]);

    try {
      final response = await _client.post(
        Uri.parse('${ApiEndpoints.baseUrl}/saved/${scheme.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'note': note}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to bookmark.');
      }
      await fetchSavedSchemes();
    } catch (e) {
      // Revert optimistic change
      await fetchSavedSchemes();
      throw Exception('Network error bookmarking scheme. Try again.');
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark(String schemeId) async {
    final token = _getToken();

    // Optimistic local update
    state = state.copyWith(schemes: state.schemes.where((s) => s.id != schemeId).toList());

    try {
      final response = await _client.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/saved/$schemeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to unsave.');
      }
      await fetchSavedSchemes();
    } catch (e) {
      await fetchSavedSchemes();
      throw Exception('Network error removing bookmark.');
    }
  }

  /// Update private notes
  Future<void> editBookmarkNote(String schemeId, String note) async {
    final token = _getToken();
    try {
      final response = await _client.put(
        Uri.parse('${ApiEndpoints.baseUrl}/saved/$schemeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'note': note}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to update note.');
      }
      await fetchSavedSchemes();
    } catch (e) {
      throw Exception('Failed to update private note: $e');
    }
  }
}
