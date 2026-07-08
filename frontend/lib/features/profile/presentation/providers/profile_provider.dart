import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

// Dependency injection providers for Profile module
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return ProfileRemoteDataSource(client: client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sharedPreferences: sharedPrefs,
  );
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository: repository);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier({required ProfileRepository repository})
      : _repository = repository,
        super(ProfileState.initial()) {
    // Automatically load profile once the notifier is instantiated
    fetchProfile();
  }

  /// Get current user profile details
  Future<void> fetchProfile() async {
    state = ProfileState.loading();
    try {
      final profile = await _repository.getProfile();
      if (profile != null) {
        state = ProfileState.loaded(profile);
      } else {
        state = const ProfileState(status: ProfileStatus.initial, profile: null);
      }
    } catch (e) {
      state = ProfileState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Create or update user profile parameters
  Future<void> saveProfile(UserProfile profile) async {
    final currentProfile = state.profile;
    state = ProfileState.saving(currentProfile);
    try {
      final updatedProfile = await _repository.saveProfile(profile);
      state = ProfileState.saved(updatedProfile);
      // Automatically reset status to loaded with updated details
      state = ProfileState.loaded(updatedProfile);
    } catch (e) {
      state = ProfileState.error(e.toString().replaceAll('Exception: ', ''), profile: currentProfile);
    }
  }
}
