import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  static const String _tokenKey = 'auth_token';

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<User> register(String name, String email, String password) async {
    try {
      final data = await remoteDataSource.register(name, email, password);
      final String token = data['token'] as String;
      final User user = data['user'] as User;

      // Persist the JWT token locally
      await sharedPreferences.setString(_tokenKey, token);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final data = await remoteDataSource.login(email, password);
      final String token = data['token'] as String;
      final User user = data['user'] as User;

      // Persist the JWT token locally
      await sharedPreferences.setString(_tokenKey, token);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(_tokenKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = sharedPreferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      // Validate token by fetching the profile from the server
      final user = await remoteDataSource.getProfile(token);
      return user;
    } catch (_) {
      // Token is expired or server is unreachable. Clear token cache.
      await sharedPreferences.remove(_tokenKey);
      return null;
    }
  }
}
