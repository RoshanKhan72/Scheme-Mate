import 'package:equatable/equatable.dart';

import '../../../../features/schemes/domain/entities/scheme.dart';

class DashboardSummary extends Equatable {
  final int profileCompletion;
  final DateTime? lastUpdated;
  final int eligibleCount;
  final int partiallyEligibleCount;
  final int missingDocumentsCount;
  final List<String> missingDocuments;
  final List<Scheme> recommended;
  final List<Scheme> newSchemes;
  final List<Scheme> trending;
  final List<Scheme> closingSoon;

  const DashboardSummary({
    required this.profileCompletion,
    this.lastUpdated,
    required this.eligibleCount,
    required this.partiallyEligibleCount,
    required this.missingDocumentsCount,
    required this.missingDocuments,
    required this.recommended,
    required this.newSchemes,
    required this.trending,
    required this.closingSoon,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final feeds = json['feeds'] as Map<String, dynamic>? ?? {};
    
    final recList = feeds['recommended'] as List? ?? [];
    final newList = feeds['newSchemes'] as List? ?? [];
    final trendList = feeds['trending'] as List? ?? [];
    final closeList = feeds['closingSoon'] as List? ?? [];

    return DashboardSummary(
      profileCompletion: json['profileCompletion'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
      eligibleCount: json['eligibleCount'] as int? ?? 0,
      partiallyEligibleCount: json['partiallyEligibleCount'] as int? ?? 0,
      missingDocumentsCount: json['missingDocumentsCount'] as int? ?? 0,
      missingDocuments: List<String>.from(json['missingDocuments'] as List? ?? []),
      recommended: recList.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList(),
      newSchemes: newList.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList(),
      trending: trendList.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList(),
      closingSoon: closeList.map((item) => Scheme.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileCompletion': profileCompletion,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'eligibleCount': eligibleCount,
      'partiallyEligibleCount': partiallyEligibleCount,
      'missingDocumentsCount': missingDocumentsCount,
      'missingDocuments': missingDocuments,
      'feeds': {
        'recommended': recommended.map((s) => s.toJson()).toList(),
        'newSchemes': newSchemes.map((s) => s.toJson()).toList(),
        'trending': trending.map((s) => s.toJson()).toList(),
        'closingSoon': closingSoon.map((s) => s.toJson()).toList(),
      },
    };
  }

  @override
  List<Object?> get props => [
        profileCompletion,
        lastUpdated,
        eligibleCount,
        partiallyEligibleCount,
        missingDocumentsCount,
        missingDocuments,
        recommended,
        newSchemes,
        trending,
        closingSoon,
      ];
}
