import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_record.dart';
import 'game_records_provider.dart';

/// Analytics for a specific difficulty level
class DifficultyAnalytics {
  final String difficulty;
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final double averageDuration;
  final int totalMoves;

  const DifficultyAnalytics({
    required this.difficulty,
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.averageDuration,
    required this.totalMoves,
  });

  /// Get emoji for difficulty
  String getEmoji() {
    switch (difficulty) {
      case 'easy':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'hard':
        return '🔴';
      default:
        return '👥'; // Local play
    }
  }

  /// Get label for difficulty
  String getLabel() {
    switch (difficulty) {
      case 'easy':
        return 'かんたん';
      case 'medium':
        return 'ふつう';
      case 'hard':
        return 'つよい';
      default:
        return 'ローカル';
    }
  }
}

/// Performance data point for trend analysis
class PerformancePoint {
  final int gameNumber;
  final DateTime date;
  final double winRate; // 0.0 to 1.0
  final int movesInGame;
  final int durationSeconds;

  const PerformancePoint({
    required this.gameNumber,
    required this.date,
    required this.winRate,
    required this.movesInGame,
    required this.durationSeconds,
  });
}

/// Game analytics state
class GameAnalyticsState {
  final List<GameRecord> allRecords;
  final List<DifficultyAnalytics> difficultyBreakdown;
  final List<PerformancePoint> recentPerformance;
  final double overallWinRate;
  final int totalGamesAnalyzed;
  final int gamesThisWeek;
  final int gamesThisMonth;
  final double averageDurationOverall;
  final bool isLoading;
  final String? error;

  const GameAnalyticsState({
    required this.allRecords,
    required this.difficultyBreakdown,
    required this.recentPerformance,
    required this.overallWinRate,
    required this.totalGamesAnalyzed,
    required this.gamesThisWeek,
    required this.gamesThisMonth,
    required this.averageDurationOverall,
    this.isLoading = false,
    this.error,
  });

  /// Get best performing difficulty
  DifficultyAnalytics? getBestPerformance() {
    if (difficultyBreakdown.isEmpty) return null;
    return difficultyBreakdown.reduce(
      (a, b) => a.winRate > b.winRate ? a : b,
    );
  }

  /// Get worst performing difficulty
  DifficultyAnalytics? getWorstPerformance() {
    if (difficultyBreakdown.isEmpty) return null;
    return difficultyBreakdown.reduce(
      (a, b) => a.winRate < b.winRate ? a : b,
    );
  }

  /// Calculate win rate trend (improving, stable, declining)
  String getTrend() {
    if (recentPerformance.length < 5) return '収集中';

    final firstHalf = recentPerformance
        .skip(recentPerformance.length ~/ 2)
        .fold<double>(0, (sum, p) => sum + p.winRate) /
        (recentPerformance.length / 2);

    final secondHalf = recentPerformance
        .take(recentPerformance.length ~/ 2)
        .fold<double>(0, (sum, p) => sum + p.winRate) /
        (recentPerformance.length / 2);

    final improvement = secondHalf - firstHalf;
    if (improvement > 0.1) return '📈 向上中';
    if (improvement < -0.1) return '📉 低下中';
    return '➡️ 安定';
  }

  /// Games per day average
  double getGamesPerDay() {
    if (allRecords.isEmpty) return 0;
    if (allRecords.length == 1) return 0;

    final oldestGame = allRecords.last.playedAt;
    final newestGame = allRecords.first.playedAt;
    final daysDiff = newestGame.difference(oldestGame).inDays;

    if (daysDiff == 0) return allRecords.length.toDouble();
    return allRecords.length / (daysDiff + 1);
  }
}

/// Notifier for game analytics
class GameAnalyticsNotifier extends StateNotifier<GameAnalyticsState> {
  GameAnalyticsNotifier(GameRecordsState recordsState)
      : super(
          _buildAnalytics(recordsState),
        );

  /// Build analytics from records
  static GameAnalyticsState _buildAnalytics(GameRecordsState recordsState) {
    final records = recordsState.allRecords;

    if (records.isEmpty) {
      return GameAnalyticsState(
        allRecords: [],
        difficultyBreakdown: [],
        recentPerformance: [],
        overallWinRate: 0,
        totalGamesAnalyzed: 0,
        gamesThisWeek: 0,
        gamesThisMonth: 0,
        averageDurationOverall: 0,
        isLoading: false,
      );
    }

    // Calculate difficulty breakdown
    final difficultyMap = <String, List<GameRecord>>{};
    for (final record in records) {
      final diff = record.aiDifficulty ?? 'local';
      difficultyMap.putIfAbsent(diff, () => []).add(record);
    }

    final difficultyBreakdown = difficultyMap.entries.map((entry) {
      final games = entry.value;
      final wins = games.where((g) => g.result == GameResult.playerAWins).length;
      final losses =
          games.where((g) => g.result == GameResult.playerBWins).length;
      final draws = games.where((g) => g.result == GameResult.draw).length;

      final avgDuration =
          games.fold<int>(0, (sum, g) => sum + g.durationSeconds) /
              games.length;
      final totalMoves =
          games.fold<int>(0, (sum, g) => sum + g.totalMoves);

      return DifficultyAnalytics(
        difficulty: entry.key,
        totalGames: games.length,
        wins: wins,
        losses: losses,
        draws: draws,
        winRate: games.isEmpty ? 0 : wins / games.length,
        averageDuration: avgDuration,
        totalMoves: totalMoves,
      );
    }).toList()
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Calculate overall statistics
    final totalWins = records.where((r) => r.result == GameResult.playerAWins).length;
    final overallWinRate = records.isEmpty ? 0.0 : totalWins / records.length;

    // Recent performance (last 20 games)
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    final gamesThisWeek =
        records.where((r) => r.playedAt.isAfter(oneWeekAgo)).length;
    final gamesThisMonth =
        records.where((r) => r.playedAt.isAfter(oneMonthAgo)).length;

    final avgDurationOverall = records.isEmpty
        ? 0.0
        : records.fold<int>(0, (sum, r) => sum + r.durationSeconds) /
            records.length;

    // Build recent performance trend
    final recentPerformance = <PerformancePoint>[];
    int runningWins = 0;
    for (int i = records.length - 1; i >= 0 && i >= records.length - 20; i--) {
      final record = records[i];
      if (record.result == GameResult.playerAWins) {
        runningWins++;
      }
      final gamesCount = records.length - i;
      final winRate = runningWins / gamesCount;

      recentPerformance.insert(
        0,
        PerformancePoint(
          gameNumber: gamesCount,
          date: record.playedAt,
          winRate: winRate,
          movesInGame: record.totalMoves,
          durationSeconds: record.durationSeconds,
        ),
      );
    }

    return GameAnalyticsState(
      allRecords: records,
      difficultyBreakdown: difficultyBreakdown,
      recentPerformance: recentPerformance,
      overallWinRate: overallWinRate,
      totalGamesAnalyzed: records.length,
      gamesThisWeek: gamesThisWeek,
      gamesThisMonth: gamesThisMonth,
      averageDurationOverall: avgDurationOverall,
      isLoading: false,
    );
  }

  /// Refresh analytics
  void refresh(GameRecordsState recordsState) {
    state = _buildAnalytics(recordsState);
  }
}

/// Riverpod provider for game analytics
final gameAnalyticsProvider =
    StateNotifierProvider<GameAnalyticsNotifier, GameAnalyticsState>((ref) {
  final recordsState = ref.watch(gameRecordsProvider);
  return GameAnalyticsNotifier(recordsState);
});

/// Convenience selector for difficulty breakdown
final difficultyBreakdownProvider = Provider<List<DifficultyAnalytics>>((ref) {
  return ref.watch(gameAnalyticsProvider).difficultyBreakdown;
});

/// Convenience selector for overall win rate
final overallWinRateProvider = Provider<double>((ref) {
  return ref.watch(gameAnalyticsProvider).overallWinRate;
});

/// Convenience selector for games this week
final gamesThisWeekProvider = Provider<int>((ref) {
  return ref.watch(gameAnalyticsProvider).gamesThisWeek;
});

/// Convenience selector for trend
final analyticsTrendProvider = Provider<String>((ref) {
  return ref.watch(gameAnalyticsProvider).getTrend();
});

/// Convenience selector for games per day
final gamesPerDayProvider = Provider<double>((ref) {
  return ref.watch(gameAnalyticsProvider).getGamesPerDay();
});
