import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/achievements.dart';
import '../engine/game_analytics.dart';

/// Achievement rarity tier for visual distinction
enum AchievementRarity {
  common,     // Bronze - Basic achievements
  uncommon,   // Silver - Moderate difficulty
  rare,       // Gold - High difficulty
  epic,       // Diamond - Very difficult
}

/// Extended achievement data with progress and metadata
class AchievementWithProgress {
  final Achievement achievement;
  final AchievementRarity rarity;
  final double progress; // 0.0 to 1.0
  final int progressCurrent;
  final int progressMax;
  final DateTime? unlockedAt;
  final bool isNew; // Unlocked in this session

  const AchievementWithProgress({
    required this.achievement,
    required this.rarity,
    required this.progress,
    required this.progressCurrent,
    required this.progressMax,
    this.unlockedAt,
    this.isNew = false,
  });

  /// Get rarity color for UI display
  String getRarityLabel() {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
    }
  }

  /// Get progress text (e.g., "5/10")
  String getProgressText() {
    if (progressMax == 0) return 'Locked';
    return '$progressCurrent/$progressMax';
  }
}

/// State for achievements display
class AchievementsState {
  final Map<String, AchievementWithProgress> allAchievements;
  final List<AchievementWithProgress> unlockedAchievements;
  final List<AchievementWithProgress> lockedAchievements;
  final AchievementWithProgress? lastUnlocked; // Most recently unlocked
  final int totalUnlocked;
  final double completionPercentage;
  final bool isLoading;

  const AchievementsState({
    required this.allAchievements,
    required this.unlockedAchievements,
    required this.lockedAchievements,
    this.lastUnlocked,
    required this.totalUnlocked,
    required this.completionPercentage,
    this.isLoading = false,
  });

  /// Achievements sorted by rarity (epic first)
  List<AchievementWithProgress> getByRarity(AchievementRarity rarity) {
    return allAchievements.values
        .where((a) => a.rarity == rarity)
        .toList();
  }

  /// Get closest achievements to unlock (by progress)
  List<AchievementWithProgress> getClosestToUnlock() {
    return lockedAchievements
        .where((a) => a.progress > 0)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
  }
}

/// Notifier for managing achievements
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final AchievementManager _manager;
  final GameAnalytics? _analytics;

  AchievementsNotifier(this._manager, [this._analytics])
      : super(
          const AchievementsState(
            allAchievements: {},
            unlockedAchievements: [],
            lockedAchievements: [],
            totalUnlocked: 0,
            completionPercentage: 0,
            isLoading: true,
          ),
        ) {
    _initializeAchievements();
  }

  /// Initialize achievements with progress tracking
  void _initializeAchievements() {
    final achievements = _manager.achievements;
    final withProgress = <String, AchievementWithProgress>{};

    for (final entry in achievements.entries) {
      final achievement = entry.value;
      final (rarity, progress, current, max) =
          _calculateProgress(achievement.id);

      withProgress[entry.key] = AchievementWithProgress(
        achievement: achievement,
        rarity: rarity,
        progress: progress,
        progressCurrent: current,
        progressMax: max,
        unlockedAt: achievement.unlockedAt,
      );
    }

    final unlocked = withProgress.values
        .where((a) => a.achievement.isUnlocked)
        .toList();
    final locked = withProgress.values
        .where((a) => !a.achievement.isUnlocked)
        .toList();

    unlocked.sort((a, b) {
      if (a.unlockedAt == null || b.unlockedAt == null) return 0;
      return b.unlockedAt!.compareTo(a.unlockedAt!);
    });

    state = AchievementsState(
      allAchievements: withProgress,
      unlockedAchievements: unlocked,
      lockedAchievements: locked,
      lastUnlocked: unlocked.isNotEmpty ? unlocked.first : null,
      totalUnlocked: unlocked.length,
      completionPercentage: withProgress.isEmpty
          ? 0
          : unlocked.length / withProgress.length,
      isLoading: false,
    );
  }

  /// Calculate progress for an achievement based on analytics
  (AchievementRarity, double, int, int) _calculateProgress(String id) {
    if (_analytics == null) {
      return (AchievementRarity.common, 0, 0, 1);
    }

    switch (id) {
      case 'first_win':
        final progress = _analytics!.baseStats.playerAWins > 0 ? 1.0 : 0.0;
        return (
          AchievementRarity.common,
          progress,
          _analytics!.baseStats.playerAWins,
          1,
        );

      case 'ten_wins':
        final current = _analytics!.baseStats.playerAWins;
        return (
          AchievementRarity.uncommon,
          (current / 10).clamp(0, 1),
          current,
          10,
        );

      case 'fifty_wins':
        final current = _analytics!.baseStats.playerAWins;
        return (
          AchievementRarity.rare,
          (current / 50).clamp(0, 1),
          current,
          50,
        );

      case 'hundred_wins':
        final current = _analytics!.baseStats.playerAWins;
        return (
          AchievementRarity.epic,
          (current / 100).clamp(0, 1),
          current,
          100,
        );

      case 'beat_easy':
      case 'beat_medium':
      case 'beat_hard':
        return (AchievementRarity.uncommon, 0, 0, 1);

      case 'win_streak_5':
        final current = _analytics!.baseStats.playerAWinStreak;
        return (
          AchievementRarity.uncommon,
          (current / 5).clamp(0, 1),
          current,
          5,
        );

      case 'win_streak_10':
        final current = _analytics!.baseStats.playerAWinStreak;
        return (
          AchievementRarity.rare,
          (current / 10).clamp(0, 1),
          current,
          10,
        );

      case 'perfect_game':
        return (AchievementRarity.epic, 0, 0, 1);

      default:
        return (AchievementRarity.common, 0, 0, 1);
    }
  }

  /// Unlock an achievement
  void unlockAchievement(String id) {
    _manager.achievements[id]?.unlock();
    _initializeAchievements();
  }

  /// Refresh achievement progress from analytics
  void refreshProgress(GameAnalytics analytics) {
    _initializeAchievements();
  }
}

/// Riverpod provider for shared achievement manager
final achievementManagerProvider = Provider<AchievementManager>((ref) {
  return AchievementManager();
});

/// Riverpod provider for achievements state
final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  final manager = ref.watch(achievementManagerProvider);
  return AchievementsNotifier(manager);
});

/// Convenience selector for unlocked achievements
final unlockedAchievementsProvider = Provider<List<AchievementWithProgress>>(
  (ref) => ref.watch(achievementsProvider).unlockedAchievements,
);

/// Convenience selector for locked achievements
final lockedAchievementsProvider = Provider<List<AchievementWithProgress>>(
  (ref) => ref.watch(achievementsProvider).lockedAchievements,
);

/// Convenience selector for completion percentage
final achievementCompletionProvider = Provider<double>(
  (ref) => ref.watch(achievementsProvider).completionPercentage,
);
