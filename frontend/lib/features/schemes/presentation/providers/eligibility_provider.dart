import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/scheme_repository.dart';
import 'scheme_provider.dart';
import 'scheme_state.dart';

final eligibilityProvider = StateNotifierProvider<EligibilityNotifier, SchemeState>((ref) {
  final repo = ref.watch(schemeRepositoryProvider);
  return EligibilityNotifier(repository: repo);
});

class EligibilityNotifier extends StateNotifier<SchemeState> {
  final SchemeRepository _repository;

  EligibilityNotifier({required SchemeRepository repository})
      : _repository = repository,
        super(SchemeState.initial()) {
    fetchMatchingSchemes();
  }

  /// Evaluate matches against active profile demographics
  Future<void> fetchMatchingSchemes() async {
    state = SchemeState.loading();
    try {
      final matchedList = await _repository.getMatchedSchemes();
      state = SchemeState.loaded(matchedList);
    } catch (e) {
      state = state.copyWith(
        status: SchemeStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
