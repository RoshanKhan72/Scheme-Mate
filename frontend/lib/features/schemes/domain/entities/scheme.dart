import 'package:equatable/equatable.dart';
import 'eligibility_result.dart';

class Scheme extends Equatable {
  final String id;
  final String name;
  final String description;
  final String state;
  final String category;
  final Map<String, dynamic> eligibilityRules;
  final List<String> requiredDocuments;
  final String benefits;
  final String? officialWebsite;
  final String? applicationLink;
  final String? pdfNotificationLink;
  final String applicationMode;
  final String status;
  final String sourceType;
  final String officialDepartment;
  final DateTime? lastVerifiedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final int viewsCount;
  final int savesCount;
  final List<String> beneficiaryTypes;
  final List<String> tags;
  final int versionNumber;
  final String? lastUpdatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EligibilityResult? eligibilityResult;
  
  // Bookmark details properties
  final String? privateNote;
  final DateTime? savedAt;
  final DateTime? lastViewedAt;

  const Scheme({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    required this.category,
    required this.eligibilityRules,
    required this.requiredDocuments,
    required this.benefits,
    this.officialWebsite,
    this.applicationLink,
    this.pdfNotificationLink,
    required this.applicationMode,
    required this.status,
    required this.sourceType,
    required this.officialDepartment,
    this.lastVerifiedDate,
    this.startDate,
    this.endDate,
    required this.viewsCount,
    required this.savesCount,
    required this.beneficiaryTypes,
    required this.tags,
    required this.versionNumber,
    this.lastUpdatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.eligibilityResult,
    this.privateNote,
    this.savedAt,
    this.lastViewedAt,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      state: json['state'] as String,
      category: json['category'] as String,
      eligibilityRules: json['eligibility_rules'] as Map<String, dynamic>? ?? {},
      requiredDocuments: List<String>.from(json['required_documents'] as List? ?? []),
      benefits: json['benefits'] as String,
      officialWebsite: json['official_website'] as String?,
      applicationLink: json['application_link'] as String?,
      pdfNotificationLink: json['pdf_notification_link'] as String?,
      applicationMode: json['application_mode'] as String? ?? 'Online',
      status: json['status'] as String? ?? 'Open',
      sourceType: json['source_type'] as String,
      officialDepartment: json['official_department'] as String,
      lastVerifiedDate: json['last_verified_date'] != null
          ? DateTime.parse(json['last_verified_date'] as String)
          : null,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      viewsCount: json['views_count'] as int? ?? 0,
      savesCount: json['saves_count'] as int? ?? 0,
      beneficiaryTypes: List<String>.from(json['beneficiary_types'] as List? ?? []),
      tags: List<String>.from(json['tags'] as List? ?? []),
      versionNumber: json['version_number'] as int? ?? 1,
      lastUpdatedBy: json['last_updated_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      eligibilityResult: json['eligibilityResult'] != null
          ? EligibilityResult.fromJson(json['eligibilityResult'] as Map<String, dynamic>)
          : null,
      privateNote: json['private_note'] as String?,
      savedAt: json['saved_at'] != null ? DateTime.parse(json['saved_at'] as String) : null,
      lastViewedAt: json['last_viewed_at'] != null ? DateTime.parse(json['last_viewed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'id': id,
      'name': name,
      'description': description,
      'state': state,
      'category': category,
      'eligibility_rules': eligibilityRules,
      'required_documents': requiredDocuments,
      'benefits': benefits,
      'official_website': officialWebsite,
      'application_link': applicationLink,
      'pdf_notification_link': pdfNotificationLink,
      'application_mode': applicationMode,
      'status': status,
      'source_type': sourceType,
      'official_department': officialDepartment,
      'last_verified_date': lastVerifiedDate?.toIso8601String().substring(0, 10),
      'start_date': startDate?.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'views_count': viewsCount,
      'saves_count': savesCount,
      'beneficiary_types': beneficiaryTypes,
      'tags': tags,
      'version_number': versionNumber,
      'last_updated_by': lastUpdatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (eligibilityResult != null) {
      data['eligibilityResult'] = eligibilityResult!.toJson();
    }
    if (privateNote != null) {
      data['private_note'] = privateNote;
    }
    if (savedAt != null) {
      data['saved_at'] = savedAt!.toIso8601String();
    }
    if (lastViewedAt != null) {
      data['last_viewed_at'] = lastViewedAt!.toIso8601String();
    }

    return data;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        state,
        category,
        eligibilityRules,
        requiredDocuments,
        benefits,
        officialWebsite,
        applicationLink,
        pdfNotificationLink,
        applicationMode,
        status,
        sourceType,
        officialDepartment,
        lastVerifiedDate,
        startDate,
        endDate,
        viewsCount,
        savesCount,
        beneficiaryTypes,
        tags,
        versionNumber,
        lastUpdatedBy,
        createdAt,
        updatedAt,
        eligibilityResult,
        privateNote,
        savedAt,
        lastViewedAt,
      ];
}
