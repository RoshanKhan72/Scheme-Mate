import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_entity.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationEntity> notifications;
  final bool isOffline;
  final DateTime? cachedAt;
  final String? errorMessage;
  
  // Preferences settings
  final NotificationStatus preferencesStatus;
  final Map<String, bool> preferences;

  const NotificationState({
    required this.status,
    required this.notifications,
    required this.isOffline,
    this.cachedAt,
    this.errorMessage,
    required this.preferencesStatus,
    required this.preferences,
  });

  factory NotificationState.initial() => const NotificationState(
        status: NotificationStatus.initial,
        notifications: [],
        isOffline: false,
        preferencesStatus: NotificationStatus.initial,
        preferences: {},
      );

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationEntity>? notifications,
    bool? isOffline,
    DateTime? cachedAt,
    String? errorMessage,
    NotificationStatus? preferencesStatus,
    Map<String, bool>? preferences,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt ?? this.cachedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      preferencesStatus: preferencesStatus ?? this.preferencesStatus,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        isOffline,
        cachedAt,
        errorMessage,
        preferencesStatus,
        preferences,
      ];
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(httpClientProvider);
  return NotificationNotifier(sharedPreferences: sharedPrefs, client: client);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final SharedPreferences _sharedPrefs;
  final http.Client _client;

  static const String _tokenKey = 'auth_token';
  static const String _cacheKey = 'cached_notifications';
  static const String _cacheTimeKey = 'cached_notifications_at';
  static const String _prefCacheKey = 'cached_notification_preferences';

  NotificationNotifier({required SharedPreferences sharedPreferences, required http.Client client})
      : _sharedPrefs = sharedPreferences,
        _client = client,
        super(NotificationState.initial()) {
    fetchNotifications();
    fetchPreferences();
  }

  String _getToken() {
    final token = _sharedPrefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    return token;
  }

  int get unreadCount {
    return state.notifications.where((n) => !n.isRead).length;
  }

  /// Fetch notifications list
  Future<void> fetchNotifications() async {
    state = state.copyWith(status: NotificationStatus.loading);
    try {
      final token = _getToken();
      final response = await _client.get(
        Uri.parse('${ApiEndpoints.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final List list = body['notifications'] as List? ?? [];
        final items = list.map((n) => NotificationEntity.fromJson(n as Map<String, dynamic>)).toList();
        
        // Caching
        final jsonStr = jsonEncode(items.map((s) => s.toJson()).toList());
        await _sharedPrefs.setString(_cacheKey, jsonStr);
        await _sharedPrefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());

        state = state.copyWith(
          status: NotificationStatus.loaded,
          notifications: items,
          isOffline: false,
        );
      } else {
        throw Exception(body['message'] ?? 'Failed to load notifications.');
      }
    } catch (e) {
      // Offline fallback
      final cachedStr = _sharedPrefs.getString(_cacheKey);
      final cachedTimeStr = _sharedPrefs.getString(_cacheTimeKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List decoded = jsonDecode(cachedStr);
        final items = decoded.map((n) => NotificationEntity.fromJson(n as Map<String, dynamic>)).toList();
        final cachedAt = cachedTimeStr != null ? DateTime.parse(cachedTimeStr) : DateTime.now();

        state = state.copyWith(
          status: NotificationStatus.loaded,
          notifications: items,
          isOffline: true,
          cachedAt: cachedAt,
        );
      } else {
        state = state.copyWith(
          status: NotificationStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    final token = _getToken();
    
    // Optimistic local state update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return NotificationEntity(
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            type: n.type,
            priority: n.priority,
            targetType: n.targetType,
            targetId: n.targetId,
            isRead: true,
            scheduledAt: n.scheduledAt,
            expiresAt: n.expiresAt,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList(),
    );

    try {
      final response = await _client.put(
        Uri.parse('${ApiEndpoints.baseUrl}/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception();
      }
    } catch (_) {
      // Rollback
      fetchNotifications();
    }
  }

  /// Mark all notifications read
  Future<void> markAllRead() async {
    final token = _getToken();

    state = state.copyWith(
      notifications: state.notifications.map((n) {
        return NotificationEntity(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          priority: n.priority,
          targetType: n.targetType,
          targetId: n.targetId,
          isRead: true,
          scheduledAt: n.scheduledAt,
          expiresAt: n.expiresAt,
          createdAt: n.createdAt,
        );
      }).toList(),
    );

    try {
      final response = await _client.put(
        Uri.parse('${ApiEndpoints.baseUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception();
      }
    } catch (_) {
      fetchNotifications();
    }
  }

  /// Delete notification alert
  Future<void> deleteNotification(String id) async {
    final token = _getToken();

    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );

    try {
      final response = await _client.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/notifications/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception();
      }
    } catch (_) {
      fetchNotifications();
    }
  }

  /// Fetch notification preferences
  Future<void> fetchPreferences() async {
    state = state.copyWith(preferencesStatus: NotificationStatus.loading);
    try {
      final token = _getToken();
      final response = await _client.get(
        Uri.parse('${ApiEndpoints.baseUrl}/notifications/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final prefsObj = body['preferences'] as Map<String, dynamic>;
        
        final Map<String, bool> mappedPrefs = {
          'notify_new_matches': prefsObj['notify_new_matches'] as bool? ?? true,
          'notify_scheme_updates': prefsObj['notify_scheme_updates'] as bool? ?? true,
          'notify_closing_soon': prefsObj['notify_closing_soon'] as bool? ?? true,
          'notify_profile_reminders': prefsObj['notify_profile_reminders'] as bool? ?? true,
          'notify_system': prefsObj['notify_system'] as bool? ?? true,
        };

        // Cache preferences
        await _sharedPrefs.setString(_prefCacheKey, jsonEncode(mappedPrefs));

        state = state.copyWith(
          preferencesStatus: NotificationStatus.loaded,
          preferences: mappedPrefs,
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      // Offline fallback preferences
      final cachedStr = _sharedPrefs.getString(_prefCacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedStr);
        final Map<String, bool> cachedPrefs = decoded.map((key, value) => MapEntry(key, value as bool));
        state = state.copyWith(
          preferencesStatus: NotificationStatus.loaded,
          preferences: cachedPrefs,
        );
      } else {
        state = state.copyWith(preferencesStatus: NotificationStatus.error);
      }
    }
  }

  /// Update preferences settings
  Future<void> updatePreferences(Map<String, bool> updatedPrefs) async {
    final token = _getToken();
    
    // Optimistic local update
    state = state.copyWith(preferences: updatedPrefs);

    try {
      final response = await _client.put(
        Uri.parse('${ApiEndpoints.baseUrl}/notifications/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedPrefs),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        await fetchPreferences();
      } else {
        throw Exception();
      }
    } catch (e) {
      await fetchPreferences();
      throw Exception('Failed to update notification preferences.');
    }
  }
}
