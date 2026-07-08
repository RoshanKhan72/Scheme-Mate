import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String userId;
  final DateTime dob;
  final String gender;
  final String state;
  final String district;
  final String? taluk;
  final String villageCity;
  final String occupation;
  final String education;
  final double annualIncome;
  final String maritalStatus;
  final String category;
  final bool minorityStatus;
  final bool disabilityStatus;
  final bool isStudent;
  final bool isFarmer;
  final bool isBusinessOwner;
  final String bplAplStatus;
  final Map<String, dynamic> documents;
  final Map<String, dynamic> extraEligibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.dob,
    required this.gender,
    required this.state,
    required this.district,
    this.taluk,
    required this.villageCity,
    required this.occupation,
    required this.education,
    required this.annualIncome,
    required this.maritalStatus,
    required this.category,
    required this.minorityStatus,
    required this.disabilityStatus,
    required this.isStudent,
    required this.isFarmer,
    required this.isBusinessOwner,
    required this.bplAplStatus,
    required this.documents,
    required this.extraEligibility,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Automatically computes the user's age based on date of birth
  int get age {
    final today = DateTime.now();
    int computedAge = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      computedAge--;
    }
    return computedAge;
  }

  /// Calculates profile completion percentage (0 - 100%) and tracks missing fields
  Map<String, dynamic> get completionMetrics {
    int score = 0;
    final List<String> missing = [];

    // 1. Age/DOB (Should be valid)
    if (dob.isBefore(DateTime.now().subtract(const Duration(days: 365)))) {
      score += 10;
    } else {
      missing.add('Date of Birth');
    }

    // 2. Gender
    if (gender.isNotEmpty && gender != 'Select') {
      score += 10;
    } else {
      missing.add('Gender');
    }

    // 3. State
    if (state.isNotEmpty && state != 'Select State') {
      score += 10;
    } else {
      missing.add('State');
    }

    // 4. District
    if (district.isNotEmpty && district != 'Select District') {
      score += 10;
    } else {
      missing.add('District');
    }

    // 5. Village/City
    if (villageCity.trim().isNotEmpty) {
      score += 10;
    } else {
      missing.add('Village/City');
    }

    // 6. Occupation
    if (occupation.isNotEmpty && occupation != 'Select Occupation') {
      score += 10;
    } else {
      missing.add('Occupation');
    }

    // 7. Education
    if (education.isNotEmpty && education != 'Select Education') {
      score += 10;
    } else {
      missing.add('Education');
    }

    // 8. Marital Status
    if (maritalStatus.isNotEmpty && maritalStatus != 'Select Marital Status') {
      score += 10;
    } else {
      missing.add('Marital Status');
    }

    // 9. Category
    if (category.isNotEmpty && category != 'Select Category') {
      score += 10;
    } else {
      missing.add('Category');
    }

    // 10. Key documents checklist (e.g., Aadhaar verified)
    final hasAadhaar = documents['Aadhaar']?['exists'] == true;
    final hasIncomeCert = documents['Income Certificate']?['exists'] == true;
    if (hasAadhaar) {
      score += 10;
    } else {
      missing.add('Aadhaar Document status');
    }

    // Optional advisory notice for income certificate
    if (!hasIncomeCert) {
      missing.add('Income Certificate status');
    }

    return {
      'percentage': score,
      'missing': missing,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dob: DateTime.parse(json['dob'] as String),
      gender: json['gender'] as String,
      state: json['state'] as String,
      district: json['district'] as String,
      taluk: json['taluk'] as String?,
      villageCity: json['village_city'] as String,
      occupation: json['occupation'] as String,
      education: json['education'] as String,
      annualIncome: double.parse(json['annual_income'].toString()),
      maritalStatus: json['marital_status'] as String,
      category: json['category'] as String,
      minorityStatus: json['minority_status'] as bool? ?? false,
      disabilityStatus: json['disability_status'] as bool? ?? false,
      isStudent: json['is_student'] as bool? ?? false,
      isFarmer: json['is_farmer'] as bool? ?? false,
      isBusinessOwner: json['is_business_owner'] as bool? ?? false,
      bplAplStatus: json['bpl_apl_status'] as String? ?? 'None',
      documents: json['documents'] as Map<String, dynamic>? ?? {},
      extraEligibility: json['extra_eligibility'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'dob': dob.toIso8601String().substring(0, 10), // Date part only
      'gender': gender,
      'state': state,
      'district': district,
      'taluk': taluk,
      'village_city': villageCity,
      'occupation': occupation,
      'education': education,
      'annual_income': annualIncome,
      'marital_status': maritalStatus,
      'category': category,
      'minority_status': minorityStatus,
      'disability_status': disabilityStatus,
      'is_student': isStudent,
      'is_farmer': isFarmer,
      'is_business_owner': isBusinessOwner,
      'bpl_apl_status': bplAplStatus,
      'documents': documents,
      'extra_eligibility': extraEligibility,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        dob,
        gender,
        state,
        district,
        taluk,
        villageCity,
        occupation,
        education,
        annualIncome,
        maritalStatus,
        category,
        minorityStatus,
        disabilityStatus,
        isStudent,
        isFarmer,
        isBusinessOwner,
        bplAplStatus,
        documents,
        extraEligibility,
        createdAt,
        updatedAt,
      ];
}
