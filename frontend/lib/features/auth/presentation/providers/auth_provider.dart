import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

// 1. Dependency Injection Providers
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return AuthRemoteDataSource(client: client);
});

// SharedPreferences provider will be overridden in main() during startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sharedPreferences: sharedPrefs,
  );
});

// 2. Auth State Notifier Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository: repository);
});

// 3. State Notifier Implementation
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier({required AuthRepository repository})
      : _repository = repository,
        super(AuthState.initial()) {
    // Automatically check for existing user session on creation
    checkAuthStatus();
  }

  /// Verification check for existing JWT session
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error('Failed to restore authentication session.');
    }
  }

  /// Sign up a new user
  Future<void> register(String name, String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _repository.register(name, email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Authenticate an existing user
  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Sign out current user
  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await _repository.logout();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error('Failed to log out correctly.');
    }
  }
}
