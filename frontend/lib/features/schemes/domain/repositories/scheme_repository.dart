import '../entities/scheme.dart';

abstract class SchemeRepository {
  /// Fetch list of government schemes with optional queries and filters
  Future<List<Scheme>> getAllSchemes({
    String? search,
    String? state,
    String? category,
    String? status,
    String? beneficiaryType,
  });

  /// Fetch list of matched schemes evaluated against the logged-in user profile
  Future<List<Scheme>> getMatchedSchemes();

  /// Fetch single scheme details by UUID. Automatically increments views
  Future<Scheme> getSchemeById(String id);

  /// Add a new government scheme to the database (Admin only)
  Future<Scheme> createScheme(Scheme scheme);

  /// Edit details of an existing scheme and record updates (Admin only)
  Future<Scheme> updateScheme(String id, Scheme scheme, String changeSummary);

  /// Delete a scheme permanently (Admin only)
  Future<void> deleteScheme(String id);
}
