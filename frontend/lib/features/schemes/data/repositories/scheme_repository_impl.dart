import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/scheme.dart';
import '../../domain/repositories/scheme_repository.dart';
import '../datasources/scheme_remote_data_source.dart';

class SchemeRepositoryImpl implements SchemeRepository {
  final SchemeRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  static const String _tokenKey = 'auth_token';

  SchemeRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  String _getToken() {
    final token = sharedPreferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  @override
  Future<List<Scheme>> getAllSchemes({
    String? search,
    String? state,
    String? category,
    String? status,
    String? beneficiaryType,
  }) async {
    return await remoteDataSource.getAllSchemes(
      search: search,
      state: state,
      category: category,
      status: status,
      beneficiaryType: beneficiaryType,
    );
  }

  @override
  Future<List<Scheme>> getMatchedSchemes() async {
    final token = _getToken();
    return await remoteDataSource.getMatchedSchemes(token);
  }

  @override
  Future<Scheme> getSchemeById(String id) async {
    return await remoteDataSource.getSchemeById(id);
  }

  @override
  Future<Scheme> createScheme(Scheme scheme) async {
    final token = _getToken();
    return await remoteDataSource.createScheme(token, scheme);
  }

  @override
  Future<Scheme> updateScheme(String id, Scheme scheme, String changeSummary) async {
    final token = _getToken();
    return await remoteDataSource.updateScheme(token, id, scheme, changeSummary);
  }

  @override
  Future<void> deleteScheme(String id) async {
    final token = _getToken();
    await remoteDataSource.deleteScheme(token, id);
  }
}
