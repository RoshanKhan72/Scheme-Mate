import 'package:equatable/equatable.dart';

class RuleCheck extends Equatable {
  final String ruleId;
  final bool? passed;
  final String message;

  const RuleCheck({
    required this.ruleId,
    this.passed,
    required this.message,
  });

  factory RuleCheck.fromJson(Map<String, dynamic> json) {
    return RuleCheck(
      ruleId: json['ruleId'] as String,
      passed: json['passed'] as bool?,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'passed': passed,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [ruleId, passed, message];
}

class EligibilityResult extends Equatable {
  final String status;
  final int matchScore;
  final int confidence;
  final List<RuleCheck> checks;
  final List<String> missingFields;

  const EligibilityResult({
    required this.status,
    required this.matchScore,
    required this.confidence,
    required this.checks,
    required this.missingFields,
  });

  factory EligibilityResult.fromJson(Map<String, dynamic> json) {
    final list = json['checks'] as List? ?? [];
    final checksList = list.map((item) => RuleCheck.fromJson(item as Map<String, dynamic>)).toList();
    
    return EligibilityResult(
      status: json['status'] as String,
      matchScore: json['matchScore'] as int? ?? 0,
      confidence: json['confidence'] as int? ?? 100,
      checks: checksList,
      missingFields: List<String>.from(json['missingFields'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'matchScore': matchScore,
      'confidence': confidence,
      'checks': checks.map((c) => c.toJson()).toList(),
      'missingFields': missingFields,
    };
  }

  @override
  List<Object?> get props => [status, matchScore, confidence, checks, missingFields];
}
