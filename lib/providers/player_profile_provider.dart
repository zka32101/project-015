import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_analytics.dart';
import '../engine/game_record.dart';
import 'achievements_provider.dart';
import 'game_records_provider.dart';

/// Player profile with aggregated statistics and achievements
class PlayerProfile {
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int currentStreak;
  final int bestStreak;
  final double averageGameDuration;
  final int totalMoves;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final double achievementCompletion;
  final List<GameRecord> recentGames;
  final DateTime? lastGamePlayed;
  final String skillLevel;
  final int estimatedRating;

  const PlayerProfile({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.averageGameDuration,
    required this.totalMoves,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
    required this.achievementCompletion,
    required this.recentGames,
    required this.lastGamePlayed,
    required this.skillLevel,
    required this.estimatedRating,
  });

  /// Get player level based on wins
  String getPlayerLevel() {
    if (wins < 5) return 'ビギナー';
    if (wins < 10) return 'ノービス';
    if (wins < 25) return 'アマチュア';
    if (wins < 50) return 'セミプロ';
    if (wins < 100) return 'プロ';
    return 'マスター';
  }

  /// Get recent performance (last 10 games)
  double getRecentWinRate() {
    if (recentGames.isEmpty) return 0.0;
    final recentWins = recentGames
        .take(10)
        .where((g) => g.result == GameResult.playerAWins)
        .length;
    return recentWins / (recentGames.take(10).length);
  }

  /// Get performance trend (improvement indicator)
  String getPerformanceTrend() {
    if (recentGames.length < 5) return '→';

    final oldAverage = recentGames
        .skip(10)
        .take(10)
        .where((g) => g.result == GameResult.playerAWins)
        .length /
        (10.0);
    final newAverage = getRecentWinRate();

    if (newAverage > oldAverage + 0.1) return '↗ 上昇中';
    if (newAverage < oldAverage - 0.1) return '↘ 下降中';
    return '→ 安定';
  }

  /// Calculate total hours played
  double getTotalHoursPlayed() {
    return totalMoves / 8.0; // Rough estimate: ~8 moves per minute per player
  }
}

/// State for player profile
class PlayerProfileState {
  final PlayerProfile profile;
  final bool isLoading;
  final String? error;

  const PlayerProfileState({
    required this.profile,
    this.isLoading = false,
    this.error,
  });

  /// Create a copy with modified fields
  PlayerProfileState copyWith({
    PlayerProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return PlayerProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for player profile
class PlayerProfileNotifier extends StateNotifier<PlayerProfileState> {
  final GameAnalytics _analytics;

  PlayerProfileNotifier(this._analytics, GameRecordsState recordsState, AchievementsState achievementsState)
      : super(
          PlayerProfileState(
            profile: _buildProfile(_analytics, recordsState, achievementsState),
            isLoading: false,
          ),
        );

  /// Build player profile from analytics and records
  static PlayerProfile _buildProfile(
    GameAnalytics analytics,
    GameRecordsState recordsState,
    AchievementsState achievementsState,
  ) {
    final stats = analytics.baseStats;
    final records = recordsState.allRecords;

    // Calculate win/loss/draw counts
    int wins = 0, losses = 0, draws = 0;
    for (final record in records) {
      if (record.result == GameResult.playerAWins) {
        wins++;
      } else if (record.result == GameResult.playerBWins) {
        losses++;
      } else {
        draws++;
      }
    }

    final totalGames = records.length;
    final winRate = totalGames > 0 ? wins / totalGames : 0.0;

    // Calculate average game duration
    double averageDuration = 0.0;
    if (records.isNotEmpty) {
      final totalDuration =
          records.fold<int>(0, (sum, r) => sum + r.durationSeconds);
      averageDuration = totalDuration / records.length;
    }

    // Calculate total moves
    final totalMoves = records.fold<int>(0, (sum, r) => sum + r.totalMoves);

    // Recent games (last 5)
    final recentGames = records.length > 5 ? records.sublist(0, 5) : records;

    // Last game played
    final lastGamePlayed = records.isNotEmpty ? records.first.playedAt : null;

    // Achievement counts
    final achievementsUnlocked = achievementsState.totalUnlocked;
    final achievementsTotal = achievementsState.allAchievements.length;
    final achievementCompletion = achievementsState.completionPercentage;

    // Estimate skill rating (simple formula)
    final estimatedRating = (wins * 10) + (stats.playerAWinStreak * 5);

    return PlayerProfile(
      totalGames: totalGames,
      wins: wins,
      losses: losses,
      draws: draws,
      winRate: winRate,
      currentStreak: stats.playerAWinStreak,
      bestStreak: stats.playerALongestStreak,
      averageGameDuration: averageDuration,
      totalMoves: totalMoves,
      achievementsUnlocked: achievementsUnlocked,
      achievementsTotal: achievementsTotal,
      achievementCompletion: achievementCompletion,
      recentGames: recentGames,
      lastGamePlayed: lastGamePlayed,
      skillLevel: 'Player',
      estimatedRating: estimatedRating,
    );
  }

  /// Refresh profile data
  void refresh(GameRecordsState recordsState, AchievementsState achievementsState) {
    state = state.copyWith(
      profile: _buildProfile(_analytics, recordsState, achievementsState),
    );
  }
}

/// Riverpod provider for game analytics
final gameAnalyticsProvider = Provider<GameAnalytics>((ref) {
  return GameAnalytics();
});

/// Riverpod provider for player profile
final playerProfileProvider =
    StateNotifierProvider<PlayerProfileNotifier, PlayerProfileState>((ref) {
  final analytics = ref.watch(gameAnalyticsProvider);
  final recordsState = ref.watch(gameRecordsProvider);
  final achievementsState = ref.watch(achievementsProvider);

  return PlayerProfileNotifier(analytics, recordsState, achievementsState);
});

/// Convenience selector for player profile
final playerLevelProvider = Provider<String>((ref) {
  final profile = ref.watch(playerProfileProvider).profile;
  return profile.getPlayerLevel();
});

/// Convenience selector for recent win rate
final recentWinRateProvider = Provider<double>((ref) {
  final profile = ref.watch(playerProfileProvider).profile;
  return profile.getRecentWinRate();
});

/// Convenience selector for performance trend
final performanceTrendProvider = Provider<String>((ref) {
  final profile = ref.watch(playerProfileProvider).profile;
  return profile.getPerformanceTrend();
});

/// Convenience selector for total hours played
final totalHoursPlayedProvider = Provider<double>((ref) {
  final profile = ref.watch(playerProfileProvider).profile;
  return profile.getTotalHoursPlayed();
});
