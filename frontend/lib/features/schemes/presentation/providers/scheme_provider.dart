import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/scheme_remote_data_source.dart';
import '../../data/repositories/scheme_repository_impl.dart';
import '../../domain/entities/scheme.dart';
import '../../domain/repositories/scheme_repository.dart';
import 'scheme_state.dart';

// Dependency injection providers for Schemes module
final schemeRemoteDataSourceProvider = Provider<SchemeRemoteDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return SchemeRemoteDataSource(client: client);
});

final schemeRepositoryProvider = Provider<SchemeRepository>((ref) {
  final remoteDataSource = ref.watch(schemeRemoteDataSourceProvider);
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return SchemeRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sharedPreferences: sharedPrefs,
  );
});

final schemesProvider = StateNotifierProvider<SchemeNotifier, SchemeState>((ref) {
  final repository = ref.watch(schemeRepositoryProvider);
  return SchemeNotifier(repository: repository);
});

class SchemeNotifier extends StateNotifier<SchemeState> {
  final SchemeRepository _repository;

  // Track currently applied filter settings for easy refreshes
  String? _lastSearch;
  String? _lastState;
  String? _lastCategory;
  String? _lastStatus;
  String? _lastBeneficiaryType;

  SchemeNotifier({required SchemeRepository repository})
      : _repository = repository,
        super(SchemeState.initial()) {
    fetchSchemes();
  }

  /// Fetch matching government schemes from server
  Future<void> fetchSchemes({
    String? search,
    String? selectedState,
    String? category,
    String? status,
    String? beneficiaryType,
  }) async {
    _lastSearch = search;
    _lastState = selectedState;
    _lastCategory = category;
    _lastStatus = status;
    _lastBeneficiaryType = beneficiaryType;

    state = SchemeState.loading();
    try {
      final schemesList = await _repository.getAllSchemes(
        search: search,
        state: selectedState,
        category: category,
        status: status,
        beneficiaryType: beneficiaryType,
      );
      state = SchemeState.loaded(schemesList);
    } catch (e) {
      state = SchemeState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Reload schemes using the last applied filters
  Future<void> refreshSchemes() async {
    await fetchSchemes(
      search: _lastSearch,
      selectedState: _lastState,
      category: _lastCategory,
      status: _lastStatus,
      beneficiaryType: _lastBeneficiaryType,
    );
  }

  /// Fetch detailed information of a single scheme
  Future<void> fetchSchemeDetails(String id) async {
    final currentSchemes = state.schemes;
    state = state.copyWith(status: SchemeStatus.detailsLoading);
    try {
      final details = await _repository.getSchemeById(id);
      state = state.copyWith(
        status: SchemeStatus.detailsLoaded,
        selectedScheme: details,
      );
      
      // Update the views count in the current list locally too
      final updatedList = currentSchemes.map((s) {
        if (s.id == id) {
          return details;
        }
        return s;
      }).toList();
      
      state = state.copyWith(schemes: updatedList, selectedScheme: details);
    } catch (e) {
      state = state.copyWith(
        status: SchemeStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Add a new government scheme (Admin guarded)
  Future<void> addScheme(Scheme scheme) async {
    final currentSchemes = state.schemes;
    state = state.copyWith(status: SchemeStatus.saving);
    try {
      final created = await _repository.createScheme(scheme);
      state = state.copyWith(
        status: SchemeStatus.saved,
        schemes: [...currentSchemes, created],
      );
      // Reload schemes
      await refreshSchemes();
    } catch (e) {
      state = state.copyWith(
        status: SchemeStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Update scheme details (Admin guarded)
  Future<void> editScheme(String id, Scheme scheme, String changeSummary) async {
    state = state.copyWith(status: SchemeStatus.saving);
    try {
      final updated = await _repository.updateScheme(id, scheme, changeSummary);
      state = state.copyWith(
        status: SchemeStatus.saved,
        selectedScheme: updated,
      );
      await refreshSchemes();
    } catch (e) {
      state = state.copyWith(
        status: SchemeStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Delete a scheme (Admin guarded)
  Future<void> removeScheme(String id) async {
    state = state.copyWith(status: SchemeStatus.saving);
    try {
      await _repository.deleteScheme(id);
      state = state.copyWith(status: SchemeStatus.saved);
      await refreshSchemes();
    } catch (e) {
      state = state.copyWith(
        status: SchemeStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
