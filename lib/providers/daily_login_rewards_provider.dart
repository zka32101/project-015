import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily login reward tier
class LoginRewardTier {
  final int day;
  final int rewardPoints;
  final String emoji;
  final String title;

  const LoginRewardTier({
    required this.day,
    required this.rewardPoints,
    required this.emoji,
    required this.title,
  });
}

/// Login streak information
class LoginStreak {
  final int currentStreak;
  final int bestStreak;
  final int totalLoginDays;
  final DateTime lastLoginDate;
  final DateTime? nextRewardDate;

  const LoginStreak({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalLoginDays,
    required this.lastLoginDate,
    this.nextRewardDate,
  });

  /// Get reward multiplier based on streak
  double getStreakMultiplier() {
    if (currentStreak >= 30) return 3.0;
    if (currentStreak >= 20) return 2.5;
    if (currentStreak >= 10) return 2.0;
    if (currentStreak >= 7) return 1.5;
    return 1.0;
  }

  /// Check if can claim reward today
  bool canClaimToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);

    return today.isAfter(lastLogin);
  }

  /// Check if streak is active (not broken)
  bool isStreakActive() {
    final now = DateTime.now();
    final yesterdayEnd = DateTime.now().subtract(const Duration(days: 1));
    return lastLoginDate.isAfter(yesterdayEnd);
  }

  /// Copy with modifications
  LoginStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    int? totalLoginDays,
    DateTime? lastLoginDate,
    DateTime? nextRewardDate,
  }) {
    return LoginStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalLoginDays: totalLoginDays ?? this.totalLoginDays,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      nextRewardDate: nextRewardDate ?? this.nextRewardDate,
    );
  }
}

/// Daily login reward state
class DailyLoginRewardsState {
  final LoginStreak streak;
  final int todayRewardPoints;
  final bool hasClaimedToday;
  final List<LoginRewardTier> rewardTiers;
  final bool isLoading;
  final String? error;

  const DailyLoginRewardsState({
    required this.streak,
    required this.todayRewardPoints,
    required this.hasClaimedToday,
    required this.rewardTiers,
    this.isLoading = false,
    this.error,
  });

  /// Get current reward tier
  LoginRewardTier getCurrentTier() {
    final day = streak.currentStreak;
    for (final tier in rewardTiers) {
      if (tier.day == day) return tier;
    }
    return rewardTiers.last;
  }

  /// Get next reward tier
  LoginRewardTier? getNextTier() {
    final day = streak.currentStreak;
    for (final tier in rewardTiers) {
      if (tier.day > day) return tier;
    }
    return null;
  }

  /// Get progress to next milestone
  int getProgressToNextMilestone() {
    final nextTier = getNextTier();
    if (nextTier == null) return 0;
    return nextTier.day - streak.currentStreak;
  }

  /// Copy with modifications
  DailyLoginRewardsState copyWith({
    LoginStreak? streak,
    int? todayRewardPoints,
    bool? hasClaimedToday,
    List<LoginRewardTier>? rewardTiers,
    bool? isLoading,
    String? error,
  }) {
    return DailyLoginRewardsState(
      streak: streak ?? this.streak,
      todayRewardPoints: todayRewardPoints ?? this.todayRewardPoints,
      hasClaimedToday: hasClaimedToday ?? this.hasClaimedToday,
      rewardTiers: rewardTiers ?? this.rewardTiers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for daily login rewards
class DailyLoginRewardsNotifier
    extends StateNotifier<DailyLoginRewardsState> {
  final SharedPreferences prefs;

  DailyLoginRewardsNotifier(this.prefs)
      : super(_buildInitialState(prefs)) {
    _initializeRewards();
  }

  /// Initialize rewards
  void _initializeRewards() {
    _updateStreak();
  }

  /// Build initial state
  static DailyLoginRewardsState _buildInitialState(
    SharedPreferences prefs,
  ) {
    final streak = _loadOrCreateStreak(prefs);
    final rewardTiers = _generateRewardTiers();

    // Calculate today's reward
    int todayReward = 10;
    if (streak.canClaimToday()) {
      final multiplier = streak.getStreakMultiplier();
      todayReward = (10 * multiplier).toInt();
    }

    return DailyLoginRewardsState(
      streak: streak,
      todayRewardPoints: todayReward,
      hasClaimedToday: !streak.canClaimToday(),
      rewardTiers: rewardTiers,
      isLoading: false,
    );
  }

  /// Load or create login streak
  static LoginStreak _loadOrCreateStreak(SharedPreferences prefs) {
    final lastLoginStr = prefs.getString('last_login_date');
    final currentStreak = prefs.getInt('login_streak') ?? 0;
    final bestStreak = prefs.getInt('best_login_streak') ?? 0;
    final totalDays = prefs.getInt('total_login_days') ?? 0;

    DateTime lastLogin;
    if (lastLoginStr != null) {
      lastLogin = DateTime.parse(lastLoginStr);
    } else {
      lastLogin = DateTime.now().subtract(const Duration(days: 1));
    }

    return LoginStreak(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalLoginDays: totalDays,
      lastLoginDate: lastLogin,
    );
  }

  /// Update streak
  void _updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = DateTime(state.streak.lastLoginDate.year,
        state.streak.lastLoginDate.month, state.streak.lastLoginDate.day);

    if (today.isAfter(lastLogin)) {
      // New day login
      int newStreak = state.streak.currentStreak + 1;
      int newTotal = state.streak.totalLoginDays + 1;
      int newBest = state.streak.bestStreak;

      // Check if streak is broken
      final expectedLastLogin = now.subtract(const Duration(days: 1));
      if (!state.streak.isStreakActive() && state.streak.currentStreak > 0) {
        // Streak was broken, reset to 1
        newStreak = 1;
      }

      // Update best streak
      if (newStreak > newBest) {
        newBest = newStreak;
        await prefs.setInt('best_login_streak', newBest);
      }

      // Save to preferences
      await prefs.setString('last_login_date', now.toIso8601String());
      await prefs.setInt('login_streak', newStreak);
      await prefs.setInt('total_login_days', newTotal);

      // Update state
      final updatedStreak = state.streak.copyWith(
        currentStreak: newStreak,
        bestStreak: newBest,
        totalLoginDays: newTotal,
        lastLoginDate: now,
      );

      final multiplier = updatedStreak.getStreakMultiplier();
      final todayReward = (10 * multiplier).toInt();

      state = state.copyWith(
        streak: updatedStreak,
        todayRewardPoints: todayReward,
        hasClaimedToday: false,
      );
    }
  }

  /// Claim daily reward
  Future<void> claimDailyReward() async {
    if (!state.streak.canClaimToday()) {
      state = state.copyWith(
        error: 'Already claimed today',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Save reward claim
      await prefs.setString('last_reward_claimed', DateTime.now().toIso8601String());

      // In a real app, would add reward to player account here
      state = state.copyWith(
        hasClaimedToday: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to claim reward: $e',
      );
    }
  }

  /// Generate reward tiers
  static List<LoginRewardTier> _generateRewardTiers() {
    return [
      const LoginRewardTier(
        day: 1,
        rewardPoints: 10,
        emoji: '🌱',
        title: 'はじまり',
      ),
      const LoginRewardTier(
        day: 7,
        rewardPoints: 70,
        emoji: '🌿',
        title: '1週間',
      ),
      const LoginRewardTier(
        day: 14,
        rewardPoints: 140,
        emoji: '🌳',
        title: '2週間',
      ),
      const LoginRewardTier(
        day: 21,
        rewardPoints: 210,
        emoji: '🌲',
        title: '3週間',
      ),
      const LoginRewardTier(
        day: 30,
        rewardPoints: 300,
        emoji: '🏔️',
        title: '1ヶ月',
      ),
      const LoginRewardTier(
        day: 60,
        rewardPoints: 600,
        emoji: '🌋',
        title: '2ヶ月',
      ),
      const LoginRewardTier(
        day: 90,
        rewardPoints: 900,
        emoji: '⛰️',
        title: '3ヶ月',
      ),
      const LoginRewardTier(
        day: 180,
        rewardPoints: 1800,
        emoji: '🗻',
        title: '半年',
      ),
    ];
  }
}

/// Riverpod provider for daily login rewards
final dailyLoginRewardsProvider =
    StateNotifierProvider<DailyLoginRewardsNotifier, DailyLoginRewardsState>(
        (ref) async {
  final prefs = await SharedPreferences.getInstance();
  return DailyLoginRewardsNotifier(prefs);
});

/// Alternative sync provider
final dailyLoginRewardsSyncProvider =
    StateNotifierProvider<DailyLoginRewardsNotifier, DailyLoginRewardsState>(
        (ref) {
  // This will be replaced with actual SharedPreferences instance
  // For now, returns a provider that needs initialization
  throw UnimplementedError();
});
