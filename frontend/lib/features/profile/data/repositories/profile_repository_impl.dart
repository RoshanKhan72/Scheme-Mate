import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  static const String _tokenKey = 'auth_token';

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  String _getToken() {
    final token = sharedPreferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('User authentication session has expired. Please log in again.');
    }
    return token;
  }

  @override
  Future<UserProfile?> getProfile() async {
    final token = _getToken();
    return await remoteDataSource.getProfile(token);
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final token = _getToken();
    return await remoteDataSource.updateProfile(token, profile);
  }
}
