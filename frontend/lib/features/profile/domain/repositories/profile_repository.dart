import '../entities/user_profile.dart';

abstract class ProfileRepository {
  /// Fetch the current authenticated user's eligibility profile parameter settings.
  /// Returns null if profile is not created yet.
  Future<UserProfile?> getProfile();

  /// Create or update user profile parameters on the server database.
  Future<UserProfile> saveProfile(UserProfile profile);
}
