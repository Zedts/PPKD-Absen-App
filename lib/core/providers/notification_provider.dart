import 'package:flutter/material.dart';

import '../database/notification_database_service.dart';
import '../models/app_notification_model.dart';

/// Provider managing reactive notification state and SQFlite integration.
class NotificationProvider extends ChangeNotifier {
  final NotificationDatabaseService _dbService;

  NotificationProvider({NotificationDatabaseService? dbService})
      : _dbService = dbService ?? NotificationDatabaseService.instance;

  List<AppNotificationModel> _notifications = [];
  List<AppNotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Reactive badge text capped at 99.
  /// Returns '' if 0, '1'..'99', or '99+' if greater than 99.
  String get badgeText {
    if (_unreadCount <= 0) return '';
    if (_unreadCount > 99) return '99+';
    return _unreadCount.toString();
  }

  /// Initializes and fetches notifications from the SQLite database.
  Future<void> init() async {
    await loadNotifications();
  }

  /// Loads all notifications from SQFlite and updates the reactive unread count.
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _dbService.getAllNotifications();
      _unreadCount = _notifications.where((item) => !item.isRead).length;
    } catch (_) {
      // Fallback empty list on error
      _notifications = [];
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inserts a new notification into SQFlite and updates reactive state.
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final newNotif = AppNotificationModel(
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    try {
      final insertedId = await _dbService.insertNotification(newNotif);
      final itemWithId = newNotif.copyWith(id: insertedId);
      _notifications.insert(0, itemWithId);
      _unreadCount++;
      notifyListeners();
    } catch (_) {
      // If error occurs, refresh from DB
      await loadNotifications();
    }
  }

  /// Marks a specific notification as read in SQFlite and immediately updates state.
  Future<void> markAsRead(int? id) async {
    if (id == null) return;

    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;

    // If already read, no need to update
    if (_notifications[index].isRead) return;

    // Optimistically update in-memory state
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    if (_unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    // Persist to SQFlite
    try {
      await _dbService.markAsRead(id);
    } catch (_) {
      // Revert/refresh on failure
      await loadNotifications();
    }
  }

  /// Deletes all notifications from SQFlite and clears in-memory state.
  Future<void> deleteAllNotifications() async {
    try {
      await _dbService.deleteAllNotifications();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {
      await loadNotifications();
    }
  }
}
