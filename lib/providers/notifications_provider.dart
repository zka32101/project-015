import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification type
enum NotificationType {
  achievement('🏆', 'Achievement Unlocked'),
  milestone('⭐', 'Milestone Reached'),
  goal('🎯', 'Goal Completed'),
  streak('🔥', 'Streak!'),
  level('📈', 'Level Up'),
  seasonal('📅', 'Season Milestone'),
  reward('🎁', 'Reward Earned'),
  info('ℹ️', 'Information');

  final String emoji;
  final String label;
  const NotificationType(this.emoji, this.label);

  /// Get color for notification type
  Color getColor() {
    switch (this) {
      case NotificationType.achievement:
        return Colors.purple;
      case NotificationType.milestone:
        return Colors.blue;
      case NotificationType.goal:
        return Colors.teal;
      case NotificationType.streak:
        return Colors.red;
      case NotificationType.level:
        return Colors.orange;
      case NotificationType.seasonal:
        return Colors.indigo;
      case NotificationType.reward:
        return Colors.amber;
      case NotificationType.info:
        return Colors.grey;
    }
  }
}

/// In-app notification
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Duration displayDuration;
  final VoidCallback? onTap;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.displayDuration = const Duration(seconds: 4),
    this.onTap,
  });

  /// Copy with modifications
  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    Duration? displayDuration,
    VoidCallback? onTap,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      displayDuration: displayDuration ?? this.displayDuration,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Notifications state
class NotificationsState {
  final List<AppNotification> activeNotifications;
  final List<AppNotification> history;
  final bool isNotificationEnabled;

  const NotificationsState({
    required this.activeNotifications,
    required this.history,
    this.isNotificationEnabled = true,
  });

  /// Copy with modifications
  NotificationsState copyWith({
    List<AppNotification>? activeNotifications,
    List<AppNotification>? history,
    bool? isNotificationEnabled,
  }) {
    return NotificationsState(
      activeNotifications: activeNotifications ?? this.activeNotifications,
      history: history ?? this.history,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
    );
  }
}

/// Notifier for notifications
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier()
      : super(const NotificationsState(
          activeNotifications: [],
          history: [],
          isNotificationEnabled: true,
        ));

  /// Add notification
  void showNotification(AppNotification notification) {
    if (!state.isNotificationEnabled) return;

    // Add to active notifications
    final updatedActive = [...state.activeNotifications, notification];
    state = state.copyWith(activeNotifications: updatedActive);

    // Add to history (keep last 50)
    final updatedHistory = [notification, ...state.history].take(50).toList();
    state = state.copyWith(history: updatedHistory);

    // Auto-remove after display duration
    Future.delayed(notification.displayDuration, () {
      removeNotification(notification.id);
    });
  }

  /// Remove notification
  void removeNotification(String id) {
    final updated = state.activeNotifications
        .where((n) => n.id != id)
        .toList();
    state = state.copyWith(activeNotifications: updated);
  }

  /// Clear all active notifications
  void clearAll() {
    state = state.copyWith(activeNotifications: []);
  }

  /// Toggle notifications
  void toggleNotifications() {
    state = state.copyWith(
      isNotificationEnabled: !state.isNotificationEnabled,
    );
  }

  /// Show achievement notification
  void showAchievementUnlocked(String title, String description) {
    final notification = AppNotification(
      id: 'achievement_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.achievement,
      title: title,
      message: description,
      timestamp: DateTime.now(),
    );
    showNotification(notification);
  }

  /// Show goal completed notification
  void showGoalCompleted(String goalTitle, int rewardPoints) {
    final notification = AppNotification(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.goal,
      title: 'クリア！ $goalTitle',
      message: '+$rewardPoints ポイント獲得',
      timestamp: DateTime.now(),
    );
    showNotification(notification);
  }

  /// Show streak notification
  void showStreakMilestone(int streakDays) {
    final notification = AppNotification(
      id: 'streak_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.streak,
      title: '${streakDays}日連続ログイン！',
      message: 'ストリークボーナスを獲得しました',
      timestamp: DateTime.now(),
    );
    showNotification(notification);
  }

  /// Show level up notification
  void showLevelUp(String levelName) {
    final notification = AppNotification(
      id: 'level_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.level,
      title: 'レベルアップ！',
      message: levelName,
      timestamp: DateTime.now(),
    );
    showNotification(notification);
  }

  /// Show reward notification
  void showRewardEarned(String rewardName, int amount) {
    final notification = AppNotification(
      id: 'reward_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.reward,
      title: rewardName,
      message: '+$amount ポイント',
      timestamp: DateTime.now(),
    );
    showNotification(notification);
  }

  /// Show seasonal milestone
  void showSeasonalMilestone(String season, String tier) {
    final notification = AppNotification(
      id: 'seasonal_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.seasonal,
      title: 'シーズンマイルストーン',
      message: '$season $tier に到達',
      timestamp: DateTime.now(),
    );
    showNotification(notification);
  }
}

/// Riverpod provider for notifications
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
