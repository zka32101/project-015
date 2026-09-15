import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Challenge difficulty
enum ChallengeDifficulty {
  easy('かんたん'),
  normal('ふつう'),
  hard('むずかしい'),
  expert('エキスパート');

  final String label;
  const ChallengeDifficulty(this.label);
}

/// Challenge reward tier
class ChallengeReward {
  final int basePoints;
  final int bonus; // Extra points for completion
  final String emoji;

  const ChallengeReward({
    required this.basePoints,
    required this.bonus,
    required this.emoji,
  });
}

/// Daily challenge
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeDifficulty difficulty;
  final ChallengeReward reward;
  final DateTime createdDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final int progress; // 0-100 percentage
  final String requirement;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.difficulty,
    required this.reward,
    required this.createdDate,
    this.isCompleted = false,
    this.completedDate,
    this.progress = 0,
    required this.requirement,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    ChallengeDifficulty? difficulty,
    ChallengeReward? reward,
    DateTime? createdDate,
    bool? isCompleted,
    DateTime? completedDate,
    int? progress,
    String? requirement,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      difficulty: difficulty ?? this.difficulty,
      reward: reward ?? this.reward,
      createdDate: createdDate ?? this.createdDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      progress: progress ?? this.progress,
      requirement: requirement ?? this.requirement,
    );
  }
}

/// Daily challenges state
class DailyChallengesState {
  final List<DailyChallenge> todaysChallenges;
  final DateTime currentDate;
  final int completedCount;
  final int totalRewardsToday;
  final int totalRewardsThisWeek;
  final int completionStreak;
  final bool isLoading;
  final String? error;

  const DailyChallengesState({
    required this.todaysChallenges,
    required this.currentDate,
    this.completedCount = 0,
    this.totalRewardsToday = 0,
    this.totalRewardsThisWeek = 0,
    this.completionStreak = 0,
    this.isLoading = false,
    this.error,
  });

  /// Get completion percentage
  double getCompletionPercentage() {
    if (todaysChallenges.isEmpty) return 0.0;
    return completedCount / todaysChallenges.length;
  }

  /// Copy with modifications
  DailyChallengesState copyWith({
    List<DailyChallenge>? todaysChallenges,
    DateTime? currentDate,
    int? completedCount,
    int? totalRewardsToday,
    int? totalRewardsThisWeek,
    int? completionStreak,
    bool? isLoading,
    String? error,
  }) {
    return DailyChallengesState(
      todaysChallenges: todaysChallenges ?? this.todaysChallenges,
      currentDate: currentDate ?? this.currentDate,
      completedCount: completedCount ?? this.completedCount,
      totalRewardsToday: totalRewardsToday ?? this.totalRewardsToday,
      totalRewardsThisWeek: totalRewardsThisWeek ?? this.totalRewardsThisWeek,
      completionStreak: completionStreak ?? this.completionStreak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for daily challenges
class DailyChallengesNotifier extends StateNotifier<DailyChallengesState> {
  final SharedPreferences prefs;

  DailyChallengesNotifier(this.prefs)
      : super(_buildInitialState(prefs)) {
    _initializeChallenges();
  }

  /// Initialize challenges
  void _initializeChallenges() {
    _generateTodaysChallenges();
  }

  /// Build initial state
  static DailyChallengesState _buildInitialState(SharedPreferences prefs) {
    return DailyChallengesState(
      todaysChallenges: [],
      currentDate: DateTime.now(),
      completionStreak: prefs.getInt('challenge_completion_streak') ?? 0,
    );
  }

  /// Generate today's challenges
  void _generateTodaysChallenges() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we already generated challenges for today
    final lastGenerationStr = prefs.getString('last_challenge_generation_date');
    if (lastGenerationStr != null) {
      final lastGeneration = DateTime.parse(lastGenerationStr);
      final lastDate = DateTime(
        lastGeneration.year,
        lastGeneration.month,
        lastGeneration.day,
      );
      if (lastDate == today) {
        // Already generated for today, load from prefs
        _loadChallengesFromPrefs();
        return;
      }
    }

    // Generate new challenges for today
    final challenges = _createChallenges(today);
    state = state.copyWith(
      todaysChallenges: challenges,
      currentDate: today,
      completedCount: 0,
      totalRewardsToday: 0,
    );

    // Save generation date
    prefs.setString('last_challenge_generation_date', today.toIso8601String());
  }

  /// Load challenges from preferences
  void _loadChallengesFromPrefs() {
    final completedIds = prefs.getStringList('completed_challenge_ids') ?? [];
    final totalRewardsTodayStr = prefs.getString('total_rewards_today');

    if (totalRewardsTodayStr != null) {
      final parts = totalRewardsTodayStr.split('|');
      if (parts.length >= 2) {
        final rewards = int.tryParse(parts[0]) ?? 0;
        final completed = int.tryParse(parts[1]) ?? 0;

        state = state.copyWith(
          totalRewardsToday: rewards,
          completedCount: completed,
        );
      }
    }
  }

  /// Create challenges for a date
  List<DailyChallenge> _createChallenges(DateTime date) {
    final random = math.Random(date.millisecondsSinceEpoch ~/ 86400000);

    return [
      _createChallenge(
        id: 'challenge_wins_${date.day}',
        title: '3勝チャレンジ',
        description: '3回連続で勝利',
        emoji: '🏆',
        difficulty: ChallengeDifficulty.easy,
        reward: const ChallengeReward(
          basePoints: 50,
          bonus: 20,
          emoji: '⭐',
        ),
        requirement: '3勝達成',
        random: random,
        date: date,
      ),
      _createChallenge(
        id: 'challenge_accuracy_${date.day}',
        title: '高スコアチャレンジ',
        description: '60点以上でゲーム完了',
        emoji: '📊',
        difficulty: ChallengeDifficulty.normal,
        reward: const ChallengeReward(
          basePoints: 75,
          bonus: 30,
          emoji: '⭐',
        ),
        requirement: '60点以上',
        random: random,
        date: date,
      ),
      _createChallenge(
        id: 'challenge_speed_${date.day}',
        title: 'スピードラン',
        description: '5分以内に5勝',
        emoji: '⚡',
        difficulty: ChallengeDifficulty.hard,
        reward: const ChallengeReward(
          basePoints: 100,
          bonus: 50,
          emoji: '⭐',
        ),
        requirement: '5分以内に5勝',
        random: random,
        date: date,
      ),
      _createChallenge(
        id: 'challenge_expert_${date.day}',
        title: 'エキスパートモード',
        description: 'ハードAIに3連勝',
        emoji: '👑',
        difficulty: ChallengeDifficulty.expert,
        reward: const ChallengeReward(
          basePoints: 150,
          bonus: 100,
          emoji: '💎',
        ),
        requirement: 'ハードAIに3連勝',
        random: random,
        date: date,
      ),
    ];
  }

  /// Create a single challenge
  DailyChallenge _createChallenge({
    required String id,
    required String title,
    required String description,
    required String emoji,
    required ChallengeDifficulty difficulty,
    required ChallengeReward reward,
    required String requirement,
    required math.Random random,
    required DateTime date,
  }) {
    return DailyChallenge(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      difficulty: difficulty,
      reward: reward,
      createdDate: date,
      requirement: requirement,
      progress: random.nextInt(80), // Random progress 0-80%
    );
  }

  /// Complete a challenge
  Future<void> completeChallenge(DailyChallenge challenge) async {
    if (challenge.isCompleted) return;

    try {
      final completed = [...state.todaysChallenges];
      final index = completed
          .indexWhere((c) => c.id == challenge.id);

      if (index != -1) {
        completed[index] = completed[index].copyWith(
          isCompleted: true,
          completedDate: DateTime.now(),
          progress: 100,
        );
      }

      final newCompletedCount = state.completedCount + 1;
      final newRewards =
          state.totalRewardsToday +
          challenge.reward.basePoints +
          challenge.reward.bonus;
      final newWeeklyRewards =
          state.totalRewardsThisWeek + newRewards;

      // Update streak
      int newStreak = state.completionStreak;
      if (newCompletedCount == completed.length) {
        // All challenges completed today
        newStreak = state.completionStreak + 1;
        await prefs.setInt('challenge_completion_streak', newStreak);
      }

      // Save completion
      final completedIds = prefs.getStringList('completed_challenge_ids') ?? [];
      if (!completedIds.contains(challenge.id)) {
        completedIds.add(challenge.id);
        await prefs.setStringList('completed_challenge_ids', completedIds);
      }

      // Save rewards
      await prefs.setString(
        'total_rewards_today',
        '$newRewards|$newCompletedCount',
      );

      state = state.copyWith(
        todaysChallenges: completed,
        completedCount: newCompletedCount,
        totalRewardsToday: newRewards,
        totalRewardsThisWeek: newWeeklyRewards,
        completionStreak: newStreak,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete challenge: $e');
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(
    String challengeId,
    int progress,
  ) async {
    try {
      final updated = [...state.todaysChallenges];
      final index = updated.indexWhere((c) => c.id == challengeId);

      if (index != -1) {
        updated[index] = updated[index].copyWith(progress: progress);
      }

      state = state.copyWith(todaysChallenges: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update progress: $e');
    }
  }
}

/// Riverpod provider for daily challenges
final dailyChallengesProvider =
    StateNotifierProvider<DailyChallengesNotifier, DailyChallengesState>(
  (ref) async {
    final prefs = await SharedPreferences.getInstance();
    return DailyChallengesNotifier(prefs);
  },
);

/// Alternative sync provider (for testing)
final dailyChallengesSyncProvider =
    StateNotifierProvider<DailyChallengesNotifier, DailyChallengesState>(
        (ref) {
  throw UnimplementedError();
});
