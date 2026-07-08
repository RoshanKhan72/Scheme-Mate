import '../entities/user.dart';

abstract class AuthRepository {
  /// Authenticates a user with email and password, returning the User object
  Future<User> login(String email, String password);

  /// Registers a new user account, returning the User object
  Future<User> register(String name, String email, String password);

  /// Logs out the user, clearing local session/token caches
  Future<void> logout();

  /// Gets the currently logged-in user profile, if session token exists
  Future<User?> getCurrentUser();
}
