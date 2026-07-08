import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String targetType;
  final String? targetId;
  final bool isRead;
  final DateTime scheduledAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.targetType,
    this.targetId,
    required this.isRead,
    required this.scheduledAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      priority: json['priority'] as String? ?? 'Medium',
      targetType: json['target_type'] as String? ?? 'none',
      targetId: json['target_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'target_type': targetType,
      'target_id': targetId,
      'is_read': isRead,
      'scheduled_at': scheduledAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        type,
        priority,
        targetType,
        targetId,
        isRead,
        scheduledAt,
        expiresAt,
        createdAt,
      ];
}
