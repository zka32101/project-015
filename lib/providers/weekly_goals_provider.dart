import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_analytics_provider.dart';

/// Weekly goal type
enum GoalType {
  winCount,
  winRate,
  gamesPlayed,
  streak,
  achievementUnlock,
  difficultyProgress,
}

/// Single weekly goal
class WeeklyGoal {
  final String id;
  final GoalType type;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final int reward;
  final bool isCompleted;

  const WeeklyGoal({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.reward,
    required this.isCompleted,
  });

  /// Get progress percentage
  double getProgress() {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0, 1);
  }

  /// Check if goal is achievable by end date
  bool isAchievableByEndDate(double currentRate) {
    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return isCompleted;

    final projectedValue = (currentValue + (daysRemaining * currentRate)).toInt();
    return projectedValue >= targetValue;
  }

  /// Get emoji for goal type
  String getEmoji() {
    switch (type) {
      case GoalType.winCount:
        return '🏆';
      case GoalType.winRate:
        return '📈';
      case GoalType.gamesPlayed:
        return '🎮';
      case GoalType.streak:
        return '🔥';
      case GoalType.achievementUnlock:
        return '⭐';
      case GoalType.difficultyProgress:
        return '⬆️';
    }
  }

  /// Get reward description
  String getRewardDescription() {
    switch (reward) {
      case 100:
        return '銀バッジ';
      case 250:
        return '金バッジ';
      case 500:
        return 'プラチナバッジ';
      default:
        return '$reward ポイント';
    }
  }

  /// Copy with modifications
  WeeklyGoal copyWith({
    int? currentValue,
    bool? isCompleted,
  }) {
    return WeeklyGoal(
      id: id,
      type: type,
      title: title,
      description: description,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate,
      endDate: endDate,
      reward: reward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Daily challenge
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final DateTime date;
  final bool isCompleted;
  final int reward;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.date,
    required this.isCompleted,
    required this.reward,
  });

  /// Check if challenge is today
  bool isToday() {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get progress percentage
  double getProgress() {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0, 1);
  }
}

/// Weekly goals state
class WeeklyGoalsState {
  final List<WeeklyGoal> activeGoals;
  final DailyChallenge? todayChallenge;
  final int totalRewardsEarned;
  final List<String> completedGoalIds;
  final int totalPointsAvailable;
  final int pointsEarned;
  final double overallProgress;
  final bool isLoading;
  final String? error;

  const WeeklyGoalsState({
    required this.activeGoals,
    this.todayChallenge,
    required this.totalRewardsEarned,
    required this.completedGoalIds,
    required this.totalPointsAvailable,
    required this.pointsEarned,
    required this.overallProgress,
    this.isLoading = false,
    this.error,
  });

  /// Get next milestone
  int getNextMilestonePoints() {
    final milestones = [100, 250, 500, 1000, 2500, 5000];
    return milestones.firstWhere((m) => m > pointsEarned, orElse: () => 5000);
  }

  /// Get next goal to complete
  WeeklyGoal? getNextGoalToComplete() {
    return activeGoals
        .where((g) => !g.isCompleted)
        .reduce((a, b) => a.getProgress() > b.getProgress() ? a : b);
  }
}

/// Notifier for weekly goals
class WeeklyGoalsNotifier extends StateNotifier<WeeklyGoalsState> {
  final SharedPreferences prefs;
  final GameAnalyticsState analytics;

  WeeklyGoalsNotifier(this.prefs, this.analytics)
      : super(_buildState(prefs, analytics)) {
    _initializeGoals();
  }

  /// Initialize goals and challenges
  void _initializeGoals() {
    _updateGoalProgress();
  }

  /// Build state
  static WeeklyGoalsState _buildState(
    SharedPreferences prefs,
    GameAnalyticsState analytics,
  ) {
    final goals = _generateWeeklyGoals(analytics);
    final todayChallenge = _generateDailyChallenge();
    final pointsEarned =
        prefs.getInt('weekly_goals_points_earned') ?? 0;
    final completedGoalIds =
        prefs.getStringList('completed_goal_ids') ?? [];

    final totalPoints = goals.fold<int>(0, (sum, g) => sum + g.reward);
    final completedPoints = goals
        .where((g) => completedGoalIds.contains(g.id))
        .fold<int>(0, (sum, g) => sum + g.reward);

    return WeeklyGoalsState(
      activeGoals: goals,
      todayChallenge: todayChallenge,
      totalRewardsEarned: completedGoalIds.length,
      completedGoalIds: completedGoalIds,
      totalPointsAvailable: totalPoints,
      pointsEarned: pointsEarned,
      overallProgress: totalPoints > 0 ? completedPoints / totalPoints : 0,
      isLoading: false,
    );
  }

  /// Generate weekly goals based on analytics
  static List<WeeklyGoal> _generateWeeklyGoals(GameAnalyticsState analytics) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final goals = <WeeklyGoal>[];

    // Win count goal
    goals.add(WeeklyGoal(
      id: 'weekly_wins_${weekStart.toString().split(' ')[0]}',
      type: GoalType.winCount,
      title: '今週5勝達成',
      description: '今週中に5勝以上獲得しましょう',
      targetValue: 5,
      currentValue: analytics.allRecords
          .where((r) => r.playedAt.isAfter(weekStart))
          .where((r) => r.result.toString() == 'GameResult.playerAWins')
          .length,
      startDate: weekStart,
      endDate: weekEnd,
      reward: 100,
      isCompleted: false,
    ));

    // Games played goal
    goals.add(WeeklyGoal(
      id: 'weekly_games_${weekStart.toString().split(' ')[0]}',
      type: GoalType.gamesPlayed,
      title: '10ゲームプレイ',
      description: '週に10ゲーム以上プレイしましょう',
      targetValue: 10,
      currentValue: analytics.gamesThisWeek,
      startDate: weekStart,
      endDate: weekEnd,
      reward: 100,
      isCompleted: false,
    ));

    // Win rate goal
    goals.add(WeeklyGoal(
      id: 'weekly_winrate_${weekStart.toString().split(' ')[0]}',
      type: GoalType.winRate,
      title: '勝率60%維持',
      description: '今週の勝率を60%以上に保ちましょう',
      targetValue: 60,
      currentValue: (analytics.overallWinRate * 100).toInt(),
      startDate: weekStart,
      endDate: weekEnd,
      reward: 250,
      isCompleted: false,
    ));

    // Streak goal
    goals.add(WeeklyGoal(
      id: 'weekly_streak_${weekStart.toString().split(' ')[0]}',
      type: GoalType.streak,
      title: '3連勝達成',
      description: '3連勝以上を達成しましょう',
      targetValue: 3,
      currentValue: analytics.difficultyBreakdown.isNotEmpty
          ? analytics.difficultyBreakdown
              .map((d) => d.totalGames)
              .reduce((a, b) => a + b)
          : 0,
      startDate: weekStart,
      endDate: weekEnd,
      reward: 150,
      isCompleted: false,
    ));

    return goals;
  }

  /// Generate daily challenge
  static DailyChallenge _generateDailyChallenge() {
    final now = DateTime.now();
    // Use date as seed for consistent daily challenge
    final seed = now.year * 10000 + now.month * 100 + now.day;

    final challenges = [
      DailyChallenge(
        id: 'daily_wins_$seed',
        title: '今日3勝',
        description: '今日中に3勝以上獲得',
        targetValue: 3,
        currentValue: 0,
        date: now,
        isCompleted: false,
        reward: 50,
      ),
      DailyChallenge(
        id: 'daily_hard_$seed',
        title: '難易度つよいでプレイ',
        description: 'つよいAIと1ゲーム',
        targetValue: 1,
        currentValue: 0,
        date: now,
        isCompleted: false,
        reward: 75,
      ),
      DailyChallenge(
        id: 'daily_quick_$seed',
        title: 'クイックプレイ',
        description: '5分以内に5ゲーム完了',
        targetValue: 5,
        currentValue: 0,
        date: now,
        isCompleted: false,
        reward: 60,
      ),
    ];

    return challenges[seed % challenges.length];
  }

  /// Update goal progress from analytics
  void _updateGoalProgress() {
    // This would be called periodically to update goal progress
    // In a real implementation, this would refresh from persistent storage
  }

  /// Complete a goal
  Future<void> completeGoal(String goalId) async {
    final completed = List<String>.from(state.completedGoalIds);
    if (!completed.contains(goalId)) {
      completed.add(goalId);
      await prefs.setStringList('completed_goal_ids', completed);

      // Update points
      final goal = state.activeGoals.firstWhere((g) => g.id == goalId);
      final newPoints = state.pointsEarned + goal.reward;
      await prefs.setInt('weekly_goals_points_earned', newPoints);

      state = _buildState(prefs, GameAnalyticsState(
        allRecords: [],
        difficultyBreakdown: [],
        recentPerformance: [],
        overallWinRate: 0,
        totalGamesAnalyzed: 0,
        gamesThisWeek: 0,
        gamesThisMonth: 0,
        averageDurationOverall: 0,
      ));
    }
  }

  /// Complete daily challenge
  Future<void> completeDailyChallenge() async {
    if (state.todayChallenge != null) {
      final reward = state.todayChallenge!.reward;
      final newPoints = state.pointsEarned + reward;
      await prefs.setInt('weekly_goals_points_earned', newPoints);
    }
  }

  /// Reset weekly goals (call on week change)
  Future<void> resetWeeklyGoals() async {
    await prefs.setStringList('completed_goal_ids', []);
    await prefs.setInt('weekly_goals_points_earned', 0);
  }
}

/// Riverpod provider for weekly goals
final weeklyGoalsProvider =
    StateNotifierProvider<WeeklyGoalsNotifier, WeeklyGoalsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final analytics = ref.watch(gameAnalyticsProvider);

  return prefs.maybeWhen(
    data: (preferences) => WeeklyGoalsNotifier(preferences, analytics),
    orElse: () => WeeklyGoalsNotifier(
      SharedPreferences.getInstance() as SharedPreferences,
      analytics,
    ),
  );
});

// Import needed from game_records_provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});
