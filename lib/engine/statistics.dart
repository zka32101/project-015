import 'models.dart';

/// Tracks game statistics: win/loss records, streaks, win rates, etc.
class GameStatistics {
  /// Total games played (against AI or local 2-player)
  int totalGames = 0;

  /// Games won by player A
  int playerAWins = 0;

  /// Games won by player B
  int playerBWins = 0;

  /// Games ended in draw
  int draws = 0;

  /// Current win streak for player A
  int playerAWinStreak = 0;

  /// Current win streak for player B
  int playerBWinStreak = 0;

  /// Longest win streak ever for player A
  int playerALongestStreak = 0;

  /// Longest win streak ever for player B
  int playerBLongestStreak = 0;

  /// Win rate for player A against each AI difficulty
  final Map<String, GameDifficultyStats> statsByDifficulty = {
    'local': GameDifficultyStats(),
    'easy': GameDifficultyStats(),
    'medium': GameDifficultyStats(),
    'hard': GameDifficultyStats(),
  };

  /// Record a completed game result
  void recordGame({
    required GameResult result,
    required String? aiDifficultyLabel,
  }) {
    final difficulty = aiDifficultyLabel ?? 'local';

    totalGames++;

    switch (result) {
      case GameResult.playerAWins:
        playerAWins++;
        playerAWinStreak++;
        playerBWinStreak = 0;
        if (playerAWinStreak > playerALongestStreak) {
          playerALongestStreak = playerAWinStreak;
        }
        statsByDifficulty[difficulty]?.wins++;
        break;
      case GameResult.playerBWins:
        playerBWins++;
        playerBWinStreak++;
        playerAWinStreak = 0;
        if (playerBWinStreak > playerBLongestStreak) {
          playerBLongestStreak = playerBWinStreak;
        }
        statsByDifficulty[difficulty]?.losses++;
        break;
      case GameResult.draw:
        draws++;
        playerAWinStreak = 0;
        playerBWinStreak = 0;
        statsByDifficulty[difficulty]?.draws++;
        break;
      case GameResult.ongoing:
        // Should not happen
        break;
    }

    statsByDifficulty[difficulty]?.totalGames++;
  }

  /// Get win rate for player A (0.0 to 1.0, or NaN if no games)
  double get playerAWinRate {
    if (totalGames == 0) return double.nan;
    return playerAWins / totalGames;
  }

  /// Get win rate for player B (0.0 to 1.0, or NaN if no games)
  double get playerBWinRate {
    if (totalGames == 0) return double.nan;
    return playerBWins / totalGames;
  }

  /// Format win rate as percentage string
  String formatWinRate(double winRate) {
    if (winRate.isNaN) return 'N/A';
    return '${(winRate * 100).toStringAsFixed(1)}%';
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'playerAWins': playerAWins,
      'playerBWins': playerBWins,
      'draws': draws,
      'playerAWinStreak': playerAWinStreak,
      'playerBWinStreak': playerBWinStreak,
      'playerALongestStreak': playerALongestStreak,
      'playerBLongestStreak': playerBLongestStreak,
      'statsByDifficulty': {
        for (final entry in statsByDifficulty.entries)
          entry.key: entry.value.toJson(),
      },
    };
  }

  /// Create from JSON
  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    final stats = GameStatistics();
    stats.totalGames = json['totalGames'] ?? 0;
    stats.playerAWins = json['playerAWins'] ?? 0;
    stats.playerBWins = json['playerBWins'] ?? 0;
    stats.draws = json['draws'] ?? 0;
    stats.playerAWinStreak = json['playerAWinStreak'] ?? 0;
    stats.playerBWinStreak = json['playerBWinStreak'] ?? 0;
    stats.playerALongestStreak = json['playerALongestStreak'] ?? 0;
    stats.playerBLongestStreak = json['playerBLongestStreak'] ?? 0;

    final diffStats = json['statsByDifficulty'] as Map<String, dynamic>?;
    if (diffStats != null) {
      for (final entry in diffStats.entries) {
        if (stats.statsByDifficulty.containsKey(entry.key)) {
          stats.statsByDifficulty[entry.key] =
              GameDifficultyStats.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    }

    return stats;
  }
}

/// Statistics for games at a specific difficulty level
class GameDifficultyStats {
  int totalGames = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;

  double get winRate {
    if (totalGames == 0) return double.nan;
    return wins / totalGames;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'draws': draws,
    };
  }

  factory GameDifficultyStats.fromJson(Map<String, dynamic> json) {
    final stats = GameDifficultyStats();
    stats.totalGames = json['totalGames'] ?? 0;
    stats.wins = json['wins'] ?? 0;
    stats.losses = json['losses'] ?? 0;
    stats.draws = json['draws'] ?? 0;
    return stats;
  }
}
