import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/screens/profile_edit_screen.dart';
import '../../../schemes/presentation/screens/scheme_detail_screen.dart';
import '../providers/notification_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: 'Mark all as read',
            onPressed: state.notifications.isEmpty ? null : () => notifier.markAllRead(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Preferences',
            onPressed: () => _showPreferencesBottomSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner
            if (state.isOffline)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.withValues(alpha: 0.15),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_outlined, color: Colors.orange, size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline Mode: Showing cached notifications.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading / empty / list displays
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.fetchNotifications(),
                child: state.status == NotificationStatus.loading && state.notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.notifications.isEmpty
                        ? const Center(child: Text('No notifications found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = state.notifications[index];
                              
                              // Color codes by priority
                              Color priorityColor = Colors.blue;
                              if (notification.priority == 'Critical') priorityColor = Colors.red;
                              if (notification.priority == 'High') priorityColor = Colors.orange;
                              if (notification.priority == 'Low') priorityColor = Colors.grey;

                              return Dismissible(
                                key: Key(notification.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  notifier.deleteNotification(notification.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Notification removed.'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: notification.isRead 
                                          ? (isDark ? Colors.blueGrey[800]! : Colors.grey[200]!)
                                          : priorityColor.withValues(alpha: 0.5),
                                      width: notification.isRead ? 1 : 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      // 1. Mark as read
                                      if (!notification.isRead) {
                                        notifier.markAsRead(notification.id);
                                      }

                                      // 2. Target deep linking routing (as requested!)
                                      if (notification.targetType == 'scheme' && notification.targetId != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => SchemeDetailScreen(schemeId: notification.targetId!),
                                          ),
                                        );
                                      } else if (notification.targetType == 'profile') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const ProfileEditScreen(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Unread Badge marker dot
                                          if (!notification.isRead) ...[
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(top: 6, right: 8),
                                              decoration: BoxDecoration(
                                                color: priorityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Priority Tag
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: priorityColor.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        notification.priority.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: priorityColor,
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Time Label
                                                    Text(
                                                      _formatTime(notification.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  notification.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: notification.isRead 
                                                        ? (isDark ? Colors.blueGrey[300] : Colors.blueGrey[800])
                                                        : (isDark ? Colors.white : Colors.black),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notification.message,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.blueGrey[400] : Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inMinutes < 60) {
      if (difference.inMinutes == 0) return 'Just now';
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showPreferencesBottomSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    
    // Create copy of preferences to edit
    Map<String, bool> tempPrefs = Map.from(state.preferences);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Notification Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('New Matching Schemes', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Notify when new schemes match profile', style: TextStyle(fontSize: 11)),
                    value: tempPrefs['notify_new_matches'] ?? true,
                    onChanged: (val) => setState(() => tempPrefs['notify_new_matches'] = val),
                  ),
                  SwitchListTile(
                    title: const Text('Scheme Updates', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Notify when bookmarks are modified', style: TextStyle(fontSize: 11)),
                    value: tempPrefs['notify_scheme_updates'] ?? true,
                    onChanged: (val) => setState(() => tempPrefs['notify_scheme_updates'] = val),
                  ),
                  SwitchListTile(
                    title: const Text('Deadline Reminders', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Notify when bookmarks approach deadlines', style: TextStyle(fontSize: 11)),
                    value: tempPrefs['notify_closing_soon'] ?? true,
                    onChanged: (val) => setState(() => tempPrefs['notify_closing_soon'] = val),
                  ),
                  SwitchListTile(
                    title: const Text('Profile Reminders', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Notify when profile parameters are incomplete', style: TextStyle(fontSize: 11)),
                    value: tempPrefs['notify_profile_reminders'] ?? true,
                    onChanged: (val) => setState(() => tempPrefs['notify_profile_reminders'] = val),
                  ),
                  SwitchListTile(
                    title: const Text('System Announcements', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Updates, notifications, and platform alerts', style: TextStyle(fontSize: 11)),
                    value: tempPrefs['notify_system'] ?? true,
                    onChanged: (val) => setState(() => tempPrefs['notify_system'] = val),
                  ),
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    child: const Text('Save Settings'),
                    onPressed: () {
                      notifier.updatePreferences(tempPrefs);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
